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
import 'package:thaheen_lms/features/course/presentation/widgets/course_search_bar.dart';
import 'package:thaheen_lms/features/course/presentation/widgets/empty_search_view.dart';
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

    testWidgets(
      'renders persistent CourseSearchBar and dispatches search on input',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          CourseListLoaded(
            courses: [testCourse],
            progressPercentages: const {'c1': 0},
          ),
        );
        when(() => mockCubit.search(any())).thenReturn(null);

        // Act
        await tester.pumpWidget(
          buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
        );
        await tester.pump();

        // Assert search bar is present
        expect(find.byType(CourseSearchBar), findsOneWidget);
        expect(find.text('ابحث عن دورة أو محاضر...'), findsOneWidget);

        // Act: enter text
        await tester.enterText(find.byType(TextField), 'تشريح');
        await tester.pump();

        // Assert: cubit.search called
        verify(() => mockCubit.search('تشريح')).called(1);
      },
    );

    testWidgets(
      'renders search results header and filters list when searchQuery is active',
      (tester) async {
        // Arrange
        final secondCourse = Course(
          id: 'c2',
          title: 'علم الأدوية',
          instructor: 'د. خالد',
          thumbnail: 'assets/images/placeholder.png',
          sections: const [],
        );

        final cwItem = ContinueWatchingItem(
          course: testCourse,
          lesson: testLesson,
          progress: LessonProgress(
            lessonId: 'l1',
            courseId: 'c1',
            lastPositionSec: 30,
            isCompleted: false,
            lastAccessedAt: DateTime.utc(2026, 9, 25),
          ),
        );

        when(() => mockCubit.state).thenReturn(
          CourseListLoaded(
            courses: [testCourse, secondCourse],
            progressPercentages: const {'c1': 50, 'c2': 0},
            continueWatching: cwItem,
            searchQuery: 'تشريح',
          ),
        );

        // Act
        await tester.pumpWidget(
          buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
        );
        await tester.pump();

        // Assert: ContinueWatchingCard is hidden during search
        expect(find.byType(ContinueWatchingCard), findsNothing);

        // Assert: Search header with count
        expect(find.text('نتائج البحث (1)'), findsOneWidget);

        // Assert: only matching course card is rendered
        expect(find.text('علم التشريح البشري'), findsOneWidget);
        expect(find.text('علم الأدوية'), findsNothing);
      },
    );

    testWidgets(
      'renders EmptySearchView and handles clear when search has zero matches',
      (tester) async {
        // Arrange
        when(() => mockCubit.state).thenReturn(
          CourseListLoaded(
            courses: [testCourse],
            progressPercentages: const {'c1': 0},
            searchQuery: 'كيمياء',
          ),
        );
        when(() => mockCubit.clearSearch()).thenReturn(null);

        // Act
        await tester.pumpWidget(
          buildTestableWidget(child: CourseListPage(cubit: mockCubit)),
        );
        await tester.pump();

        // Assert: EmptySearchView rendered with clear action
        expect(find.byType(EmptySearchView), findsOneWidget);
        expect(find.text('لا توجد نتائج تطابق بحثك'), findsOneWidget);
        expect(
          find.text(
            'لم نعثر على دورات تطابق "كيمياء". يرجى المحاولة بكلمات أخرى.',
          ),
          findsOneWidget,
        );
        expect(find.text('مسح البحث وتصفح الكل'), findsOneWidget);

        // Act: tap clear button in EmptySearchView via observable Arabic text
        await tester.tap(
          find.widgetWithText(OutlinedButton, 'مسح البحث وتصفح الكل'),
        );
        await tester.pump();

        // Assert: clearSearch was called
        verify(() => mockCubit.clearSearch()).called(1);
      },
    );
  });
}
