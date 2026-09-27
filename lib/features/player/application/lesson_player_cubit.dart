import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../course/domain/repositories/i_course_repository.dart';
import '../domain/entities/course_progress.dart';
import '../domain/repositories/i_progress_repository.dart';
import 'lesson_player_state.dart';

/// Cubit managing video playback, controls lifecycle, 90% auto-completion,
/// speed cycling, and playback progress persistence.
class LessonPlayerCubit extends Cubit<LessonPlayerState> {
  final String courseId;
  String lessonId;
  final ICourseRepository courseRepository;
  final IProgressRepository progressRepository;
  final VideoPlayerController Function(String assetPath)? controllerFactory;

  VideoPlayerController? _controller;
  double _sessionSpeed = 1.0;
  Timer? _controlsTimer;
  bool _isDisposed = false;

  static const List<double> supportedSpeeds = [1.0, 1.25, 1.5, 2.0];

  LessonPlayerCubit({
    required this.courseId,
    required this.lessonId,
    required this.courseRepository,
    required this.progressRepository,
    this.controllerFactory,
  }) : super(const LessonPlayerInitial());

  VideoPlayerController? get controller => _controller;

  /// Safe state emission guarding against post-closure crashes per Constitution V.3.
  void emitSafe(LessonPlayerState state) {
    if (!isClosed && !_isDisposed) {
      emit(state);
    }
  }

  /// Initializes the video controller, resolves next lesson, and begins playback.
  Future<void> initializeLesson() async {
    emitSafe(const LessonPlayerLoading());

    // 1. Resolve course syllabus
    final courseResult = await courseRepository.getCourseById(courseId);
    if (courseResult.isLeft) {
      emitSafe(
        LessonPlayerError(userMessageArabic: courseResult.left.messageArabic),
      );
      return;
    }
    final course = courseResult.right;

    // 2. Find current lesson
    final allLessons = course.allLessonsOrdered;
    final lessonIndex = allLessons.indexWhere((l) => l.id == lessonId);
    if (lessonIndex == -1) {
      emitSafe(
        const LessonPlayerError(
          userMessageArabic: 'لم يتم العثور على الدرس في هذه الدورة',
        ),
      );
      return;
    }
    final lesson = allLessons[lessonIndex];

    // 3. Resolve next lesson
    final nextLesson = (lessonIndex + 1 < allLessons.length)
        ? allLessons[lessonIndex + 1]
        : null;

    // 4. Resolve saved progress
    final progressResult = await progressRepository.getCourseProgress(courseId);
    final courseProgress = progressResult.fold(
      (failure) => CourseProgress.empty(courseId),
      (progress) => progress,
    );

    final savedProgressResult = await progressRepository.getLessonProgress(
      lessonId,
    );
    final savedProgress = savedProgressResult.fold(
      (failure) => null,
      (progress) => progress,
    );

    final bool isNextLessonUnlocked =
        nextLesson != null &&
        courseProgress.isLessonUnlocked(nextLesson, allLessons);

    // 5. Initialize VideoPlayerController with fault tolerance
    try {
      await _controller?.dispose();
      final factory =
          controllerFactory ?? (path) => VideoPlayerController.asset(path);
      _controller = factory(lesson.videoAssetPath);
      await _controller!.initialize();

      // Auto-resume from last saved position (US4 / T063)
      if (savedProgress != null && savedProgress.lastPositionSec > 0) {
        final resumeDuration = Duration(seconds: savedProgress.lastPositionSec);
        if (resumeDuration < _controller!.value.duration) {
          await _controller!.seekTo(resumeDuration);
        }
      }

      // Apply session playback speed
      await _controller!.setPlaybackSpeed(_sessionSpeed);

      // Autoplay on load
      await _controller!.play();

      // Listen for video ticks
      _controller!.addListener(_onControllerTick);

      final totalDuration = _controller!.value.duration;
      final currentPos = _controller!.value.position;

      emitSafe(
        LessonPlayerReady(
          lesson: lesson,
          course: course,
          currentPosition: currentPos,
          totalDuration: totalDuration,
          isPlaying: _controller!.value.isPlaying,
          playbackSpeed: _sessionSpeed,
          isCompleted: savedProgress?.isCompleted ?? false,
          isControlsVisible: true,
          isFullscreen: false,
          nextLesson: nextLesson,
          isNextLessonUnlocked: isNextLessonUnlocked,
        ),
      );

      _startControlsTimer();
    } catch (e) {
      _controller?.removeListener(_onControllerTick);
      _controller = null;
      emitSafe(
        LessonPlayerError(
          lesson: lesson,
          userMessageArabic: 'عذراً، ملف الفيديو تالف أو غير متوفر حالياً',
          canRetry: true,
        ),
      );
    }
  }

