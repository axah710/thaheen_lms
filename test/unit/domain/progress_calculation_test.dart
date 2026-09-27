import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';

void main() {
  group('Course Progress % Calculation Invariant Tests (AAA Pattern)', () {
    test('returns 0% when course has zero lessons (Zero-Division Guard)', () {
      // Arrange
      const course = Course(
        id: 'empty-course',
        title: 'دورة فارغة',
        instructor: 'د. منسق',
        thumbnail: 'assets/images/placeholder.png',
        sections: [],
      );
      final progressMap = <String, LessonProgress>{};

      // Act
      final percentage = course.calculateProgressPercentage(progressMap);

      // Assert
      expect(percentage, equals(0));
      expect(course.isCourseCompleted(progressMap), isFalse);
    });

    test('returns 25% when 1 of 4 lessons is completed across 2 sections', () {
      // Arrange
      final l1 = Lesson(
        id: 'l1',
        courseId: 'c1',
        sectionId: 's1',
        title: 'الدرس 1',
        durationSec: 100,
        videoAssetPath: 'assets/videos/v1.mp4',
        globalOrderIndex: 0,
      );
      final l2 = Lesson(
        id: 'l2',
        courseId: 'c1',
        sectionId: 's1',
        title: 'الدرس 2',
        durationSec: 100,
        videoAssetPath: 'assets/videos/v2.mp4',
        globalOrderIndex: 1,
      );
      final l3 = Lesson(
        id: 'l3',
        courseId: 'c1',
        sectionId: 's2',
        title: 'الدرس 3',
        durationSec: 100,
        videoAssetPath: 'assets/videos/v3.mp4',
        globalOrderIndex: 2,
      );
      final l4 = Lesson(
        id: 'l4',
        courseId: 'c1',
        sectionId: 's2',
        title: 'الدرس 4',
        durationSec: 100,
        videoAssetPath: 'assets/videos/v4.mp4',
        globalOrderIndex: 3,
      );

      final s1 = Section(
        id: 's1',
        courseId: 'c1',
        title: 'القسم 1',
        orderIndex: 0,
        lessons: [l1, l2],
      );
      final s2 = Section(
        id: 's2',
        courseId: 'c1',
        title: 'القسم 2',
        orderIndex: 1,
        lessons: [l3, l4],
      );

      final course = Course(
        id: 'c1',
        title: 'التشريح',
        instructor: 'د. سارة',
        thumbnail: 'assets/images/anatomy.png',
        sections: [s1, s2],
      );

      final progressMap = {
        'l1': LessonProgress(
          lessonId: 'l1',
          courseId: 'c1',
          lastPositionSec: 95,
          isCompleted: true,
          lastAccessedAt: DateTime.now().toUtc(),
        ),
      };

      // Act
      final percentage = course.calculateProgressPercentage(progressMap);

      // Assert
      expect(percentage, equals(25)); // 1/4 * 100
      expect(course.calculateCompletedCount(progressMap), equals(1));
      expect(course.isCourseCompleted(progressMap), isFalse);
    });

    test('returns 50% when 2 of 4 lessons are completed', () {
      // Arrange
      final l1 = Lesson(
        id: 'l1',
        courseId: 'c1',
        sectionId: 's1',
        title: '1',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 0,
      );
      final l2 = Lesson(
        id: 'l2',
        courseId: 'c1',
        sectionId: 's1',
        title: '2',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 1,
      );
      final l3 = Lesson(
        id: 'l3',
        courseId: 'c1',
        sectionId: 's2',
        title: '3',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 2,
      );
      final l4 = Lesson(
        id: 'l4',
        courseId: 'c1',
        sectionId: 's2',
        title: '4',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 3,
      );

      final course = Course(
        id: 'c1',
        title: 'التشريح',
        instructor: 'د. سارة',
        thumbnail: 'thumb',
        sections: [
          Section(
            id: 's1',
            courseId: 'c1',
            title: 's1',
            orderIndex: 0,
            lessons: [l1, l2],
          ),
          Section(
            id: 's2',
            courseId: 'c1',
            title: 's2',
            orderIndex: 1,
            lessons: [l3, l4],
          ),
        ],
      );

      final progressMap = {
        'l1': LessonProgress(
          lessonId: 'l1',
          courseId: 'c1',
          lastPositionSec: 10,
          isCompleted: true,
          lastAccessedAt: DateTime.now().toUtc(),
        ),
        'l2': LessonProgress(
          lessonId: 'l2',
          courseId: 'c1',
          lastPositionSec: 10,
          isCompleted: true,
          lastAccessedAt: DateTime.now().toUtc(),
        ),
      };

      // Act
      final percentage = course.calculateProgressPercentage(progressMap);

      // Assert
      expect(percentage, equals(50));
      expect(course.calculateCompletedCount(progressMap), equals(2));
      expect(course.isCourseCompleted(progressMap), isFalse);
    });

    test('returns 100% and isCourseCompleted == true when all 4 lessons are completed', () {
      // Arrange
      final l1 = Lesson(
        id: 'l1',
        courseId: 'c1',
        sectionId: 's1',
        title: '1',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 0,
      );
      final l2 = Lesson(
        id: 'l2',
        courseId: 'c1',
        sectionId: 's1',
        title: '2',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 1,
      );
      final l3 = Lesson(
        id: 'l3',
        courseId: 'c1',
        sectionId: 's2',
        title: '3',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 2,
      );
      final l4 = Lesson(
        id: 'l4',
        courseId: 'c1',
        sectionId: 's2',
        title: '4',
        durationSec: 10,
        videoAssetPath: 'v',
        globalOrderIndex: 3,
      );

      final course = Course(
        id: 'c1',
        title: 'التشريح',
        instructor: 'د. سارة',
        thumbnail: 'thumb',
        sections: [
          Section(
            id: 's1',
            courseId: 'c1',
            title: 's1',
            orderIndex: 0,
            lessons: [l1, l2],
          ),
          Section(
            id: 's2',
            courseId: 'c1',
            title: 's2',
            orderIndex: 1,
            lessons: [l3, l4],
          ),
        ],
      );

      final progressMap = {
        'l1': LessonProgress(
          lessonId: 'l1',
          courseId: 'c1',
          lastPositionSec: 10,
          isCompleted: true,
          lastAccessedAt: DateTime.now().toUtc(),
        ),
        'l2': LessonProgress(
          lessonId: 'l2',
          courseId: 'c1',
          lastPositionSec: 10,
          isCompleted: true,
          lastAccessedAt: DateTime.now().toUtc(),
        ),
        'l3': LessonProgress(
          lessonId: 'l3',
          courseId: 'c1',
          lastPositionSec: 10,
          isCompleted: true,
          lastAccessedAt: DateTime.now().toUtc(),
        ),
        'l4': LessonProgress(
          lessonId: 'l4',
          courseId: 'c1',
          lastPositionSec: 10,
          isCompleted: true,
          lastAccessedAt: DateTime.now().toUtc(),
        ),
      };

      // Act
      final percentage = course.calculateProgressPercentage(progressMap);

      // Assert
      expect(percentage, equals(100));
      expect(course.calculateCompletedCount(progressMap), equals(4));
      expect(course.isCourseCompleted(progressMap), isTrue);
    });
  });
}
