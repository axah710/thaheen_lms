import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/app/theme.dart';
import 'package:thaheen_lms/features/course/application/course_list_cubit.dart';
import 'package:thaheen_lms/features/course/application/course_list_state.dart';
import 'package:thaheen_lms/features/course/domain/entities/continue_watching_item.dart';
import 'package:thaheen_lms/features/course/domain/entities/course.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/course/presentation/course_list_page.dart';
import 'package:thaheen_lms/features/course/presentation/widgets/continue_watching_card.dart';
import 'package:thaheen_lms/features/course/presentation/widgets/course_card.dart';
import 'package:thaheen_lms/features/player/domain/entities/lesson_progress.dart';

class MockCourseListCubit extends MockCubit<CourseListState>
    implements CourseListCubit {}

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
  late MockCourseListCubit mockCubit;

  final testLesson = Lesson(
    id: 'l1',
    courseId: 'c1',
    sectionId: 's1',
    title: 'مقدمة في التشريح',
    durationSec: 100,
    videoAssetPath: 'assets/videos/anatomy_intro.mp4',
    globalOrderIndex: 0,
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
        lessons: [testLesson],
      ),
    ],
  );

  setUp(() {
    mockCubit = MockCourseListCubit();
  });

  group('CourseListPage Widget Tests (AAA Pattern)', () {
    testWidgets('renders loading spinner when state is CourseListLoading', (
      tester,
    ) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(const CourseListLoading());

      // Act
      await tester.pumpWidget(
        buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'renders course cards and hides Continue Watching card when none in progress',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          CourseListLoaded(
            courses: [testCourse],
            progressPercentages: const {'c1': 45},
            continueWatching: null,
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
        );
        await tester.pump();

        // Assert
        expect(find.text('منصة طهين التعليمية'), findsOneWidget);
        expect(find.text('جميع الدورات المتاحة'), findsOneWidget);
        expect(find.text('علم التشريح البشري'), findsOneWidget);
        expect(find.text('د. سارة الأحمد'), findsOneWidget);
        expect(find.byType(CourseCard), findsOneWidget);
        expect(find.byType(ContinueWatchingCard), findsNothing);
      },
    );

    testWidgets(
      'renders Continue Watching card when an in-progress lesson exists',
      (tester) async {
        // Arrange
        final cwItem = ContinueWatchingItem(
          course: testCourse,
          lesson: testLesson,
          progress: LessonProgress(
            lessonId: 'l1',
            courseId: 'c1',
            lastPositionSec: 40,
            isCompleted: false,
            lastAccessedAt: DateTime.utc(2026, 9, 25),
          ),
        );

        when(() => mockCubit.state).thenReturn(
          CourseListLoaded(
            courses: [testCourse],
            progressPercentages: const {'c1': 40},
            continueWatching: cwItem,
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
        );
        await tester.pump();

        // Assert
        expect(find.byType(ContinueWatchingCard), findsOneWidget);
        expect(find.text('متابعة التعلم'), findsOneWidget);
        expect(find.text('استئناف الدرس'), findsOneWidget);
      },
    );

    testWidgets(
      'renders friendly Arabic empty state when courses list is empty (Zero Red Screens)',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          const CourseListLoaded(
            courses: [],
            progressPercentages: {},
            continueWatching: null,
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
        );
        await tester.pump();

        // Assert
        expect(find.text('لا توجد دورات متاحة حالياً'), findsOneWidget);
        expect(find.byType(CourseCard), findsNothing);
        expect(find.byType(ContinueWatchingCard), findsNothing);
      },
    );

    testWidgets('renders retryable error view when state is CourseListError', (
      tester,
    ) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(
        const CourseListError(
          userMessageArabic: 'تعذر الاتصال بملف البيانات المحلي',
        ),
      );

      // Act
      await tester.pumpWidget(
        buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
      );
      await tester.pump();

      // Assert
      expect(find.text('تعذر الاتصال بملف البيانات المحلي'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });
}
