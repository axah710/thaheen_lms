import 'package:flutter/material.dart';

import 'rtl_seek_bar.dart';

/// Overlay widget providing play/pause toggle, scrubbable RTL seek bar,
/// speed pill selector, and fullscreen toggle.
///
/// Complies with Constitution Principle IV (unmirrored media playback icons).
class CustomVideoControls extends StatelessWidget {
  final bool isVisible;
  final bool isPlaying;
  final double playbackSpeed;
  final bool isFullscreen;
  final Duration currentPosition;
  final Duration totalDuration;
  final String lessonTitle;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSpeedTap;
  final VoidCallback onFullscreenToggle;
  final VoidCallback onBack;
  final VoidCallback onUserInteraction;

  const CustomVideoControls({
    super.key,
    required this.isVisible,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.isFullscreen,
    required this.currentPosition,
    required this.totalDuration,
    required this.lessonTitle,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeedTap,
    required this.onFullscreenToggle,
    required this.onBack,
    required this.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final speedLabel = playbackSpeed == 1.0
        ? '1.0x'
        : playbackSpeed == 1.25
        ? '1.25x'
        : playbackSpeed == 1.5
        ? '1.5x'
        : '2.0x';

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            top: isFullscreen,
            bottom: isFullscreen,
            left: isFullscreen,
            right: isFullscreen,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top control bar
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 8,
                    end: 12,
                    top: 4,
                    bottom: 4,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        tooltip: 'رجوع',
                        onPressed: onBack,
                      ),
                      const SizedBox(width: 8),

                      // Lesson Title
                      Expanded(
                        child: Text(
                          lessonTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Speed pill selector
                      InkWell(
                        onTap: () {
                          onUserInteraction();
                          onSpeedTap();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            speedLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Play/Pause button (flexes to available space)
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: InkWell(
                        onTap: () {
                          onUserInteraction();
                          onPlayPause();
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              // Unmirrored universal media playback icon per Principle IV
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom control bar with Seek bar & inline Fullscreen
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: 4,
                    start: 4,
                    end: 4,
                  ),
                  child: RtlSeekBar(
                    currentPosition: currentPosition,
                    totalDuration: totalDuration,
                    onSeek: (position) {
                      onUserInteraction();
                      onSeek(position);
                    },
                    onSeekStart: onUserInteraction,
                    onSeekEnd: onUserInteraction,
                    trailing: IconButton(
                      icon: Icon(
                        isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: isFullscreen ? 'تصغير الشاشة' : 'ملء الشاشة',
                      onPressed: () {
                        onUserInteraction();
                        onFullscreenToggle();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
