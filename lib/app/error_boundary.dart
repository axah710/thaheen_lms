import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

/// Global Error Boundary replacing Flutter's default red screen of death
/// with a dignified, user-facing Arabic fallback card per Constitution Principle V.
class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? details;

  const CustomErrorWidget({super.key, this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.errorRed,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'حدث خطأ غير متوقع في العرض',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نعتذر عن هذا الخطأ غير المتوقع. يرجى إعادة المحاولة أو العودة للدورات.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (kDebugMode && details != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      details!.summary.toString(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Registers [CustomErrorWidget] as the global framework [ErrorWidget.builder].
void initGlobalErrorBoundary() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(details: details);
  };
}
