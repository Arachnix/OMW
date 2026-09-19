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

/// Lucide icons (the set used throughout the Figma file), bundled from
/// lucide-static under the ISC licence (assets/icons/LICENSE.txt).
class Lucide {
  Lucide._();

  static const String _dir = 'assets/icons';

  static const String alarmClock = '$_dir/alarm-clock.svg';
  static const String arrowDownLeft = '$_dir/arrow-down-left.svg';
  static const String arrowLeft = '$_dir/arrow-left.svg';
  static const String arrowRight = '$_dir/arrow-right.svg';
  static const String arrowUpRight = '$_dir/arrow-up-right.svg';
  static const String badgeCheck = '$_dir/badge-check.svg';
  static const String bell = '$_dir/bell.svg';
  static const String check = '$_dir/check.svg';
  static const String chevronLeft = '$_dir/chevron-left.svg';
  static const String chevronRight = '$_dir/chevron-right.svg';
  static const String circleAlert = '$_dir/circle-alert.svg';
  static const String circleCheck = '$_dir/circle-check.svg';
  static const String circleHelp = '$_dir/circle-help.svg';
  static const String circleX = '$_dir/circle-x.svg';
  static const String clock = '$_dir/clock.svg';
  static const String coins = '$_dir/coins.svg';
  static const String copy = '$_dir/copy.svg';
  static const String creditCard = '$_dir/credit-card.svg';
  static const String heart = '$_dir/heart.svg';
  static const String history = '$_dir/history.svg';
  static const String house = '$_dir/house.svg';
  static const String info = '$_dir/info.svg';
  static const String list = '$_dir/list.svg';
  static const String lock = '$_dir/lock.svg';
  static const String logOut = '$_dir/log-out.svg';
  static const String mapPin = '$_dir/map-pin.svg';
  static const String mapPinCheck = '$_dir/map-pin-check.svg';
  static const String messageSquare = '$_dir/message-square.svg';
  static const String navigation = '$_dir/navigation.svg';
  static const String phone = '$_dir/phone.svg';
  static const String radio = '$_dir/radio.svg';
  static const String refreshCw = '$_dir/refresh-cw.svg';
  static const String scanQrCode = '$_dir/scan-qr-code.svg';
  static const String settings = '$_dir/settings.svg';
  static const String shield = '$_dir/shield.svg';
  static const String shoppingBag = '$_dir/shopping-bag.svg';
  static const String shuffle = '$_dir/shuffle.svg';
  static const String star = '$_dir/star.svg';
  static const String store = '$_dir/store.svg';
  static const String trendingUp = '$_dir/trending-up.svg';
  static const String triangleAlert = '$_dir/triangle-alert.svg';
  static const String user = '$_dir/user.svg';
  static const String userCog = '$_dir/user-cog.svg';
  static const String wallet = '$_dir/wallet.svg';
  static const String x = '$_dir/x.svg';
  static const String zap = '$_dir/zap.svg';
  static const String locate = '$_dir/locate.svg';
  static const String handCoins = '$_dir/hand-coins.svg';
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

  /// Mascot face in the Account profile card (cropped from Figma 125:6).
  static const String mascotAvatar = 'assets/figma/mascot_avatar.png';

  /// Waving mascot on "Buy Tokens" (Figma 125:253).
  static const String mascotWave = 'assets/figma/mascot_wave.png';

  /// Celebrating mascot on "Payment Successful!" (Figma 125:605).
  static const String mascotSuccess = 'assets/figma/mascot_success.png';

  /// Courier portrait on "Order Details" (Figma 164:43).
  static const String courierPhoto = 'assets/figma/courier_photo.jpg';

  /// Circular mascot on the sign-in frames ("logo 1" in Figma).
  static const String mascotLogo = 'assets/brand/logo.jpeg';

  /// Muted handwritten wordmark animation for the splash.
  static const String wordmarkVideo =
      'assets/brand/final handwritten text OnMyWay.mp4';

  /// Static fallback when the wordmark video can't play.
  static const String wordmarkStill = 'assets/brand/logo_handwritten.png';
}
