/// تشغيل التلاوة آيةً آية: من أي آية، مع التكرار ووقفة التدبر.
///
/// يجري التشغيل على قائمة فيها ملف لكل آية، من الآية المختارة إلى آخر سورتها ثم
/// ما بعدها. يجلب المشغّل الملفات التالية مسبقاً، فتتتابع الآيات بلا فجوة إلا
/// الوقفة التي طلبها القارئ.
library;

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../data/quran/quran_models.dart';
import '../../data/quran/quran_repository.dart';
import 'audio_downloads.dart';
import 'recitation_handler.dart';
import 'reciters.dart';

/// ما يحتاجه التشغيل من مشغّل الصوت؛ يُستبدل في الاختبارات.
abstract class AudioEngine {
  /// رقم العنصر الجاري في القائمة.
  Stream<int?> get index;
  Stream<bool> get playing;

  /// هل ينتظر المشغّل وصول الصوت.
  Stream<bool> get loading;

  /// حين تنتهي القائمة.
  Stream<void> get completed;
  Stream<Object> get errors;

  /// يحمّل [tracks] قائمةً جاهزة للتشغيل من [start]، ويرمي خطأ إن تعذّر جلب
  /// الملف الأول.
  Future<void> load(List<AudioTrack> tracks, {int start = 0});
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(int index);
  Future<void> stop();
}

/// مشغّل الصوت في الجهاز.
class JustAudioEngine implements AudioEngine {
  JustAudioEngine() {
    RecitationHandler.instance?.attach(_player);
  }

  final _player = AudioPlayer();

  @override
  Stream<int?> get index => _player.currentIndexStream;

  @override
  Stream<bool> get playing => _player.playingStream;

  @override
  Stream<bool> get loading => _player.processingStateStream
      .map(
        (s) => s == ProcessingState.loading || s == ProcessingState.buffering,
      )
      .distinct();

  @override
  Stream<void> get completed => _player.processingStateStream.where(
    (s) => s == ProcessingState.completed,
  );

  @override
  Stream<Object> get errors => _player.errorStream;

  @override
  Future<void> load(List<AudioTrack> tracks, {int start = 0}) {
    // ما يعرضه الإشعار وشاشة القفل.
    RecitationHandler.instance?.setItems([
      for (final (i, t) in tracks.indexed)
        MediaItem(
          id: '$i:${t.uri}',
          title: t.title,
          artist: t.artist,
          album: 'تَدْبِير',
        ),
    ]);
    return _player.setAudioSources([
      for (final t in tracks) AudioSource.uri(t.uri),
    ], initialIndex: start);
  }

  @override
  Future<void> play() async {
    // يبدأ التشغيل دون انتظار نهايته، كما تفعل play() عادة.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> stop() => _player.stop();
}

/// ملف في قائمة التشغيل، وما يُعرض عنه في الإشعار.
class AudioTrack {
  final Uri uri;
  final String title;
  final String artist;

  const AudioTrack(this.uri, {required this.title, required this.artist});
}

/// قائمة التشغيل: ملف لكل عنصر، والآية التي يقرؤها.
class AudioQueue {
  final List<AudioTrack> tracks;

  /// الآية التي يقرؤها كل عنصر؛ والبسملة تحمل الآية التي تفتتحها.
  final List<Ayah> ayahs;

  const AudioQueue._(this.tracks, this.ayahs);

  /// مصدر كل عنصر.
  List<Uri> get urls => [for (final t in tracks) t.uri];

