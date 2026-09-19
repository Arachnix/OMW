import 'package:flutter/material.dart';

import '../../design_system.dart';
import '../../state/location_service.dart';

/// "gps-error" (Figma 164:12). Pops `true` when the user chooses to enter
/// the address manually, `false` after a successful retry.
class GpsErrorScreen extends StatefulWidget {
  const GpsErrorScreen({
    super.key,
    required this.reason,
    required this.onRetry,
  });

  final String reason;
  final Future<void> Function() onRetry;

  static Route<bool> route({
    required String reason,
    required Future<void> Function() onRetry,
  }) => MaterialPageRoute(
    builder: (_) => GpsErrorScreen(reason: reason, onRetry: onRetry),
  );

  @override
  State<GpsErrorScreen> createState() => _GpsErrorScreenState();
}

class _GpsErrorScreenState extends State<GpsErrorScreen> {
  bool _busy = false;
  late String _reason = widget.reason;

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await widget.onRetry();
      if (mounted) Navigator.of(context).pop(false);
    } on LocationFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _reason = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tip(String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SvgIcon(Lucide.circleCheck, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              t,
              style: AppText.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppRadii.stroke,
                    ),
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.fillMuted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppRadii.stroke,
                      ),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppRadii.stroke,
                        ),
                      ),
                      child: const SvgIcon(Lucide.x, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  'GPS Signal Failure',
                  textAlign: TextAlign.center,
                  style: AppText.headingLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We are unable to pinpoint your current location. $_reason '
                'Please verify that your phone\'s location access is active and '
                'you have a clear sky view.',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted.copyWith(fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.xl),
              Panel(
                stroke: AppRadii.strokeBold,
                child: Column(
                  children: [
                    tip('Enable "Always Allow" location services'),
                    tip('Turn off Wi-Fi block & restart App'),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              PillButton(
                label: 'Retry Connection',
                busy: _busy,
                textStyle: AppText.label.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                ),
                onPressed: _retry,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(
                      color: AppColors.ink,
                      width: AppRadii.strokeBold,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Enter Address Manually',
                    style: AppText.label.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
