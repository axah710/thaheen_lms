import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/player/domain/entities/course_progress.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';

void main() {
  group('Sequential Unlock Invariant Rule Tests (AAA Pattern)', () {
    // 3 lessons across 2 sections:
    // Section 1: l1 (idx 0), l2 (idx 1)
    // Section 2: l3 (idx 2)
    final l1 = Lesson(
      id: 'l1',
      courseId: 'c1',
      sectionId: 's1',
      title: 'الدرس الأول',
      durationSec: 100,
      videoAssetPath: 'v1.mp4',
      globalOrderIndex: 0,
    );

    final l2 = Lesson(
      id: 'l2',
      courseId: 'c1',
      sectionId: 's1',
      title: 'الدرس الثاني',
      durationSec: 120,
      videoAssetPath: 'v2.mp4',
      globalOrderIndex: 1,
    );

    final l3 = Lesson(
      id: 'l3',
      courseId: 'c1',
      sectionId: 's2',
      title: 'الدرس الثالث في القسم الثاني',
      durationSec: 140,
      videoAssetPath: 'v3.mp4',
      globalOrderIndex: 2,
    );

    final allLessons = [l1, l2, l3];

    test('Lesson 1 (globalOrderIndex == 0) is ALWAYS unlocked by default', () {
      // Arrange
      const progress = CourseProgress(courseId: 'c1', lessonProgressMap: {});

      // Act & Assert
      expect(progress.isLessonUnlocked(l1, allLessons), isTrue);
    });

    test('Lesson 2 is locked when Lesson 1 is not completed', () {
      // Arrange
      const progress = CourseProgress(courseId: 'c1', lessonProgressMap: {});

      // Act & Assert
      expect(progress.isLessonUnlocked(l2, allLessons), isFalse);
    });

    test('Lesson 2 unlocks when Lesson 1 is completed', () {
      // Arrange
      final progress = CourseProgress(
        courseId: 'c1',
        lessonProgressMap: {
          'l1': LessonProgress(
            lessonId: 'l1',
            courseId: 'c1',
            lastPositionSec: 95,
            isCompleted: true,
            lastAccessedAt: DateTime.now().toUtc(),
          ),
        },
      );

      // Act & Assert
      expect(progress.isLessonUnlocked(l1, allLessons), isTrue);
      expect(progress.isLessonUnlocked(l2, allLessons), isTrue);
      expect(
        progress.isLessonUnlocked(l3, allLessons),
        isFalse,
      ); // l3 still locked
    });

    test('Lesson 3 (across section boundary) unlocks when preceding Lesson 2 completes', () {
      // Arrange
      final progress = CourseProgress(
        courseId: 'c1',
        lessonProgressMap: {
          'l1': LessonProgress(
            lessonId: 'l1',
            courseId: 'c1',
            lastPositionSec: 100,
            isCompleted: true,
            lastAccessedAt: DateTime.now().toUtc(),
          ),
          'l2': LessonProgress(
            lessonId: 'l2',
            courseId: 'c1',
            lastPositionSec: 120,
            isCompleted: true,
            lastAccessedAt: DateTime.now().toUtc(),
          ),
        },
      );

      // Act & Assert
      expect(progress.isLessonUnlocked(l1, allLessons), isTrue);
      expect(progress.isLessonUnlocked(l2, allLessons), isTrue);
      expect(progress.isLessonUnlocked(l3, allLessons), isTrue);
    });

    test('Lesson 3 remains locked if Lesson 1 is completed but Lesson 2 is skipped (Prevents Skipping)', () {
      // Arrange
      final progress = CourseProgress(
        courseId: 'c1',
        lessonProgressMap: {
          'l1': LessonProgress(
            lessonId: 'l1',
            courseId: 'c1',
            lastPositionSec: 100,
            isCompleted: true,
            lastAccessedAt: DateTime.now().toUtc(),
          ),
          // l2 is missing or incomplete
          'l2': LessonProgress(
            lessonId: 'l2',
            courseId: 'c1',
            lastPositionSec: 30,
            isCompleted: false,
            lastAccessedAt: DateTime.now().toUtc(),
          ),
        },
      );

      // Act & Assert
      expect(progress.isLessonUnlocked(l1, allLessons), isTrue);
      expect(progress.isLessonUnlocked(l2, allLessons), isTrue);
      expect(
        progress.isLessonUnlocked(l3, allLessons),
        isFalse,
      ); // l3 strictly locked!
    });
  });
}
