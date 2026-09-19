import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/omw_card.dart';
import '../widgets/route_card.dart';

/// Sender "Activity" tab. Not drawn in Figma; built from the same card,
/// eyebrow and route components as the Home frame.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().history;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      itemCount: history.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Semantics(
            header: true,
            child: Text('Your deliveries', style: AppText.sectionTitle),
          );
        }
        return _ActivityCard(request: history[i - 1]);
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM, h:mm a').format(request.createdAt);
    final done = request.status == DeliveryStatus.delivered;

    return OmwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardEyebrow(
            label: request.status.label.toUpperCase(),
            trailing: _StatusChip(done: done, fare: request.fare),
          ),
          const SizedBox(height: AppSpacing.md),
          RouteStops(pickup: request.pickup, destination: request.destination),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${request.parcel.label} · ${request.parcel.weight} · $when',
            style: AppText.caption.copyWith(color: AppColors.inkAt(0.6)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.done, required this.fare});

  final bool done;
  final int fare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done ? AppColors.surface : AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.ink),
      ),
      child: Text(
        '₹$fare',
        style: AppText.badge.copyWith(
          color: done ? AppColors.ink : AppColors.surface,
        ),
      ),
    );
  }
}
