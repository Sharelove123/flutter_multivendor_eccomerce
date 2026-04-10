import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF121A23);
  static const secondaryColor = Color(0xFFB88347);
  static const tertiaryColor = Color(0xFFF4EFE6);
  static const surfaceColor = Color(0xFFFFFCF7);
  static const backgroundColor = Color(0xFFF8F5EE);
  static const mutedTextColor = Color(0xFF64748B);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: secondaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          height: 0.95,
          color: primaryColor,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          height: 1,
          color: primaryColor,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: primaryColor,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: primaryColor,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          height: 1.7,
          color: primaryColor,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          height: 1.6,
          color: primaryColor,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          height: 1.5,
          color: mutedTextColor,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: primaryColor,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
      ),
      cardColor: surfaceColor,
      dividerColor: const Color(0x14000000),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x14000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: secondaryColor, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: Color(0x14000000)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
