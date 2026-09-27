/// Formats a [Duration] into `mm:ss` (or `hh:mm:ss`) using Western Arabic numerals (0-9).
String formatDuration(Duration duration) {
  if (duration.isNegative) return '00:00';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  final minutesStr = minutes.toString().padLeft(2, '0');
  final secondsStr = seconds.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:$minutesStr:$secondsStr';
  }
  return '$minutesStr:$secondsStr';
}
