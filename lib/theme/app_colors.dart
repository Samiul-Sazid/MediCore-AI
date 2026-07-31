import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Dark Backgrounds
  static const Color background = Color(0xFF0A0E1A); // Deep midnight blue/black
  static const Color surface = Color(0xFF111827);    // Dark slate gray surface
  static const Color surfaceLight = Color(0xFF1F2937); // Elevated surface
  static const Color cardBg = Color(0x0DFFFFFF);      // 5% white translucent for glassmorphism
  static const Color cardBorder = Color(0x1AFFFFFF);  // 10% white border

  // Glassmorphic Overlays
  static const Color glassFill = Color(0x14FFFFFF);   // 8% white
  static const Color glassBorder = Color(0x26FFFFFF); // 15% white

  // Primary Brand Gradients & Colors (Teal / Emerald / Cyan)
  static const Color primary = Color(0xFF00D4AA);      // Vivid Teal
  static const Color primaryDark = Color(0xFF00A383);
  static const Color primaryLight = Color(0xFF33E0BC);
  static const Color secondary = Color(0xFF00B4D8);    // Cyan Blue

  static const List<Color> primaryGradient = [
    Color(0xFF00D4AA),
    Color(0xFF00B4D8),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF7C3AED), // Deep Purple
    Color(0xFFA855F7), // Vibrant Violet
  ];

  static const List<Color> cardGradient = [
    Color(0x1F2DD4BF),
    Color(0x0F0284C7),
  ];

  static const List<Color> alertGradient = [
    Color(0x33EF4444),
    Color(0x1AF59E0B),
  ];

  // Accent & State Colors
  static const Color purple = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);  // Mint Emerald
  static const Color warning = Color(0xFFF59E0B);  // Amber Gold
  static const Color danger = Color(0xFFEF4444);   // Crimson Red
  static const Color info = Color(0xFF0EA5E9);     // Sky Blue

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);   // Pure white/off-white
  static const Color textSecondary = Color(0xFF9CA3AF); // Muted gray
  static const Color textMuted = Color(0xFF6B7280);     // Dim gray
  static const Color textDisabled = Color(0xFF4B5563);  // Darker gray

  // Functional Elements
  static const Color divider = Color(0x1F9CA3AF);
  static const Color inputBg = Color(0x1A1F2937);
  static const Color inputBorder = Color(0x339CA3AF);
  static const Color inputFocusBorder = Color(0xFF00D4AA);
}
