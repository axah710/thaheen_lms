import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_status.dart';

void main() {
  group('90% Lesson Auto-Completion & Invariant Rules (AAA Pattern)', () {
    final baseTime = DateTime.utc(2026, 9, 25, 12, 0, 0);

    test('lesson starts as notStarted and incomplete with 0 position', () {
      // Arrange & Act
      final progress = LessonProgress.initial(lessonId: 'l1', courseId: 'c1');

      // Assert
      expect(progress.lastPositionSec, 0);
      expect(progress.isCompleted, isFalse);
      expect(progress.status, LessonStatus.notStarted);
    });

    test('playback below 90% transitions status to inProgress and keeps isCompleted false', () {
      // Arrange
      final initial = LessonProgress.initial(lessonId: 'l1', courseId: 'c1');
      const durationSec = 100;
      const positionSec = 89; // 89% < 90%

      // Act
      final updated = initial.recordPlayback(
        currentPositionSec: positionSec,
        durationSec: durationSec,
        timestamp: baseTime,
      );

      // Assert
      expect(updated.lastPositionSec, 89);
      expect(updated.isCompleted, isFalse);
      expect(updated.status, LessonStatus.inProgress);
    });

    test('playback reaching exactly 90% marks isCompleted true and status completed', () {
      // Arrange
      final initial = LessonProgress.initial(lessonId: 'l1', courseId: 'c1');
      const durationSec = 100;
      const positionSec = 90; // Exactly 90%

      // Act
      final updated = initial.recordPlayback(
        currentPositionSec: positionSec,
        durationSec: durationSec,
        timestamp: baseTime,
      );

      // Assert
      expect(updated.lastPositionSec, 90);
      expect(updated.isCompleted, isTrue);
      expect(updated.status, LessonStatus.completed);
    });

    test('playback exceeding 90% marks isCompleted true', () {
      // Arrange
      final initial = LessonProgress.initial(lessonId: 'l1', courseId: 'c1');
      const durationSec = 200;
      const positionSec = 190; // 95% > 90%

      // Act
      final updated = initial.recordPlayback(
        currentPositionSec: positionSec,
        durationSec: durationSec,
        timestamp: baseTime,
      );

      // Assert
      expect(updated.lastPositionSec, 190);
      expect(updated.isCompleted, isTrue);
      expect(updated.status, LessonStatus.completed);
    });

    test('backward scrub idempotency: scrubbing backwards after 90% keeps isCompleted true', () {
      // Arrange: Lesson already marked completed
      final completed = LessonProgress(
        lessonId: 'l1',
        courseId: 'c1',
        lastPositionSec: 95,
        isCompleted: true,
        lastAccessedAt: baseTime,
      );

      // Act: Scrub back to 20s (20%)
      final scrubbed = completed.recordPlayback(
        currentPositionSec: 20,
        durationSec: 100,
        timestamp: baseTime.add(const Duration(minutes: 1)),
      );

      // Assert: isCompleted remains TRUE (irreversible invariant)
      expect(scrubbed.lastPositionSec, 20);
      expect(scrubbed.isCompleted, isTrue);
      expect(scrubbed.status, LessonStatus.completed);
    });

    test('replay-preserves-completion: replaying from 00:00 retains isCompleted true (FR-015/FR-017)', () {
      // Arrange
      final completed = LessonProgress(
        lessonId: 'l1',
        courseId: 'c1',
        lastPositionSec: 100,
        isCompleted: true,
        lastAccessedAt: baseTime,
      );

      // Act: User replays lesson from beginning (0 seconds)
      final replayed = completed.recordPlayback(
        currentPositionSec: 0,
        durationSec: 100,
        timestamp: baseTime.add(const Duration(minutes: 5)),
      );

      // Assert: isCompleted stays true
      expect(replayed.lastPositionSec, 0);
      expect(replayed.isCompleted, isTrue);
      expect(replayed.status, LessonStatus.completed);
    });

    test('duration-safety guard: zero or negative duration never triggers completion and guards against division by zero', () {
      // Arrange
      final initial = LessonProgress.initial(lessonId: 'l1', courseId: 'c1');

      // Act: duration is 0
      final zeroDuration = initial.recordPlayback(
        currentPositionSec: 50,
        durationSec: 0,
        timestamp: baseTime,
      );

      // Act: duration is negative
      final negativeDuration = initial.recordPlayback(
        currentPositionSec: 50,
        durationSec: -10,
        timestamp: baseTime,
      );

      // Assert
      expect(zeroDuration.isCompleted, isFalse);
      expect(zeroDuration.lastPositionSec, 50);
      expect(negativeDuration.isCompleted, isFalse);
      expect(negativeDuration.lastPositionSec, 50);
    });

    test('position clamping: positions outside [0, durationSec] are clamped safely', () {
      // Arrange
      final initial = LessonProgress.initial(lessonId: 'l1', courseId: 'c1');
      const durationSec = 100;

      // Act: Negative position
      final negativePos = initial.recordPlayback(
        currentPositionSec: -15,
        durationSec: durationSec,
        timestamp: baseTime,
      );

      // Act: Position exceeding duration
      final overPos = initial.recordPlayback(
        currentPositionSec: 150,
        durationSec: durationSec,
        timestamp: baseTime,
      );

      // Assert
      expect(negativePos.lastPositionSec, 0);
      expect(overPos.lastPositionSec, 100);
      expect(overPos.isCompleted, isTrue);
    });
  });
}
