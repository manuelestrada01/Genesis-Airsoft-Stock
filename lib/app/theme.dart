import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const primary = Color(0xFFF5C518);
  static const primaryDark = Color(0xFFE0B000);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textTertiary = Color(0xFF999999);
  static const success = Color(0xFF2ECC71);
  static const danger = Color(0xFFE53935);
  static const warning = Color(0xFFFFC107);
  static const border = Color(0xFFE0E0E0);
  static const dark = Color(0xFF1A1A2E);
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract class AppRadius {
  static const double xs = 6;   // badges, tags
  static const double sm = 8;   // image clips
  static const double md = 12;  // cards, inputs, botones
  static const double lg = 16;  // CardTheme
  static const double xl = 20;  // bottom sheets, category chips
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.nunitoSansTextTheme();
  final textTheme = baseTextTheme.copyWith(
    headlineLarge: GoogleFonts.rubik(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
    headlineMedium: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineSmall: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleLarge: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleMedium: GoogleFonts.rubik(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
  );

  return ThemeData(
    useMaterial3: true,
    textTheme: textTheme,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.dark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.dark,
      foregroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.dark,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
  );
}
