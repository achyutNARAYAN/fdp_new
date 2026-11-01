import 'package:flutter/material.dart';

/// Design tokens specified in Section 22:
/// Primary — Sage Green: #9CAF88 (RGB 156, 175, 136)
/// Secondary — Concrete Grey: #A7A7A7 (RGB 167, 167, 167)
/// Accent — Burnt Amber: #CC5500 (RGB 204, 85, 0)
/// Background: #F5F7F3 (Sage Green at 10% tint over white)
/// Cards: #FFFFFF
/// Primary Text: #171A14 (Sage Green at 15% brightness)
/// Secondary Text: #5C5C5C (Concrete Grey at 55% brightness)
/// Neutral Border: #868686 (3:1 contrast on white)
class AppColors {
  AppColors._();

  // Primary: Sage Green
  static const Color primary = Color(0xFF9CAF88);
  static const Color primaryPressed = Color(0xFF859574);
  static const Color primaryTint20 = Color(0xFFEBEFE7);
  static const Color primaryTint10 = Color(0xFFF5F7F3);
  static const Color onPrimary = Color(0xFF171A14);

  // Surface & Background
  static const Color background = Color(0xFFF5F7F3);
  static const Color surface = Color(0xFFFFFFFF);

  // Neutral: Concrete Grey
  static const Color neutral = Color(0xFFA7A7A7);
  static const Color neutralBorder = Color(0xFF868686);
  static const Color neutralLight = Color(0x33A7A7A7); // 20% opacity
  static const Color divider = Color(0x40A7A7A7); // 25% opacity

  // Text
  static const Color textPrimary = Color(0xFF171A14);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textMuted = Color(0xFFA7A7A7);

  // Accent: Burnt Amber
  static const Color accent = Color(0xFFCC5500);
  static const Color accentPressed = Color(0xFFAD4800);
  static const Color accentTint12 = Color(0xFFF9EBE0);

  // Regulatory Diet Marker Standard Colors
  static const Color vegGreen = Color(0xFF2E7D32);
  static const Color nonVegBrown = Color(0xFF8B2500);
  static const Color eggYellow = Color(0xFFF57F17);

  // Status semantic shortcuts
  static const Color successBg = primaryTint20;
  static const Color successBorder = primary;
  static const Color successText = textPrimary;

  static const Color pendingBg = Colors.white;
  static const Color pendingBorder = accent;
  static const Color pendingText = accent;

  static const Color errorBg = accentTint12;
  static const Color errorBorder = accent;
  static const Color errorText = textPrimary;

  static const Color infoBg = Color(0x33A7A7A7);
  static const Color infoText = textSecondary;
}

