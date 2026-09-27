import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/course/presentation/course_details_page.dart';
import '../features/course/presentation/course_list_page.dart';
import '../features/player/presentation/lesson_player_page.dart';

/// App router configuration using GoRouter.
final GoRouter appRouter = GoRouter(
  initialLocation: '/courses',
  routes: [
    GoRoute(
      path: '/courses',
      name: 'courses',
      builder: (context, state) => const CourseListPage(),
      routes: [
        GoRoute(
          path: ':id',
          name: 'course_details',
          builder: (context, state) {
            final courseId = state.pathParameters['id'] ?? '';
            return CourseDetailsPage(courseId: courseId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      builder: (context, state) {
        final queryParams = state.uri.queryParameters;
        final extra = state.extra as Map<String, dynamic>?;

        final courseId =
            extra?['courseId'] as String? ?? queryParams['courseId'] ?? '';
        final lessonId =
            extra?['lessonId'] as String? ?? queryParams['lessonId'] ?? '';

        return LessonPlayerPage(courseId: courseId, lessonId: lessonId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'الصفحة غير موجودة: ${state.uri}',
        style: const TextStyle(fontSize: 16),
      ),
    ),
  ),
);
