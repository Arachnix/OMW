import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/omw_api.dart';
import '../design_system.dart';
import '../models/omw_models.dart';
import '../models/order_model.dart';
import '../state/app_state.dart';
import '../utils/geo.dart';
import 'order_details_screen.dart';
import 'runner/reject_assignment_screen.dart';

/// Notification sheets (Figma "notification-order-accepted" frames):
/// - 164:116 Order Accepted!        (sender, courier claimed)
/// - 164:267 Package Secured        (sender, pickup verified)
/// - 163:182 Delivery Arrived!      (sender, courier at drop-off)
/// - 163:76  Order Cancelled        (sender, courier dropped the job)
/// - 163:129 Along-Your-Route!      (courier, new task near the route)
/// - 163:315 On the way to Pickup   (sender, live tracking)
/// plus the courier's acceptance confirmation.
///
/// Figma shows these over a live map; the app has no map tiles, so they open
/// over the current screen behind [AppColors.scrim].

enum _Action {
  track,
  searchNew,
  dashboard,
  contact,
  details,
  call,
  handoff,
  accept,
  decline,
  startDelivery,
  drop,
}

/// Watches [AppState.pendingNotice] and presents notices one at a time over
/// the app shell. Closing a sheet in any way dismisses its notice.
class NoticeHost extends StatefulWidget {
  const NoticeHost({super.key, required this.child});

  final Widget child;

  @override
  State<NoticeHost> createState() => _NoticeHostState();
}

class _NoticeHostState extends State<NoticeHost> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    final notice = context.select<AppState, AppNotice?>((s) => s.pendingNotice);
    if (notice != null && !_showing) {
      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await presentNotice(context, notice);
        if (!mounted) return;
        setState(() => _showing = false);
      });
    }
    return widget.child;
  }
}

Future<void> presentNotice(BuildContext context, AppNotice notice) async {
  final state = context.read<AppState>();
  final task = state.taskById(notice.task.id) ?? notice.task;
  final action = await showNoticeSheet<_Action>(
    context,
    builder: (_) => switch (notice.kind) {
      NoticeKind.accepted => _AcceptedSheet(task: task),
      NoticeKind.pickedUp => _SecuredSheet(task: task),
      NoticeKind.arrived => _ArrivedSheet(task: task),
      NoticeKind.cancelledByCourier => _CancelledSheet(task: task),
      NoticeKind.alongRoute => _AlongRouteSheet(notice: notice, task: task),
      NoticeKind.delivered => _AcceptedSheet(task: task),
    },
  );
  state.dismissNotice(notice);
  if (!context.mounted) return;
  switch (action) {
    case _Action.track:
      await presentTracking(context, task);
    case _Action.searchNew:
      showSnack(context, 'Your request is back on the courier feed.');
    case _Action.dashboard:
      state.setSenderTab(SenderTab.home);
    case _Action.call:
      showSnack(context, 'Calling is simulated in this demo.');
    case _Action.handoff:
      await Navigator.of(context).push(OrderDetailsScreen.route(task.id));
    case _Action.accept:
      await acceptTask(context, task);
    default:
      break;
  }
}

/// Claims [task] for the courier and shows the confirmation sheet.
Future<void> acceptTask(BuildContext context, OmwTask task) async {
  final state = context.read<AppState>();
  try {
    final claimed = await state.claim(task);
    if (!context.mounted) return;
    await presentCourierAccepted(context, claimed);
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message);
  }
}

Future<void> presentTracking(BuildContext context, OmwTask task) async {
  final action = await showNoticeSheet<_Action>(
    context,
    builder: (_) => _TrackingSheet(taskId: task.id),
  );
  if (!context.mounted) return;
  switch (action) {
    case _Action.contact:
      showSnack(context, 'Calling is simulated in this demo.');
    case _Action.details:
      await Navigator.of(context).push(OrderDetailsScreen.route(task.id));
    default:
      break;
  }
}

