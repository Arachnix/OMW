import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Inter text styles named after their role in the Figma frames.
///
/// Inter is bundled locally (assets/fonts/inter) so no fonts are fetched at
/// runtime.
class AppText {
  AppText._();

  static const String family = 'Inter';

  static const TextStyle _base = TextStyle(
    fontFamily: family,
    color: AppColors.ink,
    height: 1.2,
  );

  // Sign-in
  static final TextStyle authTitle = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  static final TextStyle authBody = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static final TextStyle fieldText = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static final TextStyle button = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static final TextStyle legal = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textMuted,
  );

  // App frames
  static final TextStyle cardEyebrow = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle badge = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.surface,
  );
  static final TextStyle routeLabel = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle routeValue = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle sectionTitle = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle tileTitle = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle tileTitleSelected = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle tileCaption = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle tileCaptionSelected = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle caption = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle price = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );
  static final TextStyle inputLabel = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle inputValue = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle cta = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AppColors.surface,
  );
  static final TextStyle navActive = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle navInactive = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle pill = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Landing ("onmyway-home-screen")
  static final TextStyle brandTitle = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w900,
  );
  static final TextStyle tagline = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AppColors.inkAt(0.61),
  );
  static final TextStyle headline = _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    height: 1.15,
  );
  static final TextStyle choiceTitle = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  // Courier feed: compact "request-card-3"
  static final TextStyle stopTitle = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle stopDetail = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkAt(0.6),
  );
  static final TextStyle statValue = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle statCaption = _base.copyWith(
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: AppColors.inkAt(0.6),
  );
  static final TextStyle priceCompact = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w900,
  );
  static final TextStyle ctaCompact = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.surface,
  );

  // Notification sheets ("notification-order-accepted" frames)
  static final TextStyle sheetTitle = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle sheetBody = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.inkAt(0.6),
  );
  static final TextStyle trackingTitle = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle orderMeta = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inkAt(0.6),
  );
  static final TextStyle orderCaption = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.inkAt(0.6),
  );
  static final TextStyle orderValue = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle orderValueStrong = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle chip = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle buttonLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Display (Archivo Black): titles and amounts on the wallet, account and
  // payment frames. Archivo Black has no ₹ glyph, so Inter supplies it.
  static const String displayFamily = 'ArchivoBlack';

  static const TextStyle _display = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: [family],
    color: AppColors.ink,
    fontWeight: FontWeight.w400,
    height: 1.1,
  );

  /// "Wallet & Earnings", "Account", "Buy Tokens".
  static final TextStyle displayTitle = _display.copyWith(fontSize: 28);

  /// "FUEL YOUR MOVEMENT." eyebrow under page titles.
  static final TextStyle displayEyebrow = _display.copyWith(
    fontSize: 12,
    color: AppColors.inkAt(0.6),
  );

  /// Balance hero amount ("₹240").
  static final TextStyle displayAmount = _display.copyWith(fontSize: 36);

  /// Stat card figures ("₹1,240", "28").
  static final TextStyle displayStat = _display.copyWith(fontSize: 24);

  /// Token pack names and prices ("50 Tokens", "₹100").
  static final TextStyle displayItem = _display.copyWith(fontSize: 17);

  /// Buttons on the wallet / payment frames ("Buy 500 Tokens for ₹800").
  static final TextStyle displayButton = _display.copyWith(
    fontSize: 16,
    color: AppColors.surface,
  );

  /// Small display labels ("Buy Tokens →" inline button, "Save 5%").
  static final TextStyle displaySmall = _display.copyWith(fontSize: 13);

  // Body text used across the newer frames
  static final TextStyle body = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  static final TextStyle bodyMuted = body.copyWith(color: AppColors.inkAt(0.6));
  static final TextStyle label = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle labelSmall = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkAt(0.6),
  );
  static final TextStyle overline = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.inkAt(0.6),
  );
  static final TextStyle headingLarge = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle heading = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
}
