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
import 'widgets/course_search_bar.dart';
import 'widgets/empty_search_view.dart';

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

class _CourseListView extends StatefulWidget {
  const _CourseListView();

  @override
  State<_CourseListView> createState() => _CourseListViewState();
}

class _CourseListViewState extends State<_CourseListView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<CourseListCubit>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة طهين التعليمية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الدورات',
            onPressed: () {
              _clearSearch();
              context.read<CourseListCubit>().refresh();
            },
          ),
        ],
      ),
      body: BlocListener<CourseListCubit, CourseListState>(
        listener: (context, state) {
          if (state is CourseListLoaded) {
            if (state.storageWasReset) {
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
            if (!state.isSearching && _searchController.text.isNotEmpty) {
              _searchController.clear();
            }
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

              final filteredCourses = state.filteredCourses;
              final isSearching = state.isSearching;

              return RefreshIndicator(
                color: AppTheme.primaryTeal,
                onRefresh: () async {
                  await context.read<CourseListCubit>().refresh();
                },
                child: ListView(
                  padding: const EdgeInsetsDirectional.all(16),
                  children: [
                    // Persistent Arabic Search Bar
                    CourseSearchBar(
                      controller: _searchController,
                      onChanged: (query) {
                        context.read<CourseListCubit>().search(query);
                      },
                      onClear: _clearSearch,
                    ),
                    const SizedBox(height: 16),

                    // Continue watching hero card if available and not searching
                    if (!isSearching && state.hasContinueWatching) ...[
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
                    Text(
                      isSearching
                          ? 'نتائج البحث (${filteredCourses.length})'
                          : 'جميع الدورات المتاحة',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Empty Search State
                    if (isSearching && filteredCourses.isEmpty)
                      EmptySearchView(
                        query: state.searchQuery,
                        onClear: _clearSearch,
                      ),

                    // Courses list
                    ...filteredCourses.map((course) {
                      final progress =
                          state.progressPercentages[course.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 16),
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
