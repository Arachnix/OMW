import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/omw_api.dart';
import '../design_system.dart';
import '../models/omw_models.dart';
import '../models/order_model.dart';
import '../state/app_state.dart';
import 'order_details_screen.dart';
import 'order_notice_sheets.dart';
import 'sender/cancel_order_screen.dart';

/// Sender "Activity" tab: Figma "activity_orders" (86:497), with the
/// "Activity - Empty State" edge frame when there are no requests.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final active = state.activeRequests;
    final past = state.pastRequests;

    if (active.isEmpty && past.isEmpty) {
      return _EmptyActivity(onCreate: () => state.setSenderTab(SenderTab.home));
    }

    final accepted = active.where((t) => t.status != TaskStatus.open).toList();
    final waiting = active.where((t) => t.status == TaskStatus.open).toList();

    return Column(
      children: [
        AppHeader(
          onMascotTap: state.goToLanding,
          onAvatarTap: state.openAccount,
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.ink,
            onRefresh: state.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.ink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sender Activity',
                                style: AppText.label.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Semantics(
                            header: true,
                            child: Text(
                              'Pending Orders',
                              style: AppText.heading.copyWith(fontSize: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (waiting.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '${waiting.length} waiting',
                          style: AppText.badge.copyWith(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final t in accepted) ...[
                  _AcceptedBanner(task: t),
                  const SizedBox(height: AppSpacing.lg),
                ],
                for (final t in waiting) ...[
                  _WaitingCard(task: t),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (active.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Text(
                      'No active requests right now.',
                      style: AppText.bodyMuted,
                    ),
                  ),
                if (past.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const SectionLabel('PAST ORDERS'),
                  MenuGroup(
                    children: [
                      for (final t in past.take(20)) _PastRow(task: t),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Order Accepted & on Route — Track Live" banner.
class _AcceptedBanner extends StatelessWidget {
  const _AcceptedBanner({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    final picked = task.status == TaskStatus.inTransit;
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      radius: AppRadii.tile,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).push(OrderDetailsScreen.route(task.id)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.fillMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inkAt(0.6), width: 2.5),
              ),
              child: const SvgIcon(Lucide.check, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picked ? 'Package Picked Up' : 'Order Accepted & on Route',
                    style: AppText.label.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${task.runnerName ?? 'Your courier'} is on the way',
                    style: AppText.body,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () => presentTracking(context, task),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.surface,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Track Live',
                style: AppText.badge.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Waiting for courier.." card with price, cancel and +₹5 increase.
class _WaitingCard extends StatefulWidget {
  const _WaitingCard({required this.task});

  final OmwTask task;

  @override
  State<_WaitingCard> createState() => _WaitingCardState();
}

class _WaitingCardState extends State<_WaitingCard> {
  bool _busy = false;

  Future<void> _surge() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final t = await context.read<AppState>().surge(widget.task);
      if (mounted) showSnack(context, 'Offer raised to ₹${t.wager}.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Panel(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      radius: 24,
      stroke: AppRadii.strokeBold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppRadii.strokeBold,
                ),
              ),
              child: Text(
                'Waiting for courier..',
                style: AppText.chip.copyWith(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            label: 'Current offered price ₹${task.wager}',
            excludeSemantics: true,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'CURRENT OFFERED PRICE',
                    style: AppText.label.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AnimatedSwitcher(
                  duration: AppMotion.medium,
                  child: Text(
                    '₹${task.wager}',
                    key: ValueKey(task.wager),
                    style: AppText.price,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SplitActionPill(
            left: (
              icon: Lucide.x,
              label: 'Cancel Order',
              onTap: () =>
                  Navigator.of(context).push(CancelOrderScreen.route(task.id)),
            ),
            right: (
              icon: Lucide.handCoins,
              label: _busy ? 'Raising…' : '+₹${AppState.surgeStep} Increase',
              onTap: _surge,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.ink, thickness: 2, height: 2),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${task.parcel.label} (${task.parcel.weight})',
            style: AppText.bodyMuted.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.md),
          TrackStop(
            lead: const SvgIcon(AppIcons.mapPin, size: 20),
            title: 'Pickup Spot',
            address: task.pickupName,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: CustomPaint(size: Size(2, 36), painter: DotsPainter()),
            ),
          ),
          TrackStop(
            lead: const TargetMarker(),
            title: 'Delivery Destination',
            address: task.dropName,
          ),
        ],
      ),
    );
  }
}

class _PastRow extends StatelessWidget {
  const _PastRow({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM, h:mm a').format(task.createdAt);
    final delivered = task.status == TaskStatus.delivered;
    return MenuRow(
      icon: delivered ? Lucide.circleCheck : Lucide.circleX,
      title: '${task.shortPickup} → ${task.shortDrop}',
      subtitle:
          '${delivered ? 'Delivered' : 'Cancelled'} · ₹${task.wager} · $when',
      onTap: () =>
          Navigator.of(context).push(OrderDetailsScreen.route(task.id)),
    );
  }
}

/// Edge state 1: "Your Activity / No Orders Yet".
class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Your Activity', style: AppText.displayTitle),
            ),
            Text('TRACK YOUR REQUESTS', style: AppText.displayEyebrow),
            const Spacer(),
            Center(
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.panel),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.stroke,
                  ),
                ),
                child: const SvgIcon(AppIcons.box, size: 52),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Orders Yet',
              textAlign: TextAlign.center,
              style: AppText.displayItem.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your active and past delivery requests will appear here. '
              'Need something brought to you?',
              textAlign: TextAlign.center,
              style: AppText.bodyMuted,
            ),
            const Spacer(flex: 2),
            DisplayButton(label: 'Place Delivery Request', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}
