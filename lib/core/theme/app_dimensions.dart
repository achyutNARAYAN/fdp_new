import 'package:flutter/material.dart';

/// Spacing, grid and shape according to Section 22:
/// 4pt base grid: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.
/// Radii: buttons 16, inputs 14, cards 20, images 16, dialogs 24, bottom sheet 28.
/// Heights: top bar 56, input 56, primary CTA 52, bottom nav 64, chip 40.
class AppDimensions {
  AppDimensions._();

  // Spacing scale
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;
  static const double p64 = 64.0;

  // Component heights
  static const double heightTopBar = 56.0;
  static const double heightInput = 56.0;
  static const double heightButton = 52.0;
  static const double heightBottomNav = 64.0;
  static const double heightChip = 40.0;
  static const double heightFloatingCart = 56.0;
  static const double minTouchTarget = 48.0;

  // Corner radii
  static const double radiusButton = 16.0;
  static const double radiusInput = 14.0;
  static const double radiusCard = 20.0;
  static const double radiusImage = 16.0;
  static const double radiusDialog = 24.0;
  static const double radiusBottomSheet = 28.0;
  static const double radiusPill = 999.0;
  static const double radiusBadge = 8.0;

  // Elevation shadows
  static List<BoxShadow> get elevationLevel1 => [
        const BoxShadow(
          color: Color(0x0F171A14), // 6%
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
        const BoxShadow(
          color: Color(0x0A171A14), // 4%
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  static List<BoxShadow> get elevationLevel2 => [
        const BoxShadow(
          color: Color(0x14171A14), // 8%
          offset: Offset(0, 4),
          blurRadius: 16,
        ),
      ];

  static List<BoxShadow> get elevationLevel3 => [
        const BoxShadow(
          color: Color(0x24171A14), // 14%
          offset: Offset(0, 8),
          blurRadius: 28,
        ),
      ];
}
