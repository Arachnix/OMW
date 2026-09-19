import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import '../order_notice_sheets.dart';
import 'edit_route_screen.dart';

/// Courier home: Figma "runner-feed" (120:5), plus the "Runner Feed - Empty
/// Route" and "Network Error" edge frames. Tasks come from GET /api/tasks
/// ranked around the runner's position and active route.
class RunnerFeedScreen extends StatelessWidget {
  const RunnerFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.visibleFeed;
    final error = state.feedError;

    return Column(
      children: [
        const _RunnerHeader(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.ink,
            onRefresh: state.refreshFeed,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const _ActiveRouteCard(),
                const SizedBox(height: AppSpacing.lg),
                if (error != null)
                  ErrorBlock(
                    title: 'Failed to Load Feed',
                    message:
                        'Please check your internet connection or try '
                        'refreshing the request feed.',
                    action: FilledButton(
                      onPressed: state.refreshFeed,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'Retry Loading',
                        style: AppText.badge.copyWith(fontSize: 13),
                      ),
                    ),
                  )
                else ...[
                  _Filters(state: state),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.feedLoading && state.allFeed.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.ink),
                      ),
                    )
                  else if (items.isEmpty)
                    _EmptyRoute(state: state)
                  else
                    for (final item in items) ...[
                      RunnerTaskCard(
                        key: ValueKey(item.task.id),
                        item: item,
                        onAccept: () => acceptTask(context, item.task),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  _OnlineCard(state: state),
                  const SizedBox(height: AppSpacing.lg),
                  _EarningsBar(state: state),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RunnerHeader extends StatelessWidget {
  const _RunnerHeader();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppRadii.strokeBold),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave runner mode',
            onPressed: state.goToLanding,
            icon: const SvgIcon(Lucide.circleX, size: 30),
          ),
          Text(
            'OnMyWay',
            style: AppText.heading.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Semantics(
            label: state.online
                ? 'Runner mode, online'
                : 'Runner mode, offline',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: state.online ? AppColors.surface : null,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Runner Mode',
                    style: AppText.badge.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          AppHeaderAvatar(onTap: state.openAccount),
        ],
      ),
    );
  }
}

