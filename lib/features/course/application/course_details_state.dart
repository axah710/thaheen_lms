import 'package:equatable/equatable.dart';

import '../../player/domain/entities/course_progress.dart';
import '../../player/domain/entities/lesson_status.dart';
import '../domain/entities/course.dart';
import '../domain/entities/lesson.dart';

/// Sealed state hierarchy for CourseDetailsCubit.
sealed class CourseDetailsState extends Equatable {
  const CourseDetailsState();

  @override
  List<Object?> get props => [];
}

class CourseDetailsInitial extends CourseDetailsState {
  const CourseDetailsInitial();
}

class CourseDetailsLoading extends CourseDetailsState {
  const CourseDetailsLoading();
}

class CourseDetailsLoaded extends CourseDetailsState {
  final Course course;
  final CourseProgress courseProgress;
  final List<Lesson> allOrderedLessons;

  const CourseDetailsLoaded({
    required this.course,
    required this.courseProgress,
    required this.allOrderedLessons,
  });

  int get overallProgressPercentage =>
      courseProgress.calculateOverallProgress(course.totalLessonsCount);

  bool isLessonUnlocked(Lesson lesson) =>
      courseProgress.isLessonUnlocked(lesson, allOrderedLessons);

  LessonStatus getLessonStatus(Lesson lesson) =>
      courseProgress.getLessonStatus(lesson.id);

  @override
  List<Object?> get props => [course, courseProgress, allOrderedLessons];
}

class CourseDetailsError extends CourseDetailsState {
  final String userMessageArabic;

  const CourseDetailsError({required this.userMessageArabic});

  @override
  List<Object?> get props => [userMessageArabic];
}
