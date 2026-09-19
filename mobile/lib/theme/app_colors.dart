import 'package:flutter/material.dart';

/// Colour tokens extracted from the OMW Figma file.
///
/// The app is strictly black and white: ink on white or off-white, with light
/// neutral greys for filled surfaces and hairlines. Figma's few red/green
/// accents (errors, credits, "verified") are rendered in ink; state is carried
/// by icons, weight and outlines instead of hue.
class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF000000);

  /// Near-black of the wallet / payment frames (`#111111`).
  static const Color inkDeep = Color(0xFF111111);
  static const Color surface = Color(0xFFFFFFFF);

  /// Off-white page background of the wallet, account and payment frames
  /// (`#FAFAF9`).
  static const Color canvas = Color(0xFFFAFAF9);

  /// Selected cargo tile, custom-amount pill, icon discs (`#F5F5F5`).
  static const Color fillMuted = Color(0xFFF5F5F5);

  /// Info boxes and icon tiles on the off-white frames (`#F5F5F4`).
  static const Color fillWarm = Color(0xFFF5F5F4);

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

  /// Errors are ink too (monochrome rule); pair them with an alert icon.
  static const Color error = ink;

  /// Dim overlay behind notification sheets.
  static const Color scrim = Color(0x99000000);

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

  /// Wallet / account cards (balance card, profile card).
  static const double panel = 20;

  /// Page-title icon buttons (back, history, settings).
  static const double iconButton = 10;

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
