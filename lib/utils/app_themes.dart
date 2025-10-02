import 'package:flutter/material.dart';

class AppThemes {
  // Brand Colors (consistent with your current green palette)
  static const Color deepGreen = Color(0xFF0B5D3B);
  static const Color lightGreenFill = Color(0xFFE8F5E9);
  static const Color borderGreen = Color(0xFF66BB6A);
  static const Color backgroundLight = Color(0xFFF5F7FA);

  // Dark theme colors that complement the green brand
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);
  static const Color lightGreenFillDark = Color(0xFF1A3325);
  static const Color borderGreenDark = Color(0xFF4A7C59);

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: deepGreen,
        primaryContainer: lightGreenFill,
        secondary: borderGreen,
        secondaryContainer: Color(0xFFC8E6C9),
        surface: Colors.white,
        surfaceContainerHighest: Color(0xFFF1F1F1),
        error: Color(0xFFB00020),
        onPrimary: Colors.white,
        onPrimaryContainer: deepGreen,
        onSecondary: Colors.white,
        onSecondaryContainer: deepGreen,
        onSurface: Color(0xFF1C1B1F),
        onSurfaceVariant: Color(0xFF49454F),
        onError: Colors.white,
        outline: Color(0xFF79747E),
        outlineVariant: Color(0xFFCAC4D0),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFF313033),
        onInverseSurface: Color(0xFFF4EFF4),
        inversePrimary: Color(0xFF7FC685),
        surfaceTint: deepGreen,
      ),
      useMaterial3: true,
      brightness: Brightness.light,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 4,
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          elevation: 2,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: deepGreen,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepGreen,
          side: const BorderSide(color: deepGreen),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: borderGreen.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: borderGreen.withOpacity(0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: deepGreen, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFB00020), width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFB00020), width: 2),
        ),
        filled: true,
        fillColor: lightGreenFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(
          fontSize: 14,
          letterSpacing: 0.1,
          color: deepGreen,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          letterSpacing: 0.1,
          color: deepGreen.withOpacity(0.6),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Enhanced text styles for both languages
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, height: 1.3),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.25, height: 1.3),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.3),
        headlineLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.4),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.4),
        headlineSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.4),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0.25, height: 1.5),
        bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0.25, height: 1.5),
        bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, letterSpacing: 0.4, height: 1.5),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        labelMedium: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.4),
        labelSmall: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.4),
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7FC685), // Lighter green for dark mode
        primaryContainer: lightGreenFillDark,
        secondary: borderGreenDark,
        secondaryContainer: Color(0xFF2D4A32),
        surface: surfaceDark,
        surfaceContainerHighest: surfaceVariantDark,
        error: Color(0xFFCF6679),
        onPrimary: Color(0xFF003910),
        onPrimaryContainer: Color(0xFF7FC685),
        onSecondary: Color(0xFF003910),
        onSecondaryContainer: Color(0xFF7FC685),
        onSurface: Color(0xFFE6E1E5),
        onSurfaceVariant: Color(0xFFCAC4D0),
        onError: Color(0xFF690005),
        outline: Color(0xFF938F99),
        outlineVariant: Color(0xFF49454F),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFFE6E1E5),
        onInverseSurface: Color(0xFF313033),
        inversePrimary: deepGreen,
        surfaceTint: Color(0xFF7FC685),
      ),
      useMaterial3: true,
      brightness: Brightness.dark,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        backgroundColor: surfaceDark,
        foregroundColor: Color(0xFFE6E1E5),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFFE6E1E5),
        ),
        iconTheme: IconThemeData(color: Color(0xFFE6E1E5)),
        actionsIconTheme: IconThemeData(color: Color(0xFFE6E1E5)),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 4,
        color: surfaceDark,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7FC685),
          foregroundColor: const Color(0xFF003910),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          elevation: 2,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF7FC685),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF7FC685),
          side: const BorderSide(color: Color(0xFF7FC685)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: borderGreenDark.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: borderGreenDark.withOpacity(0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF7FC685), width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFFCF6679), width: 2),
        ),
        filled: true,
        fillColor: lightGreenFillDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(
          fontSize: 14,
          letterSpacing: 0.1,
          color: Color(0xFF7FC685),
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          letterSpacing: 0.1,
          color: const Color(0xFF7FC685).withOpacity(0.6),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7FC685),
        foregroundColor: Color(0xFF003910),
        elevation: 6,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),

      // Enhanced dark theme text styles
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, height: 1.3),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.25, height: 1.3),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.3),
        headlineLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.4),
        headlineMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.4),
        headlineSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.4),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0.25, height: 1.5),
        bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, letterSpacing: 0.25, height: 1.5),
        bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, letterSpacing: 0.4, height: 1.5),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
        labelMedium: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.4),
        labelSmall: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.4),
      ),
    );
  }
}