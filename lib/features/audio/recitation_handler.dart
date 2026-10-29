/// التلاوة خارج التطبيق: إشعار التشغيل وأزرار شاشة القفل.
///
/// audio_service keeps the recitation playing once the app leaves the
/// screen. This handler shows the player's state in the notification and
/// passes the notification's buttons back to the player, as
/// just_audio_background did before it.
library;

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// يربط مشغّل التلاوة بإشعار النظام.
class RecitationHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  /// The handler made at startup, or null where the platform has no
  /// background playback (desktop, tests).
  static RecitationHandler? instance;

  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// Ends the recitation in the app, as its own close button does. Without
  /// it, a stop from the notification left the app holding a stopped
  /// player that a later play could not restart.
  Future<void> Function()? onStop;

  /// Follows [player] from now on. The player is made on first use, so the
  /// handler exists before it does.
  void attach(AudioPlayer player) {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions
      ..clear()
      ..addAll([
        // Errors reach the app through the player's errorStream.
        player.playbackEventStream.listen(
          (_) => _broadcast(),
          onError: (Object _, StackTrace _) {},
        ),
        player.playingStream.listen((_) => _broadcast()),
        player.currentIndexStream.listen(_showItem),
      ]);
    _player = player;
  }

  /// What the notification shows for each item of the queue just loaded.
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
        // Every button but stop shows in the compact notification.
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
    // A stopped player has nothing to resume: a play key then does nothing
    // rather than wait on audio that will not come.
    final player = _player;
    if (player == null || player.processingState == ProcessingState.idle) {
      return;
    }
    // As in the app, starts playing without waiting for the end.
    unawaited(player.play());
  }

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> seek(Duration position) async => _player?.seek(position);

  @override
  Future<void> skipToNext() async => _player?.seekToNext();

  @override
  Future<void> skipToPrevious() async => _player?.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async =>
      _player?.seek(Duration.zero, index: index);

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
