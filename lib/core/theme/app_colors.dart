import 'package:flutter/material.dart';

/// Centralized color palette for the Nutrifit app.
/// Uses a fitness-oriented green/teal palette with premium accents.
sealed class AppColors {
  // ──────────────────── Brand / Primary ────────────────────
  static const Color primary = Color(0xFF2EC4B6);
  static const Color primaryDark = Color(0xFF1A9E93);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFFFFD166);

  // ──────────────────── Light theme ────────────────────
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1A1A2E);
  static const Color lightOnSurface = Color(0xFF2D2D3A);
  static const Color lightOutline = Color(0xFFE0E0E0);

  // ──────────────────── Dark theme ────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2C);
  static const Color darkOnBackground = Color(0xFFF1F1F1);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOutline = Color(0xFF3A3A4A);

  // ──────────────────── Semantic ────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);
}
