import 'dart:async';

import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// In-memory fake implementation of [VideoPlayerPlatform] for hermetic testing.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int _nextPlayerId = 1;
  Duration simulatedDuration;
  Duration currentPosition = Duration.zero;
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  bool shouldFailInitialization = false;

  final Map<int, StreamController<VideoEvent>> _controllers = {};

  FakeVideoPlayerPlatform({
    this.simulatedDuration = const Duration(seconds: 100),
    this.shouldFailInitialization = false,
  });

  static FakeVideoPlayerPlatform register({
    Duration duration = const Duration(seconds: 100),
    bool shouldFailInitialization = false,
  }) {
    final fake = FakeVideoPlayerPlatform(
      simulatedDuration: duration,
      shouldFailInitialization: shouldFailInitialization,
    );
    VideoPlayerPlatform.instance = fake;
    return fake;
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextPlayerId++;
    _controllers[id] = StreamController<VideoEvent>.broadcast();
    return id;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) {
    return create(options.dataSource);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final controller = _controllers.putIfAbsent(
      playerId,
      () => StreamController<VideoEvent>.broadcast(),
    );

    // Send initialized or error event as soon as subscriber listens
    scheduleMicrotask(() {
      if (!controller.isClosed) {
        if (shouldFailInitialization) {
          controller.addError(
            PlatformException(
              code: 'MEDIA_CORRUPT',
              message: 'Failed to decode media file',
            ),
          );
        } else {
          controller.add(
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: simulatedDuration,
              size: const Size(1920, 1080),
            ),
          );
        }
      }
    });

    return controller.stream;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {
    isPlaying = true;
  }

  @override
  Future<void> pause(int playerId) async {
    isPlaying = false;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    playbackSpeed = speed;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    currentPosition = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    return currentPosition;
  }

  @override
  Future<void> dispose(int playerId) async {
    await _controllers[playerId]?.close();
    _controllers.remove(playerId);
  }
}
