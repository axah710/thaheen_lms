import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../player/data/data_sources/progress_local_data_source.dart';
import '../../player/data/repositories/progress_repository_impl.dart';
import '../application/course_list_cubit.dart';
import '../application/course_list_state.dart';
import '../data/data_sources/course_local_data_source.dart';
import '../data/repositories/course_repository_impl.dart';
import '../domain/repositories/i_course_repository.dart';
import '../../player/domain/repositories/i_progress_repository.dart';
import 'widgets/continue_watching_card.dart';
import 'widgets/course_card.dart';

/// Screen displaying the courses catalog and "Continue Watching" hero card.
class CourseListPage extends StatelessWidget {
  final CourseListCubit? cubit;
  final ICourseRepository? courseRepository;
  final IProgressRepository? progressRepository;

  const CourseListPage({
    super.key,
    this.cubit,
    this.courseRepository,
    this.progressRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<CourseListCubit>.value(
        value: cubit!,
        child: const _CourseListView(),
      );
    }

    if (courseRepository != null && progressRepository != null) {
      return BlocProvider(
        create: (_) => CourseListCubit(
          courseRepository: courseRepository!,
          progressRepository: progressRepository!,
        )..loadCourses(),
        child: const _CourseListView(),
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
        final courseRepo =
            courseRepository ?? CourseRepositoryImpl(CourseLocalDataSource());
        final progressRepo =
            progressRepository ??
            ProgressRepositoryImpl(
              ProgressLocalDataSource(storage),
              onCorruptReset: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تمت إعادة ضبط سجل التعلم المحلي لسلامة البيانات',
                          textAlign: TextAlign.right,
                        ),
                        backgroundColor: AppTheme.warningAmber,
                      ),
                    );
                  }
                });
              },
            );

        return BlocProvider(
          create: (_) => CourseListCubit(
            courseRepository: courseRepo,
            progressRepository: progressRepo,
          )..loadCourses(),
          child: const _CourseListView(),
        );
      },
    );
  }
}

class _CourseListView extends StatelessWidget {
  const _CourseListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة طهين التعليمية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الدورات',
            onPressed: () => context.read<CourseListCubit>().refresh(),
          ),
        ],
      ),
      body: BlocListener<CourseListCubit, CourseListState>(
        listener: (context, state) {
          if (state is CourseListLoaded && state.storageWasReset) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'تمت إعادة ضبط سجل التعلم المحلي لسلامة البيانات',
                  textAlign: TextAlign.right,
                ),
                backgroundColor: AppTheme.warningAmber,
              ),
            );
          }
        },
        child: BlocBuilder<CourseListCubit, CourseListState>(
          builder: (context, state) {
            if (state is CourseListLoading || state is CourseListInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              );
            }

            if (state is CourseListError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
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
                        state.userMessageArabic,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<CourseListCubit>().refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is CourseListLoaded) {
              if (state.courses.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 56,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد دورات متاحة حالياً',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'يرجى التأكد من توفر الدورات في الحزمة المحلية',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppTheme.primaryTeal,
                onRefresh: () => context.read<CourseListCubit>().refresh(),
                child: ListView(
                  padding: const EdgeInsetsDirectional.all(16),
                  children: [
                    // Continue watching hero card if available
                    if (state.hasContinueWatching) ...[
                      ContinueWatchingCard(
                        item: state.continueWatching!,
                        onResume: () {
                          context.push(
                            '/player?courseId=${state.continueWatching!.course.id}&lessonId=${state.continueWatching!.lesson.id}',
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Header
                    const Text(
                      'جميع الدورات المتاحة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Courses list
                    ...state.courses.map((course) {
                      final progress =
                          state.progressPercentages[course.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CourseCard(
                          course: course,
                          progressPercentage: progress,
                          onTap: () {
                            context.push('/courses/${course.id}');
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
