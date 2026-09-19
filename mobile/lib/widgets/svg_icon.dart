import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Renders one of the Figma-exported SVG icons, recoloured to [color].
///
/// Icons are decorative by default; pass [semanticLabel] when the icon alone
/// carries meaning.
class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.asset, {
    super.key,
    this.size = 16,
    this.color = AppColors.ink,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