/// Courier side, right after a successful claim.
Future<void> presentCourierAccepted(BuildContext context, OmwTask task) async {
  final state = context.read<AppState>();
  final action = await showNoticeSheet<_Action>(
    context,
    builder: (_) => _CourierAcceptedSheet(task: task),
  );
  if (!context.mounted) return;
  switch (action) {
    case _Action.startDelivery:
      state.setCourierTab(CourierTab.activity);
    case _Action.drop:
      await Navigator.of(context).push(RejectAssignmentScreen.route(task.id));
    default:
      break;
  }
}

String _first(String? name) => (name ?? 'Courier').split(' ').first;

// Sheets ---------------------------------------------------------------------

class _AcceptedSheet extends StatelessWidget {
  const _AcceptedSheet({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    return NoticeSheet(
      children: [
        NoticeHeader(
          icon: const SvgIcon(Lucide.check, color: AppColors.surface, size: 24),
          title: 'Order Accepted!',
          subtitle:
              'Pickup partner ${task.runnerName ?? 'a campus runner'} is on the way.',
        ),
        const NoticeRule(),
        OrderSummaryCard(task: task),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: 'View Live Tracking',
          onPressed: () => Navigator.of(context).pop(_Action.track),
        ),
      ],
    );
  }
}

class _SecuredSheet extends StatelessWidget {
  const _SecuredSheet({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    final minutes = Geo.walkMinutes(
      Geo.walkMeters(
        task.pickupLat,
        task.pickupLng,
        task.dropLat,
        task.dropLng,
      ),
    );
    final eta = DateFormat('h:mm a').format(
      (task.pickedUpAt ?? DateTime.now()).add(Duration(minutes: minutes)),
    );
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: AppText.bodyMuted.copyWith(fontSize: 16)),
          ),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: AppText.label.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return NoticeSheet(
      children: [
        NoticeHeader(
          filled: false,
          icon: const SvgIcon(AppIcons.box, size: 24),
          title: 'Package Secured',
          subtitle:
              '${task.runnerName ?? 'Your courier'} has successfully picked up your item.',
        ),
        const NoticeRule(),
        row('Next Step:', 'In Transit to ${task.shortDrop}'),
        row('Estimated Delivery:', eta),
        const SizedBox(height: AppSpacing.sm),
        PillButton(
          label: 'Track Route Live',
          onPressed: () => Navigator.of(context).pop(_Action.track),
        ),
      ],
    );
  }
}

