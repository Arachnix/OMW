import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'svg_icon.dart';

/// White card with the 1.5px ink outline and 16px radius used throughout the
/// Figma app frames.
class OmwCard extends StatelessWidget {
  const OmwCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.strokeWidth = AppRadii.stroke,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// 1.5 by default; compact feed cards use [AppRadii.strokeBold].
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.ink, width: strokeWidth),
      ),
      child: child,
    );
  }
}

/// "● FAST COURIER MATCH" style header row with an optional trailing widget.
class CardEyebrow extends StatelessWidget {
  const CardEyebrow({
    super.key,
    required this.label,
    this.trailing,
    this.hollowDot = false,
  });

  final String label;
  final Widget? trailing;

  /// Outlined dot, as on the compact "SLIGHT DETOUR" feed cards.
  final bool hollowDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: hollowDot ? null : AppColors.ink,
            shape: BoxShape.circle,
            border: hollowDot
                ? Border.all(color: AppColors.ink, width: AppRadii.stroke)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(label, style: AppText.cardEyebrow),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Black pill with the paper-plane icon, e.g. "~18 mins".
class EtaBadge extends StatelessWidget {
  const EtaBadge({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Estimated $minutes minutes',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SvgIcon(AppIcons.send, size: 12, color: AppColors.surface),
            const SizedBox(width: AppSpacing.xs),
            Text('~$minutes mins', style: AppText.badge),
          ],
        ),
      ),
    );
  }
}
