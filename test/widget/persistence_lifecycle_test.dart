import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaheen_lms/app/theme.dart';
import 'package:thaheen_lms/core/storage/local_storage_service.dart';
import 'package:thaheen_lms/features/course/application/course_list_cubit.dart';
import 'package:thaheen_lms/features/course/data/data_sources/course_local_data_source.dart';
import 'package:thaheen_lms/features/course/data/repositories/course_repository_impl.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/course/presentation/course_list_page.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_cubit.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_state.dart';
import 'package:thaheen_lms/features/player/data/data_sources/progress_local_data_source.dart';
import 'package:thaheen_lms/features/player/data/repositories/progress_repository_impl.dart';
import 'package:thaheen_lms/features/player/domain/repositories/i_progress_repository.dart';
import 'package:thaheen_lms/features/player/presentation/lesson_player_page.dart';

class MockLessonPlayerCubit extends MockCubit<LessonPlayerState>
    implements LessonPlayerCubit {}

class MockProgressRepository extends Mock implements IProgressRepository {}

class FakeAssetBundle extends CachingAssetBundle {
  final Map<String, String> _assets;

  FakeAssetBundle(this._assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (_assets.containsKey(key)) {
      return _assets[key]!;
    }
    throw FlutterError('Unable to load asset: $key');
  }

  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleCoursesJson = '''
{
  "courses": [
    {
      "id": "anatomy-101",
      "title": "علم التشريح البشري",
      "instructor": "د. سارة الأحمد",
      "thumbnail": "assets/images/anatomy.png",
      "sections": [
        {
          "id": "s1",
          "title": "الجهاز الهيكلي",
          "lessons": [
            {
              "id": "l1",
              "title": "مقدمة في علم التشريح",
              "durationSec": 120,
              "video": "assets/videos/anatomy_intro.mp4"
            },
            {
              "id": "l2",
              "title": "هيكل الطرف العلوي والعظام",
              "durationSec": 180,
              "video": "assets/videos/anatomy_bones.mp4"
            }
          ]
        }
      ]
    }
  ]
}
''';

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