  /// من [from] إلى آخر سورتها، كل آية [repeat] مرة، بصوت [reciter].
  ///
  /// السورة التي تبدأ من أولها تُفتتح بالبسملة، إلا الفاتحة (فهي أولها)
  /// والتوبة. ومصدر كل ملف [source]: التنزيل، أو الإنترنت افتراضياً.
  factory AudioQueue.from(
    Ayah from,
    Reciter reciter, {
    int repeat = 1,
    Uri Function(int ayahId)? source,
  }) {
    final repo = QuranRepository.instance;
    final surah = repo.getSurah(from.surahNumber);
    final uriFor = source ?? reciter.urlFor;
    final tracks = <AudioTrack>[];
    final ayahs = <Ayah>[];
    void add(int fileId, Ayah ayah) {
      tracks.add(
        AudioTrack(
          uriFor(fileId),
          title:
              'سورة ${surah.name} · الآية '
              '${ArabicSearchNormalizer.toArabicDigits(ayah.ayahNumber)}',
          artist: reciter.name,
        ),
      );
      ayahs.add(ayah);
    }

    for (var n = from.ayahNumber; n <= surah.ayahCount; n++) {
      final ayah = repo.getAyah(surah.number, n);
      if (ayah == null) continue;
      if (n == 1 && surah.number != 1 && surah.number != 9) add(1, ayah);
      for (var i = 0; i < repeat; i++) {
        add(ayah.id, ayah);
      }
    }
    return AudioQueue._(tracks, ayahs);
  }

  /// أول عنصر للآية [ayah]، أو null إن لم تكن في القائمة.
  int? startOf(Ayah ayah) {
    final i = ayahs.indexWhere((a) => a.id == ayah.id);
    return i < 0 ? null : i;
  }
}

/// متحكم التلاوة المسموعة.
class QuranAudio extends ChangeNotifier {
  QuranAudio._(this._makeEngine);

  static QuranAudio _instance = QuranAudio._(JustAudioEngine.new);

  /// مشغّل التطبيق الوحيد.
  static QuranAudio get instance => _instance;

  /// للاختبارات: يضع مكانه مشغّلاً فوق محرك بديل.
  @visibleForTesting
  static set instance(QuranAudio audio) => _instance = audio;

  /// للاختبارات: مشغّل فوق [engine].
  @visibleForTesting
  factory QuranAudio.withEngine(AudioEngine engine) =>
      QuranAudio._(() => engine);

  final AudioEngine Function() _makeEngine;
  AudioEngine? _engine;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// المحرك، يُنشأ عند أول استخدام فلا تحتاج إليه الشاشات التي لا تشغّل شيئاً.
  AudioEngine get _player {
    final existing = _engine;
    if (existing != null) return existing;
    final engine = _engine = _makeEngine();
    // إيقاف الإشعار يغلق التلاوة، كما يفعل إيقاف الشريط.
    RecitationHandler.instance?.onStop = stop;
    _subscriptions.addAll([
      engine.index.listen(_onIndex),
      engine.playing.listen((p) {
        playing = p;
        notifyListeners();
      }),
      engine.loading.listen((l) {
        loading = l;
        notifyListeners();
      }),
      engine.completed.listen((_) => _onCompleted()),
      engine.errors.listen((_) => _fail()),
    ]);
    return engine;
  }

  static const _key = 'quran_audio';

  AudioQueue? _queue;
  Timer? _pauseTimer;

  /// الآية الجارية، أو null حين لا شيء يُتلى.
  Ayah? current;
  bool playing = false;
  bool loading = false;

  /// يُرفع حين تعذّر جلب التلاوة، ويُمسح عند التشغيل التالي؛ تعرضه الشاشات مرة.
  bool failed = false;

  /// هل التلاوة جارية، تعمل أو موقوفة مؤقتاً.
  bool get active => current != null;

  /// هل التشغيل موقوف لوقفة ما بعد الآية.
  bool get resting => _pauseTimer?.isActive ?? false;

  Map<String, dynamic> get _saved => UserDataStore.instance.featureState(_key);

  Reciter get reciter => reciterById(_saved['reciter'] as String?);

  /// كم مرة تُقرأ كل آية.
  int get repeat => (_saved['repeat'] as int? ?? 1).clamp(1, 10);

  /// ثواني الوقفة بعد كل آية للتدبر.
  int get pauseSeconds => (_saved['pause'] as int? ?? 0).clamp(0, 30);

  Future<void> _save(String key, Object value) async {
    await UserDataStore.instance.saveFeatureState(_key, {
      ..._saved,
      key: value,
    });
    notifyListeners();
  }

  /// يختار القارئ، ويعيد الآية الحالية بصوته.
  Future<void> setReciter(Reciter r) async {
    await _save('reciter', r.id);
    final now = current;
    if (now != null) await playFrom(now);
  }

