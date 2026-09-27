import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Fallback widget displayed when a course has zero lessons or sections.
///
/// Complies with Constitution Principle V (Zero Red Screens).
class EmptyCourseView extends StatelessWidget {
  const EmptyCourseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 56, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text(
            'لا توجد دروس متاحة حالياً في هذه الدورة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'سيتم إضافة المحتوى التعليمي قريباً',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
