import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Persistent Arabic search bar for filtering courses by title and instructor.
///
/// Complies with Constitution Principle IV (Arabic-first & RTL Ergonomics).
class CourseSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const CourseSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'ابحث عن دورة أو محاضر...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        key: const Key('course_search_bar_field'),
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.normal,
          ),
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondary,
            size: 22,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, textEditingValue, child) {
              if (textEditingValue.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                key: const Key('course_search_bar_clear_button'),
                icon: const Icon(
                  Icons.clear_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                tooltip: 'مسح البحث',
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              );
            },
          ),
          filled: true,
          fillColor: AppTheme.surfaceCard,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderLight, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderLight, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryTeal,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
