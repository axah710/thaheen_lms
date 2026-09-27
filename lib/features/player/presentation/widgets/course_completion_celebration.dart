import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';

/// Celebratory dialog presented upon completing all lessons in a course.
class CourseCompletionCelebration extends StatelessWidget {
  final String courseTitle;
  final VoidCallback onDismiss;

  const CourseCompletionCelebration({
    super.key,
    required this.courseTitle,
    required this.onDismiss,
  });

  /// Displays the celebration modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String courseTitle,
    VoidCallback? onFinished,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CourseCompletionCelebration(
        courseTitle: courseTitle,
        onDismiss: () {
          sheetContext.pop();
          onFinished?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(28),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy / Celebration Icon
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppTheme.statusCompletedBg,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.emoji_events_rounded,
                size: 42,
                color: AppTheme.statusCompleted,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Congratulatory Title
          const Text(
            'تهانينا! لقد أتممت الدورة بنجاح 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Course title and 100% confirmation
          Text(
            'لقد أنهيت جميع دروس "$courseTitle" بنسبة إنجاز 100%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Return action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'العودة إلى تفاصيل الدورة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
