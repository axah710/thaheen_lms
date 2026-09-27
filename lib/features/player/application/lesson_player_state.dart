import 'package:equatable/equatable.dart';

import '../../course/domain/entities/course.dart';
import '../../course/domain/entities/lesson.dart';

/// Sealed state hierarchy for LessonPlayerCubit.
sealed class LessonPlayerState extends Equatable {
  const LessonPlayerState();

  @override
  List<Object?> get props => [];
}

class LessonPlayerInitial extends LessonPlayerState {
  const LessonPlayerInitial();
}

class LessonPlayerLoading extends LessonPlayerState {
  final Lesson? lesson;

  const LessonPlayerLoading({this.lesson});

  @override
  List<Object?> get props => [lesson];
}

class LessonPlayerReady extends LessonPlayerState {
  final Lesson lesson;
  final Course course;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final double playbackSpeed; // 1.0, 1.25, 1.5, 2.0
  final bool isCompleted;
  final bool isControlsVisible;
  final bool isFullscreen;
  final Lesson? nextLesson;
  final bool isNextLessonUnlocked;

  const LessonPlayerReady({
    required this.lesson,
    required this.course,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.isCompleted,
    required this.isControlsVisible,
    required this.isFullscreen,
    this.nextLesson,
    required this.isNextLessonUnlocked,
  });

  /// Invariant Rule: Duration-safe fraction with zero-division guard.
  double get progressFraction {
    if (totalDuration.inMilliseconds <= 0) return 0.0;
    return (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  /// True if there is no subsequent lesson in the course syllabus.
  bool get isTerminalLesson => nextLesson == null;

  LessonPlayerReady copyWith({
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isPlaying,
    double? playbackSpeed,
    bool? isCompleted,
    bool? isControlsVisible,
    bool? isFullscreen,
    Lesson? nextLesson,
    bool? isNextLessonUnlocked,
  }) {
    return LessonPlayerReady(
      lesson: lesson,
      course: course,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isCompleted: isCompleted ?? this.isCompleted,
      isControlsVisible: isControlsVisible ?? this.isControlsVisible,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      nextLesson: nextLesson ?? this.nextLesson,
      isNextLessonUnlocked: isNextLessonUnlocked ?? this.isNextLessonUnlocked,
    );
  }

  @override
  List<Object?> get props => [
    lesson,
    course,
    currentPosition,
    totalDuration,
    isPlaying,
    playbackSpeed,
    isCompleted,
    isControlsVisible,
    isFullscreen,
    nextLesson,
    isNextLessonUnlocked,
  ];
}

class LessonPlayerError extends LessonPlayerState {
  final Lesson? lesson;
  final String userMessageArabic;
  final bool canRetry;

  const LessonPlayerError({
    this.lesson,
    required this.userMessageArabic,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [lesson, userMessageArabic, canRetry];
}
