import '../../../player/domain/entities/lesson_progress.dart';
import 'lesson.dart';

/// Pure Dart domain entity representing a curriculum section.
///
/// Contains zero Flutter widget/UI dependencies per Constitution Principle II.
class Section {
  final String id;
  final String courseId;
  final String title;
  final int orderIndex;
  final List<Lesson> lessons;

  const Section({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
    required this.lessons,
  });

  /// Total number of lessons in this section.
  int get totalLessonsCount => lessons.length;

  /// Counts completed lessons in this section given [progressMap].
  int calculateCompletedCount(Map<String, LessonProgress> progressMap) {
    return lessons.where((l) => progressMap[l.id]?.isCompleted ?? false).length;
  }

  /// True if all lessons in this section are completed and section is non-empty.
  bool isCompleted(Map<String, LessonProgress> progressMap) {
    return lessons.isNotEmpty &&
        calculateCompletedCount(progressMap) == lessons.length;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Section &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseId == other.courseId &&
          title == other.title &&
          orderIndex == other.orderIndex;

  @override
  int get hashCode => Object.hash(id, courseId, title, orderIndex);

  @override
  String toString() =>
      'Section(id: $id, title: $title, order: $orderIndex, lessons: ${lessons.length})';
}
