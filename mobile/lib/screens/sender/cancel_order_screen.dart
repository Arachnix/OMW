import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/omw_api.dart';
import '../../design_system.dart';
import '../../models/omw_models.dart';
import '../../state/app_state.dart';

/// "requester-order-cancellation" (Figma 164:299). Open requests are
/// refunded in full; once a courier has accepted, a flat ₹5 fee goes to them.
class CancelOrderScreen extends StatefulWidget {
  const CancelOrderScreen({super.key, required this.taskId});

  final String taskId;

  static Route<void> route(String taskId) =>
      MaterialPageRoute(builder: (_) => CancelOrderScreen(taskId: taskId));

  static const reasons = [
    'Accidental order / wrong address',
    'Delivery window is too long',
    'Driver is taking too long to arrive',
    'Changed my mind / no longer needed',
  ];

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  int _reason = 0;
  bool _busy = false;

  Future<void> _confirm(OmwTask task) async {
    setState(() => _busy = true);
    try {
      final r = await context.read<AppState>().cancelRequest(
        task,
        reason: CancelOrderScreen.reasons[_reason],
      );
      if (!mounted) return;
      showSnack(
        context,
        r.fee > 0
            ? 'Order cancelled. ₹${r.refunded} refunded, ₹${r.fee} paid to your courier.'
            : 'Order cancelled. ₹${r.refunded} refunded to your wallet.',
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = context.watch<AppState>().taskById(widget.taskId);
    if (task == null) return const Scaffold(body: SizedBox.shrink());
    final accepted = task.status == TaskStatus.claimed;
    const fee = AppState.lateCancelFee;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CenteredHeader(title: 'Cancel Order'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                children: [
                  Panel(
                    stroke: AppRadii.strokeBold,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER #${task.id}',
                          style: AppText.overline.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          task.title,
                          style: AppText.heading.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('To: ${task.dropName}', style: AppText.bodyMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    header: true,
                    child: Text(
                      'Please select a cancellation reason:',
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (
                    var i = 0;
                    i < CancelOrderScreen.reasons.length;
                    i++
                  ) ...[
                    ReasonOption(
                      label: CancelOrderScreen.reasons[i],
                      selected: _reason == i,
                      onTap: () => setState(() => _reason = i),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (accepted) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Panel(
                      color: AppColors.fillMuted,
                      stroke: AppRadii.strokeBold,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CANCELLATION POLICY WARNING',
                            style: AppText.cardEyebrow.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'A ₹$fee fee will be charged because courier '
                            '${task.runnerName ?? 'your courier'} has already '
                            'accepted and is en route. This compensates their '
                            'travel time.',
                            style: AppText.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(
                          color: AppColors.ink,
                          width: AppRadii.strokeBold,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'Keep My Order',
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PillButton(
                    height: 52,
                    busy: _busy,
                    label: accepted
                        ? 'Confirm Cancellation (₹$fee Fee)'
                        : 'Confirm Cancellation',
                    textStyle: AppText.label.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: () => _confirm(task),
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
