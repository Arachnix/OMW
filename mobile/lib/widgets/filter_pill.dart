import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Selectable pill from the "Pills" component on the delivery feed.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: selected ? AppColors.inkSoft : AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.inkSoft : AppColors.divider,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              // Keeps the touch target at least 40dp tall.
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.medium,
                    style: AppText.pill.copyWith(
                      color: selected ? AppColors.surface : AppColors.ink,
                    ),
                    child: Text(label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
