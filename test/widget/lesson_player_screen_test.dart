import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/app/theme.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_cubit.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_state.dart';
import 'package:thaheen_lms/features/player/domain/repositories/i_progress_repository.dart';
import 'package:thaheen_lms/features/player/presentation/lesson_player_page.dart';
import 'package:thaheen_lms/features/player/presentation/widgets/course_completion_celebration.dart';
import 'package:thaheen_lms/features/player/presentation/widgets/custom_video_controls.dart';
import 'package:thaheen_lms/features/player/presentation/widgets/in_player_error_card.dart';
import 'package:thaheen_lms/features/player/presentation/widgets/rtl_seek_bar.dart';

import '../helpers/fake_video_player_platform.dart';

class MockLessonPlayerCubit extends MockCubit<LessonPlayerState>
    implements LessonPlayerCubit {}

class MockProgressRepository extends Mock implements IProgressRepository {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLessonPlayerCubit mockCubit;
  late MockProgressRepository mockProgressRepository;

  final lesson1 = Lesson(
    id: 'l1',
    courseId: 'c1',
    sectionId: 's1',
    title: 'مقدمة في علم التشريح',
    durationSec: 100,
    videoAssetPath: 'assets/videos/anatomy_intro.mp4',
    globalOrderIndex: 0,
  );

  final lesson2 = Lesson(
    id: 'l2',
    courseId: 'c1',
    sectionId: 's1',
    title: 'الجهاز الهيكلي والعظام',
    durationSec: 200,
    videoAssetPath: 'assets/videos/anatomy_bones.mp4',
    globalOrderIndex: 1,
  );

  final testCourse = Course(
    id: 'c1',
    title: 'علم التشريح البشري',
    instructor: 'د. سارة الأحمد',
    thumbnail: 'assets/images/anatomy.png',
    sections: [
      Section(
        id: 's1',
        courseId: 'c1',
        title: 'القسم الأول',
        orderIndex: 0,
        lessons: [lesson1, lesson2],
      ),
    ],
  );