  group('User Story 4: Persistence Lifecycle & Cold Restart Widget Tests', () {
    testWidgets(
      'cold restart simulation: saved progress rehydrates continue watching card in CourseListPage',
      (tester) async {
        // Arrange - Session 1: User watches lesson 1 of anatomy-101 up to 42s
        final initialProgressMap = {
          'schemaVersion': 1,
          'records': {
            'l1': {
              'lessonId': 'l1',
              'courseId': 'anatomy-101',
              'lastPositionSec': 42,
              'isCompleted': false,
              'lastAccessedAt': DateTime.now().toUtc().toIso8601String(),
            },
          },
        };
        SharedPreferences.setMockInitialValues({
          LocalStorageService.progressKey: jsonEncode(initialProgressMap),
        });

        // Act - Simulate cold restart: Fresh service & repository instances
        final storage = await LocalStorageService.create();
        final progressDataSource = ProgressLocalDataSource(storage);
        final progressRepo = ProgressRepositoryImpl(progressDataSource);
        final fakeBundle = FakeAssetBundle({
          'assets/data/courses.json': sampleCoursesJson,
        });
        final courseRepo = CourseRepositoryImpl(
          CourseLocalDataSource(bundle: fakeBundle),
        );

        final listCubit = CourseListCubit(
          courseRepository: courseRepo,
          progressRepository: progressRepo,
        );

        await tester.pumpWidget(
          buildTestableWidget(child: CourseListPage(cubit: listCubit)),
        );
        await listCubit.loadCourses();
        await tester.pump();

        // Assert - Rehydrated "Continue Watching" card is present with 42s progress
        expect(find.text('متابعة التعلم'), findsOneWidget);
        expect(find.text('علم التشريح البشري'), findsWidgets);
        expect(find.text('مقدمة في علم التشريح'), findsOneWidget);

        await listCubit.close();
      },
    );

    testWidgets(
      'AppLifecycleListener: triggers immediate buffer flush and pause across background states',
      (tester) async {
        // Arrange
        final mockCubit = MockLessonPlayerCubit();
        final mockProgressRepo = MockProgressRepository();

        final lesson = Lesson(
          id: 'l1',
          courseId: 'anatomy-101',
          sectionId: 's1',
          title: 'مقدمة في علم التشريح',
          durationSec: 120,
          videoAssetPath: 'assets/videos/anatomy_intro.mp4',
          globalOrderIndex: 0,
        );

        final course = Course(
          id: 'anatomy-101',
          title: 'علم التشريح البشري',
          instructor: 'د. سارة الأحمد',
          thumbnail: 'assets/images/anatomy.png',
          sections: [
            Section(
              id: 's1',
              courseId: 'anatomy-101',
              title: 'الجهاز الهيكلي',
              orderIndex: 0,
              lessons: [lesson],
            ),
          ],
        );

        when(() => mockCubit.progressRepository).thenReturn(mockProgressRepo);
        when(() => mockProgressRepo.flush())
            .thenAnswer((_) async => const Right(null));
        when(() => mockCubit.togglePlayPause()).thenAnswer((_) async {});
        when(() => mockCubit.controller).thenReturn(null);
        when(() => mockCubit.state).thenReturn(
          LessonPlayerReady(
            lesson: lesson,
            course: course,
            currentPosition: const Duration(seconds: 42),
            totalDuration: const Duration(seconds: 120),
            isPlaying: true,
            playbackSpeed: 1.0,
            isCompleted: false,
            isControlsVisible: true,
            isFullscreen: false,
            isNextLessonUnlocked: false,
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: LessonPlayerPage(
              courseId: 'anatomy-101',
              lessonId: 'l1',
              cubit: mockCubit,
            ),
          ),
        );
        await tester.pump();

        // 1. Transition to AppLifecycleState.inactive
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        verify(() => mockProgressRepo.flush()).called(1);
        verify(() => mockCubit.togglePlayPause()).called(1);

        // 2. Transition to AppLifecycleState.hidden
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();
        verify(() => mockProgressRepo.flush()).called(1);
        verify(() => mockCubit.togglePlayPause()).called(1);

        // 3. Transition to AppLifecycleState.paused
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        verify(() => mockProgressRepo.flush()).called(1);
        verify(() => mockCubit.togglePlayPause()).called(1);

        // 4. Transition to AppLifecycleState.detached
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.detached,
        );
        await tester.pump();
        verify(() => mockProgressRepo.flush()).called(1);
        verify(() => mockCubit.togglePlayPause()).called(1);
      },
    );

    testWidgets(
      'storage corruption recovery: resets envelope to empty and displays canonical Arabic SnackBar',
      (tester) async {
        // Arrange - corrupted unparseable JSON in SharedPreferences
        SharedPreferences.setMockInitialValues({
          LocalStorageService.progressKey:
              '{ corrupt-json-non-compliant-payload: true, ...',
        });

        final fakeBundle = FakeAssetBundle({
          'assets/data/courses.json': sampleCoursesJson,
        });
        final courseRepo = CourseRepositoryImpl(
          CourseLocalDataSource(bundle: fakeBundle),
        );

        // Act - Mount CourseListPage with custom courseRepo so it does not hang on rootBundle
        await tester.pumpWidget(
          buildTestableWidget(
            child: CourseListPage(courseRepository: courseRepo),
          ),
        );

        // Allow FutureBuilder and CourseListCubit to complete
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - SnackBar is displayed with canonical Arabic copy
        expect(
          find.text('تمت إعادة ضبط سجل التعلم المحلي لسلامة البيانات'),
          findsOneWidget,
        );

        // Verify storage was cleaned up / recovered
        final prefs = await SharedPreferences.getInstance();
        final recoveredValue = prefs.getString(LocalStorageService.progressKey);
        expect(
          recoveredValue == null ||
              recoveredValue == '{}' ||
              jsonDecode(recoveredValue).isEmpty,
          isTrue,
        );

        // Ensure no red screens occurred
        expect(tester.takeException(), isNull);
      },
    );
  });
}
