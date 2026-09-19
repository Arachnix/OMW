import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/omw_api.dart';
import '../../design_system.dart';
import '../../models/omw_models.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';

/// "delivery-code" (Figma 120:218) and "Delivery Code - Invalid Input" edge
/// state. Verifies the requester's code via POST /api/tasks/:id/verify-delivery,
/// which releases the escrow bounty and returns the runner's stake.
class DeliveryCodeScreen extends StatefulWidget {
  const DeliveryCodeScreen({super.key, required this.taskId});

  final String taskId;

  static Route<void> route(String taskId) =>
      MaterialPageRoute(builder: (_) => DeliveryCodeScreen(taskId: taskId));

  /// Wrong attempts allowed before the screen locks (client-side guard).
  static const maxAttempts = 3;

  @override
  State<DeliveryCodeScreen> createState() => _DeliveryCodeScreenState();
}

class _DeliveryCodeScreenState extends State<DeliveryCodeScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  int _failures = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Let the requester know the courier is at the drop-off.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      final t = s.taskById(widget.taskId);
      if (t != null) s.announceArrival(t);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _locked => _failures >= DeliveryCodeScreen.maxAttempts;

  Future<void> _verify(OmwTask task) async {
    if (_code.text.length != 4 || _busy || _locked) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().verifyDelivery(task, _code.text);
      if (!mounted) return;
      showSnack(context, 'Delivered! ₹${task.wager} added to your earnings.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.isNetwork) {
          _error = e.message;
        } else {
          _failures++;
          final left = DeliveryCodeScreen.maxAttempts - _failures;
          _error = left > 0
              ? 'The entered code does not match. $left attempt${left == 1 ? '' : 's'} remaining before route locks.'
              : 'Too many wrong codes. Contact support to unlock this delivery.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = context.watch<AppState>().taskById(widget.taskId);
    if (task == null) return const Scaffold(body: SizedBox.shrink());
    final invalid = _error != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                children: [
                  Row(
                    children: [
                      Tooltip(
                        message: 'Back',
                        child: InkResponse(
                          onTap: () => Navigator.of(context).pop(),
                          radius: 28,
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
                            child: const SvgIcon(Lucide.chevronLeft, size: 22),
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => showInfo(
                          context,
                          'Delivery code',
                          'The requester sees a 4-digit code on their Order '
                              'Details screen. Enter it to complete the '
                              'delivery; your bounty and stake are released '
                              'instantly.',
                        ),
                        icon: const SvgIcon(Lucide.circleHelp, size: 18),
                        label: Text(
                          'Help',
                          style: AppText.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(
                            color: AppColors.ink,
                            width: AppRadii.strokeBold,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'DELIVERY #${task.id}',
                    style: AppText.overline.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    header: true,
                    child: Text(
                      'Enter Delivery Code',
                      style: AppText.headingLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ask the requester for the 4-digit code to complete this delivery.',
                    style: AppText.bodyMuted.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _RouteSummary(task: task),
                  const SizedBox(height: AppSpacing.xl),
                  OtpBoxes(
                    controller: _code,
                    error: invalid,
                    enabled: !_locked,
                    onCompleted: (_) => _verify(task),
                  ),
                  if (invalid) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ErrorBlock(
                      title: 'Invalid Verification Code',
                      message: _error!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PillButton(
                    label: 'Verify Delivery',
                    height: 52,
                    busy: _busy,
                    textStyle: AppText.label.copyWith(
                      color: AppColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: _code.text.length == 4 && !_locked
                        ? () => _verify(task)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => showSnack(
                        context,
                        'QR scanning needs the camera. Enter the code for now.',
                      ),
                      icon: const SvgIcon(Lucide.scanQrCode, size: 20),
                      label: Text(
                        'Scan QR Instead',
                        style: AppText.label.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(
                          color: AppColors.ink,
                          width: AppRadii.strokeBold,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Panel(
                    color: AppColors.fillMuted,
                    stroke: AppRadii.strokeBold,
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Row(
                      children: [
                        const SvgIcon(Lucide.circleAlert, size: 20),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Can\'t get the code? Ask the requester to check their app.',
                            style: AppText.body,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () {
                            context.read<AppState>().announceArrival(task);
                            showSnack(
                              context,
                              '${task.requesterName} was pinged to open their code.',
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.field,
                              ),
                            ),
                          ),
                          child: Text(
                            'Message',
                            style: AppText.badge.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Stepper(status: task.status),
          ],
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.task});

  final OmwTask task;

  @override
  Widget build(BuildContext context) {
    Widget stop(String title, String detail) => Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.ink,
              width: AppRadii.strokeBold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.label.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(detail, style: AppText.labelSmall.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
    return Panel(
      stroke: AppRadii.strokeBold,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  stop(task.shortPickup, '${task.categoryLabel} · 1 item'),
                  const SizedBox(height: AppSpacing.md),
                  stop(task.shortDrop, 'Drop-off'),
                ],
              ),
            ),
            const VerticalDivider(color: AppColors.divider, width: 20),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('YOUR EARNINGS', style: AppText.overline),
                  Text('₹${task.wager}', style: AppText.displayStat),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fillMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgIcon(task.parcel.icon, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          task.parcel.label,
                          style: AppText.labelSmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Accepted › Picked Up › On Way › Delivered" footer.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final reached = switch (status) {
      TaskStatus.claimed => 1,
      TaskStatus.inTransit => 3,
      TaskStatus.delivered => 4,
      _ => 0,
    };
    const steps = ['Accepted', 'Picked Up', 'On Way', 'Delivered'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.ink, width: AppRadii.strokeBold),
        ),
      ),
      child: Semantics(
        label: 'Progress: ${steps.take(reached).join(', ')} done',
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SvgIcon(
                      Lucide.chevronRight,
                      size: 14,
                      color: AppColors.inkAt(0.6),
                    ),
                  ),
                if (i < reached)
                  const SvgIcon(Lucide.circleCheck, size: 16)
                else
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.inkAt(0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Text(
                  steps[i],
                  style: AppText.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: i < reached ? AppColors.ink : AppColors.inkAt(0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
