/// Domain Failure Hierarchy for Thaheen LMS.
///
/// All domain and data layer operations return functional `Either<Failure, T>`
/// to ensure hermetic error tolerance and prevent red screens.
sealed class Failure {
  final String messageArabic;
  final Object? cause;

  const Failure({required this.messageArabic, this.cause});

  @override
  String toString() =>
      '$runtimeType(messageArabic: $messageArabic, cause: $cause)';
}

/// Emitted when loading bundled assets (e.g. courses.json, video files, thumbnails) fails.
class AssetBundleFailure extends Failure {
  final String assetPath;

  const AssetBundleFailure({
    required this.assetPath,
    required super.messageArabic,
    super.cause,
  });
}

/// Emitted when JSON payload parsing fails or violates schema validation.
class JsonParsingFailure extends Failure {
  const JsonParsingFailure({required super.messageArabic, super.cause});
}

/// Emitted when local device storage operations fail.
class StorageFailure extends Failure {
  const StorageFailure({required super.messageArabic, super.cause});
}

/// Emitted when a requested course or lesson cannot be located.
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.messageArabic, super.cause});
}

/// Emitted when video controller initialization or playback fails due to corrupt or missing media.
class MediaPlaybackFailure extends Failure {
  final String videoPath;

  const MediaPlaybackFailure({
    required this.videoPath,
    required super.messageArabic,
    super.cause,
  });
}
