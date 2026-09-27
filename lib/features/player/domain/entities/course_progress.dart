import '../../../course/domain/entities/lesson.dart';
import 'lesson_progress.dart';
import 'lesson_status.dart';

/// Pure Dart aggregate entity encapsulating progress across all lessons in a course,
/// the Sequential Unlock Rule, and the Continue Watching resolver.
///
/// Contains zero Flutter widget/UI dependencies per Constitution Principle II.
class CourseProgress {
  final String courseId;
  final Map<String, LessonProgress> lessonProgressMap;

  const CourseProgress({
    required this.courseId,
    required this.lessonProgressMap,
  });

  /// Factory constructor for an un-started course with empty progress.
  factory CourseProgress.empty(String courseId) {
    return CourseProgress(courseId: courseId, lessonProgressMap: const {});
  }

  /// Invariant Rule: Sequential Unlock.
  /// 1. Lesson 1 (globalOrderIndex == 0) is ALWAYS unlocked.
  /// 2. Lesson N (N > 0) is unlocked IF AND ONLY IF Lesson N-1 has isCompleted == true.
  /// 3. Operates seamlessly across section boundaries via globalOrderIndex.
  bool isLessonUnlocked(Lesson lesson, List<Lesson> allOrderedLessons) {
    if (lesson.isFirstLesson) return true;

    final prevIndex = lesson.globalOrderIndex - 1;
    if (prevIndex < 0 || prevIndex >= allOrderedLessons.length) {
      return false;
    }

    final prevLesson = allOrderedLessons[prevIndex];
    final prevProgress = lessonProgressMap[prevLesson.id];

    return prevProgress?.isCompleted ?? false;
  }

  /// Returns the current [LessonStatus] for [lessonId].
  LessonStatus getLessonStatus(String lessonId) {
    return lessonProgressMap[lessonId]?.status ?? LessonStatus.notStarted;
  }

  /// Total count of completed lessons in this course.
  int get completedLessonsCount {
    return lessonProgressMap.values.where((p) => p.isCompleted).length;
  }

  /// Calculates the overall course percentage with zero-division guard.
  int calculateOverallProgress(int totalLessons) {
    if (totalLessons <= 0) return 0;
    return ((completedLessonsCount / totalLessons) * 100).round().clamp(0, 100);
  }

  /// Resolves the in-progress lesson for this course with the latest lastAccessedAt.
  ///
  /// Filters for lessons where `lastPositionSec > 0 && isCompleted == false`
  /// (status == inProgress) and sorts descending by `lastAccessedAt`.
  Lesson? getContinueWatchingLesson(List<Lesson> allOrderedLessons) {
    final inProgressLessons = allOrderedLessons.where((lesson) {
      final progress = lessonProgressMap[lesson.id];
      return progress != null && progress.status == LessonStatus.inProgress;
    }).toList();

    if (inProgressLessons.isEmpty) return null;

    inProgressLessons.sort((a, b) {
      final pA = lessonProgressMap[a.id]!;
      final pB = lessonProgressMap[b.id]!;
      return pB.lastAccessedAt.compareTo(pA.lastAccessedAt);
    });

    return inProgressLessons.first;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseProgress &&
          runtimeType == other.runtimeType &&
          courseId == other.courseId;

  @override
  int get hashCode => courseId.hashCode;

  @override
  String toString() =>
      'CourseProgress(courseId: $courseId, completed: $completedLessonsCount)';
}
