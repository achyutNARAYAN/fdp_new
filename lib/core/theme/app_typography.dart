import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography according to Section 22:
/// Uses Inter/SF Pro compatible styling with tabular numerals for prices and countdowns.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto'; // Standard sans-serif available across platforms

  static const TextStyle display = TextStyle(
    fontSize: 30,
    height: 36 / 30,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle itemName = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle price = TextStyle(
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  static const TextStyle countdown = TextStyle(
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );
}

