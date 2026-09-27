import 'package:flutter/material.dart';

/// App-wide theme configuration, color tokens, and typography for Thaheen LMS.
///
/// Designed with Arabic-first RTL ergonomics and healthcare teal/cyan aesthetics.
class AppTheme {
  // Brand color palette (Medical Teal / Cyan)
  static const Color primaryTeal = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFFCCFBF1); // Teal 100
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color accentDark = Color(0xFF0891B2); // Cyan 600

  // Neutral palette
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9); // Slate 100

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status Badge Colors
  static const Color statusNotStarted = Color(0xFF64748B); // Slate 500
  static const Color statusNotStartedBg = Color(0xFFF1F5F9); // Slate 100

  static const Color statusInProgress = Color(0xFF0284C7); // Sky 600
  static const Color statusInProgressBg = Color(0xFFE0F2FE); // Sky 100

  static const Color statusCompleted = Color(0xFF10B981); // Emerald 500
  static const Color statusCompletedBg = Color(0xFFD1FAE5); // Emerald 100

  static const Color statusLocked = Color(0xFF94A3B8); // Slate 400
  static const Color statusLockedBg = Color(0xFFF8FAFC); // Slate 50

  // Error & Warning
  static const Color errorRed = Color(0xFFEF4444); // Red 500
  static const Color errorBg = Color(0xFFFEE2E2); // Red 100
  static const Color warningAmber = Color(0xFFF59E0B); // Amber 500

  /// Returns light ThemeData configured for Arabic RTL presentation.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryTeal,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      onPrimaryContainer: primaryDark,
      secondary: accentCyan,
      onSecondary: Colors.white,
      surface: surfaceWhite,
      onSurface: textPrimary,
      error: errorRed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