  void _onControllerTick() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state is! LessonPlayerReady) return;

    final currentState = state as LessonPlayerReady;
    final position = _controller!.value.position;
    final isPlaying = _controller!.value.isPlaying;

    // Check 90% auto-completion invariant
    final durationSec = currentState.totalDuration.inSeconds;
    final positionSec = position.inSeconds;

    // Record playback in repository (debounced automatically)
    progressRepository.recordPlaybackPosition(
      courseId: courseId,
      lessonId: currentState.lesson.id,
      positionSec: positionSec,
      durationSec: durationSec,
    );

    final reached90 = durationSec > 0 && (positionSec / durationSec) >= 0.90;
    final bool isCompleted = currentState.isCompleted || reached90;
    final bool isNextUnlocked =
        currentState.isNextLessonUnlocked || isCompleted;

    emitSafe(
      currentState.copyWith(
        currentPosition: position,
        isPlaying: isPlaying,
        isCompleted: isCompleted,
        isNextLessonUnlocked: isNextUnlocked,
      ),
    );
  }

  /// Toggles play/pause and triggers an immediate persistence flush on pause.
  Future<void> togglePlayPause() async {
    if (_controller == null || state is! LessonPlayerReady) return;

    final currentState = state as LessonPlayerReady;
    if (currentState.isPlaying) {
      await _controller!.pause();
      // Immediate flush on pause per Constitution VI & FR-021
      await progressRepository.flush();
      emitSafe(currentState.copyWith(isPlaying: false));
    } else {
      await _controller!.play();
      emitSafe(currentState.copyWith(isPlaying: true));
      _startControlsTimer();
    }
  }

  /// Seeks to a specific timestamp and triggers immediate persistence flush.
  Future<void> seekTo(Duration target) async {
    if (_controller == null || state is! LessonPlayerReady) return;

    await _controller!.seekTo(target);

    final currentState = state as LessonPlayerReady;
    final durationSec = currentState.totalDuration.inSeconds;
    final positionSec = target.inSeconds;

    await progressRepository.recordPlaybackPosition(
      courseId: courseId,
      lessonId: currentState.lesson.id,
      positionSec: positionSec,
      durationSec: durationSec,
    );
    await progressRepository.flush();

    final reached90 = durationSec > 0 && (positionSec / durationSec) >= 0.90;
    final bool isCompleted = currentState.isCompleted || reached90;

    emitSafe(
      currentState.copyWith(
        currentPosition: target,
        isCompleted: isCompleted,
        isNextLessonUnlocked: currentState.isNextLessonUnlocked || isCompleted,
      ),
    );
  }

  /// Cycles playback speed: 1.0x -> 1.25x -> 1.5x -> 2.0x -> 1.0x.
  Future<void> cyclePlaybackSpeed() async {
    if (state is! LessonPlayerReady) return;

    final currentIndex = supportedSpeeds.indexOf(_sessionSpeed);
    _sessionSpeed =
        supportedSpeeds[(currentIndex + 1) % supportedSpeeds.length];

    await _controller?.setPlaybackSpeed(_sessionSpeed);

    final currentState = state as LessonPlayerReady;
    emitSafe(currentState.copyWith(playbackSpeed: _sessionSpeed));
  }

  /// Shows or hides controls overlay with a 3-second auto-hide timeout.
  void toggleControls() {
    if (state is! LessonPlayerReady) return;
    final currentState = state as LessonPlayerReady;
    final newVisibility = !currentState.isControlsVisible;

    emitSafe(currentState.copyWith(isControlsVisible: newVisibility));

    if (newVisibility && currentState.isPlaying) {
      _startControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (state is LessonPlayerReady) {
        final currentState = state as LessonPlayerReady;
        if (currentState.isPlaying) {
          emitSafe(currentState.copyWith(isControlsVisible: false));
        }
      }
    });
  }

  /// Toggles fullscreen display mode.
  void toggleFullscreen() {
    if (state is! LessonPlayerReady) return;
    final currentState = state as LessonPlayerReady;
    emitSafe(currentState.copyWith(isFullscreen: !currentState.isFullscreen));
  }

  /// Advances to next lesson if unlocked.
  Future<void> playNextLesson() async {
    if (state is! LessonPlayerReady) return;
    final currentState = state as LessonPlayerReady;

    if (currentState.nextLesson != null && currentState.isNextLessonUnlocked) {
      await _controller?.pause();
      await progressRepository.flush();
      _controller?.removeListener(_onControllerTick);
      await _controller?.dispose();
      _controller = null;

      lessonId = currentState.nextLesson!.id;
      await initializeLesson();
    }
  }

  @override
  Future<void> close() async {
    _isDisposed = true;
    _controlsTimer?.cancel();
    _controller?.removeListener(_onControllerTick);
    await progressRepository.flush();
    await _controller?.dispose();
    _controller = null;
    return super.close();
  }
}
