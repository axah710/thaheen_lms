import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/features/player/data/data_sources/progress_local_data_source.dart';
import 'package:thaheen_lms/features/player/data/models/lesson_progress_dto.dart';
import 'package:thaheen_lms/features/player/data/models/progress_envelope_dto.dart';
import 'package:thaheen_lms/features/player/data/repositories/progress_repository_impl.dart';

class MockProgressLocalDataSource extends Mock
    implements ProgressLocalDataSource {}

void main() {
  late MockProgressLocalDataSource mockDataSource;
  late ProgressRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(ProgressEnvelopeDto.empty());
  });

  setUp(() {
    mockDataSource = MockProgressLocalDataSource();
    repository = ProgressRepositoryImpl(
      mockDataSource,
      debounceDuration: const Duration(
        milliseconds: 100,
      ), // Fast debounce for tests
    );
  });

  tearDown(() {
    repository.dispose();
  });

  group('ProgressRepositoryImpl Unit Tests (AAA Pattern)', () {
    test(
      'in-memory caching: loads envelope once on initial read and reuses cache',
      () async {
        // Arrange
        final initialEnvelope = ProgressEnvelopeDto(
          schemaVersion: 1,
          records: {
            'l1': const LessonProgressDto(
              lessonId: 'l1',
              courseId: 'c1',
              lastPositionSec: 30,
              isCompleted: false,
              lastAccessedAt: '2026-09-25T12:00:00.000Z',
            ),
          },
        );
        when(() => mockDataSource.getEnvelope()).thenReturn(initialEnvelope);

        // Act: Multiple reads
        final res1 = await repository.getLessonProgress('l1');
        final res2 = await repository.getCourseProgress('c1');
        final res3 = await repository.getAllProgress();

        // Assert
        expect(res1.right?.lastPositionSec, 30);
        expect(res2.right.lessonProgressMap.containsKey('l1'), isTrue);
        expect(res3.right.length, 1);
        // dataSource.getEnvelope() called only ONCE!
        verify(() => mockDataSource.getEnvelope()).called(1);
      },
    );

    test('debounces continuous playback updates: aggregates updates and writes once after timer', () async {
      // Arrange
      when(() => mockDataSource.getEnvelope())
          .thenReturn(ProgressEnvelopeDto.empty());
      when(() => mockDataSource.saveEnvelope(any()))
          .thenAnswer((_) async => true);

      // Act: Rapid updates below 90% (e.g. 5 consecutive seconds of playback)
      await repository.recordPlaybackPosition(
        courseId: 'c1',
        lessonId: 'l1',
        positionSec: 10,
        durationSec: 100,
      );
      await repository.recordPlaybackPosition(
        courseId: 'c1',
        lessonId: 'l1',
        positionSec: 11,
        durationSec: 100,
      );
      await repository.recordPlaybackPosition(
        courseId: 'c1',
        lessonId: 'l1',
        positionSec: 12,
        durationSec: 100,
      );

      // Assert before timer expires: 0 writes to storage!
      verifyNever(() => mockDataSource.saveEnvelope(any()));

      // Wait for debounce timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Assert: Exactly 1 write committed with the latest position (12)
      final captured = verify(() => mockDataSource.saveEnvelope(captureAny()))
          .captured;
      expect(captured.length, 1);
      final savedEnvelope = captured.first as ProgressEnvelopeDto;
      expect(savedEnvelope.records['l1']?.lastPositionSec, 12);
    });

    test('immediate flush when crossing 90% completion threshold without waiting for debounce', () async {
      // Arrange
      when(() => mockDataSource.getEnvelope())
          .thenReturn(ProgressEnvelopeDto.empty());
      when(() => mockDataSource.saveEnvelope(any()))
          .thenAnswer((_) async => true);

      // Act: Playback reaches 90%
      await repository.recordPlaybackPosition(
        courseId: 'c1',
        lessonId: 'l1',
        positionSec: 90,
        durationSec: 100, // 90%
      );

      // Assert: Immediate write occurs synchronously without awaiting debounce!
      verify(() => mockDataSource.saveEnvelope(any())).called(1);
    });

    test('explicit flush commits pending dirty buffer immediately', () async {
      // Arrange
      when(() => mockDataSource.getEnvelope())
          .thenReturn(ProgressEnvelopeDto.empty());
      when(() => mockDataSource.saveEnvelope(any()))
          .thenAnswer((_) async => true);

      await repository.recordPlaybackPosition(
        courseId: 'c1',
        lessonId: 'l1',
        positionSec: 45,
        durationSec: 100,
      );

      // Act: User pauses video -> triggers explicit flush
      await repository.flush();

      // Assert
      verify(() => mockDataSource.saveEnvelope(any())).called(1);

      // Another flush does nothing because buffer is no longer dirty
      await repository.flush();
      verify(() => mockDataSource.getEnvelope()).called(1);
      verifyNoMoreInteractions(mockDataSource);
    });

    test(
      'handles corrupted JSON recovery gracefully by returning empty envelope',
      () async {
        // Arrange: When dataSource recovers from corrupted data and yields empty envelope
        when(() => mockDataSource.getEnvelope())
            .thenReturn(ProgressEnvelopeDto.empty());

        // Act
        final result = await repository.getAllProgress();

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right, isEmpty);
      },
    );
  });
}
