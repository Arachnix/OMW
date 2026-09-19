import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'svg_icon.dart';

/// Pickup and destination sub-cards joined by a dashed connector
/// ("addresses-container" in Figma).
///
/// When [onEditPickup] / [onEditDestination] are null the stops are read-only.
class RouteStops extends StatelessWidget {
  const RouteStops({
    super.key,
    required this.pickup,
    required this.destination,
    this.onEditPickup,
    this.onEditDestination,
  });

  final String pickup;
  final String destination;
  final VoidCallback? onEditPickup;
  final VoidCallback? onEditDestination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StopTile(
          icon: AppIcons.mapPin,
          label: 'Pickup Spot',
          address: pickup,
          trailing: AppIcons.circleArrowLeft,
          onTap: onEditPickup,
        ),
        const Padding(
          padding: EdgeInsets.only(left: 26),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CustomPaint(size: Size(2, 16), painter: _DashPainter()),
          ),
        ),
        _StopTile(
          icon: AppIcons.globe,
          label: 'Delivery Destination',
          address: destination,
          trailing: AppIcons.arrowUpRight,
          onTap: onEditDestination,
        ),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.icon,
    required this.label,
    required this.address,
    required this.trailing,
    this.onTap,
  });

  final String icon;
  final String label;
  final String address;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.tile);
    return Semantics(
      button: onTap != null,
      label: '$label: $address${onTap != null ? '. Double tap to change' : ''}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.ink),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.fillMuted,
                    shape: BoxShape.circle,
                  ),
                  child: SvgIcon(icon),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.routeLabel),
                      const SizedBox(height: AppSpacing.xxs),
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: Text(
                          address,
                          key: ValueKey(address),
                          style: AppText.routeValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SvgIcon(trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = AppRadii.strokeBold;
    const dash = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash * 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
