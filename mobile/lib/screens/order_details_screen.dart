import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system.dart';
import '../models/omw_models.dart';
import '../state/app_state.dart';
import '../utils/geo.dart';
import 'sender/cancel_order_screen.dart';

/// "order-details-otp" (Figma 164:43): live status, route, the delivery
/// handoff code, courier and package details for one of the sender's
/// requests.
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.taskId});

  final String taskId;

  static Route<void> route(String taskId) =>
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(taskId: taskId));

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Pull the freshest copy (OTP, runner) from the server.
    context.read<AppState>().reloadTask(widget.taskId).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final task = context.watch<AppState>().taskById(widget.taskId);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            CenteredHeader(
              title: 'Order Details',
              underline: true,
              trailing: task == null
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${task.id}',
                        style: AppText.badge.copyWith(fontSize: 13),
                      ),
                    ),
            ),
            Expanded(
              child: task == null
                  ? const Center(child: CircularProgressIndicator())
                  : _Body(task: task),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.task});

  final OmwTask task;

  (String, String) get _status {
    final toDrop = Geo.walkMinutes(
      Geo.walkMeters(
        task.pickupLat,
        task.pickupLng,
        task.dropLat,
        task.dropLng,
      ),
    );
    return switch (task.status) {
      TaskStatus.open => ('LIVE STATUS', 'Waiting for a courier'),
      TaskStatus.claimed => ('LIVE STATUS', 'Partner heading to pickup'),
      TaskStatus.inTransit => (
        'LIVE STATUS',
        'Partner Arriving in $toDrop mins',
      ),
      TaskStatus.delivered => ('STATUS', 'Delivered'),
      TaskStatus.cancelled => ('STATUS', 'Order cancelled'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (label, value) = _status;
    final canCancel =
        task.status == TaskStatus.open || task.status == TaskStatus.claimed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Panel(
          color: AppColors.fillMuted,
          stroke: AppRadii.strokeBold,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.overline.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        value,
                        style: AppText.heading.copyWith(fontSize: 19),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.strokeBold,
                  ),
                ),
                child: const SvgIcon(AppIcons.truck, size: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Panel(
          stroke: AppRadii.strokeBold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROUTE SUMMARY',
                style: AppText.overline.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              _Stop(square: false, label: 'PICKUP', value: task.pickupName),
              const SizedBox(height: AppSpacing.md),
              _Stop(square: true, label: 'DELIVERY', value: task.dropName),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Panel(
          stroke: AppRadii.strokeBold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SECURE HANDOFF VERIFICATION',
                style: AppText.overline.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Provide this code to courier on delivery:',
                      style: AppText.label.copyWith(
                        color: AppColors.inkAt(0.6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Semantics(
                    label:
                        'Delivery code ${task.deliveryOtp?.split('').join(' ')}',
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                      child: Text(
                        task.deliveryOtp ?? '----',
                        style: AppText.heading.copyWith(
                          color: AppColors.surface,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (task.runnerName != null) ...[
          Panel(
            stroke: AppRadii.strokeBold,
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    AppImages.courierPhoto,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    semanticLabel: 'Courier ${task.runnerName}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.runnerName!,
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('OMW Campus Runner', style: AppText.bodyMuted),
                    ],
                  ),
                ),
                _RoundAction(
                  icon: Lucide.phone,
                  label: 'Call ${task.runnerName}',
                ),
                const SizedBox(width: AppSpacing.sm),
                _RoundAction(
                  icon: Lucide.messageSquare,
                  label: 'Message ${task.runnerName}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Panel(
          stroke: AppRadii.strokeBold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PACKAGE & SERVICE',
                style: AppText.overline.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              _Row('Category', task.categoryLabel),
              _Row('Content', task.title),
              if (task.notes.isNotEmpty) _Row('Notes', task.notes),
              const Divider(color: AppColors.ink, thickness: 2, height: 20),
              _Row('Delivery Fee', '₹${task.wager}'),
            ],
          ),
        ),
        const SizedBox(height: 40),
        if (canCancel)
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).push(CancelOrderScreen.route(task.id)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(
                  color: AppColors.ink,
                  width: AppRadii.strokeBold,
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Cancel Order',
                style: AppText.label.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.square, required this.label, required this.value});

  final bool square;
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.ink,
                width: AppRadii.strokeBold,
              ),
            ),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.ink,
                shape: square ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: square ? BorderRadius.circular(1.5) : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.overline.copyWith(fontSize: 13)),
                Text(
                  value,
                  style: AppText.label.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.k, this.v);

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: AppText.label.copyWith(color: AppColors.inkAt(0.6))),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: AppText.label.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => showSnack(
            context,
            'Calling and chat are simulated in this demo.',
          ),
          radius: 26,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.ink,
                width: AppRadii.strokeBold,
              ),
            ),
            child: SvgIcon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}
