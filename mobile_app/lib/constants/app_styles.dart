import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // Headings
  static TextStyle titleLarge = GoogleFonts.cairo(
    fontSize: 22.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textMain,
    height: 1.25,
  );

  static TextStyle titleMedium = GoogleFonts.cairo(
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
    height: 1.25,
  );

  static TextStyle titleSmall = GoogleFonts.cairo(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
    height: 1.25,
  );

  // Body Texts
  static TextStyle bodyDefault = GoogleFonts.cairo(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textDefault,
    height: 1.5,
  );

  static TextStyle bodyMuted = GoogleFonts.cairo(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  static TextStyle labelBold = GoogleFonts.cairo(
    fontSize: 11.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
  );

  // Card Borders and Radius
  static BorderRadius cardRadius = BorderRadius.circular(22.r);
  static BorderRadius pageCardRadius = BorderRadius.circular(30.r);
  static BorderRadius buttonRadius = BorderRadius.circular(16.r);
  static BorderRadius inputRadius = BorderRadius.circular(12.r);

  // Box Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16.r,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> activeCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24.r,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16.r,
      offset: const Offset(0, 6),
    ),
  ];

  static TextStyle buttonText = GoogleFonts.cairo(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}

