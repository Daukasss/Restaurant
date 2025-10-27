import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A365D);
  static const Color secondaryColor = Color(0xFFF5F0E6);
  static const Color backgroundColor = Colors.white;
  static const Color accentColor = Color.fromARGB(255, 26, 54, 93);
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: primaryColor,
        onSurface: primaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryColor.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        displayMedium:
            TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        displaySmall:
            TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        headlineMedium:
            TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        headlineSmall:
            TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        titleMedium:
            TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: primaryColor),
        bodyLarge: TextStyle(color: primaryColor),
        bodyMedium: TextStyle(color: primaryColor),
        bodySmall: TextStyle(color: Colors.grey),
      ),
    );
  }
}
