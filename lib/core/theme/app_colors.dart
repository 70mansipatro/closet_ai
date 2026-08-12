import 'package:flutter/material.dart';

/// Centralized color palette for ClosetAI's "Premium AI Fashion" theme.
/// Inspired by a cyan -> blue -> purple -> pink abstract gradient identity.
class AppColors {
  AppColors._();

  // Core spectrum
  static const Color cyan = Color(0xFF22E5FF);
  static const Color teal = Color(0xFF14B8A6);
  static const Color brightBlue = Color(0xFF3B82F6);
  static const Color blue = Color(0xFF2563EB);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color deepPurple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);
  static const Color green = Color(0xFF22C55E);
  static const Color gold = Color(0xFFFACC15);
  static const Color orange = Color(0xFFFB923C);

  // Deep navy / purple neutrals (dark base)
  static const Color navyDeep = Color(0xFF070A1F);
  static const Color navy = Color(0xFF0B0F2E);
  static const Color navySurface = Color(0xFF161A3D);
  static const Color navySurfaceAlt = Color(0xFF1E2350);
  static const Color navyBorder = Color(0xFF2C3163);

  // Light neutrals
  static const Color lightBg = Color(0xFFF6F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF0EFFB);
  static const Color lightBorder = Color(0xFFE3E1F5);

  // Text
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFB7BBDE);
  static const Color textOnLight = Color(0xFF15132B);
  static const Color textOnLightMuted = Color(0xFF5F5C7A);

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFACC15);
}
