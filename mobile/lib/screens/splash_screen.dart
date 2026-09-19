import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_video_wordmark.dart';

/// Short, muted wordmark animation. Advances when the video ends, after a
/// brief hold on the static fallback, on tap, or after a safety timeout.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration maxDuration = Duration(seconds: 5);
  static const Duration hold = Duration(milliseconds: 900);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.maxDuration, _advance);
  }

  void _scheduleAdvance() {
    _timer?.cancel();
    _timer = Timer(SplashScreen.hold, _advance);
  }

  void _advance() {
    _timer?.cancel();
    if (mounted) context.read<AppState>().finishSplash();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.72).clamp(200.0, 360.0);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Semantics(
        button: true,
        label: 'OnMyWay. Tap to continue',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _advance,
          child: SafeArea(
            child: Center(
              child: BrandVideoWordmark(
                width: width,
                onFinished: _scheduleAdvance,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
