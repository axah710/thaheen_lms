import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/app/theme.dart';
import 'package:thaheen_lms/features/course/application/course_details_cubit.dart';
import 'package:thaheen_lms/features/course/application/course_details_state.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/course/presentation/course_details_page.dart';
import 'package:thaheen_lms/features/course/presentation/widgets/empty_course_view.dart';
import 'package:thaheen_lms/features/course/presentation/widgets/section_card.dart';
import 'package:thaheen_lms/features/player/domain/entities/course_progress.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';

class MockCourseDetailsCubit extends MockCubit<CourseDetailsState>
    implements CourseDetailsCubit {}

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
  late MockCourseDetailsCubit mockCubit;

  final lesson1 = Lesson(
    id: 'l1',
    courseId: 'c1',
    sectionId: 's1',
    title: 'مقدمة في علم التشريح',
    durationSec: 120,
    videoAssetPath: 'assets/videos/anatomy_intro.mp4',
    globalOrderIndex: 0,
  );

  final lesson2 = Lesson(
    id: 'l2',
    courseId: 'c1',
    sectionId: 's1',
    title: 'الجهاز الهيكلي والعظام',
    durationSec: 180,
    videoAssetPath: 'assets/videos/anatomy_bones.mp4',
    globalOrderIndex: 1,
  );

  final lesson3 = Lesson(
    id: 'l3',
    courseId: 'c1',
    sectionId: 's2',
    title: 'الجهاز العضلي المتقدم',
    durationSec: 240,
    videoAssetPath: 'assets/videos/anatomy_muscles.mp4',
    globalOrderIndex: 2,
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
        title: 'القسم الأول: الأساسيات',
        orderIndex: 0,
        lessons: [lesson1, lesson2],
      ),
      Section(
        id: 's2',
        courseId: 'c1',
        title: 'القسم الثاني: العضلات',
        orderIndex: 1,
        lessons: [lesson3],
      ),
    ],
  );

  setUp(() {
    mockCubit = MockCourseDetailsCubit();
  });

  group('CourseDetailsPage Widget Tests (AAA Pattern)', () {
    testWidgets(
      'renders loading indicator when state is CourseDetailsLoading',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(const CourseDetailsLoading());

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: CourseDetailsPage(courseId: 'c1', cubit: mockCubit),
          ),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'renders course header, progress, section hierarchy, and badges',
      (tester) async {
        // Arrange: l1 is completed, l2 is in-progress (unlocked), l3 is locked
        final progress = CourseProgress(
          courseId: 'c1',
          lessonProgressMap: {
            'l1': LessonProgress(
              lessonId: 'l1',
              courseId: 'c1',
              lastPositionSec: 120,
              isCompleted: true,
              lastAccessedAt: DateTime.utc(2026, 9, 25),
            ),
            'l2': LessonProgress(
              lessonId: 'l2',
              courseId: 'c1',
              lastPositionSec: 60,
              isCompleted: false,
              lastAccessedAt: DateTime.utc(2026, 9, 25),
            ),
          },
        );

        when(() => mockCubit.state).thenReturn(
          CourseDetailsLoaded(
            course: testCourse,
            courseProgress: progress,
            allOrderedLessons: [lesson1, lesson2, lesson3],
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: CourseDetailsPage(courseId: 'c1', cubit: mockCubit),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('علم التشريح البشري'), findsAtLeastNWidgets(1));
        expect(find.text('د. سارة الأحمد'), findsOneWidget);
        expect(find.text('القسم الأول: الأساسيات'), findsOneWidget);
        expect(find.text('القسم الثاني: العضلات'), findsOneWidget);

        // Status badges
        expect(find.text('مكتمل'), findsWidgets); // L1 is completed
        expect(find.text('قيد التقدم'), findsOneWidget); // L2 is in-progress
        expect(find.text('مغلق'), findsOneWidget); // L3 is locked

        // Section cards
        expect(find.byType(SectionCard), findsNWidgets(2));
      },
    );

    testWidgets(
      'intercepts tap on locked lesson and displays debounced Arabic SnackBar',
      (tester) async {
        // Arrange: l1 is not completed, so l2 and l3 are locked
        final progress = CourseProgress.empty('c1');

        when(() => mockCubit.state).thenReturn(
          CourseDetailsLoaded(
            course: testCourse,
            courseProgress: progress,
            allOrderedLessons: [lesson1, lesson2, lesson3],
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: CourseDetailsPage(courseId: 'c1', cubit: mockCubit),
          ),
        );
        await tester.pump();

        // Scroll to locked lesson and tap it
        await tester.ensureVisible(find.text('الجهاز الهيكلي والعظام'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('الجهاز الهيكلي والعظام'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Assert
        expect(
          find.text('يجب إكمال الدرس السابق أولاً لفتح هذا الدرس'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders empty section fallback message when a section has zero lessons',
      (tester) async {
        // Arrange: Course with a regular section and an empty section
        final normalSection = Section(
          id: 's1',
          courseId: 'c1',
          title: 'القسم الأول',
          orderIndex: 0,
          lessons: [lesson1],
        );

        final emptySection = Section(
          id: 's_empty',
          courseId: 'c1',
          title: 'قسم فارغ',
          orderIndex: 1,
          lessons: const [],
        );

        final courseWithEmptySection = Course(
          id: 'c1',
          title: 'دورة تجريبية',
          instructor: 'د. خالد',
          thumbnail: 'assets/images/anatomy.png',
          sections: [normalSection, emptySection],
        );

        when(() => mockCubit.state).thenReturn(
          CourseDetailsLoaded(
            course: courseWithEmptySection,
            courseProgress: CourseProgress.empty('c1'),
            allOrderedLessons: [lesson1],
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: CourseDetailsPage(courseId: 'c1', cubit: mockCubit),
          ),
        );
        await tester.pump();

        // Scroll to empty section
        await tester.ensureVisible(find.text('قسم فارغ'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('لا توجد دروس في هذا القسم حالياً'), findsOneWidget);
      },
    );

    testWidgets(
      'renders EmptyCourseView fallback when course has zero lessons',
      (tester) async {
        // Arrange: Empty course
        final emptyCourse = const Course(
          id: 'c_empty',
          title: 'دورة فارغة',
          instructor: 'د. خالد',
          thumbnail: 'assets/images/anatomy.png',
          sections: [],
        );

        when(() => mockCubit.state).thenReturn(
          CourseDetailsLoaded(
            course: emptyCourse,
            courseProgress: CourseProgress.empty('c_empty'),
            allOrderedLessons: const [],
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: CourseDetailsPage(courseId: 'c_empty', cubit: mockCubit),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.byType(EmptyCourseView), findsOneWidget);
        expect(
          find.text('لا توجد دروس متاحة حالياً في هذه الدورة'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders retryable error view when state is CourseDetailsError',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          const CourseDetailsError(
            userMessageArabic: 'لم يتم العثور على الدورة',
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(
            child: CourseDetailsPage(courseId: 'c1', cubit: mockCubit),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('لم يتم العثور على الدورة'), findsOneWidget);
        expect(find.text('إعادة المحاولة'), findsOneWidget);
      },
    );
  });
}
