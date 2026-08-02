import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgStart, // Clean white background for area behind bottom nav bar
      primaryColor: AppColors.primaryAccent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryAccent,
        background: AppColors.bgMiddle,
        surface: AppColors.cardBg,
        error: AppColors.dangerStart,
      ),
      fontFamily: GoogleFonts.cairo().fontFamily,
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.cairo(
          color: AppColors.textMain,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: GoogleFonts.cairo(
          color: AppColors.textMain,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.cairo(
          color: AppColors.textDefault,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.cairo(
          color: AppColors.textDefault,
          fontWeight: FontWeight.w400,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dangerStart),
        ),
        hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
        labelStyle: GoogleFonts.cairo(color: AppColors.textDefault, fontWeight: FontWeight.w600),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.primaryAccent,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}

