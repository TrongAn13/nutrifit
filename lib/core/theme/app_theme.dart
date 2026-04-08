import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material 3 theme configuration for Nutrifit.
/// Provides both [lightTheme] and [darkTheme].
class AppTheme {
  const AppTheme._();

  // ───────────────────────── Light Theme ─────────────────────────

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    textTheme: _buildTextTheme(Brightness.light),
    appBarTheme: _buildAppBarTheme(Brightness.light),
    cardTheme: _buildCardTheme(Brightness.light),
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
    dividerTheme: const DividerThemeData(color: AppColors.lightOutline),
  );

  // ───────────────────────── Dark Theme ─────────────────────────

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    canvasColor: AppColors.darkBackground,
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: _buildAppBarTheme(Brightness.dark),
    cardTheme: _buildCardTheme(Brightness.dark),
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(Brightness.dark),
    dividerTheme: const DividerThemeData(color: AppColors.darkOutline),
  );

  // ───────────────────────── Text Theme ─────────────────────────

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color color = brightness == Brightness.light
        ? AppColors.lightOnBackground
        : AppColors.darkOnBackground;

    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: color),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color),
        bodyLarge: TextStyle(fontSize: 16, color: color),
        bodyMedium: TextStyle(fontSize: 14, color: color),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ───────────────────────── AppBar ─────────────────────────

  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.darkBackground,
      foregroundColor: isLight ? AppColors.lightOnBackground : AppColors.darkOnBackground,
      surfaceTintColor: Colors.transparent,
    );
  }

  // ───────────────────────── Card ─────────────────────────

  static CardThemeData _buildCardTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    return CardThemeData(
      elevation: isLight ? 1 : 2,
      color: isLight ? AppColors.lightSurface : AppColors.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // ───────────────────────── Elevated Button ─────────────────────────

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ───────────────────────── Input Decoration ─────────────────────────

  static InputDecorationTheme _buildInputDecorationTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    final Color borderColor = isLight ? AppColors.lightOutline : AppColors.darkOutline;
    final Color fillColor = isLight ? AppColors.lightSurface : AppColors.darkSurface;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
