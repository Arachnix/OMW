import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/omw_api.dart';
import '../../design_system.dart';
import '../../state/app_state.dart';

/// "pickup-partner-order-cancellation" (Figma 164:343). Dropping an accepted
/// job slashes the runner's stake and lowers their trust score by 1.5%
/// (POST /api/tasks/:id/drop); the task goes back on the feed.
class RejectAssignmentScreen extends StatefulWidget {
  const RejectAssignmentScreen({super.key, required this.taskId});

  final String taskId;

  static Route<void> route(String taskId) =>
      MaterialPageRoute(builder: (_) => RejectAssignmentScreen(taskId: taskId));

  static const reasons = [
    'Vehicle breakdown / medical emergency',
    'Package size exceeds vehicle space',
    'Pickup location is closed / incorrect',
    'Unforeseen traffic block / road closure',
  ];

  @override
  State<RejectAssignmentScreen> createState() => _RejectAssignmentScreenState();
}

class _RejectAssignmentScreenState extends State<RejectAssignmentScreen> {
  int _reason = 0;
  bool _busy = false;

  Future<void> _confirm() async {
    final state = context.read<AppState>();
    final task = state.taskById(widget.taskId);
    if (task == null) return;
    setState(() => _busy = true);
    try {
      await state.dropJob(task, RejectAssignmentScreen.reasons[_reason]);
      if (!mounted) return;
      showSnack(
        context,
        'Assignment dropped. The request is back on the feed.',
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = context.watch<AppState>().taskById(widget.taskId);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CenteredHeader(title: 'Reject Assignment'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                children: [
                  Panel(
                    color: AppColors.fillMuted,
                    stroke: AppRadii.strokeBold,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SvgIcon(Lucide.triangleAlert, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Reliability Alert',
                              style: AppText.label.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Cancellations after acceptance drop your reliability '
                          'score and forfeit your ₹${task?.runnerStake ?? 0} stake. '
                          'Consistently dropping accepted jobs can lead to '
                          'temporary account suspension.',
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Semantics(
                    header: true,
                    child: Text(
                      'Reason for dropping job #${widget.taskId}:',
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (
                    var i = 0;
                    i < RejectAssignmentScreen.reasons.length;
                    i++
                  ) ...[
                    ReasonOption(
                      label: RejectAssignmentScreen.reasons[i],
                      selected: _reason == i,
                      filledSelection: false,
                      onTap: () => setState(() => _reason = i),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Panel(
                    stroke: AppRadii.strokeBold,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Experiencing App/GPS issues?',
                                style: AppText.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Our dispatch support is online.',
                                style: AppText.bodyMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () => showSnack(
                            context,
                            'Calling support is simulated in this demo.',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: AppColors.surface,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.tile,
                              ),
                            ),
                          ),
                          child: Text(
                            'Call Support',
                            style: AppText.label.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        'Stay On Assignment',
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
                    label: 'Confirm Drop (-1.5% Reliability)',
                    textStyle: AppText.label.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: task == null ? null : _confirm,
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
