import 'package:flutter_bloc/flutter_bloc.dart';

import '../../player/domain/entities/course_progress.dart';
import '../../player/domain/repositories/i_progress_repository.dart';
import '../domain/repositories/i_course_repository.dart';
import 'course_details_state.dart';

/// Cubit managing syllabus presentation, sequential unlock evaluation,
/// and progress tracking for a single course.
class CourseDetailsCubit extends Cubit<CourseDetailsState> {
  final String courseId;
  final ICourseRepository courseRepository;
  final IProgressRepository progressRepository;

  CourseDetailsCubit({
    required this.courseId,
    required this.courseRepository,
    required this.progressRepository,
  }) : super(const CourseDetailsInitial());

  /// Safe state emission guarding against post-closure crashes per Constitution V.3.
  void emitSafe(CourseDetailsState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  /// Loads course details and syllabus, then aggregates progress and evaluates sequential unlocks.
  Future<void> loadCourseDetails() async {
    emitSafe(const CourseDetailsLoading());

    final courseResult = await courseRepository.getCourseById(courseId);

    await courseResult.fold(
      (failure) async {
        emitSafe(CourseDetailsError(userMessageArabic: failure.messageArabic));
      },
      (course) async {
        final progressResult = await progressRepository.getCourseProgress(
          courseId,
        );

        final courseProgress = progressResult.fold(
          (failure) => CourseProgress.empty(courseId),
          (progress) => progress,
        );

        emitSafe(
          CourseDetailsLoaded(
            course: course,
            courseProgress: courseProgress,
            allOrderedLessons: course.allLessonsOrdered,
          ),
        );
      },
    );
  }

  /// Refreshes syllabus and unlock states after synchronizing with durable storage.
  Future<void> refresh() async {
    await progressRepository.syncWithStorage();
    await loadCourseDetails();
  }
}
