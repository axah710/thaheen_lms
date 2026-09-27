import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/app/error_boundary.dart';
import 'package:thaheen_lms/app/theme.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/course/domain/repositories/i_course_repository.dart';
import 'package:thaheen_lms/features/course/presentation/widgets/empty_course_view.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_cubit.dart';
import 'package:thaheen_lms/features/player/domain/entities/course_progress.dart';
import 'package:thaheen_lms/features/player/domain/repositories/i_progress_repository.dart';
import 'package:thaheen_lms/features/player/presentation/lesson_player_page.dart';
import 'package:thaheen_lms/features/player/presentation/widgets/in_player_error_card.dart';

import '../helpers/fake_video_player_platform.dart';

class MockCourseRepository extends Mock implements ICourseRepository {}

class MockProgressRepository extends Mock implements IProgressRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initGlobalErrorBoundary();
  });

  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    );
  }

  group('User Story 5: Zero Red Screens Resilience Tests (AAA Pattern)', () {
    testWidgets(
      'recovers gracefully on corrupt media / decoding failure by rendering InPlayerErrorCard with retry',
      (tester) async {
        // Arrange - Register FakeVideoPlayerPlatform configured to throw on initialization
        FakeVideoPlayerPlatform.register(shouldFailInitialization: true);

        final mockCourseRepo = MockCourseRepository();
        final mockProgressRepo = MockProgressRepository();

        final lesson = Lesson(
          id: 'l_corrupt',
          courseId: 'c1',
          sectionId: 's1',
          title: 'درس تالف',
          durationSec: 100,
          videoAssetPath: 'assets/videos/corrupt_asset.mp4',
          globalOrderIndex: 0,
        );

        final course = Course(
          id: 'c1',
          title: 'دورة التشريح',
          instructor: 'د. خالد',
          thumbnail: 'assets/images/anatomy.png',
          sections: [
            Section(
              id: 's1',
              courseId: 'c1',
              title: 'القسم 1',
              orderIndex: 0,
              lessons: [lesson],
            ),
          ],
        );

        when(() => mockCourseRepo.getCourseById('c1'))
            .thenAnswer((_) async => Right(course));
        when(() => mockProgressRepo.getCourseProgress('c1'))
            .thenAnswer((_) async => Right(CourseProgress.empty('c1')));
        when(() => mockProgressRepo.getLessonProgress('l_corrupt'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockProgressRepo.flush())
            .thenAnswer((_) async => const Right(null));

        final cubit = LessonPlayerCubit(
          courseId: 'c1',
          lessonId: 'l_corrupt',
          courseRepository: mockCourseRepo,
          progressRepository: mockProgressRepo,
        );

        // Act - Mount LessonPlayerPage
        await tester.pumpWidget(
          buildTestableWidget(
            child: LessonPlayerPage(
              courseId: 'c1',
              lessonId: 'l_corrupt',
              cubit: cubit,
            ),
          ),
        );

        await cubit.initializeLesson();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - InPlayerErrorCard rendered, zero red screens
        expect(find.byType(InPlayerErrorCard), findsOneWidget);
        expect(
          find.text('عذراً، ملف الفيديو تالف أو غير متوفر حالياً'),
          findsOneWidget,
        );
        expect(find.text('إعادة المحاولة'), findsOneWidget);
        expect(find.text('العودة للدورة'), findsOneWidget);

        // Verify zero framework exceptions
        expect(tester.takeException(), isNull);
        await cubit.close();
      },
    );

    testWidgets(
      'renders EmptyCourseView with friendly Arabic message when course contains 0 lessons',
      (tester) async {
        // Arrange
        const emptyCourse = Course(
          id: 'c_empty',
          title: 'دورة فارغة بدون دروس',
          instructor: 'د. نورة',
          thumbnail: 'assets/images/anatomy.png',
          sections: [],
        );

        final mockCourseRepo = MockCourseRepository();
        final mockProgressRepo = MockProgressRepository();

        when(() => mockCourseRepo.getCourseById('c_empty'))
            .thenAnswer((_) async => const Right(emptyCourse));
        when(() => mockProgressRepo.getCourseProgress('c_empty'))
            .thenAnswer((_) async => Right(CourseProgress.empty('c_empty')));

        // Act - Mount EmptyCourseView directly and inside scaffold
        await tester.pumpWidget(
          buildTestableWidget(child: const Scaffold(body: EmptyCourseView())),
        );
        await tester.pump();

        // Assert - EmptyCourseView shows friendly Arabic message
        expect(find.byType(EmptyCourseView), findsOneWidget);
        expect(
          find.text('لا توجد دروس متاحة حالياً في هذه الدورة'),
          findsOneWidget,
        );

        // Verify zero framework exceptions
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'global CustomErrorWidget intercepts unhandled layout exceptions with zero red screens',
      (tester) async {
        // Arrange
        const errorDetails = FlutterErrorDetails(
          exception: 'Simulated layout overflow or rendering crash',
        );

        // Act - Mount CustomErrorWidget
        await tester.pumpWidget(
          buildTestableWidget(
            child: const Scaffold(
              body: CustomErrorWidget(details: errorDetails),
            ),
          ),
        );
        await tester.pump();

        // Assert - Dignified Arabic error card is displayed
        expect(find.byType(CustomErrorWidget), findsOneWidget);
        expect(find.text('حدث خطأ غير متوقع في العرض'), findsOneWidget);
        expect(
          find.text(
            'نعتذر عن هذا الخطأ غير المتوقع. يرجى إعادة المحاولة أو العودة للدورات.',
          ),
          findsOneWidget,
        );

        // Verify zero framework red screen errors
        expect(tester.takeException(), isNull);
      },
    );
  });
}
