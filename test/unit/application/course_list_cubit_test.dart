import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/core/errors/failures.dart';
import 'package:thaheen_lms/features/course/application/course_list_cubit.dart';
import 'package:thaheen_lms/features/course/application/course_list_state.dart';
import 'package:thaheen_lms/features/course/domain/entities/continue_watching_item.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/course/domain/repositories/i_course_repository.dart';
import 'package:thaheen_lms/features/player/domain/entities/course_progress.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';
import 'package:thaheen_lms/features/player/domain/repositories/i_progress_repository.dart';

class MockCourseRepository extends Mock implements ICourseRepository {}

class MockProgressRepository extends Mock implements IProgressRepository {}

void main() {
  late MockCourseRepository mockCourseRepository;
  late MockProgressRepository mockProgressRepository;

  final testLesson1 = Lesson(
    id: 'l1',
    courseId: 'c1',
    sectionId: 's1',
    title: 'درس 1',
    durationSec: 100,
    videoAssetPath: 'v1.mp4',
    globalOrderIndex: 0,
  );

  final testCourse1 = Course(
    id: 'c1',
    title: 'تشريح 101',
    instructor: 'د. سارة',
    thumbnail: 'anatomy.png',
    sections: [
      Section(
        id: 's1',
        courseId: 'c1',
        title: 'القسم 1',
        orderIndex: 0,
        lessons: [testLesson1],
      ),
    ],
  );

  setUp(() {
    mockCourseRepository = MockCourseRepository();
    mockProgressRepository = MockProgressRepository();
    when(() => mockProgressRepository.wasStorageReset).thenReturn(false);
  });

  group('CourseListCubit Bloc Tests (AAA Pattern)', () {
    test('initial state is CourseListInitial', () {
      final cubit = CourseListCubit(
        courseRepository: mockCourseRepository,
        progressRepository: mockProgressRepository,
      );
      expect(cubit.state, equals(const CourseListInitial()));
      cubit.close();
    });

    blocTest<CourseListCubit, CourseListState>(
      'emits [CourseListLoading, CourseListLoaded] when loadCourses succeeds with progress & continue watching',
      build: () {
        when(() => mockCourseRepository.getCourses())
            .thenAnswer((_) async => Right([testCourse1]));

        when(() => mockProgressRepository.getCourseProgress('c1')).thenAnswer(
          (_) async => const Right(
            CourseProgress(courseId: 'c1', lessonProgressMap: {}),
          ),
        );

        final cwItem = ContinueWatchingItem(
          course: testCourse1,
          lesson: testLesson1,
          progress: LessonProgress(
            lessonId: 'l1',
            courseId: 'c1',
            lastPositionSec: 30,
            isCompleted: false,
            lastAccessedAt: DateTime.utc(2026, 9, 25),
          ),
        );

        when(
          () => mockProgressRepository.resolveContinueWatching([testCourse1]),
        ).thenAnswer((_) async => Right(cwItem));

        return CourseListCubit(
          courseRepository: mockCourseRepository,
          progressRepository: mockProgressRepository,
        );
      },
      act: (cubit) => cubit.loadCourses(),
      expect: () => [
        const CourseListLoading(),
        isA<CourseListLoaded>()
            .having((s) => s.courses.length, 'courses length', 1)
            .having(
              (s) => s.progressPercentages['c1'],
              'progress percentage',
              0,
            )
            .having(
              (s) => s.hasContinueWatching,
              'has continue watching',
              isTrue,
            ),
      ],
    );

    blocTest<CourseListCubit, CourseListState>(
      'emits [CourseListLoading, CourseListError] when repository returns Failure',
      build: () {
        when(() => mockCourseRepository.getCourses()).thenAnswer(
          (_) async => const Left(
            AssetBundleFailure(
              assetPath: 'assets/data/courses.json',
              messageArabic: 'خطأ في تحميل الحزمة',
            ),
          ),
        );

        return CourseListCubit(
          courseRepository: mockCourseRepository,
          progressRepository: mockProgressRepository,
        );
      },
      act: (cubit) => cubit.loadCourses(),
      expect: () => [
        const CourseListLoading(),
        isA<CourseListError>().having(
          (s) => s.userMessageArabic,
          'message',
          'خطأ في تحميل الحزمة',
        ),
      ],
    );
  });
}
