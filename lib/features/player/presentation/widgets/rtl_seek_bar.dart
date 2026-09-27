import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/duration_formatter.dart';

/// Interactive scrubbable seek bar with right-to-left elapsed fill,
/// Western Arabic numeral timestamps (0-9), and zero-duration safety guard.
class RtlSeekBar extends StatefulWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Widget? trailing;

  const RtlSeekBar({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    this.trailing,
  });

  @override
  State<RtlSeekBar> createState() => _RtlSeekBarState();
}

class _RtlSeekBarState extends State<RtlSeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.totalDuration.inMilliseconds.toDouble();
    final bool isDurationValid = totalMs > 0;

    final currentMs =
        _dragValue ??
        widget.currentPosition.inMilliseconds.toDouble().clamp(
          0.0,
          isDurationValid ? totalMs : 0.0,
        );

    final displayPosition = _dragValue != null
        ? Duration(milliseconds: _dragValue!.round())
        : widget.currentPosition;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider with RTL theme
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppTheme.accentCyan,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 5,
                elevation: 2,
              ),
              overlayColor: AppTheme.accentCyan.withValues(alpha: 0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: isDurationValid ? currentMs.clamp(0.0, totalMs) : 0.0,
              min: 0.0,
              max: isDurationValid ? totalMs : 1.0,
              onChangeStart: isDurationValid
                  ? (value) {
                      widget.onSeekStart?.call();
                      setState(() {
                        _dragValue = value;
                      });
                    }
                  : null,
              onChanged: isDurationValid
                  ? (value) {
                      setState(() {
                        _dragValue = value;
                      });
                    }
                  : null,
              onChangeEnd: isDurationValid
                  ? (value) {
                      final targetDuration = Duration(
                        milliseconds: value.round(),
                      );
                      widget.onSeek(targetDuration);
                      widget.onSeekEnd?.call();
                      setState(() {
                        _dragValue = null;
                      });
                    }
                  : null,
            ),
          ),

          // Timestamps row: Elapsed (right) and Total (left) in RTL with optional trailing widget
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 16,
              end: 12,
              bottom: 2,
            ),
            child: Row(
              children: [
                Text(
                  formatDuration(displayPosition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ' / ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                Text(
                  formatDuration(widget.totalDuration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
