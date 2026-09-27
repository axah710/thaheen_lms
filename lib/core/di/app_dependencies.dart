import 'package:flutter/foundation.dart';

import '../../features/course/data/data_sources/course_local_data_source.dart';
import '../../features/course/data/repositories/course_repository_impl.dart';
import '../../features/course/domain/repositories/i_course_repository.dart';
import '../../features/player/data/data_sources/progress_local_data_source.dart';
import '../../features/player/data/repositories/progress_repository_impl.dart';
import '../../features/player/domain/repositories/i_progress_repository.dart';
import '../storage/local_storage_service.dart';

/// Application composition root holding singleton infrastructure and repositories.
class AppDependencies {
  static AppDependencies? _instance;

  /// Active singleton instance of [AppDependencies].
  static AppDependencies? get instance => _instance;

  final LocalStorageService storageService;
  final ICourseRepository courseRepository;
  final IProgressRepository progressRepository;

  const AppDependencies({
    required this.storageService,
    required this.courseRepository,
    required this.progressRepository,
  });

  /// Factory bootstrap initializing durable storage and singletons once.
  static Future<AppDependencies> bootstrap({
    LocalStorageService? storageService,
    ICourseRepository? courseRepository,
    IProgressRepository? progressRepository,
  }) async {
    final storage = storageService ?? await LocalStorageService.create();
    final courseRepo =
        courseRepository ?? CourseRepositoryImpl(CourseLocalDataSource());
    final progressRepo =
        progressRepository ??
        ProgressRepositoryImpl(ProgressLocalDataSource(storage));

    _instance = AppDependencies(
      storageService: storage,
      courseRepository: courseRepo,
      progressRepository: progressRepo,
    );

    return _instance!;
  }

  /// Sets or clears test dependencies for hermetic testing.
  @visibleForTesting
  static void setTestInstance(AppDependencies? testInstance) {
    _instance = testInstance;
  }
}
