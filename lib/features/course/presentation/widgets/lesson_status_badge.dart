import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../player/domain/entities/lesson_status.dart';

/// Stylized badge indicating the current progress or locked state of a lesson.
class LessonStatusBadge extends StatelessWidget {
  final LessonStatus status;
  final bool isLocked;

  const LessonStatusBadge({
    super.key,
    required this.status,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return _buildBadge(
        label: 'مغلق',
        icon: Icons.lock_outline_rounded,
        textColor: AppTheme.statusLocked,
        backgroundColor: AppTheme.statusLockedBg,
      );
    }

    switch (status) {
      case LessonStatus.completed:
        return _buildBadge(
          label: 'مكتمل',
          icon: Icons.check_circle_rounded,
          textColor: AppTheme.statusCompleted,
          backgroundColor: AppTheme.statusCompletedBg,
        );
      case LessonStatus.inProgress:
        return _buildBadge(
          label: 'قيد التقدم',
          icon: Icons.play_circle_filled_rounded,
          textColor: AppTheme.statusInProgress,
          backgroundColor: AppTheme.statusInProgressBg,
        );
      case LessonStatus.notStarted:
        return _buildBadge(
          label: 'لم يبدأ',
          icon: Icons.circle_outlined,
          textColor: AppTheme.statusNotStarted,
          backgroundColor: AppTheme.statusNotStartedBg,
        );
    }
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
