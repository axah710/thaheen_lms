import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Fallback widget displayed when course search produces zero matching results.
///
/// Complies with Constitution Principle V (Zero Red Screens).
class EmptySearchView extends StatelessWidget {
  final String query;
  final VoidCallback? onClear;

  const EmptySearchView({super.key, required this.query, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد نتائج تطابق بحثك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            query.isNotEmpty
                ? 'لم نعثر على دورات تطابق "$query". يرجى المحاولة بكلمات أخرى.'
                : 'يرجى المحاولة بكلمات بحث أخرى.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const Key('empty_search_clear_button'),
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: const Text('مسح البحث وتصفح الكل'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                side: const BorderSide(color: AppTheme.primaryTeal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
