/// تنزيل التلاوات للاستماع دون إنترنت، سورةً سورة لكل قارئ.
///
/// Files live in the app's own storage as `recitations/<reciter>/<n>.mp3`,
/// one per ayah numbered as in the Mushaf, so the folder itself says what
/// is downloaded. A surah needs its ayahs and, unless it is al-Fatiha or
/// at-Tawbah, the basmala (ayah 1's file), which it shares with the others.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../quran/data/quran_repository.dart';
import 'reciters.dart';

/// Fetches [url] into [to]; throws when it cannot.
typedef AudioFetch = Future<void> Function(Uri url, File to);

/// مدير تنزيل التلاوات.
class AudioDownloads extends ChangeNotifier {
  AudioDownloads._(this._root, this._fetch);

  static AudioDownloads _instance = AudioDownloads._(
    () async => Directory(
      '${(await getApplicationSupportDirectory()).path}/recitations',
    ),
    _httpFetch,
  );

  /// The app's downloads.
  static AudioDownloads get instance => _instance;

  /// Downloads kept in [root] and fetched with [fetch], for tests.
  @visibleForTesting
  static set instance(AudioDownloads downloads) => _instance = downloads;

  /// A manager over [root] that fetches with [fetch], for tests.
  @visibleForTesting
  factory AudioDownloads.at(Directory root, AudioFetch fetch) =>
      AudioDownloads._(() async => root, fetch);

  final Future<Directory> Function() _root;
  final AudioFetch _fetch;

  Directory? _dir;
  Future<void>? _ready;

  /// The ayah files on disk, by reciter.
  final _have = <String, Set<int>>{};

  /// Surahs being downloaded and how far along they are, 0 to 1.
  final _progress = <(String, int), double>{};
  final _cancelled = <(String, int)>{};

  /// Surahs whose last download failed, until they are tried again.
  final failed = <(String, int)>{};

  /// Reads what is on disk once; everything else follows from it.
  Future<void> ready() => _ready ??= () async {
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
  }();

  File _file(Reciter r, int ayahId) =>
      File('${_dir!.path}/${r.id}/$ayahId.mp3');

  /// Whether [reciter]'s file of the ayah numbered [ayahId] is on the device.
  bool has(Reciter reciter, int ayahId) =>
      _have[reciter.id]?.contains(ayahId) ?? false;

  /// Where to play the ayah numbered [ayahId] from: its downloaded file, or
  /// the internet.
  Uri sourceFor(Reciter reciter, int ayahId) => has(reciter, ayahId)
      ? _file(reciter, ayahId).uri
      : reciter.urlFor(ayahId);

  /// The files [surah] needs: its basmala, then its ayahs.
  static List<int> filesOf(int surah) {
    final repo = QuranRepository.instance;
    final first = repo.getAyah(surah, 1)!.id;
    return [
      if (surah != 1 && surah != 9) 1,
      for (var i = 0; i < repo.getSurah(surah).ayahCount; i++) first + i,
    ];
  }

  /// Whether all of [surah] by [reciter] can play without the internet.
  bool isDownloaded(Reciter reciter, int surah) =>
      filesOf(surah).every((id) => has(reciter, id));

  /// How far [surah]'s download has come, or null when none is running.
  double? progressOf(Reciter reciter, int surah) =>
      _progress[(reciter.id, surah)];

  /// يُنزّل سورة بصوت [reciter]؛ يعيد true إذا اكتملت.
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
      // A few at a time: quick, without crowding a slow connection.
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

  /// Stops [surah]'s download after the files already on their way.
  void cancel(Reciter reciter, int surah) {
    _cancelled.add((reciter.id, surah));
  }

  /// يحذف سورة؛ وتبقى البسملة ما دامت سورة أخرى منزّلة تحتاجها.
  Future<void> deleteSurah(Reciter reciter, int surah) async {
    await ready();
    final have = _have[reciter.id];
    if (have == null) return;
    // A surah keeps the basmala only while one of its own ayahs is here;
    // the basmala alone (al-Fatiha's first ayah too) holds nothing back.
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

  /// The space [reciter]'s downloads take, in bytes.
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

/// Downloads [url] into [to] over HTTPS.
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
