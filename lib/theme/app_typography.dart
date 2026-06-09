import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography roles for the Kinetic Pastel design system.
///
/// Plus Jakarta Sans is used for headlines, labels and stat numbers.
/// Be Vietnam Pro is used for body copy.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLg = GoogleFonts.plusJakartaSans(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 56 / 48,
    letterSpacing: -0.96, // -0.02em on 48px
    color: AppColors.onBackground,
  );

  static TextStyle displayLgMobile = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 44 / 36,
    letterSpacing: -0.72,
    color: AppColors.onBackground,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColors.onSurface,
  );

  static TextStyle bodyLg = GoogleFonts.beVietnamPro(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodyMd = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelBold = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    color: AppColors.onSurface,
  );

  static TextStyle statNumber = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 40 / 32,
    letterSpacing: -0.32,
    color: AppColors.onSurface,
  );
}
