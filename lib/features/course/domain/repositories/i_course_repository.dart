import 'package:either_dart/either.dart';

import '../../../../core/errors/failures.dart';
import '../entities/course.dart';
import '../entities/lesson.dart';

/// Navigation context for an opened lesson.
class LessonNavigationContext {
  final Course course;
  final Lesson lesson;
  final Lesson? nextLesson;

  const LessonNavigationContext({
    required this.course,
    required this.lesson,
    this.nextLesson,
  });
}

/// Abstract contract for loading offline courses and resolving lesson contexts.
///
/// Returns functional [Either<Failure, T>] per Constitution Principle II.
abstract interface class ICourseRepository {
  /// Loads all available courses bundled in the application assets.
  Future<Either<Failure, List<Course>>> getCourses();

  /// Retrieves a specific course by its unique [courseId].
  Future<Either<Failure, Course>> getCourseById(String courseId);

  /// Resolves a lesson and its immediate navigational context:
  /// parent [Course], target [Lesson], and optional [nextLesson].
  Future<Either<Failure, LessonNavigationContext>> getLessonContext({
    required String courseId,
    required String lessonId,
  });
}
