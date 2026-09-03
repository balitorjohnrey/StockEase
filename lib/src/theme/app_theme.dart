import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0B63B6);
  static const sky = Color(0xFF6EC1F7);
  static const glow = Color(0xFFBDEBFF);
  static const secondary = Color(0xFF65C887);
  static const success = Color(0xFF2EAD63);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE5484D);
  static const navy = Color(0xFF172033);
  static const muted = Color(0xFF7A8495);
  static const surface = Color(0xFFF6FCFF);
  static const line = Color(0xFFE5F5FD);

  static const softShadow = [
    BoxShadow(
      color: Color(0x1F0EA5E9),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const strongShadow = [
    BoxShadow(
      color: Color(0x330B63B6),
      blurRadius: 38,
      offset: Offset(0, 18),
    ),
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      error: danger,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF1FAFF),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFFF1FAFF),
        foregroundColor: navy,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: glow, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        prefixIconColor: primary,
        suffixIconColor: primary,
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
        shadowColor: primary.withValues(alpha: 0.16),
        indicatorColor: primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: primary.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(132, 48),
          elevation: 8,
          shadowColor: primary.withValues(alpha: 0.34),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          minimumSize: const Size(120, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          side: const BorderSide(color: glow),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: navy,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: navy,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(color: navy, letterSpacing: 0),
        bodySmall: TextStyle(color: muted, letterSpacing: 0),
      ),
    );
  }
}
