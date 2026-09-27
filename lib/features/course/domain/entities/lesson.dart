/// Pure Dart domain entity representing an individual learning lesson.
///
/// Contains zero Flutter widget/UI dependencies per Constitution Principle II.
class Lesson {
  final String id;
  final String courseId;
  final String sectionId;
  final String title;
  final int durationSec;
  final String videoAssetPath;
  final int globalOrderIndex;

  const Lesson({
    required this.id,
    required this.courseId,
    required this.sectionId,
    required this.title,
    required this.durationSec,
    required this.videoAssetPath,
    required this.globalOrderIndex,
  });

  /// True if this lesson is the very first lesson of the course sequence.
  bool get isFirstLesson => globalOrderIndex == 0;

  /// The 90% threshold in seconds required for auto-completion.
  double get completionThresholdSec => durationSec * 0.90;

  /// Returns duration formatted as mm:ss (e.g. 95s -> "01:35").
  /// Guards safely against 0 or negative values by returning "00:00".
  String get formattedDuration {
    if (durationSec <= 0) return '00:00';
    final minutes = (durationSec ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSec % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseId == other.courseId &&
          sectionId == other.sectionId &&
          title == other.title &&
          durationSec == other.durationSec &&
          videoAssetPath == other.videoAssetPath &&
          globalOrderIndex == other.globalOrderIndex;

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    sectionId,
    title,
    durationSec,
    videoAssetPath,
    globalOrderIndex,
  );

  @override
  String toString() =>
      'Lesson(id: $id, title: $title, duration: $formattedDuration, order: $globalOrderIndex)';
}
