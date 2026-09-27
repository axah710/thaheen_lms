import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/core/errors/failures.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/course/domain/repositories/i_course_repository.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_cubit.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_state.dart';
import 'package:thaheen_lms/features/player/domain/entities/course_progress.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';
import 'package:thaheen_lms/features/player/domain/repositories/i_progress_repository.dart';

import '../../helpers/fake_video_player_platform.dart';

class MockCourseRepository extends Mock implements ICourseRepository {}

class MockProgressRepository extends Mock implements IProgressRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCourseRepository mockCourseRepo;
  late MockProgressRepository mockProgressRepo;
  late FakeVideoPlayerPlatform fakePlatform;

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
    mockCourseRepo = MockCourseRepository();
    mockProgressRepo = MockProgressRepository();
    fakePlatform = FakeVideoPlayerPlatform.register(
      duration: const Duration(seconds: 100),
    );
    when(() => mockProgressRepo.flush())
        .thenAnswer((_) async => const Right(null));
  });

  group('LessonPlayerCubit Unit Tests (AAA Pattern)', () {
    test('initial state is LessonPlayerInitial', () {
      // Arrange & Act
      final cubit = LessonPlayerCubit(
        courseId: 'c1',
        lessonId: 'l1',
        courseRepository: mockCourseRepo,
        progressRepository: mockProgressRepo,
      );

      // Assert
      expect(cubit.state, const LessonPlayerInitial());
      cubit.close();
    });

    blocTest<LessonPlayerCubit, LessonPlayerState>(
      'emits [LessonPlayerLoading, LessonPlayerReady] on successful lesson initialization with autoplay',
      build: () {
        when(() => mockCourseRepo.getCourseById('c1'))
            .thenAnswer((_) async => Right(testCourse));
        when(() => mockProgressRepo.getCourseProgress('c1'))
            .thenAnswer((_) async => Right(CourseProgress.empty('c1')));
        when(() => mockProgressRepo.getLessonProgress('l1'))
            .thenAnswer((_) async => const Right(null));
        when(
          () => mockProgressRepo.recordPlaybackPosition(
            courseId: any(named: 'courseId'),
            lessonId: any(named: 'lessonId'),
            positionSec: any(named: 'positionSec'),
            durationSec: any(named: 'durationSec'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(LessonProgress.initial(lessonId: 'l1', courseId: 'c1')),
        );

        return LessonPlayerCubit(
          courseId: 'c1',
          lessonId: 'l1',
          courseRepository: mockCourseRepo,
          progressRepository: mockProgressRepo,
        );
      },
      act: (cubit) => cubit.initializeLesson(),
      expect: () => [
        isA<LessonPlayerLoading>(),
        isA<LessonPlayerReady>()
            .having((s) => s.lesson.id, 'lesson.id', 'l1')
            .having((s) => s.isPlaying, 'isPlaying', isTrue)
            .having((s) => s.nextLesson?.id, 'nextLesson.id', 'l2')
            .having(
              (s) => s.isNextLessonUnlocked,
              'isNextLessonUnlocked',
              isFalse,
            )
            .having((s) => s.playbackSpeed, 'playbackSpeed', 1.0),
      ],
    );

    blocTest<LessonPlayerCubit, LessonPlayerState>(
      'cycles playback speed 1.0 -> 1.25 -> 1.5 -> 2.0 -> 1.0',
      build: () {
        when(() => mockCourseRepo.getCourseById('c1'))
            .thenAnswer((_) async => Right(testCourse));
        when(() => mockProgressRepo.getCourseProgress('c1'))
            .thenAnswer((_) async => Right(CourseProgress.empty('c1')));
        when(() => mockProgressRepo.getLessonProgress('l1'))
            .thenAnswer((_) async => const Right(null));
        when(
          () => mockProgressRepo.recordPlaybackPosition(
            courseId: any(named: 'courseId'),
            lessonId: any(named: 'lessonId'),
            positionSec: any(named: 'positionSec'),
            durationSec: any(named: 'durationSec'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(LessonProgress.initial(lessonId: 'l1', courseId: 'c1')),
        );

        return LessonPlayerCubit(
          courseId: 'c1',
          lessonId: 'l1',
          courseRepository: mockCourseRepo,
          progressRepository: mockProgressRepo,
        );
      },
      act: (cubit) async {
        await cubit.initializeLesson();
        await cubit.cyclePlaybackSpeed(); // 1.25
        await cubit.cyclePlaybackSpeed(); // 1.5
        await cubit.cyclePlaybackSpeed(); // 2.0
        await cubit.cyclePlaybackSpeed(); // 1.0
      },
      verify: (cubit) {
        expect(fakePlatform.playbackSpeed, 1.0);
      },
    );

    blocTest<LessonPlayerCubit, LessonPlayerState>(
      'togglePlayPause toggles playback and flushes progress on pause',
      build: () {
        when(() => mockCourseRepo.getCourseById('c1'))
            .thenAnswer((_) async => Right(testCourse));
        when(() => mockProgressRepo.getCourseProgress('c1'))
            .thenAnswer((_) async => Right(CourseProgress.empty('c1')));
        when(() => mockProgressRepo.getLessonProgress('l1'))
            .thenAnswer((_) async => const Right(null));
        when(
          () => mockProgressRepo.recordPlaybackPosition(
            courseId: any(named: 'courseId'),
            lessonId: any(named: 'lessonId'),
            positionSec: any(named: 'positionSec'),
            durationSec: any(named: 'durationSec'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(LessonProgress.initial(lessonId: 'l1', courseId: 'c1')),
        );
        when(() => mockProgressRepo.flush())
            .thenAnswer((_) async => const Right(null));

        return LessonPlayerCubit(
          courseId: 'c1',
          lessonId: 'l1',
          courseRepository: mockCourseRepo,
          progressRepository: mockProgressRepo,
        );
      },
      act: (cubit) async {
        await cubit.initializeLesson();
        await cubit.togglePlayPause(); // pause
        await cubit.togglePlayPause(); // play
      },
      verify: (cubit) {
        verify(() => mockProgressRepo.flush()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<LessonPlayerCubit, LessonPlayerState>(
      'seekTo crossing 90% triggers auto-completion, marks lesson complete and unlocks next lesson',
      build: () {
        when(() => mockCourseRepo.getCourseById('c1'))
            .thenAnswer((_) async => Right(testCourse));
        when(() => mockProgressRepo.getCourseProgress('c1'))
            .thenAnswer((_) async => Right(CourseProgress.empty('c1')));
        when(() => mockProgressRepo.getLessonProgress('l1'))
            .thenAnswer((_) async => const Right(null));
        when(
          () => mockProgressRepo.recordPlaybackPosition(
            courseId: any(named: 'courseId'),
            lessonId: any(named: 'lessonId'),
            positionSec: any(named: 'positionSec'),
            durationSec: any(named: 'durationSec'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(LessonProgress.initial(lessonId: 'l1', courseId: 'c1')),
        );
        when(() => mockProgressRepo.flush())
            .thenAnswer((_) async => const Right(null));

        return LessonPlayerCubit(
          courseId: 'c1',
          lessonId: 'l1',
          courseRepository: mockCourseRepo,
          progressRepository: mockProgressRepo,
        );
      },
      act: (cubit) async {
        await cubit.initializeLesson();
        // Seek to 91 seconds out of 100 seconds (91% >= 90%)
        await cubit.seekTo(const Duration(seconds: 91));
      },
      verify: (cubit) {
        final state = cubit.state as LessonPlayerReady;
        expect(state.isCompleted, isTrue);
        expect(state.isNextLessonUnlocked, isTrue);
        verify(
          () => mockProgressRepo.recordPlaybackPosition(
            courseId: 'c1',
            lessonId: 'l1',
            positionSec: 91,
            durationSec: 100,
          ),
        ).called(greaterThanOrEqualTo(1));
        verify(() => mockProgressRepo.flush()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<LessonPlayerCubit, LessonPlayerState>(
      'emits LessonPlayerError when course or lesson cannot be loaded',
      build: () {
        when(() => mockCourseRepo.getCourseById('c1')).thenAnswer(
          (_) async => const Left(
            NotFoundFailure(messageArabic: 'لم يتم العثور على الدورة'),
          ),
        );

        return LessonPlayerCubit(
          courseId: 'c1',
          lessonId: 'l1',
          courseRepository: mockCourseRepo,
          progressRepository: mockProgressRepo,
        );
      },
      act: (cubit) => cubit.initializeLesson(),
      expect: () => [isA<LessonPlayerLoading>(), isA<LessonPlayerError>()],
    );

    blocTest<LessonPlayerCubit, LessonPlayerState>(
      'emits LessonPlayerError with Arabic copy on corrupt video initialization failure',
      build: () {
        fakePlatform.shouldFailInitialization = true;

        when(() => mockCourseRepo.getCourseById('c1'))
            .thenAnswer((_) async => Right(testCourse));
        when(() => mockProgressRepo.getCourseProgress('c1'))
            .thenAnswer((_) async => Right(CourseProgress.empty('c1')));
        when(() => mockProgressRepo.getLessonProgress('l1'))
            .thenAnswer((_) async => const Right(null));

        return LessonPlayerCubit(
          courseId: 'c1',
          lessonId: 'l1',
          courseRepository: mockCourseRepo,
          progressRepository: mockProgressRepo,
        );
      },
      act: (cubit) => cubit.initializeLesson(),
      expect: () => [
        isA<LessonPlayerLoading>(),
        isA<LessonPlayerError>().having(
          (s) => s.userMessageArabic,
          'userMessageArabic',
          'عذراً، ملف الفيديو تالف أو غير متوفر حالياً',
        ),
      ],
    );
  });
}
