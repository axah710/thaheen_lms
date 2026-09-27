import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/features/course/data/models/course_dto.dart';

void main() {
  group('CourseDto Deserialization & toDomain Tests (AAA Pattern)', () {
    test('deserializes valid course JSON and maps to domain with continuous globalOrderIndex', () {
      // Arrange
      final json = {
        'id': 'anatomy-101',
        'title': 'مقدمة في التشريح',
        'instructor': 'د. سارة الأحمد',
        'thumbnail': 'assets/images/anatomy.png',
        'sections': [
          {
            'id': 's1',
            'title': 'القسم الأول',
            'lessons': [
              {
                'id': 'l1',
                'title': 'الدرس 1',
                'durationSec': 120,
                'video': 'assets/videos/v1.mp4',
              },
              {
                'id': 'l2',
                'title': 'الدرس 2',
                'durationSec': 180,
                'video': 'assets/videos/v2.mp4',
              },
            ],
          },
          {
            'id': 's2',
            'title': 'القسم الثاني',
            'lessons': [
              {
                'id': 'l3',
                'title': 'الدرس 3',
                'durationSec': 150,
                'video': 'assets/videos/v3.mp4',
              },
            ],
          },
        ],
      };

      // Act
      final dto = CourseDto.fromJson(json);
      final course = dto.toDomain();

      // Assert
      expect(course.id, equals('anatomy-101'));
      expect(course.title, equals('مقدمة في التشريح'));
      expect(course.instructor, equals('د. سارة الأحمد'));
      expect(course.sections.length, equals(2));
      expect(course.totalLessonsCount, equals(3));

      final allLessons = course.allLessonsOrdered;
      expect(allLessons.length, equals(3));

      // Assert continuous globalOrderIndex across section boundaries
      expect(allLessons[0].id, equals('l1'));
      expect(allLessons[0].globalOrderIndex, equals(0));
      expect(allLessons[0].isFirstLesson, isTrue);

      expect(allLessons[1].id, equals('l2'));
      expect(allLessons[1].globalOrderIndex, equals(1));
      expect(allLessons[1].isFirstLesson, isFalse);

      expect(allLessons[2].id, equals('l3'));
      expect(allLessons[2].globalOrderIndex, equals(2));
      expect(allLessons[2].sectionId, equals('s2'));
      expect(allLessons[2].isFirstLesson, isFalse);
    });

    test('handles empty course sections gracefully', () {
      // Arrange
      final json = {
        'id': 'empty',
        'title': 'فارغ',
        'instructor': 'المنسق',
        'thumbnail': 'assets/images/placeholder.png',
        'sections': [],
      };

      // Act
      final dto = CourseDto.fromJson(json);
      final course = dto.toDomain();

      // Assert
      expect(course.sections, isEmpty);
      expect(course.totalLessonsCount, equals(0));
      expect(course.allLessonsOrdered, isEmpty);
    });
  });
}