class _ArrivedSheet extends StatelessWidget {
  const _ArrivedSheet({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    final first = _first(task.runnerName);
    return NoticeSheet(
      children: [
        NoticeHeader(
          filled: false,
          icon: const SvgIcon(Lucide.bell, size: 24),
          title: 'Delivery Arrived!',
          subtitle:
              '${task.runnerName ?? 'Your courier'} is outside with your package.',
        ),
        const NoticeRule(),
        NoticeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SECURITY DIRECTIVE', style: AppText.cardEyebrow),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Provide OTP code ${task.deliveryOtp ?? ''} to $first to '
                'unlock secure handoff of your ${task.parcel.label.toLowerCase()}.',
                style: AppText.sheetBody,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinePillButton(
                label: 'Call $first',
                onPressed: () => Navigator.of(context).pop(_Action.call),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 6,
              child: PillButton(
                label: 'View Handoff Screen',
                textStyle: AppText.buttonLarge.copyWith(
                  color: AppColors.surface,
                ),
                onPressed: () => Navigator.of(context).pop(_Action.handoff),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CancelledSheet extends StatelessWidget {
  const _CancelledSheet({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    return NoticeSheet(
      children: [
        const NoticeHeader(
          filled: false,
          icon: SvgIcon(Lucide.circleX, size: 24),
          title: 'Order Cancelled',
          subtitle: 'Your assigned courier cancelled this order.',
        ),
        const NoticeRule(),
        NoticeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REASON FOR CANCELLATION', style: AppText.cardEyebrow),
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.dropReason ?? 'Courier unable to continue',
                style: AppText.orderValueStrong,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No cancellation fee applies. We are automatically looking '
                'for a replacement partner.',
                style: AppText.sheetBody,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: 'Search New Partner',
          textStyle: AppText.buttonLarge.copyWith(color: AppColors.surface),
          onPressed: () => Navigator.of(context).pop(_Action.searchNew),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinePillButton(
          label: 'Return to Dashboard',
          onPressed: () => Navigator.of(context).pop(_Action.dashboard),
        ),
      ],
    );
  }
}

class _AlongRouteSheet extends StatelessWidget {
  const _AlongRouteSheet({required this.notice, required this.task});

  final AppNotice notice;
  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    final km = (notice.detourKm ?? 0).toStringAsFixed(1);
    return NoticeSheet(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NoticeHeader(
                icon: const SvgIcon(
                  Lucide.shuffle,
                  color: AppColors.surface,
                  size: 24,
                ),
                title: 'Along-Your-Route!',
                subtitle: 'Only $km km extra deviation.',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadii.field),
              ),
              child: Text(
                '+₹${task.wager}',
                style: AppText.sheetTitle.copyWith(color: AppColors.surface),
              ),
            ),
          ],
        ),
        const NoticeRule(),
        Row(
          children: [
            Expanded(
              child: Text(
                'ORDER #${task.id} (ADD-ON)',
                style: AppText.orderMeta.copyWith(fontSize: 13),
              ),
            ),
            const SvgIcon(Lucide.clock, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '+${notice.detourMinutes ?? 0} mins total',
              style: AppText.orderMeta.copyWith(
                color: AppColors.ink,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('1x ${task.title}', style: AppText.orderValueStrong),
        const SizedBox(height: AppSpacing.sm),
        NoticeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.pickupName, style: AppText.orderValue),
              const SizedBox(height: AppSpacing.sm),
              Text(task.dropName, style: AppText.orderValue),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinePillButton(
                label: 'Decline',
                onPressed: () => Navigator.of(context).pop(_Action.decline),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 7,
              child: PillButton(
                label: 'Accept & Add to Route',
                textStyle: AppText.buttonLarge.copyWith(
                  color: AppColors.surface,
                ),
                onPressed: () => Navigator.of(context).pop(_Action.accept),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CourierAcceptedSheet extends StatelessWidget {
  const _CourierAcceptedSheet({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    return NoticeSheet(
      children: [
        NoticeHeader(
          icon: const SvgIcon(Lucide.check, color: AppColors.surface, size: 24),
          title: 'Delivery Accepted!',
          subtitle:
              'Head to ${task.shortPickup}. ${task.requesterName} has been notified.',
        ),
        const NoticeRule(),
        OrderSummaryCard(task: task),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your ₹${task.runnerStake} commitment stake is locked until delivery.',
          style: AppText.sheetBody,
        ),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: 'Start Delivery',
          onPressed: () => Navigator.of(context).pop(_Action.startDelivery),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinePillButton(
          label: 'Drop Assignment',
          onPressed: () => Navigator.of(context).pop(_Action.drop),
        ),
      ],
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final task = context.watch<AppState>().taskById(taskId);
    if (task == null) return const SizedBox.shrink();
    final toDrop = Geo.walkMinutes(
      Geo.walkMeters(
        task.pickupLat,
        task.pickupLng,
        task.dropLat,
        task.dropLng,
      ),
    );
    final (title, eta) = switch (task.status) {
      TaskStatus.inTransit => (
        'On the way to you',
        'ETA: $toDrop minutes to delivery',
      ),
      TaskStatus.delivered => ('Delivered', 'Handed over at ${task.shortDrop}'),
      TaskStatus.open => (
        'Waiting for a courier',
        'Your request is on the feed',
      ),
      TaskStatus.cancelled => (
        'Order cancelled',
        'Escrow refunded to your wallet',
      ),
      TaskStatus.claimed => (
        'On the way to Pickup',
        'ETA: ${toDrop + 5} minutes to delivery',
      ),
    };
    return NoticeSheet(
      showHandle: false,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.field),
              border: Border.all(
                color: AppColors.ink,
                width: AppRadii.strokeBold,
              ),
            ),
            child: Text('Order ID: #${task.id}', style: AppText.chip),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.fillButton,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink,
                  width: AppRadii.strokeBold,
                ),
              ),
              child: SvgIcon(
                AppIcons.userRound,
                size: 24,
                color: AppColors.inkAt(0.6),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Courier: ${task.runnerName ?? 'Not assigned'}',
                    style: AppText.orderValueStrong,
                  ),
                  Text(
                    task.runnerName == null
                        ? 'Waiting for match'
                        : 'ID Verified',
                    style: AppText.sheetBody,
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Fare ₹${task.wager}',
              excludeSemantics: true,
              child: Text('₹${task.wager}', style: AppText.price),
            ),
          ],
        ),
        const NoticeRule(),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(title, style: AppText.trackingTitle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(eta, style: AppText.sheetBody),
        const SizedBox(height: AppSpacing.lg),
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
        const NoticeRule(),
        SplitActionPill(
          left: (
            icon: Lucide.phone,
            label: 'Contact Courier',
            onTap: () => Navigator.of(context).pop(_Action.contact),
          ),
          right: (
            icon: AppIcons.truck,
            label: 'View Order Details',
            onTap: () => Navigator.of(context).pop(_Action.details),
          ),
        ),
      ],
    );
  }
}

// Shared parts ---------------------------------------------------------------

/// "ORDER #… / ₹… / item / PICKUP / DELIVERY" card from 164:116.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    return NoticeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('ORDER #${task.id}', style: AppText.orderMeta),
              ),
              Text(
                '₹${task.wager}',
                style: AppText.orderMeta.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${task.parcel.label} · ${task.parcel.weight}',
            style: AppText.orderValue,
          ),
          const SizedBox(height: AppSpacing.md),
          NoticeStop(
            marker: StopMarker.dot,
            label: 'PICKUP',
            value: task.pickupName,
          ),
          const SizedBox(height: AppSpacing.md),
          NoticeStop(
            marker: StopMarker.square,
            label: 'DELIVERY',
            value: task.dropName,
          ),
        ],
      ),
    );
  }
}

