import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'svg_icon.dart';

/// Rounded-square outlined icon button (back / history / settings / help on
/// the wallet, account and payment frames).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 36,
    this.iconSize = 20,
  });

  final String icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.iconButton);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: const BorderSide(
                  color: AppColors.ink,
                  width: AppRadii.stroke,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox.square(
                  dimension: size,
                  child: Center(child: SvgIcon(icon, size: iconSize)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big display title with an eyebrow ("Wallet & Earnings / FUEL YOUR
/// MOVEMENT."), optional back button and trailing action.
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    required this.eyebrow,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onBack != null) ...[
                      SquareIconButton(
                        icon: Lucide.arrowLeft,
                        tooltip: 'Back',
                        size: 28,
                        iconSize: 18,
                        onTap: onBack!,
                      ),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: AppText.displayTitle),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(left: onBack != null ? 12 : 0),
                  child: Text(eyebrow, style: AppText.displayEyebrow),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Plain header with a back chevron and centred title ("Order Details",
/// "Cancel Order"), optionally underlined with a 2px rule.
class CenteredHeader extends StatelessWidget {
  const CenteredHeader({
    super.key,
    required this.title,
    this.trailing,
    this.underline = false,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final bool underline;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: underline
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.ink,
                  width: AppRadii.strokeBold,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      height: 64,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const SvgIcon(Lucide.chevronLeft, size: 24),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.heading.copyWith(fontSize: 20),
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

/// Outlined white panel used by the newer frames.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.card,
    this.stroke = AppRadii.stroke,
    this.color = AppColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double stroke;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.ink, width: stroke),
      ),
      child: child,
    );
  }
}

/// Grey info strip with a leading icon ("Tokens are used to place…").
class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.text,
    this.icon = Lucide.info,
    this.trailing,
    this.outlined = false,
  });

  final String text;
  final String icon;
  final Widget? trailing;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: outlined ? AppColors.surface : AppColors.fillWarm,
        borderRadius: BorderRadius.circular(
          outlined ? AppRadii.card : AppRadii.tile,
        ),
        border: outlined
            ? Border.all(color: AppColors.ink, width: AppRadii.stroke)
            : null,
      ),
      child: Row(
        children: [
          SvgIcon(
            icon,
            size: 20,
            color: outlined ? AppColors.ink : AppColors.inkAt(0.7),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: outlined
                  ? AppText.body.copyWith(fontWeight: FontWeight.w500)
                  : AppText.bodyMuted.copyWith(fontSize: 13),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 36px grey tile holding an icon (menu rows, transactions).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.size = 36});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.fillWarm,
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: SvgIcon(icon, size: size * 0.5),
    );
  }
}

/// Outlined group of rows separated by hairlines.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.ink, width: AppRadii.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Icon tile + title + subtitle + chevron row (Account menu).
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: Row(
            children: [
              IconTile(icon: icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppText.labelSmall.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SvgIcon(Lucide.chevronRight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat card ("28 / Deliveries / Completed").
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.caption,
    required this.icon,
  });

  final String value;
  final String label;
  final String caption;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label $caption',
      excludeSemantics: true,
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: AppText.displayStat),
                  ),
                ),
                SvgIcon(icon, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppText.label.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(caption, style: AppText.labelSmall.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Black button with the display face ("Buy 500 Tokens for ₹800").
class DisplayButton extends StatelessWidget {
  const DisplayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.height = 52,
    this.radius = AppRadii.pill,
    this.outlined = false,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool busy;
  final double height;
  final double radius;
  final bool outlined;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final fg = outlined ? AppColors.ink : AppColors.surface;
    final style = (textStyle ?? AppText.displayButton).copyWith(color: fg);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: enabled || busy ? 1 : 0.35,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Material(
            color: outlined ? AppColors.surface : AppColors.inkDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(
                color: AppColors.ink,
                width: outlined ? AppRadii.stroke : 0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Center(
                child: busy
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fg,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                SvgIcon(icon!, size: 18, color: fg),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Text(label, style: style),
                            ],
                          ),
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

/// Selectable reason row with a radio ring (cancellation screens).
///
/// [filledSelection] paints the selected row black (Figma "Cancel Order");
/// otherwise only the radio fills (Figma "Reject Assignment").
class ReasonOption extends StatelessWidget {
  const ReasonOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.filledSelection = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool filledSelection;

  @override
  Widget build(BuildContext context) {
    final dark = selected && filledSelection;
    final fg = dark ? AppColors.surface : AppColors.ink;
    final radius = BorderRadius.circular(AppRadii.tile);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: dark ? AppColors.ink : AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.ink, width: AppRadii.strokeBold),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: fg,
                        width: selected && !filledSelection ? 6 : 2,
                      ),
                    ),
                    child: dark
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.ink,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.label.copyWith(color: fg),
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

/// Section caption ("TODAY", "ENTER AMOUNT", "WITHDRAW TO").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: dark
              ? AppText.overline.copyWith(color: AppColors.ink, fontSize: 14)
              : AppText.overline,
        ),
      ),
    );
  }
}

/// Card with a dashed ink outline ("Available to deliver").
class DashedPanel extends StatelessWidget {
  const DashedPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedRRectPainter(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppRadii.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadii.tile),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Monochrome error block with an alert icon (edge states 4, 5 and 8).
class ErrorBlock extends StatelessWidget {
  const ErrorBlock({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.fillWarm,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          border: Border.all(color: AppColors.ink, width: AppRadii.strokeBold),
        ),
        child: Column(
          children: [
            const SvgIcon(Lucide.circleAlert, size: 22),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.label.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(fontSize: 13),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error line with an alert icon (form validation, monochrome).
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.fillWarm,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(color: AppColors.ink, width: AppRadii.stroke),
        ),
        child: Row(
          children: [
            const SvgIcon(Lucide.circleAlert, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppText.labelSmall.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small info dialog used for "(i)" / help buttons.
Future<void> showInfo(BuildContext context, String title, String body) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.ink, width: AppRadii.stroke),
      ),
      title: Text(title, style: AppText.heading),
      content: Text(body, style: AppText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: Text('Got it', style: AppText.label),
        ),
      ],
    ),
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String rupees(int value) {
  final s = value.abs().toString();
  // Indian digit grouping: 1,240 / 12,400 / 1,24,000
  String grouped;
  if (s.length <= 3) {
    grouped = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${value < 0 ? '-' : ''}₹$grouped';
}
