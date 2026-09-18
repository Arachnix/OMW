import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/order_model.dart';
import 'screens/account_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/order_screen.dart';
import 'screens/pending_orders_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/sign_in_screen.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_header.dart';
import 'widgets/calling_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const OmwApp(),
    ),
  );
}

class OmwApp extends StatelessWidget {
  const OmwApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OMW - Delivery Order Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgLight,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SignInScreen(),
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    Widget bodyWidget;
    switch (state.screen) {
      case ScreenType.order:
        bodyWidget = const OrderScreen();
        break;
      case ScreenType.tracking:
        bodyWidget = const TrackingScreen();
        break;
      case ScreenType.feed:
        bodyWidget = const FeedScreen();
        break;
      case ScreenType.pending:
        bodyWidget = const PendingOrdersScreen();
        break;
      case ScreenType.account:
        bodyWidget = const AccountScreen();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main screen layout
              Column(
                children: [
                  const AppHeader(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: KeyedSubtree(
                        key: ValueKey(state.screen),
                        child: bodyWidget,
                      ),
                    ),
                  ),
                  const AppBottomNav(),
                ],
              ),

          // Floating Toast Notification
          if (state.toastMessage != null)
            Positioned(
              top: 72,
              left: 20,
              right: 20,
              child: Center(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.navyDark,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            state.toastMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Calling Overlay
          const CallingOverlay(),
        ],
      ),
    ),
  ),
);
}
}
