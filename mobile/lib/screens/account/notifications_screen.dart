import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../design_system.dart';
import '../../models/omw_models.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import '../order_details_screen.dart';

/// "Notifications" (Figma 172:64): live order updates received over the
/// WebSocket this session, plus a verification reminder for active requests.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final log = state.notificationLog;
    final needCode = state.myRequests
        .where(
          (t) =>
              t.status == TaskStatus.claimed ||
              t.status == TaskStatus.inTransit,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            PageTitle(
              title: 'Notifications',
              eyebrow: 'ORDER UPDATES.',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: log.isEmpty && needCode.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SvgIcon(Lucide.bell, size: 36),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'You\'re all caught up',
                              style: AppText.label.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Courier updates for your orders will show up here.',
                              textAlign: TextAlign.center,
                              style: AppText.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        for (final t in needCode) ...[
                          _Tile(
                            icon: Lucide.info,
                            filled: false,
                            title: 'Secure Verification Required',
                            body:
                                'Please provide your OTP ${t.deliveryOtp ?? ''} '
                                'to the courier upon delivery.',
                            onTap: () =>
                                Navigator.of(context)
                                    .push(OrderDetailsScreen.route(t.id)),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        for (final n in log) ...[
                          _Tile(
                            icon: switch (n.kind) {
                              NoticeKind.accepted ||
                              NoticeKind.delivered => Lucide.check,
                              NoticeKind.pickedUp => AppIcons.box,
                              NoticeKind.arrived => Lucide.bell,
                              NoticeKind.cancelledByCourier =>
                                Lucide.circleAlert,
                              NoticeKind.alongRoute => Lucide.clock,
                            },
                            filled:
                                n.kind == NoticeKind.accepted ||
                                n.kind == NoticeKind.delivered,
                            title: n.title,
                            body:
                                '${n.body} · ${DateFormat('h:mm a').format(n.at)}',
                            onDismiss: () => state.removeFromLog(n),
                            onTap: n.task.requesterId == state.userId
                                ? () => Navigator.of(context)
                                      .push(OrderDetailsScreen.route(n.task.id))
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.filled,
    required this.title,
    required this.body,
    this.onDismiss,
    this.onTap,
  });

  final String icon;
  final bool filled;
  final String title;
  final String body;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(
          color: AppColors.ink,
          width: AppRadii.strokeBold,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled ? AppColors.ink : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.strokeBold,
                  ),
                ),
                child: SvgIcon(
                  icon,
                  size: 22,
                  color: filled ? AppColors.surface : AppColors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.label.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(body, style: AppText.bodyMuted),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: onDismiss,
                  icon: SvgIcon(
                    Lucide.x,
                    size: 20,
                    color: AppColors.inkAt(0.7),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
