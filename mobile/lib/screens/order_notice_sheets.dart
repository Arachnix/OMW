import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../design_system.dart';
import '../models/order_model.dart';
import '../state/app_state.dart';
import '../widgets/notice_sheet.dart';

/// Notification sheets from the Figma "notification-order-accepted" frames:
/// - 164:116 "Order Accepted!"   → [presentSenderNotice]
/// - 163:76  "Order Cancelled"   → [presentSenderNotice]
/// - 163:315 "On the way to Pickup" → [presentTracking]
/// plus the courier's acceptance confirmation, which reuses the 164:116
/// layout with courier copy ([presentCourierAccepted]).
///
/// Figma shows these over a live map; the app has no maps, so they open over
/// the current screen behind the [AppColors.scrim] overlay.

enum _Action {
  track,
  searchNew,
  dashboard,
  contact,
  details,
  backToFeed,
  cancelJob,
}

/// Watches [AppState.pendingNotice] and presents it over the sender shell,
/// one at a time. Closing the sheet in any way dismisses the notice.
class SenderNoticeHost extends StatefulWidget {
  const SenderNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  State<SenderNoticeHost> createState() => _SenderNoticeHostState();
}

class _SenderNoticeHostState extends State<SenderNoticeHost> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    final notice = context.select<AppState, SenderNotice?>(
      (s) => s.pendingNotice,
    );
    if (notice != null && !_showing) {
      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await presentSenderNotice(context, notice);
        if (!mounted) return;
        setState(() => _showing = false);
      });
    }
    return widget.child;
  }
}

Future<void> presentSenderNotice(
  BuildContext context,
  SenderNotice notice,
) async {
  final state = context.read<AppState>();
  final action = await showNoticeSheet<_Action>(
    context,
    builder: (_) => switch (notice.kind) {
      NoticeKind.accepted => _AcceptedSheet(request: notice.request),
      NoticeKind.cancelled => _CancelledSheet(notice: notice),
    },
  );
  state.dismissNotice(notice);
  if (!context.mounted) return;
  switch (action) {
    case _Action.track:
      await presentTracking(context, notice.request);
    case _Action.searchNew:
      state.searchNewPartner(notice.request);
      _snack(context, 'Searching for a new partner');
    case _Action.dashboard:
      state.setSenderTab(SenderTab.home);
    default:
      break;
  }
}

Future<void> presentTracking(
  BuildContext context,
  DeliveryRequest request,
) async {
  final action = await showNoticeSheet<_Action>(
    context,
    builder: (_) => _TrackingSheet(request: request),
  );
  if (!context.mounted) return;
  switch (action) {
    case _Action.contact:
      _snack(context, 'Calling is simulated in this demo');
    case _Action.details:
      context.read<AppState>().setSenderTab(SenderTab.activity);
    default:
      break;
  }
}

