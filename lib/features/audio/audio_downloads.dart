/// تنزيل التلاوات للاستماع دون إنترنت، سورةً سورة لكل قارئ.
///
/// الملفات في مساحة التطبيق الخاصة باسم `recitations/<القارئ>/<n>.mp3`، ملف لكل
/// آية برقمها في المصحف، فالمجلد نفسه يقول ما نُزّل. والسورة تحتاج آياتها،
/// والبسملة (ملف الآية ١) إلا الفاتحة والتوبة، وتشترك فيها مع غيرها.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/quran/quran_repository.dart';
import 'reciters.dart';

/// ينزّل [url] إلى [to]، ويرمي خطأ إن لم يستطع.
typedef AudioFetch = Future<void> Function(Uri url, File to);

class AudioDownloads extends ChangeNotifier {
  AudioDownloads._(this._root, this._fetch);

  static AudioDownloads _instance = AudioDownloads._(
    () async => Directory(
      '${(await getApplicationSupportDirectory()).path}/recitations',
    ),
    _httpFetch,
  );

  /// تنزيلات التطبيق.
  static AudioDownloads get instance => _instance;

  /// للاختبارات: تنزيلات في [root] بجالب [fetch].
  @visibleForTesting
  static set instance(AudioDownloads downloads) => _instance = downloads;

  /// للاختبارات: مدير على [root] بجالب [fetch].
  @visibleForTesting
  factory AudioDownloads.at(Directory root, AudioFetch fetch) =>
      AudioDownloads._(() async => root, fetch);

  final Future<Directory> Function() _root;
  final AudioFetch _fetch;

  Directory? _dir;
  Future<void>? _ready;

  /// ملفات الآيات على الجهاز، لكل قارئ.
  final _have = <String, Set<int>>{};

  /// السور قيد التنزيل ونسبة تقدّمها (0..1).
  final _progress = <(String, int), double>{};
  final _cancelled = <(String, int)>{};

  /// السور التي فشل آخر تنزيل لها، حتى تُجرّب ثانية.
  final failed = <(String, int)>{};

  /// يقرأ ما على الجهاز مرة واحدة، وكل ما بعده يُبنى عليه.
  Future<void> ready() => _ready ??= _scan().catchError((Object e) {
    // تُعاد المحاولة في المرة القادمة بدل أن يبقى الفشل محفوظاً.
    _ready = null;
    throw e;
  });

  Future<void> _scan() async {
    final dir = _dir = await _root();
    if (!dir.existsSync()) return;
    for (final folder in dir.listSync().whereType<Directory>()) {
      final ids = <int>{};
      for (final f in folder.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (!name.endsWith('.mp3')) continue;
        final id = int.tryParse(name.substring(0, name.length - 4));
        if (id != null) ids.add(id);
      }
      _have[folder.uri.pathSegments.where((s) => s.isNotEmpty).last] = ids;
    }
  }

  File _file(Reciter r, int ayahId) =>
      File('${_dir!.path}/${r.id}/$ayahId.mp3');

  /// هل ملف الآية [ayahId] بصوت [reciter] على الجهاز.
  bool has(Reciter reciter, int ayahId) =>
      _have[reciter.id]?.contains(ayahId) ?? false;

  /// مصدر تشغيل الآية [ayahId]: ملفها المنزّل، أو الإنترنت.
  Uri sourceFor(Reciter reciter, int ayahId) => has(reciter, ayahId)
      ? _file(reciter, ayahId).uri
      : reciter.urlFor(ayahId);

  /// الملفات التي تحتاجها [surah]: البسملة ثم آياتها.
  static List<int> filesOf(int surah) {
    final repo = QuranRepository.instance;
    final first = repo.getAyah(surah, 1)!.id;
    return [
      if (surah != 1 && surah != 9) 1,
      for (var i = 0; i < repo.getSurah(surah).ayahCount; i++) first + i,
    ];
  }

