import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _activeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isOnline = state.isOnline;
    final allOrders = state.allAvailableFeedOrders;

    final visibleOrders = allOrders.where((d) {
      if (d.accepted) return false;
      if (_activeFilter == 'high') return d.offerPrice > 150;
      if (_activeFilter == 'instant') {
        return d.parcelType == ParcelType.documents || d.offerPrice > 170;
      }
      if (_activeFilter == 'near') return d.distanceKm <= 3.5;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Courier Duty Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.greenLightBg : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      isOnline ? '🟢' : '⏸️',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online • Accepting Orders' : 'Duty Paused',
                        style: const TextStyle(
                          color: AppColors.navyDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isOnline
                            ? 'Radius: 8 km • Radar scanning'
                            : 'Turn online to receive live courier pings',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isOnline ? AppColors.primary : Colors.grey.shade200,
                    foregroundColor:
                        isOnline ? Colors.white : AppColors.textBody,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => state.toggleOnlineDuty(),
                  child: Text(
                    isOnline ? 'Go Offline' : 'Go Online',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'All Deliveries',
                  count: visibleOrders.length,
                  active: _activeFilter == 'all',
                  onTap: () => setState(() => _activeFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'High Fare (>₹150)',
                  active: _activeFilter == 'high',
                  onTap: () => setState(() => _activeFilter = 'high'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: '< 3.5 km',
                  active: _activeFilter == 'near',
                  onTap: () => setState(() => _activeFilter = 'near'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Instant Pickup',
                  icon: Icons.bolt_rounded,
                  active: _activeFilter == 'instant',
                  onTap: () => setState(() => _activeFilter = 'instant'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Orders List
          if (visibleOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: const [
                  Text('📡', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 12),
                  Text(
                    'Scanning for Nearby Deliveries',
                    style: TextStyle(
                      color: AppColors.navyDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Delivery requests broadcast by customers in your area will appear here.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...visibleOrders.map((order) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    children: [
                      // Window & Surge Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.cardBorder.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Window: ${order.windowLabel}',
                                style: const TextStyle(
                                  color: AppColors.navyDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.amberBadge,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      size: 12,
                                      color: AppColors.amberText,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'SURGE 1.4x',
                                      style: TextStyle(
                                        color: AppColors.amberText,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Route
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.navyDark,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 32,
                                  color: AppColors.cardBorder,
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pickup',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        order.pickup,
                                        style: const TextStyle(
                                          color: AppColors.navyDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dropoff',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        order.dropoff,
                                        style: const TextStyle(
                                          color: AppColors.navyDark,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bid & Action Bottom Panel
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius:
                              BorderRadius.vertical(bottom: Radius.circular(28)),
                          border: Border(
                            top: BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Sender's Offer",
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${order.offerPrice}',
                                      style: const TextStyle(
                                        color: AppColors.navyDark,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!order.countered)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.amberBadge,
                                      foregroundColor: AppColors.amberText,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.add_rounded,
                                        size: 16),
                                    label: const Text(
                                      '+₹5 Counter',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onPressed: () =>
                                        state.courierCounter(order.id),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenLightBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppColors.primaryLight),
                                    ),
                                    child: const Text(
                                      '+₹5 applied ✓',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: const Color(0xFF00422B),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                icon: const Icon(Icons.check_circle_rounded,
                                    size: 18),
                                label: Text(
                                  'Accept Delivery for ₹${order.offerPrice}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => state.courierAccept(
                                  order.id,
                                  order.offerPrice,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final int? count;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.count,
    this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.navyMedium : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.navyMedium : Colors.grey.shade300,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.navyDark,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.navyDark,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (count != null && active) ...[
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
