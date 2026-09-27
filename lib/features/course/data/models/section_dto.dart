import 'lesson_dto.dart';

/// Data Transfer Object for a section parsed from bundled courses.json.
class SectionDto {
  final String id;
  final String title;
  final List<LessonDto> lessons;

  const SectionDto({
    required this.id,
    required this.title,
    required this.lessons,
  });

  factory SectionDto.fromJson(Map<String, dynamic> json) {
    return SectionDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      lessons:
          (json['lessons'] as List<dynamic>?)
              ?.map(
                (lessonJson) =>
                    LessonDto.fromJson(lessonJson as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
  };
}
