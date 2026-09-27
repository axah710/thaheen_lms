import '../../domain/entities/course.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/section.dart';
import 'section_dto.dart';

/// Data Transfer Object for a course parsed from bundled courses.json.
class CourseDto {
  final String id;
  final String title;
  final String instructor;
  final String thumbnail;
  final List<SectionDto> sections;

  const CourseDto({
    required this.id,
    required this.title,
    required this.instructor,
    required this.thumbnail,
    required this.sections,
  });

  factory CourseDto.fromJson(Map<String, dynamic> json) {
    return CourseDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      instructor: json['instructor'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map(
                (sectionJson) =>
                    SectionDto.fromJson(sectionJson as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'instructor': instructor,
    'thumbnail': thumbnail,
    'sections': sections.map((section) => section.toJson()).toList(),
  };

  /// Maps DTO to pure Dart Course domain entity.
  ///
  /// Guarantees:
  /// - `globalOrderIndex` increments continuously across section boundaries (0, 1, 2...).
  /// - All collections are wrapped in unmodifiable lists for immutability.
  Course toDomain() {
    int globalIndex = 0;
    final domainSections = <Section>[];

    for (int sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final sectionDto = sections[sectionIndex];
      final domainLessons = <Lesson>[];

      for (final lessonDto in sectionDto.lessons) {
        domainLessons.add(
          lessonDto.toDomain(
            courseId: id,
            sectionId: sectionDto.id,
            globalOrderIndex: globalIndex++,
          ),
        );
      }

      domainSections.add(
        Section(
          id: sectionDto.id,
          courseId: id,
          title: sectionDto.title,
          orderIndex: sectionIndex,
          lessons: List.unmodifiable(domainLessons),
        ),
      );
    }

    return Course(
      id: id,
      title: title,
      instructor: instructor,
      thumbnail: thumbnail,
      sections: List.unmodifiable(domainSections),
    );
  }
}
