import 'package:flutter/material.dart';

import '../models/omw_models.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'omw_card.dart';
import 'pill_button.dart';
import 'route_card.dart';

/// Shown after a delivery request is broadcast. Resolves to true when the
/// user asks to see their activity.
class BroadcastConfirmationSheet extends StatelessWidget {
  const BroadcastConfirmationSheet({super.key, required this.request});

  final OmwTask request;

  static Future<bool?> show(BuildContext context, OmwTask request) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BroadcastConfirmationSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipOval(
              child: Image.asset(
                AppImages.mascotBadge,
                width: 72,
                height: 72,
                semanticLabel: 'OnMyWay mascot',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              'Request broadcast',
              textAlign: TextAlign.center,
              style: AppText.sectionTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '₹${request.wager} is locked in escrow until delivery. Nearby couriers can accept it now.',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.inkAt(0.7)),
          ),
          const SizedBox(height: AppSpacing.lg),
          OmwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardEyebrow(
                  label: request.parcel.label.toUpperCase(),
                  trailing: null,
                ),
                const SizedBox(height: AppSpacing.md),
                RouteStops(
                  pickup: request.pickupName,
                  destination: request.dropName,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: 'View activity',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text('Done', style: AppText.button),
          ),
        ],
      ),
    );
  }
}
