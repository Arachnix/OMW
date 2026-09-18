import 'package:flutter/material.dart';

class AppColors {
  // Brand Greens
  static const Color primary = Color(0xFF006C49);
  static const Color primaryDark = Color(0xFF005237);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color accentGreen = Color(0xFF6FFBBE);
  static const Color greenLightBg = Color(0xFFEFFBF5);

  // Navy / Dark
  static const Color navyDark = Color(0xFF0B1C30);
  static const Color navyMedium = Color(0xFF213145);
  static const Color textMuted = Color(0xFF565E74);
  static const Color textBody = Color(0xFF3C4A42);

  // Soft Canvas & Cards
  static const Color bgLight = Color(0xFFF8F9FF);
  static const Color cardLight = Color(0xFFEFF4FF);
  static const Color cardBorder = Color(0xFFD3E4FE);
  static const Color cardHover = Color(0xFFE5EEFF);

  // Amber / Surge
  static const Color amberBadge = Color(0xFFFFDDB8);
  static const Color amberText = Color(0xFF2A1700);
  static const Color amberBorder = Color(0xFFFFCC99);

  // Alert / Danger
  static const Color dangerBg = Color(0xFFFFDAD6);
  static const Color dangerText = Color(0xFF93000A);
  static const Color dangerRed = Color(0xFFE11D48);

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: const Color(0xFF0B1C30).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
