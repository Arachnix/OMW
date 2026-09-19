import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'svg_icon.dart';

/// "header-row" from the Figma app frames: mascot badge on the left,
/// outlined avatar button on the right.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.onMascotTap,
    required this.onAvatarTap,
  });

  final VoidCallback onMascotTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HeaderButton(
            tooltip: 'OnMyWay home',
            onTap: onMascotTap,
            child: ClipOval(
              child: Image.asset(
                AppImages.mascotBadge,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
              ),
            ),
          ),
          _HeaderButton(
            tooltip: 'Your account',
            onTap: onAvatarTap,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink,
                  width: AppRadii.stroke,
                ),
              ),
              child: const SvgIcon(AppIcons.userRound, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: SizedBox.square(dimension: 48, child: Center(child: child)),
        ),
      ),
    );
  }
}
