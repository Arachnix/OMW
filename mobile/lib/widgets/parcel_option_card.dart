import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'svg_icon.dart';

/// Cargo tile ("cargo-doc" / "cargo-smallbox" / "cargo-mediumbox" in Figma).
///
/// Selected tiles get the grey fill, 2px outline and bolder labels.
/// With [onTap] null the tile is a static summary (used on the courier feed).
class ParcelOptionCard extends StatelessWidget {
  const ParcelOptionCard({
    super.key,
    required this.type,
    required this.selected,
    this.onTap,
  });

  final ParcelType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.tile);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${type.label}, ${type.weight}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: selected ? AppColors.fillMuted : AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: AppColors.ink,
            width: selected ? AppRadii.strokeBold : AppRadii.hairline,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: AppMotion.curve,
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.surface : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: selected ? AppRadii.stroke : AppRadii.hairline,
                      ),
                    ),
                    child: SvgIcon(type.icon),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    type.label,
                    style: selected
                        ? AppText.tileTitleSelected
                        : AppText.tileTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    type.weight,
                    style: selected
                        ? AppText.tileCaptionSelected
                        : AppText.tileCaption.copyWith(
                            color: AppColors.inkAt(0.6),
                          ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
