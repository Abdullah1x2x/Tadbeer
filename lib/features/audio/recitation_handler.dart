/// التلاوة خارج التطبيق: إشعار التشغيل وأزرار شاشة القفل.
///
/// يُبقي audio_service التلاوة تعمل بعد خروج التطبيق من الشاشة. وهذا الوسيط
/// يعرض حالة المشغّل في الإشعار، ويعيد أزرار الإشعار إلى المشغّل.
library;

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// يربط مشغّل التلاوة بإشعار النظام.
class RecitationHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  /// الوسيط المنشأ عند الإقلاع، أو null حيث لا تشغيل في الخلفية (سطح المكتب
  /// والاختبارات).
  static RecitationHandler? instance;

  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// يربط أزرار الإشعار وشاشة القفل بمتحكم التلاوة في التطبيق.
  Future<void> Function()? onStop;
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;
  Future<void> Function(int index)? onSkipToQueueItem;

  /// يفصل المشغّل ويلغي الاشتراكات عند إغلاقه.
  void detach() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _player = null;
  }

  /// يتبع [player] من الآن. المشغّل يُنشأ عند أول استخدام، فالوسيط يسبقه.
  void attach(AudioPlayer player) {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions
      ..clear()
      ..addAll([
        // الأخطاء تصل التطبيق عبر errorStream في المشغّل.
        player.playbackEventStream.listen(
          (_) => _broadcast(),
          onError: (Object _, StackTrace _) {},
        ),
        player.playingStream.listen((_) => _broadcast()),
        player.currentIndexStream.listen(_showItem),
      ]);
    _player = player;
  }

  /// ما يعرضه الإشعار لكل عنصر في القائمة التي حُمّلت للتو.
  void setItems(List<MediaItem> items) {
    queue.add(items);
    _showItem(_player?.currentIndex);
  }

  void _showItem(int? index) {
    final items = queue.value;
    if (index != null && index < items.length) mediaItem.add(items[index]);
  }

  void _broadcast() {
    final player = _player;
    if (player == null) return;
    final state = player.processingState;
    final items = queue.value.length;
    final index = player.currentIndex;
    final controls = [
      if (index != null && index > 0) MediaControl.skipToPrevious,
      if (player.playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      if (index != null && index < items - 1) MediaControl.skipToNext,
    ];
    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        // كل الأزرار إلا الإيقاف تظهر في الإشعار المصغّر.
        androidCompactActionIndices: [
          for (final (i, c) in controls.indexed)
            if (c.action != MediaAction.stop) i,
        ],
        processingState: switch (state) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing:
            player.playing &&
            state != ProcessingState.idle &&
            state != ProcessingState.completed,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: index,
      ),
    );
  }

  @override
  Future<void> play() async {
    final start = onPlay;
    if (start != null) {
      await start();
      return;
    }
    // المشغّل المتوقف لا شيء فيه يُستأنف: زر التشغيل عندها لا يفعل شيئاً بدل أن
    // ينتظر صوتاً لن يأتي.
    final player = _player;
    if (player == null || player.processingState == ProcessingState.idle) {
      return;
    }
    // كما في التطبيق: يبدأ التشغيل دون انتظار نهايته.
    unawaited(player.play());
  }

  @override
  Future<void> pause() async {
    final hold = onPause;
    if (hold != null) {
      await hold();
      return;
    }
    await _player?.pause();
  }

  @override
  Future<void> seek(Duration position) async => _player?.seek(position);

  @override
  Future<void> skipToNext() async {
    final nextAction = onSkipToNext;
    if (nextAction != null) {
      await nextAction();
      return;
    }
    await _player?.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    final prevAction = onSkipToPrevious;
    if (prevAction != null) {
      await prevAction();
      return;
    }
    await _player?.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final jumpAction = onSkipToQueueItem;
    if (jumpAction != null) {
      await jumpAction(index);
      return;
    }
    await _player?.seek(Duration.zero, index: index);
  }

  @override
  Future<void> stop() async {
    final close = onStop;
    if (close != null) {
      await close();
    } else {
      await _player?.stop();
    }
    await super.stop();
  }
}
