import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_lms/core/errors/failures.dart';
import 'package:thaheen_lms/features/course/data/data_sources/course_local_data_source.dart';
import 'package:thaheen_lms/features/course/data/repositories/course_repository_impl.dart';

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

void main() {
  const validJson = '''
{
  "courses": [
    {
      "id": "c1",
      "title": "دورة 1",
      "instructor": "د. علي",
      "thumbnail": "assets/images/anatomy.png",
      "sections": [
        {
          "id": "s1",
          "title": "القسم 1",
          "lessons": [
            {
              "id": "l1",
              "title": "درس 1",
              "durationSec": 100,
              "video": "assets/videos/v1.mp4"
            },
            {
              "id": "l2",
              "title": "درس 2",
              "durationSec": 150,
              "video": "assets/videos/v2.mp4"
            }
          ]
        }
      ]
    }
  ]
}
''';

  group('CourseRepositoryImpl Unit Tests (AAA Pattern)', () {
    test('loads courses successfully and caches results in memory', () async {
      // Arrange
      final bundle = FakeAssetBundle({
        CourseLocalDataSource.defaultAssetPath: validJson,
      });
      final dataSource = CourseLocalDataSource(bundle: bundle);
      final repo = CourseRepositoryImpl(dataSource);

      // Act: First load
      final result1 = await repo.getCourses();

      // Assert: First load
      expect(result1.isRight, isTrue);
      final courses1 = result1.right;
      expect(courses1.length, equals(1));
      expect(courses1.first.id, equals('c1'));
      expect(courses1.first.sections.first.lessons.length, equals(2));

      // Act: Second load (should use in-memory cache)
      final result2 = await repo.getCourses();

      // Assert: Same cached instance returned
      expect(result2.isRight, isTrue);
      expect(identical(result1.right, result2.right), isTrue);
    });

    test('returns AssetBundleFailure when asset bundle throws', () async {
      // Arrange
      final bundle = FakeAssetBundle({}); // Missing asset
      final dataSource = CourseLocalDataSource(bundle: bundle);
      final repo = CourseRepositoryImpl(dataSource);

      // Act
      final result = await repo.getCourses();

      // Assert
      expect(result.isLeft, isTrue);
      expect(result.left, isA<AssetBundleFailure>());
      expect(result.left.messageArabic, contains('تعذر تحميل'));
    });

    test(
      'returns JsonParsingFailure when asset content is malformed',
      () async {
        // Arrange
        final bundle = FakeAssetBundle({
          CourseLocalDataSource.defaultAssetPath: '{"invalid": true}',
        });
        final dataSource = CourseLocalDataSource(bundle: bundle);
        final repo = CourseRepositoryImpl(dataSource);

        // Act
        final result = await repo.getCourses();

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left, isA<JsonParsingFailure>());
        expect(result.left.messageArabic, contains('غير صالحة'));
      },
    );

    test('getCourseById returns matching course or NotFoundFailure', () async {
      // Arrange
      final bundle = FakeAssetBundle({
        CourseLocalDataSource.defaultAssetPath: validJson,
      });
      final dataSource = CourseLocalDataSource(bundle: bundle);
      final repo = CourseRepositoryImpl(dataSource);

      // Act & Assert: Found
      final found = await repo.getCourseById('c1');
      expect(found.isRight, isTrue);
      expect(found.right.id, equals('c1'));

      // Act & Assert: Not found
      final notFound = await repo.getCourseById('c999');
      expect(notFound.isLeft, isTrue);
      expect(notFound.left, isA<NotFoundFailure>());
    });

    test('getLessonContext resolves lesson and nextLesson correctly', () async {
      // Arrange
      final bundle = FakeAssetBundle({
        CourseLocalDataSource.defaultAssetPath: validJson,
      });
      final dataSource = CourseLocalDataSource(bundle: bundle);
      final repo = CourseRepositoryImpl(dataSource);

      // Act & Assert: l1 has nextLesson l2
      final ctx1 = await repo.getLessonContext(courseId: 'c1', lessonId: 'l1');
      expect(ctx1.isRight, isTrue);
      expect(ctx1.right.lesson.id, equals('l1'));
      expect(ctx1.right.nextLesson?.id, equals('l2'));

      // Act & Assert: l2 is terminal (nextLesson is null)
      final ctx2 = await repo.getLessonContext(courseId: 'c1', lessonId: 'l2');
      expect(ctx2.isRight, isTrue);
      expect(ctx2.right.lesson.id, equals('l2'));
      expect(ctx2.right.nextLesson, isNull);
    });
  });
}
