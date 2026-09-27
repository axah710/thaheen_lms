import '../../domain/entities/lesson_progress.dart';
import 'lesson_progress_dto.dart';

/// Top-level envelope for persisting user progress in SharedPreferences
/// under the key thaheen_progress_v1.
class ProgressEnvelopeDto {
  final int schemaVersion;
  final Map<String, LessonProgressDto> records;

  const ProgressEnvelopeDto({
    required this.schemaVersion,
    required this.records,
  });

  /// Factory creating an empty progress envelope.
  factory ProgressEnvelopeDto.empty() {
    return const ProgressEnvelopeDto(schemaVersion: 1, records: {});
  }

  factory ProgressEnvelopeDto.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['schemaVersion'];
    final version = rawVersion is num
        ? rawVersion.toInt()
        : (int.tryParse(rawVersion?.toString() ?? '') ?? 1);
    final rawRecords = json['records'] as Map<String, dynamic>? ?? {};

    final parsedRecords = <String, LessonProgressDto>{};
    for (final entry in rawRecords.entries) {
      if (entry.value is Map<String, dynamic>) {
        parsedRecords[entry.key] = LessonProgressDto.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return ProgressEnvelopeDto(schemaVersion: version, records: parsedRecords);
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'records': records.map((key, value) => MapEntry(key, value.toJson())),
  };

  /// Converts envelope records to domain map.
  Map<String, LessonProgress> toDomainMap() {
    return records.map((key, value) => MapEntry(key, value.toDomain()));
  }
}
