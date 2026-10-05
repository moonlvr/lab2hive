import 'package:flutter/material.dart';

/// Single place for colors and text styles so every screen looks consistent.
class AppTheme {
  static const Color seed = Color(0xFF2E7D32); // green
  static const Color background = Color(0xFFF1F8F2); // soft green tint

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      primary: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : null,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}