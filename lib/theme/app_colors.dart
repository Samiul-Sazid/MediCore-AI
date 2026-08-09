import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Clean Light Backgrounds (Matching Exact User Image)
  static const Color background = Color(0xFFF4F6F5);    // Soft Light Off-White Background
  static const Color surface = Color(0xFFFFFFFF);       // Crisp Pure White Surface
  static const Color surfaceLight = Color(0xFFEAF2EE);  // Soft Sage / Mint Container Tint
  static const Color cardBg = Color(0xFFFFFFFF);        // White Card Surface
  static const Color cardBorder = Color(0xFFEAEAEA);    // Very Soft Light Border

  // Glassmorphic / Overlay Colors
  static const Color glassFill = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFE0E0E0);

  // Primary Brand Accents (Emerald / Sage Green from Screenshot)
  static const Color primary = Color(0xFF2D6A4F);       // Deep Sage / Emerald Green
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color secondary = Color(0xFF40916C);     // Medium Sage Green

  static const List<Color> primaryGradient = [
    Color(0xFF2D6A4F),
    Color(0xFF40916C),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF52B788),
    Color(0xFF74C69D),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF4F6F5),
  ];

  static const List<Color> alertGradient = [
    Color(0xFFFDE8E8),
    Color(0xFFFDF2E9),
  ];

  // State & Category Accents
  static const Color purple = Color(0xFF7B2CBF);
  static const Color blue = Color(0xFF1D3557);
  static const Color success = Color(0xFF2D6A4F);       // Sage Green Success
  static const Color warning = Color(0xFFE07A5F);       // Warm Terracotta Amber
  static const Color danger = Color(0xFFE63946);        // Soft Crimson Red
  static const Color info = Color(0xFF457B9D);          // Soft Steel Blue

  // Text Colors (High Contrast Dark Charcoal)
  static const Color textPrimary = Color(0xFF121212);   // Deep Dark Charcoal / Black Text
  static const Color textSecondary = Color(0xFF4A4A4A); // Medium Gray Label (70%)
  static const Color textMuted = Color(0xFF8D99AE);     // Soft Muted Gray
  static const Color textDisabled = Color(0xFFC4C4C4);  // Light Disabled Gray

  // Functional Form Elements
  static const Color divider = Color(0xFFEEF0F2);
  static const Color inputBg = Color(0xFFF8F9FA);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocusBorder = Color(0xFF2D6A4F);
}