  /// تكرار كل آية، من الآية الحالية فصاعداً.
  Future<void> setRepeat(int times) async {
    await _save('repeat', times);
    final now = current;
    if (now != null) await playFrom(now);
  }

  /// الوقفة بعد كل آية؛ تسري من الآية التالية.
  Future<void> setPauseSeconds(int seconds) => _save('pause', seconds);

  /// يبدأ التلاوة من [ayah] حتى آخر السورة ثم ما بعدها.
  Future<void> playFrom(Ayah ayah) async {
    _pauseTimer?.cancel();
    failed = false;
    current = ayah;
    loading = true;
    notifyListeners();
    // الآيات المنزّلة تُشغّل من الجهاز، والباقي من الإنترنت.
    final downloads = AudioDownloads.instance;
    await downloads.ready();
    final reciter = this.reciter;
    final queue = _queue = AudioQueue.from(
      ayah,
      reciter,
      repeat: repeat,
      source: (id) => downloads.sourceFor(reciter, id),
    );
    try {
      await _player.load(queue.tracks);
      if (!identical(queue, _queue)) return;
      await _player.play();
    } on Object {
      if (identical(queue, _queue)) _fail();
    }
  }

  /// يوقف مؤقتاً أو يستأنف.
  Future<void> toggle() async {
    if (resting) {
      // النقر أثناء الوقفة بعد الآية يكمل فوراً.
      _pauseTimer?.cancel();
      await _player.play();
      notifyListeners();
    } else if (playing) {
      await _player.pause();
    } else if (active) {
      await _player.play();
    }
  }

  Future<void> next() async {
    final now = current;
    if (now == null) return;
    final following = _neighbour(now, 1);
    if (following == null) return;
    final index = _queue?.startOf(following);
    if (index != null) {
      _pauseTimer?.cancel();
      await _player.seekTo(index);
      await _player.play();
    } else {
      await playFrom(following);
    }
  }

  Future<void> previous() async {
    final now = current;
    if (now == null) return;
    final before = _neighbour(now, -1);
    if (before == null) return;
    final index = _queue?.startOf(before);
    if (index != null) {
      _pauseTimer?.cancel();
      await _player.seekTo(index);
      await _player.play();
    } else {
      await playFrom(before);
    }
  }

  /// يوقف التلاوة ويغلق المشغّل.
  Future<void> stop() async {
    _pauseTimer?.cancel();
    _queue = null;
    current = null;
    playing = false;
    loading = false;
    notifyListeners();
    await _engine?.stop();
  }

  /// الآية على بعد [step] من [ayah] في المصحف، أو null عند طرفيه.
  static Ayah? _neighbour(Ayah ayah, int step) {
    final all = QuranRepository.instance.allAyahs;
    final i = ayah.id - 1 + step;
    return i < 0 || i >= all.length ? null : all[i];
  }

  void _onIndex(int? index) {
    final queue = _queue;
    if (index == null || queue == null || index >= queue.ayahs.length) return;
    final ayah = queue.ayahs[index];
    final previous = current;
    current = ayah;
    // تبدأ آية جديدة: الوقفة أولاً إن طلبها القارئ.
    if (previous != null && previous.id != ayah.id && pauseSeconds > 0) {
      _player.pause();
      _pauseTimer?.cancel();
      _pauseTimer = Timer(Duration(seconds: pauseSeconds), () {
        if (identical(queue, _queue)) _player.play();
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _onCompleted() {
    final last = _queue?.ayahs.last;
    if (last == null) return;
    final following = _neighbour(last, 1);
    if (following == null) {
      stop();
      return;
    }
    // إلى السورة التالية، بعد نفس الوقفة التي بين الآيات.
    if (pauseSeconds > 0) {
      _pauseTimer?.cancel();
      _pauseTimer = Timer(
        Duration(seconds: pauseSeconds),
        () => playFrom(following),
      );
      notifyListeners();
    } else {
      playFrom(following);
    }
  }

  void _fail() {
    _pauseTimer?.cancel();
    _queue = null;
    current = null;
    playing = false;
    loading = false;
    failed = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}