/// Courier side: shown right after ACCEPT. [senderNotified] is true when the
/// request belongs to this device's sender (who now has a notice waiting).
Future<void> presentCourierAccepted(
  BuildContext context,
  DeliveryRequest request, {
  required bool senderNotified,
}) async {
  final action = await showNoticeSheet<_Action>(
    context,
    builder: (_) =>
        _CourierAcceptedSheet(request: request, senderNotified: senderNotified),
  );
  if (!context.mounted || action != _Action.cancelJob) return;
  context.read<AppState>().cancelAccepted(request);
  _snack(
    context,
    senderNotified
        ? 'Job cancelled. The sender has been notified.'
        : 'Job cancelled and returned to the feed.',
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// Sheets ---------------------------------------------------------------------

class _AcceptedSheet extends StatelessWidget {
  const _AcceptedSheet({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
    return NoticeSheet(
      children: [
        const NoticeHeader(
          icon: Icon(AppGlyphs.check, color: AppColors.surface, size: 24),
          title: 'Order Accepted!',
          subtitle: 'Pickup partner ${MockData.courierName} is on the way.',
        ),
        const NoticeRule(),
        _OrderCard(request: request),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: 'View Live Tracking',
          onPressed: () => Navigator.of(context).pop(_Action.track),
        ),
      ],
    );
  }
}

class _CancelledSheet extends StatelessWidget {
  const _CancelledSheet({required this.notice});

  final SenderNotice notice;

  @override
  Widget build(BuildContext context) {
    return NoticeSheet(
      children: [
        const NoticeHeader(
          filled: false,
          icon: SvgIcon(AppIcons.circleX, size: 24),
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
                notice.reason ?? MockData.cancelReason,
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

class _CourierAcceptedSheet extends StatelessWidget {
  const _CourierAcceptedSheet({
    required this.request,
    required this.senderNotified,
  });

  final DeliveryRequest request;
  final bool senderNotified;

  @override
  Widget build(BuildContext context) {
    return NoticeSheet(
      children: [
        NoticeHeader(
          icon: const Icon(AppGlyphs.check, color: AppColors.surface, size: 24),
          title: 'Delivery Accepted!',
          subtitle: senderNotified
              ? 'Head to pickup. The sender has been notified.'
              : 'Head to pickup. It is in your accepted jobs.',
        ),
        const NoticeRule(),
        _OrderCard(request: request),
        const SizedBox(height: AppSpacing.xl),
        PillButton(
          label: 'Back to Feed',
          onPressed: () => Navigator.of(context).pop(_Action.backToFeed),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinePillButton(
          label: 'Cancel Job',
          onPressed: () => Navigator.of(context).pop(_Action.cancelJob),
        ),
      ],
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
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
            child: Text('Order ID: #${request.id}', style: AppText.chip),
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
                    'Courier: ${MockData.courierShortName}',
                    style: AppText.orderValueStrong,
                  ),
                  Text('ID Verified', style: AppText.sheetBody),
                ],
              ),
            ),
            Semantics(
              label: 'Fare ₹${request.fare}',
              excludeSemantics: true,
              child: Text('₹${request.fare}', style: AppText.price),
            ),
          ],
        ),
        const NoticeRule(),
        Semantics(
          header: true,
          child: Text('On the way to Pickup', style: AppText.trackingTitle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'ETA: ${request.etaMinutes} minutes to Pickup',
          style: AppText.sheetBody,
        ),
        const SizedBox(height: AppSpacing.lg),
        _TrackStop(
          lead: const SvgIcon(AppIcons.mapPin, size: 20),
          title: 'Pickup Spot',
          address: request.pickup,
        ),
        const Padding(
          padding: EdgeInsets.only(left: 11),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CustomPaint(size: Size(2, 36), painter: _DotsPainter()),
          ),
        ),
        _TrackStop(
          lead: const _TargetMarker(),
          title: 'Delivery Destination',
          address: request.destination,
        ),
        const NoticeRule(),
        _SplitActionPill(
          onContact: () => Navigator.of(context).pop(_Action.contact),
          onDetails: () => Navigator.of(context).pop(_Action.details),
        ),
      ],
    );
  }
}

// Parts ----------------------------------------------------------------------

/// "ORDER #… / ₹… / item / PICKUP / DELIVERY" card from 164:116.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
    return NoticeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('ORDER #${request.id}', style: AppText.orderMeta),
              ),
              Text(
                '₹${request.fare}',
                style: AppText.orderMeta.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${request.parcel.label} · ${request.parcel.weight}',
            style: AppText.orderValue,
          ),
          const SizedBox(height: AppSpacing.md),
          NoticeStop(
            marker: StopMarker.dot,
            label: 'PICKUP',
            value: request.pickup,
          ),
          const SizedBox(height: AppSpacing.md),
          NoticeStop(
            marker: StopMarker.square,
            label: 'DELIVERY',
            value: request.destination,
          ),
        ],
      ),
    );
  }
}

class _TrackStop extends StatelessWidget {
  const _TrackStop({
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

/// Outlined ring with an ink centre (delivery marker in 163:315).
class _TargetMarker extends StatelessWidget {
  const _TargetMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: AppRadii.strokeBold),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

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

/// Black pill split into "Contact Courier" and "View Order Details".
class _SplitActionPill extends StatelessWidget {
  const _SplitActionPill({required this.onContact, required this.onDetails});

  final VoidCallback onContact;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final label = AppText.orderValueStrong.copyWith(color: AppColors.surface);
    Widget half(Widget icon, String text, VoidCallback onTap) => Expanded(
      child: Semantics(
        button: true,
        label: text,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            // Scale the label down rather than truncating on narrow phones.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.sm),
                  Text(text, style: label, maxLines: 1),
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
            half(
              const Icon(AppGlyphs.phone, color: AppColors.surface, size: 20),
              'Contact Courier',
              onContact,
            ),
            half(
              const SvgIcon(AppIcons.truck, size: 20, color: AppColors.surface),
              'View Order Details',
              onDetails,
            ),
          ],
        ),
      ),
    );
  }
}
