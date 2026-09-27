import 'lesson_status.dart';

/// Pure Dart domain entity encapsulating lesson playback progress,
/// last accessed timestamp, and the 90% auto-completion invariant.
///
/// Contains zero Flutter widget/UI dependencies per Constitution Principle II.
class LessonProgress {
  final String lessonId;
  final String courseId;
  final int lastPositionSec;
  final bool isCompleted;
  final DateTime lastAccessedAt;

  const LessonProgress({
    required this.lessonId,
    required this.courseId,
    required this.lastPositionSec,
    required this.isCompleted,
    required this.lastAccessedAt,
  });

  /// Factory constructor initializing a brand-new progress record.
  factory LessonProgress.initial({
    required String lessonId,
    required String courseId,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      courseId: courseId,
      lastPositionSec: 0,
      isCompleted: false,
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// Derived status based on completion and position.
  LessonStatus get status {
    if (isCompleted) return LessonStatus.completed;
    if (lastPositionSec > 0) return LessonStatus.inProgress;
    return LessonStatus.notStarted;
  }

  /// Invariant Rule: 90% Auto-Completion & Permanent Idempotency.
  /// 1. isCompleted is irreversible: once true, it stays true.
  /// 2. If durationSec <= 0, completion cannot be triggered (guards against division by zero).
  /// 3. Completion triggers when (currentPositionSec / durationSec) >= 0.90.
  /// 4. lastPositionSec is safely clamped within [0, durationSec].
  LessonProgress recordPlayback({
    required int currentPositionSec,
    required int durationSec,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now().toUtc();
    final safePosition = durationSec > 0
        ? currentPositionSec.clamp(0, durationSec)
        : (currentPositionSec < 0 ? 0 : currentPositionSec);

    // Zero-division guard:
    final bool reached90 =
        durationSec > 0 &&
        (safePosition.toDouble() / durationSec.toDouble()) >= 0.90;

    // Idempotency: once isCompleted is true, it can never revert to false
    final bool updatedCompleted = isCompleted || reached90;

    return LessonProgress(
      lessonId: lessonId,
      courseId: courseId,
      lastPositionSec: safePosition,
      isCompleted: updatedCompleted,
      lastAccessedAt: now,
    );
  }

  LessonProgress copyWith({
    int? lastPositionSec,
    bool? isCompleted,
    DateTime? lastAccessedAt,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      courseId: courseId,
      lastPositionSec: lastPositionSec ?? this.lastPositionSec,
      isCompleted: isCompleted ?? this.isCompleted,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonProgress &&
          runtimeType == other.runtimeType &&
          lessonId == other.lessonId &&
          courseId == other.courseId &&
          lastPositionSec == other.lastPositionSec &&
          isCompleted == other.isCompleted &&
          lastAccessedAt.isAtSameMomentAs(other.lastAccessedAt);

  @override
  int get hashCode => Object.hash(
    lessonId,
    courseId,
    lastPositionSec,
    isCompleted,
    lastAccessedAt,
  );

  @override
  String toString() =>
      'LessonProgress(lessonId: $lessonId, pos: $lastPositionSec, completed: $isCompleted, status: $status)';
}
