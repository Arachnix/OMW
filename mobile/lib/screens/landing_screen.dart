import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system.dart';
import '../models/order_model.dart';
import '../state/app_state.dart';

/// "onmyway-home-screen" (Figma 112:5), headed by the "header-row" (112:12).
///
/// Post sign-in entry point: ORDER opens the sender shell, DELIVER opens the
/// courier feed.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _navOrders = 1;
  static const _navFavorites = 2;
  static const _navAccount = 3;

  void _onNav(BuildContext context, int index) {
    final state = context.read<AppState>();
    switch (index) {
      case _navOrders:
        state.enterAs(AppRole.sender, senderTab: SenderTab.activity);
      case _navFavorites:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Favorites are coming soon')),
          );
      case _navAccount:
        state.enterAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final height = MediaQuery.sizeOf(context).height;
    // Figma draws the mascot ~220 tall on an 846 frame; scale with height.
    final mascotHeight = (height * 0.26).clamp(140.0, 240.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const _BrandHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      // Top-aligned like Figma; spare height collects
                      // above the value band.
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          Image.asset(
                            AppImages.mascotTraveler,
                            height: mascotHeight,
                            fit: BoxFit.contain,
                            semanticLabel: 'OnMyWay mascot waving namaste',
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Semantics(
                            header: true,
                            child: Text(
                              'On the route?\nGrab the loot.',
                              textAlign: TextAlign.center,
                              style: AppText.headline,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'ORDER AHEAD OR GET IT DELIVERED',
                            textAlign: TextAlign.center,
                            style: AppText.tagline,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _ChoiceCard(
                                    svg: Lucide.shoppingBag,
                                    title: 'ORDER',
                                    subtitle: 'PICK UP AHEAD',
                                    onTap: () => state.enterAs(AppRole.sender),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: _ChoiceCard(
                                    svg: AppIcons.mapPin,
                                    title: 'DELIVER',
                                    subtitle: 'STRAIGHT TO YOU',
                                    onTap: () => state.enterAs(AppRole.courier),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                  const _ValueBand(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        indicator: NavIndicator.disc,
        selectedIndex: 0,
        onSelected: (i) => _onNav(context, i),
        destinations: const [
          NavDestination(icon: Lucide.house, label: 'Home'),
          NavDestination(icon: Lucide.clock, label: 'Orders'),
          NavDestination(icon: Lucide.heart, label: 'Favorites'),
          NavDestination(icon: Lucide.user, label: 'Account'),
        ],
      ),
    );
  }
}

/// Figma "header-row" (112:12): wordmark and tagline.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: Semantics(
        header: true,
        label: 'OnMyWay. Good food. Less wait.',
        excludeSemantics: true,
        child: Column(
          children: [
            Text('OnMyWay', style: AppText.brandTitle),
            const SizedBox(height: AppSpacing.xs),
            Text('GOOD FOOD. LESS WAIT.', style: AppText.tagline),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    this.svg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String? svg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);
    return Semantics(
      button: true,
      label: '$title, ${subtitle.toLowerCase()}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.ink, width: AppRadii.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppRadii.stroke,
                    ),
                  ),
                  child: SvgIcon(svg!, size: 20),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(title, style: AppText.choiceTitle),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: AppText.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SvgIcon(Lucide.arrowRight, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "FAST. RELIABLE. LOCAL." strip above the nav.
class _ValueBand extends StatelessWidget {
  const _ValueBand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.fillMuted,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.ink, width: AppRadii.stroke),
        ),
      ),
      child: Text(
        'FAST. RELIABLE. LOCAL.',
        textAlign: TextAlign.center,
        style: AppText.cardEyebrow,
      ),
    );
  }
}
