import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/omw_api.dart';
import '../../design_system.dart';
import '../../models/omw_models.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import '../order_notice_sheets.dart';
import 'delivery_code_screen.dart';
import 'reject_assignment_screen.dart';

/// Courier "Activity" tab: accepted jobs and their next step (pickup code,
/// delivery code, drop). Not drawn in Figma; composed from the Pending
/// Orders card, stops and split-button components.
class CourierJobsScreen extends StatelessWidget {
  const CourierJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final active = state.activeJobs;
    final past = state.myJobs.where((t) => !t.status.isActive).toList();

    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        children: [
          const PageTitle(
            title: 'Your Deliveries',
            eyebrow: 'TRACK YOUR JOBS.',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.ink,
              onRefresh: state.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  if (active.isEmpty && past.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const SvgIcon(AppIcons.truck, size: 40),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'No Jobs Yet',
                            style: AppText.displayItem.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Accept a request from the feed and it will show up here.',
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          DisplayButton(
                            label: 'Find Deliveries',
                            onPressed: () =>
                                state.setCourierTab(CourierTab.feed),
                          ),
                        ],
                      ),
                    ),
                  for (final t in active) ...[
                    _JobCard(task: t),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (past.isNotEmpty) ...[
                    const SectionLabel('COMPLETED'),
                    MenuGroup(
                      children: [
                        for (final t in past.take(20))
                          MenuRow(
                            icon: t.status == TaskStatus.delivered
                                ? Lucide.circleCheck
                                : Lucide.circleX,
                            title: '${t.shortPickup} → ${t.shortDrop}',
                            subtitle:
                                '${t.status == TaskStatus.delivered ? 'Earned ₹${t.wager}' : 'Cancelled'}'
                                ' · ${DateFormat('d MMM, h:mm a').format(t.deliveredAt ?? t.createdAt)}',
                            onTap: () {},
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    final picked = task.status == TaskStatus.inTransit;
    return Panel(
      radius: 24,
      stroke: AppRadii.strokeBold,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.strokeBold,
                  ),
                ),
                child: Text(
                  picked ? 'In transit' : 'Head to pickup',
                  style: AppText.chip.copyWith(fontSize: 14),
                ),
              ),
              const Spacer(),
              Text('₹${task.wager}', style: AppText.priceCompact),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ORDER #${task.id} · ${task.parcel.label} · for ${task.requesterName}',
            style: AppText.orderMeta,
          ),
          if (task.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(task.notes, style: AppText.bodyMuted.copyWith(fontSize: 13)),
          ],
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
              child: CustomPaint(size: Size(2, 28), painter: DotsPainter()),
            ),
          ),
          TrackStop(
            lead: const TargetMarker(),
            title: 'Delivery Destination',
            address: task.dropName,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!picked)
            SplitActionPill(
              left: (
                icon: Lucide.x,
                label: 'Drop Job',
                onTap: () =>
                    Navigator.of(context)
                        .push(RejectAssignmentScreen.route(task.id)),
              ),
              right: (
                icon: AppIcons.box,
                label: 'Confirm Pickup',
                onTap: () => _confirmPickup(context, task),
              ),
            )
          else
            PillButton(
              label: 'Enter Delivery Code',
              onPressed: () =>
                  Navigator.of(context).push(DeliveryCodeScreen.route(task.id)),
            ),
        ],
      ),
    );
  }
}

/// Shows the pickup code the counter/shop checks, then verifies it
/// (POST /api/tasks/:id/verify-pickup).
Future<void> _confirmPickup(BuildContext context, OmwTask task) async {
  final state = context.read<AppState>();
  final confirmed = await showNoticeSheet<bool>(
    context,
    builder: (sheet) => NoticeSheet(
      children: [
        NoticeHeader(
          filled: false,
          icon: const SvgIcon(Lucide.store, size: 24),
          title: 'Confirm Pickup',
          subtitle:
              'Show this code at ${task.pickupName} to collect the parcel.',
        ),
        const NoticeRule(),
        Center(
          child: Semantics(
            label: 'Pickup code ${task.pickupOtp?.split('').join(' ')}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadii.tile),
              ),
              child: Text(
                task.pickupOtp ?? '----',
                style: AppText.displayAmount.copyWith(
                  color: AppColors.surface,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: 'Parcel Collected',
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await state.confirmPickup(task, task.pickupOtp ?? '');
    if (context.mounted) {
      showSnack(context, 'Pickup verified. Head to ${task.shortDrop}.');
    }
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message);
  }
}
