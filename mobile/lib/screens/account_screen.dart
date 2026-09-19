import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system.dart';
import '../state/app_state.dart';
import 'account/account_pages.dart';
import 'account/notifications_screen.dart';

/// "account" (Figma 125:6). Profile, stats and settings for both roles; the
/// profile comes from GET /api/users/:id.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    void push(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        children: [
          PageTitle(
            title: 'Account',
            eyebrow: 'GOOD FOOD. LESS WAIT.',
            trailing: SquareIconButton(
              icon: Lucide.settings,
              tooltip: 'App settings',
              onTap: () => push(const AppSettingsScreen()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.ink,
              onRefresh: state.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Semantics(
                    button: true,
                    label: 'Profile, ${user?.name ?? ''}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.panel),
                      onTap: () => push(const PreferencesScreen()),
                      child: Panel(
                        radius: AppRadii.panel,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: AppRadii.stroke,
                                ),
                              ),
                              child: Image.asset(
                                AppImages.mascotAvatar,
                                width: 48,
                                height: 48,
                                excludeFromSemantics: true,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Student',
                                    style: AppText.displayItem.copyWith(
                                      fontSize: 19,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _VerifiedChip(
                                    restricted: user?.isRestricted ?? false,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'VIT Vellore${user?.hostelBlock.isNotEmpty == true ? ' · ${user!.hostelBlock}' : ''}',
                                    style: AppText.bodyMuted.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    '"On my way to a more connected campus."',
                                    style: AppText.labelSmall.copyWith(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SvgIcon(Lucide.chevronRight, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (user?.restrictionNotice != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    InlineError(user!.restrictionNotice!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StatCard(
                            value: '${state.deliveriesCompleted}',
                            label: 'Deliveries',
                            caption: 'Completed',
                            icon: AppIcons.box,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            value: '${state.myRequests.length}',
                            label: 'Requests',
                            caption: 'Placed',
                            icon: Lucide.shoppingBag,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatCard(
                            value: (user?.trustScore ?? 5).toStringAsFixed(1),
                            label: 'Trust Rating',
                            caption: 'Out of 5',
                            icon: Lucide.star,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MenuGroup(
                    children: [
                      MenuRow(
                        icon: Lucide.wallet,
                        title: 'Wallet & Earnings',
                        subtitle: 'Balance, withdraw, transaction history',
                        onTap: state.openWallet,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MenuGroup(
                    children: [
                      MenuRow(
                        icon: Lucide.settings,
                        title: 'Delivery Preferences',
                        subtitle: 'Default locations, item types, availability',
                        onTap: () => push(const PreferencesScreen()),
                      ),
                      MenuRow(
                        icon: Lucide.bell,
                        title: 'Notifications',
                        subtitle: 'Order updates, messages, promotions',
                        onTap: () => push(const NotificationsScreen()),
                      ),
                      MenuRow(
                        icon: Lucide.shield,
                        title: 'Safety & Support',
                        subtitle: 'Report issues, campus safety, help center',
                        onTap: () => push(const SafetyScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MenuGroup(
                    children: [
                      MenuRow(
                        icon: Lucide.creditCard,
                        title: 'Payment Methods',
                        subtitle: 'UPI, cards, student account',
                        onTap: () => push(const PaymentMethodsScreen()),
                      ),
                      MenuRow(
                        icon: Lucide.mapPin,
                        title: 'Campus',
                        subtitle: 'VIT Vellore',
                        onTap: () => push(const CampusScreen()),
                      ),
                      MenuRow(
                        icon: AppIcons.sliders,
                        title: 'App Settings',
                        subtitle: 'Language, theme, permissions',
                        onTap: () => push(const AppSettingsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: state.signOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(
                          color: AppColors.ink,
                          width: AppRadii.stroke,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                      ),
                      child: Text(
                        'Log Out',
                        style: AppText.label.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({required this.restricted});

  final bool restricted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.ink, width: AppRadii.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgIcon(restricted ? Lucide.circleAlert : Lucide.check, size: 12),
          const SizedBox(width: 4),
          Text(
            restricted ? 'Restricted' : 'Verified Student',
            style: AppText.badge.copyWith(color: AppColors.ink, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
