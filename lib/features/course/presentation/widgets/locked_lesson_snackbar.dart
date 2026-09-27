import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Helper for displaying the canonical debounced Arabic feedback SnackBar
/// when a student taps on a locked lesson (per FR-009).
class LockedLessonSnackBar {
  static const String canonicalMessage =
      'يجب إكمال الدرس السابق أولاً لفتح هذا الدرس';
  static const Duration displayDuration = Duration(milliseconds: 2500);

  static DateTime? _lastShownAt;
  static const Duration debounceInterval = Duration(milliseconds: 800);

  /// Shows the locked lesson feedback SnackBar.
  /// Debounces rapid repeated taps to prevent stacking.
  static void show(BuildContext context) {
    final now = DateTime.now();
    if (_lastShownAt != null &&
        now.difference(_lastShownAt!) < debounceInterval) {
      return;
    }
    _lastShownAt = now;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                canonicalMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        duration: displayDuration,
        backgroundColor: AppTheme.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsetsDirectional.all(16),
      ),
    );
  }
}
