import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mode = state.mode;
    final screen = state.screen;
    final pendingCount = state.activePendingOrders.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgLight.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: mode == AppMode.order
                ? [
                    _NavItem(
                      iconAsset: 'assets/62ba6.svg',
                      fallbackIcon: Icons.home_rounded,
                      label: 'Home',
                      active: screen == ScreenType.order,
                      onTap: () => state.setScreen(ScreenType.order),
                    ),
                    _NavItem(
                      iconAsset: 'assets/53e65.svg',
                      fallbackIcon: Icons.receipt_long_rounded,
                      label: 'Activity',
                      badge: pendingCount > 0 ? '$pendingCount' : null,
                      active: screen == ScreenType.pending ||
                          screen == ScreenType.tracking,
                      onTap: () => state.setScreen(ScreenType.pending),
                    ),
                    _NavItem(
                      iconAsset: 'assets/374f1.svg',
                      fallbackIcon: Icons.account_circle_rounded,
                      label: 'Account',
                      active: screen == ScreenType.account,
                      onTap: () => state.setScreen(ScreenType.account),
                    ),
                  ]
                : [
                    _NavItem(
                      iconAsset: 'assets/d165d.svg',
                      fallbackIcon: Icons.dynamic_feed_rounded,
                      label: 'Live Feed',
                      active: screen == ScreenType.feed,
                      onTap: () => state.setScreen(ScreenType.feed),
                    ),
                    _NavItem(
                      iconAsset: 'assets/53e65.svg',
                      fallbackIcon: Icons.moped_rounded,
                      label: 'Deliveries',
                      active: screen == ScreenType.tracking,
                      onTap: () => state.setScreen(ScreenType.tracking),
                    ),
                    _NavItem(
                      iconAsset: 'assets/374f1.svg',
                      fallbackIcon: Icons.account_balance_wallet_rounded,
                      label: 'Earnings',
                      active: screen == ScreenType.account,
                      onTap: () => state.setScreen(ScreenType.account),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconAsset;
  final IconData fallbackIcon;
  final String label;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.label,
    required this.active,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: active ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: SvgPicture.asset(
                    iconAsset,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      active ? activeColor : inactiveColor,
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (context) => Icon(
                      fallbackIcon,
                      size: 22,
                      color: active ? activeColor : inactiveColor,
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: active ? 16 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
