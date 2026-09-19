import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'api/omw_api.dart';
import 'models/order_model.dart';
import 'screens/account_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/order_notice_sheets.dart';
import 'screens/order_screen.dart';
import 'screens/runner/courier_jobs_screen.dart';
import 'screens/runner/runner_feed_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_icons.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(api: HttpOmwApi())..restoreSession(),
      child: const OmwApp(),
    ),
  );
}

class OmwApp extends StatelessWidget {
  const OmwApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnMyWay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootNavigator(),
    );
  }
}

/// Cross-fades between splash, sign-in, landing and the role shells.
class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final stage = context.select<AppState, AppStage>((s) => s.stage);
    return AnimatedSwitcher(
      duration: AppMotion.slow,
      switchInCurve: AppMotion.curve,
      child: switch (stage) {
        AppStage.splash => const SplashScreen(key: ValueKey('splash')),
        AppStage.signIn => const SignInScreen(key: ValueKey('signIn')),
        AppStage.landing => const LandingScreen(key: ValueKey('landing')),
        AppStage.app => const MainShell(key: ValueKey('app')),
      },
    );
  }
}

/// Tab body + bottom nav for the current role (Figma 4-tab bars: sender
/// Home / Activity / Wallet / Account, courier Feed / Activity / Earnings /
/// Account). Each tab draws its own header.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isSender = state.role == AppRole.sender;

    final (Widget body, Object bodyKey) = isSender
        ? switch (state.senderTab) {
            SenderTab.home => (const OrderScreen(), SenderTab.home),
            SenderTab.activity => (const ActivityScreen(), SenderTab.activity),
            SenderTab.wallet => (const WalletScreen(), SenderTab.wallet),
            SenderTab.account => (const AccountScreen(), SenderTab.account),
          }
        : switch (state.courierTab) {
            CourierTab.feed => (const RunnerFeedScreen(), CourierTab.feed),
            CourierTab.activity => (
              const CourierJobsScreen(),
              CourierTab.activity,
            ),
            CourierTab.earnings => (const WalletScreen(), CourierTab.earnings),
            CourierTab.account => (const AccountScreen(), CourierTab.account),
          };

    final destinations = isSender
        ? [
            const NavDestination(icon: Lucide.house, label: 'Home'),
            NavDestination(
              icon: Lucide.list,
              label: 'Activity',
              badge: state.waitingCount,
            ),
            const NavDestination(icon: Lucide.wallet, label: 'Wallet'),
            const NavDestination(icon: Lucide.user, label: 'Account'),
          ]
        : [
            const NavDestination(icon: Lucide.mapPinCheck, label: 'Feed'),
            NavDestination(
              icon: Lucide.history,
              label: 'Activity',
              badge: state.activeJobs.length,
            ),
            const NavDestination(icon: Lucide.wallet, label: 'Earnings'),
            const NavDestination(icon: Lucide.userCog, label: 'Account'),
          ];

    // Hide the nav while the keyboard is up so inputs keep the space.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NoticeHost(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            child: KeyedSubtree(
              key: ValueKey('$isSender-$bodyKey'),
              child: body,
            ),
          ),
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : AppBottomNav(
              topRule: true,
              destinations: destinations,
              selectedIndex: isSender
                  ? state.senderTab.index
                  : state.courierTab.index,
              onSelected: (i) => isSender
                  ? state.setSenderTab(SenderTab.values[i])
                  : state.setCourierTab(CourierTab.values[i]),
            ),
    );
  }
}
