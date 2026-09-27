import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thaheen_lms/core/storage/local_storage_service.dart';
import 'package:thaheen_lms/features/course/application/course_details_cubit.dart';
import 'package:thaheen_lms/features/course/application/course_details_state.dart';
import 'package:thaheen_lms/features/course/application/course_list_cubit.dart';
import 'package:thaheen_lms/features/course/application/course_list_state.dart';
import 'package:thaheen_lms/features/course/data/data_sources/course_local_data_source.dart';
import 'package:thaheen_lms/features/course/data/repositories/course_repository_impl.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_cubit.dart';
import 'package:thaheen_lms/features/player/application/lesson_player_state.dart';
import 'package:thaheen_lms/features/player/data/data_sources/progress_local_data_source.dart';
import 'package:thaheen_lms/features/player/data/models/progress_envelope_dto.dart';
import 'package:thaheen_lms/features/player/data/repositories/progress_repository_impl.dart';

import '../../helpers/fake_video_player_platform.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

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
  Future<ByteData> load(String key) async {
    throw UnimplementedError();
  }
}

/// Custom [HttpOverrides] that counts network attempts and blocks any remote connection.
class HermeticOfflineHttpOverrides extends HttpOverrides {
  int requestAttempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    requestAttempts++;
    throw AssertionError(
      'HERMETIC VIOLATION: Remote network request detected in 100% offline app! '
      'HttpClient was instantiated.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HermeticOfflineHttpOverrides httpOverrides;
  late MockLocalStorageService mockStorage;

  const sampleJson = '''
  {
    "courses": [
      {
        "id": "c1",
        "title": "مقدمة في التشريح",
        "instructor": "د. سارة",
        "thumbnail": "assets/images/anatomy.png",
        "sections": [
          {
            "id": "s1",
            "title": "الجهاز الهيكلي",
            "lessons": [
              {
                "id": "l1",
                "title": "العظام والمفاصل",
                "durationSec": 100,
                "video": "assets/videos/anatomy_intro.mp4"
              },
              {
                "id": "l2",
                "title": "تركيب الغضاريف",
                "durationSec": 120,
                "video": "assets/videos/anatomy_bones.mp4"
              }
            ]
          }
        ]
      }
    ]
  }
  ''';

  setUpAll(() {
    registerFallbackValue(ProgressEnvelopeDto.empty());
  });

  setUp(() {
    httpOverrides = HermeticOfflineHttpOverrides();
    HttpOverrides.global = httpOverrides;

    mockStorage = MockLocalStorageService();
    FakeVideoPlayerPlatform.register(duration: const Duration(seconds: 100));

    when(
      () => mockStorage.getProgressEnvelopeJson(
        onCorruptDataRecovered: any(named: 'onCorruptDataRecovered'),
      ),
    ).thenReturn(<String, dynamic>{});
    when(() => mockStorage.saveProgressEnvelopeJson(any()))
        .thenAnswer((_) async => true);
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('Hermetic Offline Operation (Constitution Principle I & T073)', () {
    test('HttpOverrides fails closed and intercepts unexpected remote HTTP client calls', () {
      // Arrange
      expect(httpOverrides.requestAttempts, equals(0));

      // Act & Assert: Any attempt to instantiate an HttpClient fails closed immediately
      expect(
        () => HttpClient().getUrl(Uri.parse('https://api.example.com/courses')),
        throwsA(isA<AssertionError>()),
      );
      expect(httpOverrides.requestAttempts, equals(1));
    });

    test('Data layer operations (parsing, caching, persisting) initiate 0 network requests', () async {
      // Arrange
      final bundle = FakeAssetBundle({
        CourseLocalDataSource.defaultAssetPath: sampleJson,
      });
      final courseDataSource = CourseLocalDataSource(bundle: bundle);
      final courseRepo = CourseRepositoryImpl(courseDataSource);

      final progressDataSource = ProgressLocalDataSource(mockStorage);
      final progressRepo = ProgressRepositoryImpl(progressDataSource);

      // Act
      final coursesResult = await courseRepo.getCourses();
      final courseDetailsResult = await courseRepo.getCourseById('c1');
      final initialProgress = await progressRepo.getCourseProgress('c1');

      await progressRepo.recordPlaybackPosition(
        courseId: 'c1',
        lessonId: 'l1',
        positionSec: 95,
        durationSec: 100,
      );
      await progressRepo.flush();

      // Assert
      expect(coursesResult.isRight, isTrue);
      expect(courseDetailsResult.isRight, isTrue);
      expect(initialProgress.isRight, isTrue);
      expect(
        httpOverrides.requestAttempts,
        equals(0),
        reason: 'Data sources and repositories must never create an HttpClient',
      );

      progressRepo.dispose();
    });

    test('Application Cubits (CourseList, CourseDetails, LessonPlayer) initiate 0 network requests', () async {
      // Arrange
      final bundle = FakeAssetBundle({
        CourseLocalDataSource.defaultAssetPath: sampleJson,
      });
      final courseDataSource = CourseLocalDataSource(bundle: bundle);
      final courseRepo = CourseRepositoryImpl(courseDataSource);
      final progressDataSource = ProgressLocalDataSource(mockStorage);
      final progressRepo = ProgressRepositoryImpl(progressDataSource);

      final courseListCubit = CourseListCubit(
        courseRepository: courseRepo,
        progressRepository: progressRepo,
      );

      final courseDetailsCubit = CourseDetailsCubit(
        courseId: 'c1',
        courseRepository: courseRepo,
        progressRepository: progressRepo,
      );

      final lessonPlayerCubit = LessonPlayerCubit(
        courseId: 'c1',
        lessonId: 'l1',
        courseRepository: courseRepo,
        progressRepository: progressRepo,
      );

      // Act
      await courseListCubit.loadCourses();
      await courseDetailsCubit.loadCourseDetails();
      await lessonPlayerCubit.initializeLesson();
      await lessonPlayerCubit.seekTo(const Duration(seconds: 50));
      await lessonPlayerCubit.cyclePlaybackSpeed();
      await lessonPlayerCubit.togglePlayPause();

      // Assert
      expect(courseListCubit.state, isA<CourseListLoaded>());
      expect(courseDetailsCubit.state, isA<CourseDetailsLoaded>());
      expect(lessonPlayerCubit.state, isA<LessonPlayerReady>());
      expect(
        httpOverrides.requestAttempts,
        equals(0),
        reason: 'All Cubits and offline playback must run with zero network activity',
      );

      // Cleanup
      await courseListCubit.close();
      await courseDetailsCubit.close();
      await lessonPlayerCubit.close();
      progressRepo.dispose();
    });

    test('Corrupted storage recovery initiates 0 network requests', () async {
      // Arrange
      when(
        () => mockStorage.getProgressEnvelopeJson(
          onCorruptDataRecovered: any(named: 'onCorruptDataRecovered'),
        ),
      ).thenAnswer((invocation) {
        final callback =
            invocation.namedArguments[const Symbol('onCorruptDataRecovered')]
                as void Function()?;
        callback?.call();
        return <String, dynamic>{};
      });

      final progressDataSource = ProgressLocalDataSource(mockStorage);
      final progressRepo = ProgressRepositoryImpl(progressDataSource);

      // Act
      final progress = await progressRepo.getCourseProgress('c1');

      // Assert
      expect(progress.isRight, isTrue);
      expect(progress.right.lessonProgressMap, isEmpty);
      expect(
        httpOverrides.requestAttempts,
        equals(0),
        reason: 'Corrupted storage recovery must happen completely offline',
      );

      progressRepo.dispose();
    });
  });
}
