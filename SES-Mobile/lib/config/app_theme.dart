import 'package:flutter/material.dart';

class AppTheme {
  // ─── Shared Brand Palette ──────────────────────────────────────────────────
  static const Color primaryColor    = Color(0xFF2563EB); // Indigo 600
  static const Color primaryDeep     = Color(0xFF1E40AF); // Indigo 800
  static const Color emerald        = Color(0xFF10B981); // Success
  static const Color rose           = Color(0xFFEF4444); // Danger
  static const Color amber          = Color(0xFFF59E0B); // Warning

  // ─── Constants ─────────────────────────────────────────────────────────────
  static const double radiusExtraLarge = 24.0;
  static const double radiusLarge      = 16.0;
  static const double radiusMedium     = 12.0;

  // ─── Light Mode ────────────────────────────────────────────────────────────
  static const Color lBackground     = Color(0xFFF8FAFC);
  static const Color lSurface        = Color(0xFFFFFFFF);
  static const Color lText           = Color(0xFF0F172A);
  static const Color lTextSecondary  = Color(0xFF64748B);
  static const Color lBorder         = Color(0xFFE2E8F0);

  // ─── Dark Mode ─────────────────────────────────────────────────────────────
  static const Color dBackground     = Color(0xFF020617);
  static const Color dSurface        = Color(0xFF0F172A);
  static const Color dText           = Color(0xFFF8FAFC);
  static const Color dTextSecondary  = Color(0xFF94A3B8);
  static const Color dBorder         = Color(0xFF1E293B);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme  => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark       = brightness == Brightness.dark;
    final bg           = isDark ? dBackground : lBackground;
    final surface      = isDark ? dSurface    : lSurface;
    final text         = isDark ? dText       : lText;
    final textSec      = isDark ? dTextSecondary : lTextSecondary;
    final border       = isDark ? dBorder     : lBorder;

    return ThemeData(
      useMaterial3: true,
      brightness:   brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary:   primaryColor,
        secondary: emerald,
        surface:   surface,
        background: bg,
        onSurface: text,
      ),
      scaffoldBackgroundColor: bg,
      dividerColor: border,

      // ─── Typography ────────────────────────────────────────────────────────
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 30),
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge:    TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge:     TextStyle(color: text, fontSize: 16),
        bodyMedium:    TextStyle(color: textSec, fontSize: 14),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),

      // ─── Component Themes ──────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Color(0xFF1E293B) : lSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: rose),
        ),
        hintStyle: TextStyle(color: textSec),
        labelStyle: TextStyle(color: textSec, fontWeight: FontWeight.w500),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSec,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
