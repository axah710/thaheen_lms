import 'package:equatable/equatable.dart';

import '../../../core/utils/arabic_search_helper.dart';
import '../domain/entities/continue_watching_item.dart';
import '../domain/entities/course.dart';

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

  /// Mapping from [Course.id] to integer progress percentage in the range [0, 100].
  final Map<String, int> progressPercentages;
  final ContinueWatchingItem? continueWatching;
  final bool storageWasReset;
  final String searchQuery;

  const CourseListLoaded({
    required this.courses,
    required this.progressPercentages,
    this.continueWatching,
    this.storageWasReset = false,
    this.searchQuery = '',
  });

  bool get hasContinueWatching => continueWatching != null;

  /// Whether an active search query is applied.
  bool get isSearching => searchQuery.trim().isNotEmpty;

  /// Returns courses matching [searchQuery] across title and instructor using Arabic normalization.
  ///
  /// Pre-normalizes the query once to avoid $2N$ redundant regex passes over the catalog.
  List<Course> get filteredCourses {
    if (!isSearching) return courses;

    final normalizedQuery = ArabicSearchHelper.normalize(searchQuery);
    if (normalizedQuery.isEmpty) return courses;

    return courses.where((course) {
      final matchesTitle = ArabicSearchHelper.matchesNormalized(
        course.title,
        normalizedQuery,
      );
      final matchesInstructor = ArabicSearchHelper.matchesNormalized(
        course.instructor,
        normalizedQuery,
      );
      return matchesTitle || matchesInstructor;
    }).toList();
  }

  CourseListLoaded copyWith({
    List<Course>? courses,
    Map<String, int>? progressPercentages,
    ContinueWatchingItem? continueWatching,
    bool? storageWasReset,
    String? searchQuery,
  }) {
    return CourseListLoaded(
      courses: courses ?? this.courses,
      progressPercentages: progressPercentages ?? this.progressPercentages,
      continueWatching: continueWatching ?? this.continueWatching,
      storageWasReset: storageWasReset ?? this.storageWasReset,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    courses,
    progressPercentages,
    continueWatching,
    storageWasReset,
    searchQuery,
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
