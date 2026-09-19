import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_config.dart';
import '../../design_system.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import '../wallet/upi_row.dart';

/// Account sub-pages. Not drawn in Figma; composed from the Account frame's
/// page title, panels and menu rows.

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.eyebrow,
    required this.children,
  });

  final String title;
  final String eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            PageTitle(
              title: title,
              eyebrow: eyebrow,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Role and default route.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      title: 'Preferences',
      eyebrow: 'HOW YOU USE OMW.',
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardEyebrow(label: 'I AM USING OMW TO'),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilterPill(
                    label: 'Send parcels',
                    selected: state.role == AppRole.sender,
                    onTap: () => state.setRole(AppRole.sender),
                  ),
                  FilterPill(
                    label: 'Deliver parcels',
                    selected: state.role == AppRole.courier,
                    onTap: () => state.setRole(AppRole.courier),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardEyebrow(label: 'DEFAULT DELIVERY ROUTE'),
              const SizedBox(height: AppSpacing.md),
              RouteStops(
                pickup: state.pickup?.name ?? 'Not set',
                destination: state.drop?.name ?? 'Not set',
                onEditPickup: () async {
                  final id = await LocationPickerSheet.show(
                    context,
                    title: 'Pickup Spot',
                    locations: state.locations,
                    selectedId: state.pickup?.id,
                  );
                  if (id != null) state.setPickup(id);
                },
                onEditDestination: () async {
                  final id = await LocationPickerSheet.show(
                    context,
                    title: 'Delivery Destination',
                    locations: state.locations,
                    selectedId: state.drop?.id,
                  );
                  if (id != null) state.setDrop(id);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget point(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppText.label.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(body, style: AppText.bodyMuted),
          ],
        ),
      ),
    );
    return _Page(
      title: 'Safety & Support',
      eyebrow: 'TRUSTSHIELD.',
      children: [
        point(
          'Dual-OTP handoff',
          'Every delivery is verified twice: a pickup code at the counter and '
              'a delivery code only the requester sees. Never share your code '
              'before the parcel is in your hands.',
        ),
        point(
          'Escrow protection',
          'Your bounty stays locked until the delivery code is verified. '
              'Cancel before a courier accepts for a full refund.',
        ),
        point(
          'Runner commitment stake',
          'Couriers lock 25% of the bounty when they accept. Dropping a job '
              'forfeits the stake and lowers their trust score.',
        ),
        const SizedBox(height: AppSpacing.sm),
        DisplayButton(
          label: 'Report an Issue',
          icon: Lucide.triangleAlert,
          onPressed: () => showSnack(
            context,
            'Reporting is simulated in this demo. Campus security: dial 100.',
          ),
        ),
      ],
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Page(
      title: 'Payment Methods',
      eyebrow: 'HOW YOU PAY.',
      children: [
        UpiRow(title: 'UPI'),
        SizedBox(height: AppSpacing.lg),
        InfoBox(
          icon: Lucide.lock,
          text:
              'Payments run on the Razorpay test network in this build. No '
              'real money is charged or paid out.',
        ),
      ],
    );
  }
}

class CampusScreen extends StatelessWidget {
  const CampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<AppState>().locations;
    return _Page(
      title: 'Campus',
      eyebrow: 'VIT VELLORE.',
      children: [
        Text(
          '${locations.length} delivery landmarks',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        MenuGroup(
          children: [
            for (final l in locations)
              MenuRow(
                icon: Lucide.mapPin,
                title: l.shortName,
                subtitle: '${l.categoryLabel} · ${l.name}',
                onTap: () {},
              ),
          ],
        ),
      ],
    );
  }
}

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      title: 'App Settings',
      eyebrow: 'LANGUAGE, THEME, PERMISSIONS.',
      children: [
        MenuGroup(
          children: [
            MenuRow(
              icon: Lucide.info,
              title: 'Language',
              subtitle: 'English',
              onTap: () =>
                  showSnack(context, 'More languages are coming soon.'),
            ),
            MenuRow(
              icon: Lucide.settings,
              title: 'Theme',
              subtitle: 'Black & white',
              onTap: () =>
                  showSnack(context, 'OMW uses a single monochrome theme.'),
            ),
            MenuRow(
              icon: Lucide.locate,
              title: 'Location permission',
              subtitle: 'Used for “along your route” matching',
              onTap: () => showInfo(
                context,
                'Location',
                'OMW asks for your location only when you tap “Use my '
                    'current location” in Runner mode.',
              ),
            ),
            MenuRow(
              icon: Lucide.radio,
              title: 'Server',
              subtitle: ApiConfig.baseUrl,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        DisplayButton(
          label: 'Log Out',
          icon: Lucide.logOut,
          outlined: true,
          onPressed: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
            state.signOut();
          },
        ),
      ],
    );
  }
}
