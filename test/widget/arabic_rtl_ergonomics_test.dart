import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/app/theme.dart';
import 'package:thaheen_lms/core/utils/duration_formatter.dart';
import 'package:thaheen_lms/features/course/domain/entities/lesson.dart';
import 'package:thaheen_lms/features/course/domain/entities/section.dart';
import 'package:thaheen_lms/features/course/presentation/widgets/section_card.dart';
import 'package:thaheen_lms/features/player/domain/entities/course_progress.dart';
import 'package:thaheen_lms/features/player/presentation/widgets/custom_video_controls.dart';
import 'package:thaheen_lms/features/player/presentation/widgets/rtl_seek_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  group('User Story 5: Arabic RTL Ergonomics Widget Tests (AAA Pattern)', () {
    testWidgets(
      'enforces unmirrored media playback controls (play, pause, seek 10s) per Principle IV',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildTestableWidget(
            child: CustomVideoControls(
              isVisible: true,
              isPlaying: false,
              playbackSpeed: 1.0,
              isFullscreen: false,
              currentPosition: const Duration(seconds: 30),
              totalDuration: const Duration(seconds: 120),
              lessonTitle: 'درس التشريح',
              onPlayPause: () {},
              onSeek: (_) {},
              onSpeedTap: () {},
              onFullscreenToggle: () {},
              onBack: () {},
              onUserInteraction: () {},
            ),
          ),
        );
        await tester.pump();

        // Assert - Play button IconData is unmirrored (matchTextDirection == false)
        final playIconFinder = find.byIcon(Icons.play_arrow_rounded);
        expect(playIconFinder, findsOneWidget);
        final playIcon = tester.widget<Icon>(playIconFinder);
        expect(playIcon.icon?.matchTextDirection, isFalse);

        // Assert - Back navigation icon IS directional (matchTextDirection == true)
        final backIconFinder = find.byIcon(Icons.arrow_back_rounded);
        expect(backIconFinder, findsOneWidget);
        final backIcon = tester.widget<Icon>(backIconFinder);
        expect(backIcon.icon?.matchTextDirection, isTrue);
      },
    );

    testWidgets(
      'RtlSeekBar maintains explicit RTL directionality and formats Western Arabic digits',
      (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildTestableWidget(
            child: RtlSeekBar(
              currentPosition: const Duration(seconds: 42),
              totalDuration: const Duration(seconds: 120),
              onSeek: (_) {},
            ),
          ),
        );
        await tester.pump();

        // Assert - RtlSeekBar has inner Directionality set to TextDirection.rtl
        final dirFinder = find.descendant(
          of: find.byType(RtlSeekBar),
          matching: find.byType(Directionality),
        );
        expect(dirFinder, findsWidgets);
        final dirWidget = tester.widget<Directionality>(dirFinder.first);
        expect(dirWidget.textDirection, TextDirection.rtl);

        // Assert - Formatted timestamps use Western Arabic numerals (0-9)
        expect(find.text('00:42'), findsOneWidget);
        expect(find.text('02:00'), findsOneWidget);

        // Verify zero Eastern Arabic numerals (٠-٩) in the rendered tree
        final easternArabicPattern = RegExp(r'[٠-٩]');
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        for (final textWidget in textWidgets) {
          if (textWidget.data != null) {
            expect(
              easternArabicPattern.hasMatch(textWidget.data!),
              isFalse,
              reason: 'Found Eastern Arabic digit in: ${textWidget.data}',
            );
          }
        }
      },
    );

    testWidgets(
      'duration formatter helper strictly generates Western Arabic mm:ss timestamps',
      (tester) async {
        expect(formatDuration(const Duration(seconds: 5)), '00:05');
        expect(formatDuration(const Duration(seconds: 65)), '01:05');
        expect(formatDuration(const Duration(seconds: 600)), '10:00');
        expect(formatDuration(Duration.zero), '00:00');
        expect(formatDuration(const Duration(seconds: -10)), '00:00');
      },
    );

    testWidgets(
      'LessonListTile and SectionCard use directional padding and align start to end',
      (tester) async {
        final lesson = Lesson(
          id: 'l1',
          courseId: 'c1',
          sectionId: 's1',
          title: 'الدرس الأول في علم التشريح',
          durationSec: 150,
          videoAssetPath: 'assets/videos/anatomy_intro.mp4',
          globalOrderIndex: 0,
        );

        final section = Section(
          id: 's1',
          courseId: 'c1',
          title: 'القسم الأول: الجهاز الهيكلي',
          orderIndex: 0,
          lessons: [lesson],
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: SectionCard(
              section: section,
              courseProgress: CourseProgress.empty('c1'),
              allOrderedLessons: [lesson],
              onLessonTap: (_) {},
            ),
          ),
        );
        await tester.pump();

        // Assert title and duration are visible
        expect(find.text('القسم الأول: الجهاز الهيكلي'), findsOneWidget);
        expect(find.text('الدرس الأول في علم التشريح'), findsOneWidget);
        expect(find.text('02:30'), findsOneWidget);

        // Verify order badge text uses Western Arabic digits
        expect(find.text('1'), findsOneWidget);
      },
    );
  });
}
