import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// App-wide ThemeData. Colors are centralized in [AppColors] and reusable
/// gradients live in `app_gradients.dart` — use those instead of hardcoding
/// new hex values in screens.
class AppTheme {
  AppTheme._();

  static const double _radius = 20;
  static const double _fieldRadius = 16;
  static const double _buttonRadius = 16;

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.purple,
      onPrimary: Colors.white,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      tertiary: AppColors.cyan,
      onTertiary: AppColors.textOnLight,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textOnLight,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightBorder,
    );

    return _base(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.lightBg,
      appBarBackground: AppColors.navy,
      appBarForeground: Colors.white,
      cardColor: AppColors.lightSurface,
      inputFillColor: AppColors.lightSurfaceAlt,
      hintColor: AppColors.textOnLightMuted,
      bodyColor: AppColors.textOnLight,
      navBarBackground: AppColors.navy,
      unselectedNavColor: AppColors.textOnDarkMuted,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.purple,
      onPrimary: Colors.white,
      secondary: AppColors.pink,
      onSecondary: Colors.white,
      tertiary: AppColors.cyan,
      onTertiary: AppColors.textOnDark,
      surface: AppColors.navySurface,
      onSurface: AppColors.textOnDark,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.navyBorder,
    );

    return _base(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.navyDeep,
      appBarBackground: AppColors.navyDeep,
      appBarForeground: Colors.white,
      cardColor: AppColors.navySurface,
      inputFillColor: AppColors.navySurfaceAlt,
      hintColor: AppColors.textOnDarkMuted,
      bodyColor: AppColors.textOnDark,
      navBarBackground: AppColors.navyDeep,
      unselectedNavColor: AppColors.textOnDarkMuted,
    );
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color cardColor,
    required Color inputFillColor,
    required Color hintColor,
    required Color bodyColor,
    required Color navBarBackground,
    required Color unselectedNavColor,
  }) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_buttonRadius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      splashColor: AppColors.purple.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      textTheme: ThemeData(brightness: colorScheme.brightness).textTheme.apply(
            bodyColor: bodyColor,
            displayColor: bodyColor,
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: appBarForeground,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: appBarForeground),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFillColor,
        selectedColor: AppColors.purple,
        labelStyle: TextStyle(color: bodyColor, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        side: BorderSide(color: colorScheme.outline),
        shape: StadiumBorder(side: BorderSide(color: colorScheme.outline)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.purple,
          side: const BorderSide(color: AppColors.purple, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brightBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        hintStyle: TextStyle(color: hintColor),
        labelStyle: TextStyle(color: hintColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBackground,
        indicatorColor: AppColors.purple.withValues(alpha: 0.28),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.cyan : unselectedNavColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.cyan : unselectedNavColor,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navBarBackground,
        indicatorColor: AppColors.purple.withValues(alpha: 0.28),
        selectedIconTheme: const IconThemeData(color: AppColors.cyan),
        unselectedIconTheme: IconThemeData(color: unselectedNavColor),
        selectedLabelTextStyle: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: TextStyle(color: unselectedNavColor),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.purple,
        linearTrackColor: AppColors.navyBorder,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.purple : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.purple.withValues(alpha: 0.5)
              : null,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navySurfaceAlt,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
