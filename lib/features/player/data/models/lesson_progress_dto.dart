import '../../domain/entities/lesson_progress.dart';

/// Data Transfer Object for a lesson progress record stored under thaheen_progress_v1.
class LessonProgressDto {
  final String lessonId;
  final String courseId;
  final int lastPositionSec;
  final bool isCompleted;
  final String lastAccessedAt;

  const LessonProgressDto({
    required this.lessonId,
    required this.courseId,
    required this.lastPositionSec,
    required this.isCompleted,
    required this.lastAccessedAt,
  });

  factory LessonProgressDto.fromJson(Map<String, dynamic> json) {
    final rawPos = json['lastPositionSec'];
    final pos = rawPos is num
        ? rawPos.toInt()
        : (int.tryParse(rawPos?.toString() ?? '') ?? 0);
    return LessonProgressDto(
      lessonId: json['lessonId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      lastPositionSec: pos,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastAccessedAt:
          json['lastAccessedAt'] as String? ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'courseId': courseId,
    'lastPositionSec': lastPositionSec,
    'isCompleted': isCompleted,
    'lastAccessedAt': lastAccessedAt,
  };

  LessonProgress toDomain() {
    return LessonProgress(
      lessonId: lessonId,
      courseId: courseId,
      lastPositionSec: lastPositionSec,
      isCompleted: isCompleted,
      lastAccessedAt:
          DateTime.tryParse(lastAccessedAt)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  factory LessonProgressDto.fromDomain(LessonProgress domain) {
    return LessonProgressDto(
      lessonId: domain.lessonId,
      courseId: domain.courseId,
      lastPositionSec: domain.lastPositionSec,
      isCompleted: domain.isCompleted,
      lastAccessedAt: domain.lastAccessedAt.toUtc().toIso8601String(),
    );
  }
}
