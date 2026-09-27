import 'package:flutter_bloc/flutter_bloc.dart';

import '../../player/domain/repositories/i_progress_repository.dart';
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

    await coursesResult.fold(
      (failure) async {
        emitSafe(
          CourseListError(
            userMessageArabic: failure.messageArabic,
            technicalDetails: failure.toString(),
          ),
        );
      },
      (courses) async {
        try {
          final progressPercentages = <String, int>{};

          for (final course in courses) {
            final progressResult = await progressRepository.getCourseProgress(
              course.id,
            );
            final courseProgress = progressResult.fold((f) => null, (p) => p);

            if (courseProgress != null) {
              progressPercentages[course.id] = course
                  .calculateProgressPercentage(
                    courseProgress.lessonProgressMap,
                  );
            } else {
              progressPercentages[course.id] = 0;
            }
          }

          final cwResult = await progressRepository.resolveContinueWatching(
            courses,
          );
          final continueWatching = cwResult.fold((f) => null, (item) => item);

          emitSafe(
            CourseListLoaded(
              courses: courses,
              progressPercentages: progressPercentages,
              continueWatching: continueWatching,
              storageWasReset: progressRepository.wasStorageReset,
            ),
          );
        } catch (e) {
          emitSafe(
            CourseListError(
              userMessageArabic: 'حدث خطأ أثناء معالجة بيانات التقدم للدورات',
              technicalDetails: e.toString(),
            ),
          );
        }
      },
    );
  }

  /// Refresh shortcut
  Future<void> refresh() async => loadCourses();
}