  setUp(() {
    mockCubit = MockLessonPlayerCubit();
    mockProgressRepository = MockProgressRepository();
    FakeVideoPlayerPlatform.register();
    when(() => mockCubit.controller).thenReturn(null);
    when(
      () => mockProgressRepository.flush(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockCubit.progressRepository,
    ).thenReturn(mockProgressRepository);
  });

  group('LessonPlayerPage Widget Tests (AAA Pattern)', () {
    testWidgets('renders loading spinner when state is LessonPlayerLoading', (
      tester,
    ) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(const LessonPlayerLoading());

      // Act
      await tester.pumpWidget(
        buildTestableWidget(
          child: LessonPlayerPage(
            courseId: 'c1',
            lessonId: 'l1',
            cubit: mockCubit,
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'renders custom controls, unmirrored media icon, and Western Arabic numerals',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          LessonPlayerReady(
            lesson: lesson1,
            course: testCourse,
            currentPosition: const Duration(seconds: 42),
            totalDuration: const Duration(seconds: 100),
            isPlaying: true,
            playbackSpeed: 1.0,
            isCompleted: false,
            isControlsVisible: true,
            isFullscreen: false,
            nextLesson: lesson2,
            isNextLessonUnlocked: false,
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: LessonPlayerPage(
              courseId: 'c1',
              lessonId: 'l1',
              cubit: mockCubit,
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.byType(CustomVideoControls), findsOneWidget);
        expect(find.byType(RtlSeekBar), findsOneWidget);
        expect(find.text('1.0x'), findsOneWidget);
        expect(find.text('مقدمة في علم التشريح'), findsAtLeastNWidgets(1));

        // Timestamps in Western Arabic numerals
        expect(find.text('00:42'), findsOneWidget);
        expect(find.text('01:40'), findsNWidgets(2));

        // Unmirrored pause icon while playing
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'renders disabled "الدرس التالي" button when next lesson is locked',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          LessonPlayerReady(
            lesson: lesson1,
            course: testCourse,
            currentPosition: const Duration(seconds: 30),
            totalDuration: const Duration(seconds: 100),
            isPlaying: false,
            playbackSpeed: 1.0,
            isCompleted: false,
            isControlsVisible: true,
            isFullscreen: false,
            nextLesson: lesson2,
            isNextLessonUnlocked: false, // Locked!
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: LessonPlayerPage(
              courseId: 'c1',
              lessonId: 'l1',
              cubit: mockCubit,
            ),
          ),
        );
        await tester.pump();

        // Assert: Next lesson button exists but is disabled
        final nextButtonFinder = find.widgetWithText(
          ElevatedButton,
          'الدرس التالي',
        );
        expect(nextButtonFinder, findsOneWidget);
        final elevatedButton = tester.widget<ElevatedButton>(nextButtonFinder);
        expect(elevatedButton.onPressed, isNull);
      },
    );

    testWidgets(
      'renders enabled "الدرس التالي" button when next lesson is unlocked',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          LessonPlayerReady(
            lesson: lesson1,
            course: testCourse,
            currentPosition: const Duration(seconds: 95),
            totalDuration: const Duration(seconds: 100),
            isPlaying: false,
            playbackSpeed: 1.0,
            isCompleted: true,
            isControlsVisible: true,
            isFullscreen: false,
            nextLesson: lesson2,
            isNextLessonUnlocked: true, // Unlocked!
          ),
        );
        when(() => mockCubit.playNextLesson()).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: LessonPlayerPage(
              courseId: 'c1',
              lessonId: 'l1',
              cubit: mockCubit,
            ),
          ),
        );
        await tester.pump();

        // Assert & Tap
        final nextButtonFinder = find.widgetWithText(
          ElevatedButton,
          'الدرس التالي',
        );
        final elevatedButton = tester.widget<ElevatedButton>(nextButtonFinder);
        expect(elevatedButton.onPressed, isNotNull);

        await tester.tap(nextButtonFinder);
        verify(() => mockCubit.playNextLesson()).called(1);
      },
    );

    testWidgets(
      'renders "إنهاء الدورة" button on terminal lesson and shows celebration modal',
      (tester) async {
        // Arrange: lesson2 has nextLesson == null (terminal) and isCompleted == true
        when(() => mockCubit.state).thenReturn(
          LessonPlayerReady(
            lesson: lesson2,
            course: testCourse,
            currentPosition: const Duration(seconds: 200),
            totalDuration: const Duration(seconds: 200),
            isPlaying: false,
            playbackSpeed: 1.0,
            isCompleted: true,
            isControlsVisible: true,
            isFullscreen: false,
            nextLesson: null, // Terminal lesson!
            isNextLessonUnlocked: false,
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: LessonPlayerPage(
              courseId: 'c1',
              lessonId: 'l2',
              cubit: mockCubit,
            ),
          ),
        );
        await tester.pump();

        // Assert
        final finishButtonFinder = find.widgetWithText(
          ElevatedButton,
          'إنهاء الدورة',
        );
        expect(finishButtonFinder, findsOneWidget);

        await tester.tap(finishButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Assert celebration dialog renders
        expect(find.byType(CourseCompletionCelebration), findsOneWidget);
        expect(find.text('تهانينا! لقد أتممت الدورة بنجاح 🎉'), findsOneWidget);
      },
    );

    testWidgets('renders InPlayerErrorCard when state is LessonPlayerError', (
      tester,
    ) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(
        const LessonPlayerError(
          userMessageArabic: 'عذراً، ملف الفيديو تالف أو غير متوفر حالياً',
        ),
      );
      when(() => mockCubit.initializeLesson()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        buildTestableWidget(
          child: LessonPlayerPage(
            courseId: 'c1',
            lessonId: 'l1',
            cubit: mockCubit,
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.byType(InPlayerErrorCard), findsOneWidget);
      expect(
        find.text('عذراً، ملف الفيديو تالف أو غير متوفر حالياً'),
        findsOneWidget,
      );
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text('العودة للدورة'), findsOneWidget);

      await tester.tap(find.text('إعادة المحاولة'));
      verify(() => mockCubit.initializeLesson()).called(1);
    });

    testWidgets(
      'CustomVideoControls renders without RenderFlex overflow in constrained viewports',
      (tester) async {
        // Arrange: Constrained 16:9 viewport with 360px width (202.5px height)
        await tester.binding.setSurfaceSize(const Size(360, 202.5));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: Material(
              child: SizedBox(
                width: 360,
                height: 202.5,
                child: CustomVideoControls(
                  isVisible: true,
                  isPlaying: true,
                  playbackSpeed: 1.0,
                  isFullscreen: false,
                  currentPosition: const Duration(seconds: 42),
                  totalDuration: const Duration(seconds: 100),
                  lessonTitle: 'العظام والمفاصل في التشريح البشري',
                  onPlayPause: () {},
                  onSeek: (_) {},
                  onSpeedTap: () {},
                  onFullscreenToggle: () {},
                  onBack: () {},
                  onUserInteraction: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert - zero RenderFlex overflows
        expect(tester.takeException(), isNull);
        expect(find.byType(CustomVideoControls), findsOneWidget);
        expect(find.byType(RtlSeekBar), findsOneWidget);
        expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
      },
    );
  });
}
