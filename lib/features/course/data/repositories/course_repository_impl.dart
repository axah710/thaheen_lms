import 'package:either_dart/either.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../data_sources/course_local_data_source.dart';

/// Implementation of ICourseRepository providing in-memory caching
/// and typed Failure mapping.
class CourseRepositoryImpl implements ICourseRepository {
  final CourseLocalDataSource _dataSource;
  List<Course>? _cachedCourses;

  CourseRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Course>>> getCourses() async {
    if (_cachedCourses != null) {
      return Right(_cachedCourses!);
    }

    try {
      final dtos = await _dataSource.getCourses();
      final courses = dtos.map((dto) => dto.toDomain()).toList();
      _cachedCourses = List.unmodifiable(courses);
      return Right(_cachedCourses!);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(
        JsonParsingFailure(
          messageArabic: 'حدث خطأ غير متوقع أثناء معالجة بيانات الدورات',
          cause: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Course>> getCourseById(String courseId) async {
    final coursesResult = await getCourses();
    return coursesResult.fold((failure) => Left(failure), (courses) {
      for (final course in courses) {
        if (course.id == courseId) {
          return Right(course);
        }
      }
      return Left(
        NotFoundFailure(
          messageArabic: 'لم يتم العثور على الدورة المطلوبة ($courseId)',
        ),
      );
    });
  }

  @override
  Future<Either<Failure, LessonNavigationContext>> getLessonContext({
    required String courseId,
    required String lessonId,
  }) async {
    final courseResult = await getCourseById(courseId);
    return courseResult.fold((failure) => Left(failure), (course) {
      final allLessons = course.allLessonsOrdered;
      final lessonIndex = allLessons.indexWhere((l) => l.id == lessonId);

      if (lessonIndex == -1) {
        return Left(
          NotFoundFailure(
            messageArabic: 'لم يتم العثور على الدرس المطلوب ($lessonId)',
          ),
        );
      }

      final targetLesson = allLessons[lessonIndex];
      final nextLesson = (lessonIndex + 1 < allLessons.length)
          ? allLessons[lessonIndex + 1]
          : null;

      return Right(
        LessonNavigationContext(
          course: course,
          lesson: targetLesson,
          nextLesson: nextLesson,
        ),
      );
    });
  }
}
