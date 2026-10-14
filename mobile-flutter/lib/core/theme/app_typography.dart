import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Display & Headings (Luxury Serif)
  static TextStyle displayLarge = GoogleFonts.cinzel(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPure,
    letterSpacing: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.cinzel(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPure,
    letterSpacing: 1.0,
  );

  static TextStyle headingLarge = GoogleFonts.cinzel(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPure,
    letterSpacing: 0.8,
  );

  static TextStyle headingMedium = GoogleFonts.cinzel(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.champagneGold,
    letterSpacing: 0.6,
  );

  // Body & Subtitles (Clean, ultra-legible Sans Serif)
  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPure,
    letterSpacing: 0.2,
  );

  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPure,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSubtle,
    height: 1.3,
  );

  static TextStyle labelLarge = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.champagneGold,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSubtle,
    letterSpacing: 0.3,
  );

  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.obsidianBlack,
    letterSpacing: 0.5,
  );
}
