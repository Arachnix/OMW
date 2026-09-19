import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'svg_icon.dart';

class NavDestination {
  const NavDestination({
    this.icon,
    this.glyph,
    required this.label,
    this.badge = 0,
  }) : assert(icon != null || glyph != null);

  /// Figma SVG path (preferred).
  final String? icon;

  /// Material stand-in for icons not exported from Figma yet (`AppGlyphs`).
  final IconData? glyph;
  final String label;
  final int badge;
}

/// How the active tab is marked.
enum NavIndicator {
  /// 24×2 ink bar under the label (app shells).
  underline,

  /// Ink disc behind a white icon (landing, "onmyway-home-screen").
  disc,
}

/// "bottom-nav-bar" from Figma: icon, label and a 24×2 active indicator.
/// Inactive tabs are drawn at 50% opacity.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.indicator = NavIndicator.underline,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final NavIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _NavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  index: i,
                  count: destinations.length,
                  indicator: indicator,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.index,
    required this.count,
    required this.indicator,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final int index;
  final int count;
  final NavIndicator indicator;
  final VoidCallback onTap;

  Widget _icon(Color color) {
    final svg = destination.icon;
    return svg != null
        ? SvgIcon(svg, size: 20, color: color)
        : Icon(destination.glyph, size: 20, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final badge = destination.badge;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${destination.label}, tab ${index + 1} of $count'
          '${badge > 0 ? ', $badge open' : ''}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 64)
              .copyWith(minHeight: 48),
          child: AnimatedOpacity(
            duration: AppMotion.medium,
            // The disc style keeps inactive tabs at full ink, as in Figma.
            opacity: selected || indicator == NavIndicator.disc ? 1 : 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  backgroundColor: AppColors.ink,
                  textColor: AppColors.surface,
                  child: indicator == NavIndicator.disc
                      ? AnimatedContainer(
                          duration: AppMotion.medium,
                          curve: AppMotion.curve,
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.ink : AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: _icon(
                            selected ? AppColors.surface : AppColors.ink,
                          ),
                        )
                      : _icon(AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  destination.label,
                  style: selected ? AppText.navActive : AppText.navInactive,
                ),
                if (indicator == NavIndicator.underline) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: AppMotion.curve,
                    width: selected ? 24 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
