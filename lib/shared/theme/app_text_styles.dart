import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens.
/// Poppins for body/labels/titles. Roboto for display/headlines.
/// Matches FlutterFlow ThemeTypography exactly.
abstract final class AppTextStyles {
  // --- Display (Roboto) ---
  static TextStyle get displayLarge => GoogleFonts.roboto(
      fontSize: 64, fontWeight: FontWeight.w400, color: AppColors.primaryText);
  static TextStyle get displayMedium => GoogleFonts.roboto(
      fontSize: 44, fontWeight: FontWeight.w400, color: AppColors.primaryText);
  static TextStyle get displaySmall => GoogleFonts.roboto(
      fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.primaryText);

  // --- Headline (Roboto) ---
  static TextStyle get headlineLarge => GoogleFonts.roboto(
      fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.primaryText);
  static TextStyle get headlineMedium => GoogleFonts.roboto(
      fontSize: 24, fontWeight: FontWeight.w400, color: AppColors.primaryText);
  static TextStyle get headlineSmall => GoogleFonts.roboto(
      fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.primaryText);

  // --- Title (Roboto large, Poppins medium/small) ---
  static TextStyle get titleLarge => GoogleFonts.roboto(
      fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.primaryText);
  static TextStyle get titleMedium => GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.info);
  static TextStyle get titleSmall => GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.info);

  // --- Label (Poppins) ---
  static TextStyle get labelLarge => GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.secondaryText);
  static TextStyle get labelMedium => GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.secondaryText);
  static TextStyle get labelSmall => GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.secondaryText);

  // --- Body (Poppins) ---
  static TextStyle get bodyLarge => GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.primaryText);
  static TextStyle get bodyMedium => GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.primaryText);
  static TextStyle get bodySmall => GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.primaryText);
}
