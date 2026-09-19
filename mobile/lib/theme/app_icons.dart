import 'package:flutter/material.dart';

/// Local paths of the icon and image assets exported from Figma.
///
/// Icons are the Lucide set used in the design, exported as SVG.
class AppIcons {
  AppIcons._();

  static const String _dir = 'assets/figma';

  static const String send = '$_dir/ic_send.svg';
  static const String mapPin = '$_dir/ic_map_pin.svg';
  static const String circleArrowLeft = '$_dir/ic_circle_arrow_left.svg';
  static const String globe = '$_dir/ic_globe.svg';
  static const String arrowUpRight = '$_dir/ic_arrow_up_right.svg';
  static const String file = '$_dir/ic_file.svg';
  static const String box = '$_dir/ic_box.svg';
  static const String package = '$_dir/ic_package.svg';
  static const String sliders = '$_dir/ic_sliders_horizontal.svg';
  static const String circleX = '$_dir/ic_circle_x.svg';
  static const String truck = '$_dir/ic_truck.svg';
  static const String clipboardCheck = '$_dir/ic_clipboard_check.svg';
  static const String idCard = '$_dir/ic_id_card.svg';
  static const String userRound = '$_dir/ic_user_round.svg';
  static const String google = '$_dir/logo_google.svg';
}

/// Stand-ins for Figma icons that have not been exported yet (landing and
/// compact feed cards). Figma's image export was rate-limited when these
/// screens were built. Replace each entry with an `AppIcons` SVG once
/// exported; call sites use `Icon(AppGlyphs.x)` and need a one-line swap.
class AppGlyphs {
  AppGlyphs._();

  static const IconData bag = Icons.shopping_bag_outlined;
  static const IconData arrowRight = Icons.arrow_forward;
  static const IconData store = Icons.storefront_outlined;
  static const IconData user = Icons.person_outline;
  static const IconData alarm = Icons.alarm;
  static const IconData navigation = Icons.navigation_outlined;
  static const IconData navHome = Icons.home_outlined;
  static const IconData navOrders = Icons.schedule;
  static const IconData navFavorites = Icons.favorite_border;
  static const IconData navAccount = Icons.person_outline;
  static const IconData check = Icons.check;
  static const IconData phone = Icons.phone_outlined;
}

/// Brand imagery and animation files supplied in assets/brand.
class AppImages {
  AppImages._();

  /// Header mascot badge ("image 7" in Figma).
  static const String mascotBadge = 'assets/figma/mascot_badge.png';

  /// Apple logo from the Sign_iOS frame.
  static const String apple = 'assets/figma/logo_apple.png';

  /// Full-body namaste mascot on the landing ("onmyway-home-screen").
  static const String mascotTraveler = 'assets/brand/mascot_traveler.png';

  /// Circular mascot on the sign-in frames ("logo 1" in Figma).
  static const String mascotLogo = 'assets/brand/logo.jpeg';

  /// Muted handwritten wordmark animation for the splash.
  static const String wordmarkVideo =
      'assets/brand/final handwritten text OnMyWay.mp4';

  /// Static fallback when the wordmark video can't play.
  static const String wordmarkStill = 'assets/brand/logo_handwritten.png';
}