class _ActiveRouteCard extends StatelessWidget {
  const _ActiveRouteCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final from = state.routeFrom, to = state.routeTo;
    return Panel(
      stroke: AppRadii.strokeBold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SvgIcon(Lucide.mapPin, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ACTIVE ROUTE',
                  style: AppText.cardEyebrow.copyWith(fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.fillMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '~${state.routeMinutes} min',
                  style: AppText.labelSmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            from == null || to == null
                ? 'Set your route'
                : '${from.shortName} → ${to.shortName}',
            style: AppText.heading.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Total Distance: ${state.routeKm.toStringAsFixed(1)} km',
            style: AppText.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _RouteProgress(),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).push(EditRouteScreen.route()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(
                  color: AppColors.ink,
                  width: AppRadii.strokeBold,
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Edit Route',
                style: AppText.label.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Start ring ‒ ‒ ⚡ ‒ ‒ end dot.
class _RouteProgress extends StatelessWidget {
  const _RouteProgress();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 20,
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
            ),
            const Expanded(child: CustomPaint(painter: _DashLine())),
            const SvgIcon(Lucide.zap, size: 18),
            const Expanded(child: CustomPaint(painter: _DashLine())),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashLine extends CustomPainter {
  const _DashLine();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    for (var x = 4.0; x < size.width - 4; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(x + 3.5, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in RunnerFilter.values) ...[
            _FilterChip(
              label: '${f.label} (${state.feedFor(f).length})',
              selected: state.filter == f,
              onTap: () => state.setFilter(f),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Tooltip(
            message: 'Refresh feed',
            child: InkResponse(
              onTap: state.refreshFeed,
              radius: 24,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.stroke,
                  ),
                ),
                child: const SvgIcon(AppIcons.sliders, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.ink : AppColors.surface,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.ink, width: AppRadii.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.surface : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact task card ("request-card-3"): route fit eyebrow, stops, stats,
/// fare and ACCEPT.
class RunnerTaskCard extends StatelessWidget {
  const RunnerTaskCard({super.key, required this.item, required this.onAccept});

  final FeedItem item;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final t = item.task;
    final pickup = context.read<AppState>().locationById(t.pickupId);
    final drop = context.read<AppState>().locationById(t.dropId);
    return OmwCard(
      strokeWidth: AppRadii.strokeBold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardEyebrow(
            label: item.fit.eyebrow,
            hollowDot: item.fit == RouteFit.detour,
            trailing: _DistancePill(
              label: '${item.distanceKm.toStringAsFixed(1)} km away',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stop(
                        icon: Lucide.store,
                        title: t.shortPickup,
                        detail: '${t.categoryLabel} · ${t.parcel.weight}',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Stop(
                        icon: Lucide.mapPin,
                        title: t.shortDrop,
                        detail:
                            drop?.categoryLabel ?? pickup?.categoryLabel ?? '',
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(color: AppColors.divider, width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Stat(
                        icon: Lucide.user,
                        value: '${item.distanceKm.toStringAsFixed(1)} km',
                        caption: 'to pickup',
                      ),
                      _Stat(
                        icon: Lucide.alarmClock,
                        value: '+${item.detourMinutes} min',
                        caption: 'detour',
                      ),
                      _Stat(
                        icon: t.parcel.icon,
                        value: t.parcel.label,
                        caption: t.parcel.weight,
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(color: AppColors.divider, width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('₹${t.wager}', style: AppText.priceCompact),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      button: true,
                      label:
                          'Accept ${t.shortPickup} to ${t.shortDrop} for ₹${t.wager}',
                      excludeSemantics: true,
                      child: FilledButton(
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.surface,
                          minimumSize: const Size(80, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          ),
        ],
      ),
    );
  }
}

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
          const SvgIcon(Lucide.navigation, size: 12),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppText.badge.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.icon, required this.title, required this.detail});

  final String icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: AppRadii.stroke),
          ),
          child: SvgIcon(icon, size: 16),
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
              if (detail.isNotEmpty)
                Text(
                  detail,
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

  final String icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SvgIcon(icon, size: 16),
          ),
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

/// Edge state 3: "No Orders Along Route".
class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final from = state.routeFrom?.shortName ?? 'your start';
    final to = state.routeTo?.shortName ?? 'your destination';
    final label = switch (state.filter) {
      RunnerFilter.alongRoute => 'No Orders Along Route',
      RunnerFilter.nearby => 'No Orders Nearby',
      RunnerFilter.all => 'No Open Orders',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const SvgIcon(Lucide.radio, size: 22),
          const SizedBox(height: AppSpacing.lg),
          Text(
            label,
            style: AppText.label.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'There are currently no active delivery requests matching your '
            'current route from $from to $to.',
            textAlign: TextAlign.center,
            style: AppText.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: state.refreshFeed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(
                color: AppColors.ink,
                width: AppRadii.stroke,
              ),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Refresh Feed',
              style: AppText.badge.copyWith(color: AppColors.ink, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineCard extends StatelessWidget {
  const _OnlineCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final on = state.online;
    return Semantics(
      toggled: on,
      button: true,
      label: on
          ? 'You are online. Tap to go offline.'
          : 'Available to deliver. Go online to receive orders.',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => state.setOnline(!on),
        borderRadius: BorderRadius.circular(AppRadii.tile),
        child: DashedPanel(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppColors.ink : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.stroke,
                  ),
                ),
                child: SvgIcon(
                  Lucide.radio,
                  size: 18,
                  color: on ? AppColors.surface : AppColors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      on ? 'You\'re online' : 'Available to deliver',
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      on
                          ? 'We\'ll alert you to requests along your route. Tap to go offline.'
                          : 'Go online to start receiving orders instantly.',
                      style: AppText.bodyMuted.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsBar extends StatelessWidget {
  const _EarningsBar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final today = state.earningsToday;
    return Panel(
      color: AppColors.fillMuted,
      stroke: AppRadii.strokeBold,
      radius: AppRadii.tile,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S EARNINGS", style: AppText.overline),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        rupees(today.amount),
                        style: AppText.heading.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${today.count} deliveries',
                        style: AppText.bodyMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const VerticalDivider(color: AppColors.divider, width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TOTAL BALANCE', style: AppText.overline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  rupees(state.wallet.total),
                  style: AppText.heading.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