class TrackStop extends StatelessWidget {
  const TrackStop({
    super.key,
    required this.lead,
    required this.title,
    required this.address,
  });

  final Widget lead;
  final String title;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $address',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Center(child: lead)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.orderValueStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  address,
                  style: AppText.sheetBody,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const SvgIcon(AppIcons.mapPin, size: 20),
        ],
      ),
    );
  }
}

/// Outlined ring with an ink centre (delivery marker).
class TargetMarker extends StatelessWidget {
  const TargetMarker({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: AppRadii.strokeBold),
      ),
      child: Container(
        width: size * 0.36,
        height: size * 0.36,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class DotsPainter extends CustomPainter {
  const DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = AppRadii.strokeBold
      ..strokeCap = StrokeCap.round;
    for (var y = 4.0; y < size.height; y += 10) {
      canvas.drawLine(Offset(1, y), Offset(1, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

typedef PillHalf = ({String icon, String label, VoidCallback onTap});

/// Black pill split into two actions ("Cancel Order | +₹5 Increase",
/// "Contact Courier | View Order Details").
class SplitActionPill extends StatelessWidget {
  const SplitActionPill({
    super.key,
    required this.left,
    required this.right,
    this.divider = true,
  });

  final PillHalf left;
  final PillHalf right;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final label = AppText.orderValueStrong.copyWith(color: AppColors.surface);
    Widget half(PillHalf h) => Expanded(
      child: Semantics(
        button: true,
        label: h.label,
        excludeSemantics: true,
        child: InkWell(
          onTap: h.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgIcon(h.icon, size: 20, color: AppColors.surface),
                  const SizedBox(width: AppSpacing.sm),
                  Text(h.label, style: label, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Material(
      color: AppColors.ink,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            half(left),
            if (divider)
              Container(width: 1.5, height: 30, color: AppColors.surface),
            half(right),
          ],
        ),
      ),
    );
  }
}
