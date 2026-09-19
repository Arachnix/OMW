import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system.dart';
import '../../state/app_state.dart';
import '../../state/location_service.dart';
import 'gps_error_screen.dart';

/// Pick the runner's active route (start → destination landmark) or use the
/// device location as the start. Not drawn in Figma; built from the route
/// card and header components.
class EditRouteScreen extends StatefulWidget {
  const EditRouteScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const EditRouteScreen());

  @override
  State<EditRouteScreen> createState() => _EditRouteScreenState();
}

class _EditRouteScreenState extends State<EditRouteScreen> {
  String? _from;
  String? _to;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _from = s.routeFrom?.id;
    _to = s.routeTo?.id;
  }

  Future<void> _pick(bool from) async {
    final s = context.read<AppState>();
    final id = await LocationPickerSheet.show(
      context,
      title: from ? 'Starting point' : 'Heading to',
      locations: s.locations,
      selectedId: from ? _from : _to,
    );
    if (id != null) setState(() => from ? _from = id : _to = id);
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    final s = context.read<AppState>();
    try {
      await s.useDeviceLocation();
      if (!mounted) return;
      setState(() {
        _from = s.routeFrom?.id;
        _locating = false;
      });
      showSnack(context, 'Starting from ${s.routeFrom?.shortName} (GPS).');
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      final manual = await Navigator.of(context).push<bool>(
        GpsErrorScreen.route(reason: e.message, onRetry: s.useDeviceLocation),
      );
      if (!mounted) return;
      if (manual == true) {
        await _pick(true);
      } else {
        setState(() => _from = s.routeFrom?.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final from = s.locationById(_from), to = s.locationById(_to);
    final valid = from != null && to != null && from.id != to.id;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CenteredHeader(title: 'Edit Route', underline: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Where are you walking? We\'ll match requests along the way.',
                    style: AppText.bodyMuted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OmwCard(
                    child: RouteStops(
                      pickup: from?.name ?? 'Choose a starting point',
                      destination: to?.name ?? 'Choose where you\'re heading',
                      onEditPickup: () => _pick(true),
                      onEditDestination: () => _pick(false),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _useGps,
                      icon: _locating
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.ink,
                              ),
                            )
                          : const SvgIcon(Lucide.locate, size: 18),
                      label: Text(
                        'Use my current location',
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(
                          color: AppColors.ink,
                          width: AppRadii.stroke,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  if (from != null && to != null && from.id == to.id) ...[
                    const SizedBox(height: AppSpacing.md),
                    const InlineError(
                      'Start and destination must be different.',
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: PillButton(
                label: 'Save Route',
                onPressed: valid
                    ? () {
                        s.setRoute(_from!, _to!);
                        Navigator.of(context).pop();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
