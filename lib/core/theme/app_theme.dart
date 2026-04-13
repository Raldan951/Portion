import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5C6B4A),
        brightness: Brightness.light,
        primary: const Color(0xFF5C6B4A),
        secondary: const Color(0xFF9C7A5B),
        surface: const Color(0xFFF8F4ED),
      ),
      scaffoldBackgroundColor: const Color(0xFFFBF8F2),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.0,
          color: Color(0xFF2C3A2A),
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3A2A),
        ),
        bodyLarge: TextStyle(fontSize: 17.5, height: 1.7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C6B4A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
