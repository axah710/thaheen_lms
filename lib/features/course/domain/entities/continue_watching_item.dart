import 'package:equatable/equatable.dart';

import '../../../player/domain/entities/lesson_progress.dart';
import 'course.dart';
import 'lesson.dart';

/// Pure Dart domain value object representing an in-progress lesson
/// ready to be resumed from the "Continue Watching" hero card.
class ContinueWatchingItem extends Equatable {
  final Course course;
  final Lesson lesson;
  final LessonProgress progress;

  const ContinueWatchingItem({
    required this.course,
    required this.lesson,
    required this.progress,
  });

  /// Playback ratio between 0.0 and 1.0.
  double get progressRatio {
    if (lesson.durationSec <= 0) return 0.0;
    return (progress.lastPositionSec / lesson.durationSec).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [course, lesson, progress];

  @override
  String toString() =>
      'ContinueWatchingItem(course: ${course.id}, lesson: ${lesson.id}, ratio: ${(progressRatio * 100).toStringAsFixed(1)}%)';
}
