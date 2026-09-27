import '../../../player/domain/entities/lesson_progress.dart';
import 'lesson.dart';
import 'section.dart';

/// Pure Dart domain entity representing an educational course.
///
/// Contains zero Flutter widget/UI dependencies per Constitution Principle II.
class Course {
  final String id;
  final String title;
  final String instructor;
  final String thumbnail;
  final List<Section> sections;

  const Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.thumbnail,
    required this.sections,
  });

  /// Total count of all lessons across all sections in this course.
  int get totalLessonsCount =>
      sections.fold(0, (sum, section) => sum + section.lessons.length);

  /// Flattened, ordered list of all lessons in chronological course sequence.
  List<Lesson> get allLessonsOrdered =>
      List.unmodifiable(sections.expand((section) => section.lessons));

  /// Finds a lesson by its unique [lessonId], or null if not found.
  Lesson? findLessonById(String lessonId) {
    for (final section in sections) {
      for (final lesson in section.lessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    return null;
  }

  /// Calculates total completed lessons in this course given [progressMap].
  int calculateCompletedCount(Map<String, LessonProgress> progressMap) {
    int completed = 0;
    for (final lesson in allLessonsOrdered) {
      if (progressMap[lesson.id]?.isCompleted ?? false) {
        completed++;
      }
    }
    return completed;
  }

  /// Invariant Rule: Safe progress % calculation with Zero-Division Guard.
  /// Progress % = (Completed Lessons Count / Total Lessons Count) * 100
  /// Returns 0 when totalLessonsCount == 0 (preventing NaN / crash).
  int calculateProgressPercentage(Map<String, LessonProgress> progressMap) {
    if (totalLessonsCount <= 0) return 0;
    final completed = calculateCompletedCount(progressMap);
    return ((completed / totalLessonsCount) * 100).round().clamp(0, 100);
  }

  /// True if course has at least one lesson and all lessons are completed.
  bool isCourseCompleted(Map<String, LessonProgress> progressMap) {
    return totalLessonsCount > 0 &&
        calculateCompletedCount(progressMap) == totalLessonsCount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          instructor == other.instructor &&
          thumbnail == other.thumbnail;

  @override
  int get hashCode => Object.hash(id, title, instructor, thumbnail);

  @override
  String toString() =>
      'Course(id: $id, title: $title, instructor: $instructor, totalLessons: $totalLessonsCount)';
}
