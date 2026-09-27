import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/features/player/data/models/lesson_progress_dto.dart';
import 'package:thaheen_lms/features/player/data/models/progress_envelope_dto.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';

void main() {
  group('ProgressEnvelopeDto & LessonProgressDto Serialization Tests (AAA Pattern)', () {
    final utcTimestamp = DateTime.utc(2026, 9, 25, 14, 30, 0);

    test('LessonProgressDto serializes and deserializes accurately with ISO-8601 UTC timestamp', () {
      // Arrange
      final dto = LessonProgressDto(
        lessonId: 'l1',
        courseId: 'c1',
        lastPositionSec: 45,
        isCompleted: true,
        lastAccessedAt: utcTimestamp.toIso8601String(),
      );

      // Act
      final json = dto.toJson();
      final reconstructed = LessonProgressDto.fromJson(json);

      // Assert
      expect(reconstructed.lessonId, 'l1');
      expect(reconstructed.courseId, 'c1');
      expect(reconstructed.lastPositionSec, 45);
      expect(reconstructed.isCompleted, isTrue);
      expect(reconstructed.lastAccessedAt, utcTimestamp.toIso8601String());
    });

    test('LessonProgressDto maps toDomain and fromDomain accurately', () {
      // Arrange
      final domain = LessonProgress(
        lessonId: 'l2',
        courseId: 'c1',
        lastPositionSec: 90,
        isCompleted: true,
        lastAccessedAt: utcTimestamp,
      );

      // Act
      final dto = LessonProgressDto.fromDomain(domain);
      final mappedDomain = dto.toDomain();

      // Assert
      expect(mappedDomain.lessonId, domain.lessonId);
      expect(mappedDomain.courseId, domain.courseId);
      expect(mappedDomain.lastPositionSec, domain.lastPositionSec);
      expect(mappedDomain.isCompleted, domain.isCompleted);
      expect(
        mappedDomain.lastAccessedAt.isAtSameMomentAs(domain.lastAccessedAt),
        isTrue,
      );
      expect(mappedDomain.lastAccessedAt.isUtc, isTrue);
    });

    test('ProgressEnvelopeDto serializes and deserializes multiple records with schemaVersion 1', () {
      // Arrange
      final record1 = LessonProgressDto(
        lessonId: 'l1',
        courseId: 'c1',
        lastPositionSec: 10,
        isCompleted: false,
        lastAccessedAt: utcTimestamp.toIso8601String(),
      );
      final record2 = LessonProgressDto(
        lessonId: 'l2',
        courseId: 'c1',
        lastPositionSec: 100,
        isCompleted: true,
        lastAccessedAt: utcTimestamp.toIso8601String(),
      );

      final envelope = ProgressEnvelopeDto(
        schemaVersion: 1,
        records: {'l1': record1, 'l2': record2},
      );

      // Act
      final json = envelope.toJson();
      final reconstructed = ProgressEnvelopeDto.fromJson(json);

      // Assert
      expect(reconstructed.schemaVersion, 1);
      expect(reconstructed.records.length, 2);
      expect(reconstructed.records['l1']?.lastPositionSec, 10);
      expect(reconstructed.records['l2']?.isCompleted, isTrue);

      final domainMap = reconstructed.toDomainMap();
      expect(domainMap.length, 2);
      expect(domainMap['l1']?.isCompleted, isFalse);
      expect(domainMap['l2']?.isCompleted, isTrue);
    });

    test(
      'ProgressEnvelopeDto handles empty, missing, or malformed fields safely',
      () {
        // Arrange: json with missing records and unknown types
        final malformedJson = <String, dynamic>{
          'schemaVersion': 'invalid_string',
          'records': {
            'l1': {
              'lessonId': 'l1',
              'courseId': 'c1',
              'lastPositionSec': 'not_num',
            },
            'invalid_key': 'not_a_map',
          },
        };

        // Act
        final envelope = ProgressEnvelopeDto.fromJson(malformedJson);

        // Assert: Default version 1 and skips non-map entry
        expect(envelope.schemaVersion, 1);
        expect(envelope.records.containsKey('l1'), isTrue);
        expect(envelope.records.containsKey('invalid_key'), isFalse);
        expect(envelope.records['l1']?.lastPositionSec, 0);
      },
    );
  });
}
