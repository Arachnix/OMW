import 'package:flutter/material.dart';

/// Colour tokens extracted from the OMW Figma file (node 72:282).
///
/// The design is strictly monochrome: black ink on white, with two light
/// greys for filled surfaces and two for hairlines.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF000000);
  static const Color surface = Color(0xFFFFFFFF);

  /// Selected cargo tile, custom-amount pill, icon discs (`#F5F5F5`).
  static const Color fillMuted = Color(0xFFF5F5F5);

  /// Secondary auth buttons on the sign-in screen (`#EEEEEE`).
  static const Color fillButton = Color(0xFFEEEEEE);

  /// Divider rules and outlined filter pills (`#E6E6E6`).
  static const Color divider = Color(0xFFE6E6E6);

  /// Text-field outline (`#E0E0E0`).
  static const Color fieldBorder = Color(0xFFE0E0E0);

  /// Placeholder and helper copy (`#828282`).
  static const Color textMuted = Color(0xFF828282);

  /// Near-black used by the "All Deliveries" pill (rgba 0,0,0,.9).
  static const Color inkSoft = Color(0xE6000000);

  static const Color error = Color(0xFFB3261E);

  /// Dim overlay behind notification sheets (rgba 15,23,42,.6 in Figma).
  static const Color scrim = Color(0x990F172A);

  /// Figma renders secondary copy as ink at reduced opacity.
  static Color inkAt(double opacity) => ink.withValues(alpha: opacity);
}

/// Spacing scale used across the Figma frames.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Horizontal page gutter of the app frames.
  static const double gutter = 16;

  /// Horizontal page gutter of the sign-in frames.
  static const double authGutter = 24;
}

/// Corner radii and stroke weights used across the Figma frames.
class AppRadii {
  AppRadii._();

  static const double field = 8;
  static const double tile = 12;
  static const double card = 16;
  static const double pill = 100;

  static const double hairline = 1;
  static const double stroke = 1.5;
  static const double strokeBold = 2;
}

/// Motion tokens. Kept short and restrained.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve curve = Curves.easeOutCubic;
}
