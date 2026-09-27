import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../course/data/data_sources/course_local_data_source.dart';
import '../../course/data/repositories/course_repository_impl.dart';
import '../../course/domain/repositories/i_course_repository.dart';
import '../application/lesson_player_cubit.dart';
import '../application/lesson_player_state.dart';
import '../data/data_sources/progress_local_data_source.dart';
import '../data/repositories/progress_repository_impl.dart';
import '../domain/repositories/i_progress_repository.dart';
import 'widgets/course_completion_celebration.dart';
import 'widgets/custom_video_controls.dart';
import 'widgets/in_player_error_card.dart';

/// Screen displaying the lesson video player, custom controls, and bottom navigation bar.
class LessonPlayerPage extends StatelessWidget {
  final String courseId;
  final String lessonId;
  final LessonPlayerCubit? cubit;
  final ICourseRepository? courseRepository;
  final IProgressRepository? progressRepository;

  const LessonPlayerPage({
    super.key,
    required this.courseId,
    required this.lessonId,
    this.cubit,
    this.courseRepository,
    this.progressRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<LessonPlayerCubit>.value(
        value: cubit!,
        child: const _LessonPlayerLifecycleWrapper(),
      );
    }

    final effectiveCourseRepo =
        courseRepository ?? AppDependencies.instance?.courseRepository;
    final effectiveProgressRepo =
        progressRepository ?? AppDependencies.instance?.progressRepository;

    if (effectiveCourseRepo != null && effectiveProgressRepo != null) {
      return BlocProvider(
        create: (_) => LessonPlayerCubit(
          courseId: courseId,
          lessonId: lessonId,
          courseRepository: effectiveCourseRepo,
          progressRepository: effectiveProgressRepo,
        )..initializeLesson(),
        child: const _LessonPlayerLifecycleWrapper(),
      );
    }

    return FutureBuilder<LocalStorageService>(
      future: LocalStorageService.create(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            ),
          );
        }

        final storage = snapshot.data!;
        final courseRepo =
            courseRepository ?? CourseRepositoryImpl(CourseLocalDataSource());
        final progressRepo =
            progressRepository ??
            ProgressRepositoryImpl(ProgressLocalDataSource(storage));

        return BlocProvider(
          create: (_) => LessonPlayerCubit(
            courseId: courseId,
            lessonId: lessonId,
            courseRepository: courseRepo,
            progressRepository: progressRepo,
          )..initializeLesson(),
          child: const _LessonPlayerLifecycleWrapper(),
        );
      },
    );
  }
}

class _LessonPlayerLifecycleWrapper extends StatefulWidget {
  const _LessonPlayerLifecycleWrapper();

  @override
  State<_LessonPlayerLifecycleWrapper> createState() =>
      _LessonPlayerLifecycleWrapperState();
}

class _LessonPlayerLifecycleWrapperState
    extends State<_LessonPlayerLifecycleWrapper> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // US4 / T062: Immediate write-through buffer flush across app lifecycle transitions
    _lifecycleListener = AppLifecycleListener(
      onPause: _handleBackgroundState,
      onInactive: _handleBackgroundState,
      onHide: _handleBackgroundState,
      onDetach: _handleBackgroundState,
    );
  }

  void _handleBackgroundState() {
    final cubit = context.read<LessonPlayerCubit>();
    cubit.progressRepository.flush();
    if (cubit.state is LessonPlayerReady &&
        (cubit.state as LessonPlayerReady).isPlaying) {
      cubit.togglePlayPause();
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const _LessonPlayerView();
  }
}

class _LessonPlayerView extends StatelessWidget {
  const _LessonPlayerView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LessonPlayerCubit>();
    final state = cubit.state;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await cubit.progressRepository.flush();
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: switch (state) {
          LessonPlayerInitial() || LessonPlayerLoading() => const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            ),
          ),
          LessonPlayerError(:final userMessageArabic) => Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: InPlayerErrorCard(
              messageArabic: userMessageArabic,
              onRetry: () => cubit.initializeLesson(),
              onReturn: () async {
                await cubit.progressRepository.flush();
                if (context.mounted) {
                  context.pop();
                }
              },
            ),
          ),
          LessonPlayerReady() => _buildPlayerLayout(context, cubit, state),
        },
      ),
    );
  }

  Widget _buildPlayerLayout(
    BuildContext context,
    LessonPlayerCubit cubit,
    LessonPlayerReady state,
  ) {
    final controller = cubit.controller;
    final isFullscreen = state.isFullscreen;

    final videoWidget = Stack(
      alignment: Alignment.center,
      children: [
        if (controller != null && controller.value.isInitialized)
          AspectRatio(
            aspectRatio: controller.value.aspectRatio > 0
                ? controller.value.aspectRatio
                : 16 / 9,
            child: VideoPlayer(controller),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            ),
          ),

        // Tap area to toggle overlay controls
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => cubit.toggleControls(),
          ),
        ),

        // Controls overlay
        Positioned.fill(
          child: CustomVideoControls(
            isVisible: state.isControlsVisible,
            isPlaying: state.isPlaying,
            playbackSpeed: state.playbackSpeed,
            isFullscreen: isFullscreen,
            currentPosition: state.currentPosition,
            totalDuration: state.totalDuration,
            lessonTitle: state.lesson.title,
            onPlayPause: () => cubit.togglePlayPause(),
            onSeek: (position) => cubit.seekTo(position),
            onSpeedTap: () => cubit.cyclePlaybackSpeed(),
            onFullscreenToggle: () => cubit.toggleFullscreen(),
            onBack: () async {
              await cubit.progressRepository.flush();
              if (context.mounted) {
                context.pop();
              }
            },
            onUserInteraction: () {},
          ),
        ),
      ],
    );

    if (isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: videoWidget),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video viewport with fixed aspect ratio
            Container(
              color: Colors.black,
              width: double.infinity,
              child: AspectRatio(aspectRatio: 16 / 9, child: videoWidget),
            ),

            // Lesson Details Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title Badge
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.course.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lesson Title
                    Text(
                      state.lesson.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Duration and Status
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.lesson.formattedDuration,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (state.isCompleted)
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.statusCompletedBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: AppTheme.statusCompleted,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'مكتمل',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.statusCompleted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar with Dynamic Actions
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: state.isTerminalLesson
                      ? ElevatedButton(
                          onPressed: state.isCompleted
                              ? () async {
                                  await cubit.progressRepository.flush();
                                  if (context.mounted) {
                                    CourseCompletionCelebration.show(
                                      context,
                                      courseTitle: state.course.title,
                                      onFinished: () => context.pop(),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.statusCompleted,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.statusLockedBg,
                            disabledForegroundColor: AppTheme.statusLocked,
                          ),
                          child: const Text('إنهاء الدورة'),
                        )
                      : ElevatedButton(
                          onPressed: state.isNextLessonUnlocked
                              ? () => cubit.playNextLesson()
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.statusLockedBg,
                            disabledForegroundColor: AppTheme.statusLocked,
                          ),
                          child: const Text('الدرس التالي'),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
