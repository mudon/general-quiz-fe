import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF9C27B0);
  static const primaryLight = Color(0xFFE1BEE7);
  static const primaryBg = Color(0xFFFCE4EC);

  static const secondary = Color(0xFFFF6D00);
  static const secondaryLight = Color(0xFFFFCC80);

  static const success = Color(0xFF00E676);
  static const successBg = Color(0xFFE8F5E9);

  static const error = Color(0xFFFF1744);
  static const errorBg = Color(0xFFFFEBEE);

  static const gold = Color(0xFFFFD600);
  static const sky = Color(0xFF40C4FF);
  static const pink = Color(0xFFFF4081);
  static const lime = Color(0xFFC6FF00);

  static const surface = Color(0xFFFFF9C4);

  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF616161);

  static const outline = Color(0xFF212121);

  static const List<Color> bubbleColors = [
    Color(0xFFFF6D00), Color(0xFFFF4081), Color(0xFF00E676),
    Color(0xFF40C4FF), Color(0xFFFFD600), Color(0xFF9C27B0),
    Color(0xFF00E5FF), Color(0xFFFF6E40), Color(0xFF76FF03),
  ];

  static const List<String> bubbleEmojis = [
    '🔬', '🌍', '🎬', '💻', '⚽',
    '🍕', '🧬', '🚀', '🧪', '🏛️',
    '🎵', '🛡️', '🎮', '☕', '🏆',
  ];

  static String emojiForIndex(int i) => bubbleEmojis[i % bubbleEmojis.length];

  static const List<Color> confettiColors = [
    Color(0xFFFF6D00), Color(0xFFFF4081), Color(0xFFFFD600),
    Color(0xFF00E676), Color(0xFF40C4FF), Color(0xFF9C27B0),
    Color(0xFFFF6E40), Color(0xFF00E5FF), Color(0xFFC6FF00),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          shape: StadiumBorder(),
          elevation: 6,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.outline,
          minimumSize: const Size(double.infinity, 54),
          shape: StadiumBorder(),
          side: const BorderSide(color: AppColors.outline, width: 3),
          backgroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.outline, width: 3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.4), width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 3),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: 0.8,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
