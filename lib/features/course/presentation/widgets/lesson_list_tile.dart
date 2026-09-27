import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../player/domain/entities/lesson_status.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_status_badge.dart';
import 'locked_lesson_snackbar.dart';

/// Interactive list tile representing a single lesson in the course syllabus.
class LessonListTile extends StatelessWidget {
  final Lesson lesson;
  final LessonStatus status;
  final bool isUnlocked;
  final VoidCallback onOpen;

  const LessonListTile({
    super.key,
    required this.lesson,
    required this.status,
    required this.isUnlocked,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !isUnlocked;
    final orderNumber = lesson.globalOrderIndex + 1;

    return InkWell(
      onTap: () {
        if (isLocked) {
          LockedLessonSnackBar.show(context);
        } else {
          onOpen();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Order number badge or lock icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isLocked
                    ? AppTheme.statusLockedBg
                    : AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLocked
                    ? const Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: AppTheme.statusLocked,
                      )
                    : Text(
                        '$orderNumber',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Lesson title and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? AppTheme.textMuted
                          : AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isLocked
                            ? AppTheme.textMuted
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.formattedDuration,
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocked
                              ? AppTheme.textMuted
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status badge
            LessonStatusBadge(status: status, isLocked: isLocked),
          ],
        ),
      ),
    );
  }
}
