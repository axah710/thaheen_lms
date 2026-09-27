import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/errors/failures.dart';
import '../models/course_dto.dart';

/// Local data source responsible for reading and parsing bundled courses catalog.
class CourseLocalDataSource {
  static const String defaultAssetPath = 'assets/data/courses.json';

  final AssetBundle _bundle;
  final String assetPath;

  CourseLocalDataSource({
    AssetBundle? bundle,
    this.assetPath = defaultAssetPath,
  }) : _bundle = bundle ?? rootBundle;

  /// Loads and parses the course catalog from bundled JSON.
  ///
  /// Throws [AssetBundleFailure] if the asset cannot be read from the bundle.
  /// Throws [JsonParsingFailure] if JSON decoding or mapping fails.
  Future<List<CourseDto>> getCourses() async {
    String jsonString;
    try {
      jsonString = await _bundle.loadString(assetPath);
    } catch (e) {
      throw AssetBundleFailure(
        assetPath: assetPath,
        messageArabic: 'تعذر تحميل ملف بيانات الدورات من حزمة التطبيق',
        cause: e,
      );
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic> ||
          decoded['courses'] is! List<dynamic>) {
        throw const FormatException(
          'courses.json must contain a root "courses" array',
        );
      }

      final coursesList = decoded['courses'] as List<dynamic>;
      return coursesList
          .map(
            (courseJson) =>
                CourseDto.fromJson(courseJson as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw JsonParsingFailure(
        messageArabic:
            'تعذر قراءة بيانات الدورات، الملف يحتوي على بنية غير صالحة',
        cause: e,
      );
    }
  }
}
