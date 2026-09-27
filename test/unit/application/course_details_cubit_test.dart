import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/core/errors/failures.dart';
import 'package:thaheen_lms/features/course/application/course_details_cubit.dart';
import 'package:thaheen_lms/features/course/application/course_details_state.dart';
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

  final testLesson2 = Lesson(
    id: 'l2',
    courseId: 'c1',
    sectionId: 's1',
    title: 'درس 2',
    durationSec: 120,
    videoAssetPath: 'v2.mp4',
    globalOrderIndex: 1,
  );

  final testCourse = Course(
    id: 'c1',
    title: 'دورة تجريبية',
    instructor: 'د. خالد',
    thumbnail: 'thumb.png',
    sections: [
      Section(
        id: 's1',
        courseId: 'c1',
        title: 'القسم 1',
        orderIndex: 0,
        lessons: [testLesson1, testLesson2],
      ),
    ],
  );

  setUp(() {
    mockCourseRepository = MockCourseRepository();
    mockProgressRepository = MockProgressRepository();
  });

  group('CourseDetailsCubit Bloc Tests (AAA Pattern)', () {
    test('initial state is CourseDetailsInitial', () {
      final cubit = CourseDetailsCubit(
        courseId: 'c1',
        courseRepository: mockCourseRepository,
        progressRepository: mockProgressRepository,
      );
      expect(cubit.state, equals(const CourseDetailsInitial()));
      cubit.close();
    });

    blocTest<CourseDetailsCubit, CourseDetailsState>(
      'emits [CourseDetailsLoading, CourseDetailsLoaded] on successful load',
      build: () {
        when(() => mockCourseRepository.getCourseById('c1'))
            .thenAnswer((_) async => Right(testCourse));

        final courseProgress = CourseProgress(
          courseId: 'c1',
          lessonProgressMap: {
            'l1': LessonProgress(
              lessonId: 'l1',
              courseId: 'c1',
              lastPositionSec: 100,
              isCompleted: true,
              lastAccessedAt: DateTime.utc(2026, 9, 25),
            ),
          },
        );

        when(() => mockProgressRepository.getCourseProgress('c1'))
            .thenAnswer((_) async => Right(courseProgress));

        return CourseDetailsCubit(
          courseId: 'c1',
          courseRepository: mockCourseRepository,
          progressRepository: mockProgressRepository,
        );
      },
      act: (cubit) => cubit.loadCourseDetails(),
      expect: () => [
        const CourseDetailsLoading(),
        isA<CourseDetailsLoaded>()
            .having((s) => s.course.id, 'course id', 'c1')
            .having((s) => s.allOrderedLessons.length, 'lessons count', 2)
            .having(
              (s) => s.isLessonUnlocked(testLesson1),
              'l1 unlocked',
              isTrue,
            )
            .having(
              (s) => s.isLessonUnlocked(testLesson2),
              'l2 unlocked',
              isTrue,
            )
            .having((s) => s.overallProgressPercentage, 'overall progress', 50),
      ],
    );

    blocTest<CourseDetailsCubit, CourseDetailsState>(
      'emits [CourseDetailsLoading, CourseDetailsError] on failure',
      build: () {
        when(() => mockCourseRepository.getCourseById('c1')).thenAnswer(
          (_) async => const Left(
            NotFoundFailure(messageArabic: 'لم يتم العثور على الدورة'),
          ),
        );

        return CourseDetailsCubit(
          courseId: 'c1',
          courseRepository: mockCourseRepository,
          progressRepository: mockProgressRepository,
        );
      },
      act: (cubit) => cubit.loadCourseDetails(),
      expect: () => [
        const CourseDetailsLoading(),
        isA<CourseDetailsError>().having(
          (s) => s.userMessageArabic,
          'message',
          'لم يتم العثور على الدورة',
        ),
      ],
    );
  });
}
