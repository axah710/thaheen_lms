import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// In-player error card displayed when a video file fails to load or decode.
///
/// Complies with Constitution Principle V (Zero Red Screens Fault Tolerance).
class InPlayerErrorCard extends StatelessWidget {
  final String messageArabic;
  final VoidCallback onRetry;
  final VoidCallback onReturn;

  const InPlayerErrorCard({
    super.key,
    this.messageArabic = 'عذراً، ملف الفيديو تالف أو غير متوفر حالياً',
    required this.onRetry,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(
        0xFF0F172A,
      ), // Dark slate background matching video player
      padding: const EdgeInsetsDirectional.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppTheme.errorRed,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              messageArabic,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('العودة للدورة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
