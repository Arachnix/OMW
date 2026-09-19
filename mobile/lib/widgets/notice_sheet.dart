import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Opens a notification sheet ("notification-order-accepted" frames): white,
/// 2px ink top edge, 32 top radius, over the [AppColors.scrim] overlay.
/// Swiping down or tapping the overlay dismisses it and resolves to null.
Future<T?> showNoticeSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      side: BorderSide(color: AppColors.ink, width: AppRadii.strokeBold),
    ),
    builder: builder,
  );
}

/// Sheet body: ink grab handle (tap to dismiss), 24 gutter, scrollable.
class NoticeSheet extends StatelessWidget {
  const NoticeSheet({
    super.key,
    required this.children,
    this.showHandle = true,
  });

  final List<Widget> children;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) ...[
              Center(
                child: Semantics(
                  button: true,
                  label: 'Dismiss',
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: () => Navigator.of(context).maybePop(),
                    radius: 28,
                    child: SizedBox(
                      width: 48,
                      height: 24,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// 48px status disc + title + subtitle. [filled] discs are ink with a white
/// icon ("Order Accepted!"); outlined discs are white with an ink ring
/// ("Order Cancelled").
class NoticeHeader extends StatelessWidget {
  const NoticeHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.filled = true,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? AppColors.ink : AppColors.surface,
              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(
                      color: AppColors.ink,
                      width: AppRadii.strokeBold,
                    ),
            ),
            child: ExcludeSemantics(child: icon),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: AppText.sheetTitle),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppText.sheetBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2px ink rule between sheet sections.
class NoticeRule extends StatelessWidget {
  const NoticeRule({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: SizedBox(
        height: AppRadii.strokeBold,
        child: ColoredBox(color: AppColors.ink),
      ),
    );
  }
}

/// Grey detail card inside a notice: `fillMuted`, 2px ink, radius 16.
class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.fillMuted,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.ink, width: AppRadii.strokeBold),
      ),
      child: child,
    );
  }
}

enum StopMarker { dot, square }

/// Ink disc with a white dot (pickup) or square (delivery), then an
/// uppercase caption and the address.
class NoticeStop extends StatelessWidget {
  const NoticeStop({
    super.key,
    required this.marker,
    required this.label,
    required this.value,
  });

  final StopMarker marker;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: marker == StopMarker.dot
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: marker == StopMarker.square
                    ? BorderRadius.circular(1)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.orderCaption),
                Text(
                  value,
                  style: AppText.orderValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill with a 2px ink outline, height 48 ("Return to Dashboard").
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(
            color: AppColors.ink,
            width: AppRadii.strokeBold,
          ),
          shape: const StadiumBorder(),
        ),
        child: Text(label, style: AppText.buttonLarge),
      ),
    );
  }
}
