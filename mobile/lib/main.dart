import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/order_model.dart';
import 'screens/account_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/courier_feed_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/order_notice_sheets.dart';
import 'screens/order_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_icons.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_header.dart';

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
    ChangeNotifierProvider(create: (_) => AppState(), child: const OmwApp()),
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

/// Header + tab body + bottom nav. Sender gets Home/Activity/Account; courier
/// gets Feed/Account, matching the two Figma nav bars.
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
            SenderTab.account => (const AccountScreen(), SenderTab.account),
          }
        : switch (state.courierTab) {
            CourierTab.feed => (const CourierFeedScreen(), CourierTab.feed),
            CourierTab.account => (const AccountScreen(), CourierTab.account),
          };

    final destinations = isSender
        ? [
            const NavDestination(icon: AppIcons.truck, label: 'Home'),
            NavDestination(
              icon: AppIcons.clipboardCheck,
              label: 'Activity',
              badge: state.openRequestCount,
            ),
            const NavDestination(icon: AppIcons.idCard, label: 'Account'),
          ]
        : const [
            NavDestination(icon: AppIcons.truck, label: 'Feed'),
            NavDestination(icon: AppIcons.idCard, label: 'Account'),
          ];

    // Hide the nav while the keyboard is up so inputs keep the space.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final shellBody = SafeArea(
      bottom: false,
      child: Column(
        children: [
          AppHeader(
            onMascotTap: state.goToLanding,
            onAvatarTap: state.openAccount,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              child: KeyedSubtree(key: ValueKey(bodyKey), child: body),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      // Sender notices ("Order Accepted" / "Order Cancelled") appear over
      // the sender shell only.
      body: isSender ? SenderNoticeHost(child: shellBody) : shellBody,
      bottomNavigationBar: keyboardOpen
          ? null
          : AppBottomNav(
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
