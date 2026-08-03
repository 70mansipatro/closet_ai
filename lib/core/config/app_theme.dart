import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
      scaffoldBackgroundColor: const Color(0xFFF8F7FF),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
      ),
    );
  }
}
