import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Solid black button. Defaults to the full-pill CTA from the app frames
/// ("broadcast-cta-button"); the sign-in frames use [radius] 8 and [height] 40.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.busy = false,
    this.radius = AppRadii.pill,
    this.height = 48,
    this.textStyle,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool busy;
  final double radius;
  final double height;
  final TextStyle? textStyle;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final style = textStyle ?? AppText.cta;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: enabled || busy ? 1 : 0.35,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.ink,
              disabledForegroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: busy
                  ? const SizedBox(
                      key: ValueKey('busy'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: style,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

/// Grey secondary button from the sign-in frames ("Continue with Google").
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.fillButton,
            foregroundColor: AppColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppText.button,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
