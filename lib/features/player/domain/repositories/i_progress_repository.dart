import 'package:either_dart/either.dart';

import '../../../../core/errors/failures.dart';
import '../../../course/domain/entities/continue_watching_item.dart';
import '../../../course/domain/entities/course.dart';
import '../entities/course_progress.dart';
import '../entities/lesson_progress.dart';

/// Abstract contract for managing and persisting lesson and course learning progress.
///
/// Returns functional [Either<Failure, T>] per Constitution Principle II.
abstract class IProgressRepository {
  /// Loads all stored progress records across all courses.
  Future<Either<Failure, Map<String, LessonProgress>>> getAllProgress();

  /// Retrieves the progress record for a single lesson by [lessonId].
  ///
  /// Returns `null` if the lesson has never been opened.
  Future<Either<Failure, LessonProgress?>> getLessonProgress(String lessonId);

  /// Retrieves the aggregated [CourseProgress] for a given [courseId].
  Future<Either<Failure, CourseProgress>> getCourseProgress(String courseId);

  /// Persists or updates the watched playback position for a lesson.
  ///
  /// Domain Guarantees:
  /// - Automatically computes 90% auto-completion.
  /// - Irreversible completion status.
  /// - Updates `lastAccessedAt` to UTC now.
  /// - Commits to local persistence and updates in-memory cache.
  Future<Either<Failure, LessonProgress>> recordPlaybackPosition({
    required String courseId,
    required String lessonId,
    required int positionSec,
    required int durationSec,
  });

  /// Resolves the "Continue Watching" item across all provided [courses].
  ///
  /// Returns `null` if no lessons are currently in progress.
  Future<Either<Failure, ContinueWatchingItem?>> resolveContinueWatching(
    List<Course> courses,
  );

  /// Flushes any pending debounced writes and reloads the in-memory cache
  /// from durable storage to synchronize with persistent state.
  Future<Either<Failure, void>> syncWithStorage();

  /// Immediately flushes any pending debounced writes to durable storage.
  Future<Either<Failure, void>> flush();

  /// Resets all local progress records (useful for debugging, testing, or reset button).
  Future<Either<Failure, void>> clearAllProgress();

  /// True if local progress storage was detected as corrupted and reset for data integrity.
  bool get wasStorageReset => false;
}
