import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../player/domain/entities/course_progress.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/section.dart';
import 'lesson_list_tile.dart';

/// Card widget rendering a syllabus section, its lesson count, completion status,
/// and child [LessonListTile] widgets.
class SectionCard extends StatelessWidget {
  final Section section;
  final CourseProgress courseProgress;
  final List<Lesson> allOrderedLessons;
  final void Function(Lesson lesson) onLessonTap;

  const SectionCard({
    super.key,
    required this.section,
    required this.courseProgress,
    required this.allOrderedLessons,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = section.isCompleted(courseProgress.lessonProgressMap);
    final completedCount = section.calculateCompletedCount(
      courseProgress.lessonProgressMap,
    );
    final totalCount = section.lessons.length;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCount درس',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.statusCompletedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppTheme.statusCompleted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'مكتمل',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.statusCompleted,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (completedCount > 0)
                  Text(
                    '$completedCount / $totalCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Child lessons or empty section fallback
          if (section.lessons.isEmpty)
            const Padding(
              padding: EdgeInsetsDirectional.all(24),
              child: Center(
                child: Text(
                  'لا توجد دروس في هذا القسم حالياً',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.lessons.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 64),
              itemBuilder: (context, index) {
                final lesson = section.lessons[index];
                final isUnlocked = courseProgress.isLessonUnlocked(
                  lesson,
                  allOrderedLessons,
                );
                final status = courseProgress.getLessonStatus(lesson.id);

                return LessonListTile(
                  lesson: lesson,
                  status: status,
                  isUnlocked: isUnlocked,
                  onOpen: () => onLessonTap(lesson),
                );
              },
            ),
        ],
      ),
    );
  }
}
