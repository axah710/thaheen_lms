import 'dart:async';

import 'package:either_dart/either.dart';

import '../../../../core/errors/failures.dart';
import '../../../course/domain/entities/continue_watching_item.dart';
import '../../../course/domain/entities/course.dart';
import '../../domain/entities/course_progress.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../domain/entities/lesson_status.dart';
import '../../domain/repositories/i_progress_repository.dart';
import '../data_sources/progress_local_data_source.dart';
import '../models/lesson_progress_dto.dart';
import '../models/progress_envelope_dto.dart';

/// Implementation of IProgressRepository providing in-memory caching,
/// 5-second persistence debouncing, immediate flush triggers, and
/// Continue Watching resolution.
class ProgressRepositoryImpl implements IProgressRepository {
  final ProgressLocalDataSource dataSource;
  final Duration debounceDuration;
  final void Function()? onCorruptReset;

  Map<String, LessonProgress>? _inMemoryCache;
  Timer? _debounceTimer;
  bool _isDirty = false;
  bool _wasStorageReset = false;

  @override
  bool get wasStorageReset => _wasStorageReset;

  ProgressRepositoryImpl(
    this.dataSource, {
    this.debounceDuration = const Duration(seconds: 5),
    this.onCorruptReset,
  });

  /// Ensures in-memory cache is populated from storage.
  void _ensureLoaded() {
    if (_inMemoryCache == null) {
      final envelope = onCorruptReset != null
          ? dataSource.getEnvelope(
              onCorruptReset: () {
                _wasStorageReset = true;
                onCorruptReset?.call();
              },
            )
          : dataSource.getEnvelope();
      _inMemoryCache = envelope.toDomainMap();
    }
  }

  @override
  Future<Either<Failure, Map<String, LessonProgress>>> getAllProgress() async {
    try {
      _ensureLoaded();
      return Right(Map.unmodifiable(_inMemoryCache!));
    } catch (e) {
      return Left(
        StorageFailure(
          messageArabic: 'تعذر تحميل سجل تقدم الدروس من الذاكرة المحلية',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, LessonProgress?>> getLessonProgress(
    String lessonId,
  ) async {
    try {
      _ensureLoaded();
      return Right(_inMemoryCache![lessonId]);
    } catch (e) {
      return Left(
        StorageFailure(
          messageArabic: 'تعذر تحميل سجل تقدم الدرس ($lessonId)',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CourseProgress>> getCourseProgress(
    String courseId,
  ) async {
    try {
      _ensureLoaded();
      final courseLessons = <String, LessonProgress>{};

      for (final entry in _inMemoryCache!.entries) {
        if (entry.value.courseId == courseId) {
          courseLessons[entry.key] = entry.value;
        }
      }

      return Right(
        CourseProgress(
          courseId: courseId,
          lessonProgressMap: Map.unmodifiable(courseLessons),
        ),
      );
    } catch (e) {
      return Left(
        StorageFailure(
          messageArabic: 'تعذر تجميع سجل تقدم الدورة ($courseId)',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, LessonProgress>> recordPlaybackPosition({
    required String courseId,
    required String lessonId,
    required int positionSec,
    required int durationSec,
  }) async {
    try {
      _ensureLoaded();

      final current =
          _inMemoryCache![lessonId] ??
          LessonProgress.initial(lessonId: lessonId, courseId: courseId);

      final wasCompletedBefore = current.isCompleted;
      final updated = current.recordPlayback(
        currentPositionSec: positionSec,
        durationSec: durationSec,
      );

      _inMemoryCache![lessonId] = updated;
      _isDirty = true;

      // Immediate flush if newly transitioned to completed (reached >= 90%)
      final justCompleted = !wasCompletedBefore && updated.isCompleted;
      if (justCompleted) {
        await flush();
      } else {
        _scheduleDebouncedSave();
      }

      return Right(updated);
    } catch (e) {
      return Left(
        StorageFailure(
          messageArabic: 'تعذر حفظ تقدم تشغيل الدرس ($lessonId)',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ContinueWatchingItem?>> resolveContinueWatching(
    List<Course> courses,
  ) async {
    try {
      _ensureLoaded();

      final candidates = <ContinueWatchingItem>[];

      for (final course in courses) {
        for (final lesson in course.allLessonsOrdered) {
          final progress = _inMemoryCache![lesson.id];
          if (progress != null && progress.status == LessonStatus.inProgress) {
            candidates.add(
              ContinueWatchingItem(
                course: course,
                lesson: lesson,
                progress: progress,
              ),
            );
          }
        }
      }

      if (candidates.isEmpty) {
        return const Right(null);
      }

      // Sort descending by lastAccessedAt to prioritize the most recently watched lesson
      candidates.sort(
        (a, b) =>
            b.progress.lastAccessedAt.compareTo(a.progress.lastAccessedAt),
      );

      return Right(candidates.first);
    } catch (e) {
      return Left(
        StorageFailure(
          messageArabic: 'تعذر تحديد الدرس الحالي لمتابعة التعلم',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> clearAllProgress() async {
    try {
      _debounceTimer?.cancel();
      _inMemoryCache = {};
      _isDirty = false;
      await dataSource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(
        StorageFailure(
          messageArabic: 'تعذر إعادة تعيين سجلات التقدم',
          cause: e,
        ),
      );
    }
  }

  /// Immediately commits all in-memory changes to durable storage.
  @override
  Future<Either<Failure, void>> flush() async {
    try {
      _debounceTimer?.cancel();
      if (!_isDirty || _inMemoryCache == null) return const Right(null);

      final records = _inMemoryCache!.map(
        (key, value) => MapEntry(key, LessonProgressDto.fromDomain(value)),
      );

      final envelope = ProgressEnvelopeDto(schemaVersion: 1, records: records);

      await dataSource.saveEnvelope(envelope);
      _isDirty = false;
      return const Right(null);
    } catch (e) {
      return Left(
        StorageFailure(
          messageArabic: 'تعذر حفظ البيانات في الذاكرة المحلية',
          cause: e,
        ),
      );
    }
  }

  void _scheduleDebouncedSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      flush();
    });
  }

  /// Cancels any pending timers. Call on dispose.
  void dispose() {
    flush();
  }
}