  /// هل تُشغّل [surah] بصوت [reciter] كاملة دون إنترنت.
  bool isDownloaded(Reciter reciter, int surah) =>
      filesOf(surah).every((id) => has(reciter, id));

  /// تقدّم تنزيل [surah]، أو null إن لم يكن جارياً.
  double? progressOf(Reciter reciter, int surah) =>
      _progress[(reciter.id, surah)];

  /// ينزّل [surah] بصوت [reciter]، ويعيد true إن اكتملت.
  Future<bool> downloadSurah(Reciter reciter, int surah) async {
    await ready();
    final key = (reciter.id, surah);
    if (_progress.containsKey(key)) return false;
    failed.remove(key);
    _cancelled.remove(key);
    final all = filesOf(surah);
    final missing = all.where((id) => !has(reciter, id)).toList();
    var done = all.length - missing.length;
    _progress[key] = done / all.length;
    notifyListeners();
    final folder = Directory('${_dir!.path}/${reciter.id}');
    await folder.create(recursive: true);
    final have = _have.putIfAbsent(reciter.id, () => <int>{});
    try {
      // بضعة ملفات معاً: سريع، دون إثقال الاتصال البطيء.
      for (var i = 0; i < missing.length; i += 4) {
        if (_cancelled.contains(key)) return false;
        await Future.wait([
          for (final id in missing.skip(i).take(4))
            () async {
              final file = _file(reciter, id);
              final part = File('${file.path}.part');
              await _fetch(reciter.urlFor(id), part);
              await part.rename(file.path);
              have.add(id);
              done++;
              _progress[key] = done / all.length;
              notifyListeners();
            }(),
        ]);
      }
      return true;
    } on Object {
      failed.add(key);
      return false;
    } finally {
      _progress.remove(key);
      _cancelled.remove(key);
      notifyListeners();
    }
  }

  /// يوقف تنزيل [surah] بعد الملفات التي بدأت فعلاً.
  void cancel(Reciter reciter, int surah) {
    _cancelled.add((reciter.id, surah));
  }

  /// يحذف سورة، وتبقى البسملة ما دامت سورة أخرى منزّلة تحتاجها.
  Future<void> deleteSurah(Reciter reciter, int surah) async {
    await ready();
    final have = _have[reciter.id];
    if (have == null) return;
    // تحتفظ السورة بالبسملة ما دامت إحدى آياتها هنا؛ والبسملة وحدها (وهي أول
    // الفاتحة أيضاً) لا تمنع الحذف.
    final shared = <int>{
      for (var s = 1; s <= 114; s++)
        if (s != surah && filesOf(s).any((id) => id != 1 && has(reciter, id)))
          ...filesOf(s),
    };
    for (final id in filesOf(surah)) {
      if (shared.contains(id)) continue;
      final file = _file(reciter, id);
      if (file.existsSync()) await file.delete();
      have.remove(id);
    }
    notifyListeners();
  }

  /// يحذف كل تلاوات [reciter] المنزّلة.
  Future<void> deleteAll(Reciter reciter) async {
    await ready();
    final folder = Directory('${_dir!.path}/${reciter.id}');
    if (folder.existsSync()) await folder.delete(recursive: true);
    _have.remove(reciter.id);
    notifyListeners();
  }

  /// المساحة التي تشغلها تنزيلات [reciter]، بالبايت.
  Future<int> bytesOf(Reciter reciter) async {
    await ready();
    final folder = Directory('${_dir!.path}/${reciter.id}');
    if (!folder.existsSync()) return 0;
    var total = 0;
    for (final f in folder.listSync().whereType<File>()) {
      total += f.lengthSync();
    }
    return total;
  }
}

/// ينزّل [url] إلى [to] عبر HTTPS.
Future<void> _httpFetch(Uri url, File to) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    await response.pipe(to.openWrite());
  } finally {
    client.close();
  }
}
