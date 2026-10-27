/// تشغيل التلاوة آيةً آية: من أي آية، مع التكرار ووقفة التدبر.
///
/// Playback runs through a queue of one file per ayah, from the chosen
/// ayah to the end of its surah, then on to the next surah. The player
/// fetches the next files ahead, so the ayahs follow one another without a
/// gap, except for the pause the reader asked for after each one.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../core/storage/user_data_store.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../quran/data/quran_models.dart';
import '../quran/data/quran_repository.dart';
import 'audio_downloads.dart';
import 'reciters.dart';

/// What the playback needs from an audio player; replaceable in tests.
abstract class AudioEngine {
  /// The item now playing in the queue.
  Stream<int?> get index;
  Stream<bool> get playing;

  /// Whether the player is waiting for audio to arrive.
  Stream<bool> get loading;

  /// Fires when the queue has played to its end.
  Stream<void> get completed;
  Stream<Object> get errors;

  /// Loads [tracks] as the queue, ready to play from [start]; throws when
  /// the first file cannot be fetched.
  Future<void> load(List<AudioTrack> tracks, {int start = 0});
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(int index);
  Future<void> stop();
}

/// The device's audio player.
class JustAudioEngine implements AudioEngine {
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
  Future<void> load(List<AudioTrack> tracks, {int start = 0}) =>
      _player.setAudioSources([
        for (final (i, t) in tracks.indexed)
          AudioSource.uri(
            t.uri,
            // What the notification and the lock screen show.
            tag: MediaItem(
              id: '$i:${t.uri}',
              title: t.title,
              artist: t.artist,
              album: 'تَدْبِير',
            ),
          ),
      ], initialIndex: start);

  @override
  Future<void> play() async {
    // Starts playing without waiting for the end, as play() otherwise does.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> stop() => _player.stop();
}

/// ملف واحد في قائمة التشغيل وما يُعرض عنه في الإشعار.
class AudioTrack {
  final Uri uri;
  final String title;
  final String artist;

  const AudioTrack(this.uri, {required this.title, required this.artist});
}

/// قائمة التشغيل: ملف لكل عنصر، والآية التي يقرؤها.
class AudioQueue {
  final List<AudioTrack> tracks;

  /// The ayah each item recites; the basmala carries the ayah it opens.
  final List<Ayah> ayahs;

  const AudioQueue._(this.tracks, this.ayahs);

  /// Where each item plays from.
  List<Uri> get urls => [for (final t in tracks) t.uri];

  /// From [from] to the end of its surah, each ayah [repeat] times, by
  /// [reciter]. A surah begun from its first ayah opens with the basmala,
  /// except al-Fatiha, whose first ayah it is, and at-Tawbah. Each file
  /// comes from [source] (a download, or the internet by default).
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

  /// The first item of [ayah], or null if it is not in the queue.
  int? startOf(Ayah ayah) {
    final i = ayahs.indexWhere((a) => a.id == ayah.id);
    return i < 0 ? null : i;
  }
}

/// متحكم التلاوة المسموعة.
class QuranAudio extends ChangeNotifier {
  QuranAudio._(this._makeEngine);

  static QuranAudio _instance = QuranAudio._(JustAudioEngine.new);

  /// The app's one player.
  static QuranAudio get instance => _instance;

  /// Puts a player over a stand-in engine in its place, for tests.
  @visibleForTesting
  static set instance(QuranAudio audio) => _instance = audio;

  /// A player over [engine], for tests.
  @visibleForTesting
  factory QuranAudio.withEngine(AudioEngine engine) =>
      QuranAudio._(() => engine);

  final AudioEngine Function() _makeEngine;
  AudioEngine? _engine;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// The player, made on first use so screens that never play need none.
  AudioEngine get _player {
    final existing = _engine;
    if (existing != null) return existing;
    final engine = _engine = _makeEngine();
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

  /// The ayah being recited, or null when nothing plays.
  Ayah? current;
  bool playing = false;
  bool loading = false;

  /// Set when the recitation could not be fetched; cleared on the next
  /// play. Screens show it once.
  bool failed = false;

  /// Whether a recitation is under way, playing or paused.
  bool get active => current != null;

  /// Whether playback is held for the pause after an ayah.
  bool get resting => _pauseTimer?.isActive ?? false;

  Map<String, dynamic> get _saved => UserDataStore.instance.featureState(_key);

  /// القارئ المختار.
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

  /// Sets how often each ayah is read, from the current ayah on.
  Future<void> setRepeat(int times) async {
    await _save('repeat', times);
    final now = current;
    if (now != null) await playFrom(now);
  }

  /// Sets the pause after each ayah; it applies from the next one.
  Future<void> setPauseSeconds(int seconds) => _save('pause', seconds);

  /// يبدأ التلاوة من [ayah] حتى آخر السورة ثم ما بعدها.
  Future<void> playFrom(Ayah ayah) async {
    _pauseTimer?.cancel();
    failed = false;
    current = ayah;
    loading = true;
    notifyListeners();
    // Downloaded ayahs play from the device; the rest stream.
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
      // A tap during the pause after an ayah goes on at once.
      _pauseTimer?.cancel();
      await _player.play();
      notifyListeners();
    } else if (playing) {
      await _player.pause();
    } else if (active) {
      await _player.play();
    }
  }

  /// الآية التالية.
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

  /// الآية السابقة.
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

  /// The ayah [step] places from [ayah] in the Mushaf, or null at its ends.
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
    // A new ayah begins: rest first, if the reader asked for a pause.
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
    // On to the next surah, after the same pause as between ayahs.
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
