import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../player/data/data_sources/progress_local_data_source.dart';
import '../../player/data/repositories/progress_repository_impl.dart';
import '../application/course_details_cubit.dart';
import '../application/course_details_state.dart';
import '../data/data_sources/course_local_data_source.dart';
import '../data/repositories/course_repository_impl.dart';
import '../domain/entities/course.dart';
import '../domain/entities/lesson.dart';
import 'widgets/empty_course_view.dart';
import 'widgets/section_card.dart';

/// Screen displaying the course details, syllabus, and sequential unlock indicators.
class CourseDetailsPage extends StatelessWidget {
  final String courseId;
  final CourseDetailsCubit? cubit;

  const CourseDetailsPage({super.key, required this.courseId, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<CourseDetailsCubit>.value(
        value: cubit!,
        child: const _CourseDetailsView(),
      );
    }

    return FutureBuilder<LocalStorageService>(
      future: LocalStorageService.create(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
          );
        }

        final storage = snapshot.data!;
        final courseRepo = CourseRepositoryImpl(CourseLocalDataSource());
        final progressRepo = ProgressRepositoryImpl(
          ProgressLocalDataSource(storage),
        );

        return BlocProvider(
          create: (_) => CourseDetailsCubit(
            courseId: courseId,
            courseRepository: courseRepo,
            progressRepository: progressRepo,
          )..loadCourseDetails(),
          child: const _CourseDetailsView(),
        );
      },
    );
  }
}

class _CourseDetailsView extends StatelessWidget {
  const _CourseDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseDetailsCubit, CourseDetailsState>(
      builder: (context, state) {
        final title = switch (state) {
          CourseDetailsLoaded(:final course) => course.title,
          _ => 'تفاصيل الدورة',
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'رجوع',
              onPressed: () => context.pop(),
            ),
          ),
          body: switch (state) {
            CourseDetailsInitial() || CourseDetailsLoading() => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
            CourseDetailsError(:final userMessageArabic) => Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userMessageArabic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context
                          .read<CourseDetailsCubit>()
                          .loadCourseDetails(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
            CourseDetailsLoaded() => _LoadedCourseContent(state: state),
          },
        );
      },
    );
  }
}

class _LoadedCourseContent extends StatelessWidget {
  final CourseDetailsLoaded state;

  const _LoadedCourseContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final course = state.course;
    final progress = state.courseProgress;
    final overallPercentage = state.overallProgressPercentage;
    final isCourseEmpty = course.totalLessonsCount == 0;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header Card
          _CourseHeaderCard(
            course: course,
            overallPercentage: overallPercentage,
            completedLessonsCount: progress.completedLessonsCount,
          ),
          const SizedBox(height: 24),

          // Syllabus Header
          const Text(
            'المنهج الدراسي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Empty Course View fallback or Section list
          if (isCourseEmpty)
            const EmptyCourseView()
          else
            ...course.sections.map(
              (section) => SectionCard(
                section: section,
                courseProgress: state.courseProgress,
                allOrderedLessons: state.allOrderedLessons,
                onLessonTap: (lesson) => _onLessonSelected(context, lesson),
              ),
            ),
        ],
      ),
    );
  }

  void _onLessonSelected(BuildContext context, Lesson lesson) async {
    await context.push(
      '/player',
      extra: {'courseId': state.course.id, 'lessonId': lesson.id},
    );

    if (context.mounted) {
      context.read<CourseDetailsCubit>().refresh();
    }
  }
}

class _CourseHeaderCard extends StatelessWidget {
  final Course course;
  final int overallPercentage;
  final int completedLessonsCount;

  const _CourseHeaderCard({
    required this.course,
    required this.overallPercentage,
    required this.completedLessonsCount,
  });

  @override
  Widget build(BuildContext context) {
    final progressFraction = course.totalLessonsCount > 0
        ? (overallPercentage / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                course.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.primaryLight,
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 48,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructor
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      course.instructor,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar & Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'نسبة الإنجاز',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$overallPercentage%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 8,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedLessonsCount من أصل ${course.totalLessonsCount} درس مكتمل',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
