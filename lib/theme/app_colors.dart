import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Dark Backgrounds (Apple OLED Dark Aesthetic)
  static const Color background = Color(0xFF000000);    // Pure OLED Black
  static const Color surface = Color(0xFF1C1C1E);       // iOS Elevated Dark Surface
  static const Color surfaceLight = Color(0xFF2C2C2E);  // Secondary Elevated Surface
  static const Color cardBg = Color(0xFF1C1C1E);        // Apple Health Card Surface
  static const Color cardBorder = Color(0x1FFFFFFF);    // Subtle 12% white border

  // Glassmorphic Overlays
  static const Color glassFill = Color(0x14FFFFFF);     // 8% White Blur Fill
  static const Color glassBorder = Color(0x26FFFFFF);   // 15% White Blur Border

  // Primary Brand & Apple Health Accents
  static const Color primary = Color(0xFF00D4AA);       // Vibrant Mint / Electric Teal
  static const Color primaryDark = Color(0xFF00A383);
  static const Color primaryLight = Color(0xFF33E0BC);
  static const Color secondary = Color(0xFF0A84FF);     // Apple System Blue

  // Apple Health Category Signature Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF00D4AA),
    Color(0xFF0A84FF),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFBF5AF2), // Apple Purple
    Color(0xFFFF2D55), // Apple Pink / Heart Red
  ];

  static const List<Color> cardGradient = [
    Color(0x2600D4AA),
    Color(0x120A84FF),
  ];

  static const List<Color> alertGradient = [
    Color(0x33FF453A),
    Color(0x1AFF9F0A),
  ];

  // Apple System State Colors
  static const Color purple = Color(0xFFBF5AF2);
  static const Color blue = Color(0xFF0A84FF);
  static const Color success = Color(0xFF30D158);       // Apple Neon Green
  static const Color warning = Color(0xFFFF9F0A);       // Apple Gold / Amber
  static const Color danger = Color(0xFFFF453A);        // Apple Crimson Red
  static const Color info = Color(0xFF64D2FF);          // Apple Sky Cyan

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);   // Crisp White
  static const Color textSecondary = Color(0xFFEBEBF5); // High Contrast Label (86%)
  static const Color textMuted = Color(0xFF8E8E93);     // iOS Muted Gray
  static const Color textDisabled = Color(0xFF48484A);  // iOS Dark Gray

  // Functional Form Elements
  static const Color divider = Color(0x268E8E93);
  static const Color inputBg = Color(0xFF2C2C2E);
  static const Color inputBorder = Color(0x338E8E93);
  static const Color inputFocusBorder = Color(0xFF00D4AA);
}
