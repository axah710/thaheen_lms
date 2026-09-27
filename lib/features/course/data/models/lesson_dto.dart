import '../../domain/entities/lesson.dart';

/// Data Transfer Object for a lesson parsed from bundled courses.json.
class LessonDto {
  final String id;
  final String title;
  final int durationSec;
  final String video;

  const LessonDto({
    required this.id,
    required this.title,
    required this.durationSec,
    required this.video,
  });

  factory LessonDto.fromJson(Map<String, dynamic> json) {
    return LessonDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      video: json['video'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'durationSec': durationSec,
    'video': video,
  };

  Lesson toDomain({
    required String courseId,
    required String sectionId,
    required int globalOrderIndex,
  }) {
    return Lesson(
      id: id,
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      durationSec: durationSec,
      videoAssetPath: video,
      globalOrderIndex: globalOrderIndex,
    );
  }
}
