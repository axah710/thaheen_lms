import 'package:equatable/equatable.dart';

import '../domain/entities/course.dart';
import '../domain/entities/continue_watching_item.dart';

/// Sealed state hierarchy for CourseListCubit driving the catalog screen.
sealed class CourseListState extends Equatable {
  const CourseListState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class CourseListInitial extends CourseListState {
  const CourseListInitial();
}

/// Active loading state while reading catalog or progress.
class CourseListLoading extends CourseListState {
  const CourseListLoading();
}

/// Loaded state with all courses, progress maps, and optional continue watching card.
class CourseListLoaded extends CourseListState {
  final List<Course> courses;
  final Map<String, int> progressPercentages; // courseId -> percentage [0-100]
  final ContinueWatchingItem? continueWatching;
  final bool storageWasReset;

  const CourseListLoaded({
    required this.courses,
    required this.progressPercentages,
    this.continueWatching,
    this.storageWasReset = false,
  });

  bool get hasContinueWatching => continueWatching != null;

  @override
  List<Object?> get props => [
    courses,
    progressPercentages,
    continueWatching,
    storageWasReset,
  ];
}

/// Error state with localized user-facing message.
class CourseListError extends CourseListState {
  final String userMessageArabic;
  final String? technicalDetails;

  const CourseListError({
    required this.userMessageArabic,
    this.technicalDetails,
  });

  @override
  List<Object?> get props => [userMessageArabic, technicalDetails];
}
