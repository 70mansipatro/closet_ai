import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable gradients for ClosetAI. Use these instead of defining new
/// gradients inline so the palette stays consistent across screens.
class AppGradients {
  AppGradients._();

  /// Primary brand gradient: Cyan -> Blue -> Purple -> Pink.
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cyan, AppColors.brightBlue, AppColors.purple, AppColors.pink],
  );

  /// Premium gradient: Purple -> Pink.
  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.deepPurple, AppColors.pink],
  );

  /// Cyan -> Green (laundry / success contexts).
  static const LinearGradient cyanGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cyan, AppColors.green],
  );

  /// Blue -> Purple.
  static const LinearGradient blueViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brightBlue, AppColors.purple],
  );

  /// Purple -> Pink.
  static const LinearGradient violetPink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purple, AppColors.pink],
  );

  /// Orange -> Pink.
  static const LinearGradient orangePink = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.orange, AppColors.pink],
  );

  /// Subtle deep navy/purple background wash for hero screens
  /// (auth, AI recommendation, premium). Not meant for every screen.
  static const LinearGradient navyBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.navyDeep, AppColors.navy, AppColors.navySurface],
  );

  /// Success gradient: Cyan/Green.
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cyan, AppColors.green],
  );
}
