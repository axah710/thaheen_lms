import 'package:flutter_bloc/flutter_bloc.dart';

import '../../player/domain/repositories/i_progress_repository.dart';
import '../domain/entities/continue_watching_item.dart';
import '../domain/entities/course.dart';
import '../domain/repositories/i_course_repository.dart';
import 'course_list_state.dart';

/// Cubit managing catalog loading, course progress aggregation,
/// and Continue Watching resolution for the courses screen.
class CourseListCubit extends Cubit<CourseListState> {
  final ICourseRepository courseRepository;
  final IProgressRepository progressRepository;

  CourseListCubit({
    required this.courseRepository,
    required this.progressRepository,
  }) : super(const CourseListInitial());

  /// Safe state emission guarding against post-closure crashes per Constitution V.3.
  void emitSafe(CourseListState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  /// Loads the courses catalog, aggregates progress %, and resolves continue watching item.
  Future<void> loadCourses() async {
    emitSafe(const CourseListLoading());

    final coursesResult = await courseRepository.getCourses();

    await coursesResult.fold((failure) async {
      emitSafe(
        CourseListError(
          userMessageArabic: failure.messageArabic,
          technicalDetails: failure.toString(),
        ),
      );
    }, (courses) async => _loadCatalogDetails(courses));
  }

  Future<void> _loadCatalogDetails(List<Course> courses) async {
    try {
      final progressPercentages = await _aggregateProgressPercentages(courses);
      final continueWatching = await _resolveContinueWatching(courses);

      emitSafe(
        CourseListLoaded(
          courses: courses,
          progressPercentages: progressPercentages,
          continueWatching: continueWatching,
          storageWasReset: progressRepository.wasStorageReset,
        ),
      );
    } on Exception catch (exception) {
      emitSafe(
        CourseListError(
          userMessageArabic: 'حدث خطأ أثناء معالجة بيانات التقدم للدورات',
          technicalDetails: exception.toString(),
        ),
      );
    }
  }

  Future<Map<String, int>> _aggregateProgressPercentages(
    List<Course> courses,
  ) async {
    final progressPercentages = <String, int>{};

    for (final course in courses) {
      final progressResult = await progressRepository.getCourseProgress(
        course.id,
      );
      final courseProgress = progressResult.fold(
        (failure) => null,
        (progress) => progress,
      );

      if (courseProgress != null) {
        progressPercentages[course.id] = course.calculateProgressPercentage(
          courseProgress.lessonProgressMap,
        );
      } else {
        progressPercentages[course.id] = 0;
      }
    }

    return progressPercentages;
  }

  Future<ContinueWatchingItem?> _resolveContinueWatching(
    List<Course> courses,
  ) async {
    final continueWatchingResult = await progressRepository
        .resolveContinueWatching(courses);
    return continueWatchingResult.fold(
      (failure) => null,
      (continueWatchingItem) => continueWatchingItem,
    );
  }

  /// Filters the loaded course catalog in real-time by search query.
  ///
  /// Resets [storageWasReset] to false to avoid repeated warning SnackBars on keystrokes.
  void search(String query) {
    final currentState = state;
    if (currentState is CourseListLoaded) {
      emitSafe(
        currentState.copyWith(searchQuery: query, storageWasReset: false),
      );
    }
  }

  /// Clears active search filter.
  void clearSearch() => search('');

  /// Refresh shortcut
  Future<void> refresh() async => loadCourses();
}
