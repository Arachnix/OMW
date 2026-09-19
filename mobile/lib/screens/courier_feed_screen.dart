import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import '../widgets/filter_pill.dart';
import '../widgets/omw_card.dart';
import '../widgets/parcel_option_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/route_card.dart';
import '../widgets/svg_icon.dart';
import 'order_notice_sheets.dart';

/// Courier home: the "delivery_feed" Figma frame.
class CourierFeedScreen extends StatelessWidget {
  const CourierFeedScreen({super.key});

  void _accept(BuildContext context, DeliveryRequest request) {
    final state = context.read<AppState>();
    final senderNotified = state.history.any((r) => r.id == request.id);
    final accepted = state.accept(request);
    presentCourierAccepted(context, accepted, senderNotified: senderNotified);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final feed = state.visibleFeed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            itemCount: FeedFilter.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final filter = FeedFilter.values[i];
              return FilterPill(
                label: filter.label,
                selected: state.filter == filter,
                onTap: () => state.setFilter(filter),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            child: feed.isEmpty
                ? const _EmptyFeed(key: ValueKey('empty'))
                : ListView.separated(
                    key: ValueKey(state.filter),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xs,
                      AppSpacing.gutter,
                      AppSpacing.xl,
                    ),
                    itemCount: feed.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, i) {
                      final request = feed[i];
                      void onAccept() => _accept(context, request);
                      return request.isDetour
                          ? _DetourCard(
                              key: ValueKey(request.id),
                              request: request,
                              onAccept: onAccept,
                            )
                          : _RequestCard(
                              key: ValueKey(request.id),
                              request: request,
                              onAccept: onAccept,
                            );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// "fast-courier-card" variant with REQUEST FOR MATCH and an Accept CTA.
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    super.key,
    required this.request,
    required this.onAccept,
  });

  final DeliveryRequest request;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return OmwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardEyebrow(
            label: 'REQUEST FOR MATCH',
            trailing: EtaBadge(minutes: request.etaMinutes),
          ),
          const SizedBox(height: AppSpacing.md),
          RouteStops(pickup: request.pickup, destination: request.destination),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label:
                      'Delivery offer ₹${request.fare}, '
                      '${request.distanceKm.toStringAsFixed(1)} km',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text('DELIVERY OFFER', style: AppText.cardEyebrow),
                      const SizedBox(height: AppSpacing.sm),
                      Text('₹${request.fare}', style: AppText.price),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${request.distanceKm.toStringAsFixed(1)} km trip',
                        style: AppText.caption.copyWith(
                          color: AppColors.inkAt(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 96,
                child: ParcelOptionCard(type: request.parcel, selected: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Accept Delivery Request for ₹${request.fare}',
            leading: const Icon(
              Icons.play_arrow_outlined,
              color: AppColors.surface,
              size: 20,
            ),
            onPressed: onAccept,
          ),
        ],
      ),
    );
  }
}

/// Compact "request-card-3" (Figma, on the 185:1016 feed): a short pickup on
/// the courier's current route.
class _DetourCard extends StatelessWidget {
  const _DetourCard({super.key, required this.request, required this.onAccept});

  final DeliveryRequest request;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final km = request.distanceKm.toStringAsFixed(1);
    return OmwCard(
      strokeWidth: AppRadii.strokeBold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardEyebrow(
            label: 'SLIGHT DETOUR',
            hollowDot: true,
            trailing: _DistancePill(label: '$km km away'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stop(
                      icon: const Icon(
                        AppGlyphs.store,
                        size: 16,
                        color: AppColors.ink,
                      ),
                      title: request.pickup,
                      detail: request.pickupDetail,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Stop(
                      icon: const SvgIcon(AppIcons.mapPin),
                      title: request.destination,
                      detail: request.destinationDetail,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stat(
                      icon: const Icon(
                        AppGlyphs.user,
                        size: 16,
                        color: AppColors.ink,
                      ),
                      value: '$km km',
                      caption: 'to pickup',
                    ),
                    _Stat(
                      icon: const Icon(
                        AppGlyphs.alarm,
                        size: 16,
                        color: AppColors.ink,
                      ),
                      value: '+${request.detourMinutes} min',
                      caption: 'detour',
                    ),
                    _Stat(
                      icon: SvgIcon(request.parcel.icon),
                      value: request.parcel.label,
                      caption: request.parcel.weight,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    label: 'Fare ₹${request.fare}',
                    excludeSemantics: true,
                    child: Text(
                      '₹${request.fare}',
                      style: AppText.priceCompact,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    button: true,
                    label:
                        'Accept ${request.pickup} to '
                        '${request.destination} for ₹${request.fare}',
                    excludeSemantics: true,
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.surface,
                        minimumSize: const Size(72, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.field),
                        ),
                      ),
                      child: Text('ACCEPT', style: AppText.ctaCompact),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Outlined "▲ 1.1 km away" pill.
class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.ink, width: AppRadii.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppGlyphs.navigation, size: 12, color: AppColors.ink),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppText.badge.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.title, this.detail});

  final Widget icon;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: AppRadii.stroke),
          ),
          child: icon,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.stopTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: AppText.stopDetail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.caption});

  final Widget icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: icon),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppText.statValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(caption, style: AppText.statCaption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                AppImages.mascotBadge,
                width: 72,
                height: 72,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No requests here yet', style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try another filter or check back in a minute.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: AppColors.inkAt(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
