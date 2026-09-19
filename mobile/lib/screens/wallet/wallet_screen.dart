import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../design_system.dart';
import '../../models/omw_models.dart';
import '../../models/order_model.dart';
import '../../state/app_state.dart';
import 'buy_tokens_screen.dart';
import 'withdraw_screen.dart';

enum _LedgerTab { transactions, earnings, tokens }

/// "wallet-and-earnings" (Figma 125:127) and its zero-balance edge state.
/// Balances and the ledger come from /api/wallet/balance and
/// /api/wallet/transactions.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  _LedgerTab _tab = _LedgerTab.transactions;
  final _scroll = ScrollController();
  final _ledgerKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showHistory() {
    setState(() => _tab = _LedgerTab.tokens);
    final ctx = _ledgerKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: AppMotion.medium);
    }
  }

  List<WalletTx> _filtered(List<WalletTx> all) => switch (_tab) {
    _LedgerTab.transactions => all,
    _LedgerTab.earnings => all.where((t) => t.isEarning).toList(),
    _LedgerTab.tokens =>
      all
          .where(
            (t) => t.type == TxType.purchase || t.type == TxType.withdrawal,
          )
          .toList(),
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final w = state.wallet;
    final zero = w.total == 0;
    final txs = _filtered(state.transactions);

    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        children: [
          PageTitle(
            title: 'Wallet & Earnings',
            eyebrow: 'FUEL YOUR MOVEMENT.',
            onBack: () => state.role == AppRole.sender
                ? state.setSenderTab(SenderTab.home)
                : state.setCourierTab(CourierTab.feed),
            trailing: SquareIconButton(
              icon: Lucide.history,
              tooltip: 'Token history',
              onTap: _showHistory,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.ink,
              onRefresh: state.refresh,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _BalanceCard(wallet: w),
                  const SizedBox(height: AppSpacing.lg),
                  if (zero)
                    _HowItWorks(
                      onDeliver: () {
                        state.setRole(AppRole.courier);
                      },
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: rupees(state.earningsThisMonth),
                            label: 'Total Earnings',
                            caption: 'This Month',
                            icon: AppIcons.box,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StatCard(
                            value: '${state.deliveriesCompleted}',
                            label: 'Deliveries',
                            caption: 'Completed',
                            icon: Lucide.trendingUp,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SingleChildScrollView(
                      key: _ledgerKey,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final t in _LedgerTab.values) ...[
                            _TabPill(
                              label: switch (t) {
                                _LedgerTab.transactions => 'Transactions',
                                _LedgerTab.earnings => 'Earnings',
                                _LedgerTab.tokens => 'Token History',
                              },
                              selected: _tab == t,
                              onTap: () => setState(() => _tab = t),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (txs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Nothing here yet.',
                          textAlign: TextAlign.center,
                          style: AppText.bodyMuted,
                        ),
                      )
                    else
                      ..._grouped(context, state, txs),
                    const SizedBox(height: AppSpacing.lg),
                    Panel(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need more tokens?',
                                  style: AppText.label.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Buy tokens to place delivery requests.',
                                  style: AppText.bodyMuted.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context)
                                    .push(BuyTokensScreen.route()),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.inkDeep,
                              minimumSize: const Size(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.field,
                                ),
                              ),
                            ),
                            child: Text(
                              'Buy Tokens →',
                              style: AppText.displaySmall.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    InfoBox(
                      text:
                          'Tokens are used to place delivery requests. Earn '
                          'cash by delivering!',
                      trailing: TextButton(
                        onPressed: () => showInfo(
                          context,
                          'How tokens work',
                          '1 token = ₹1. When you place a request, its bounty '
                              'is locked in escrow and released to the courier '
                              'only after the delivery code is verified. '
                              'Couriers lock a 25% commitment stake when they '
                              'accept a job and get it back on delivery.',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size(48, 40),
                        ),
                        child: Text(
                          'Learn more',
                          style: AppText.labelSmall.copyWith(
                            color: AppColors.ink,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _grouped(
    BuildContext context,
    AppState state,
    List<WalletTx> txs,
  ) {
    final now = DateTime.now();
    String bucket(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(day).inDays;
      if (diff == 0) return 'TODAY';
      if (diff == 1) return 'YESTERDAY';
      return DateFormat('d MMM yyyy').format(d).toUpperCase();
    }

    final groups = <String, List<WalletTx>>{};
    for (final t in txs) {
      groups.putIfAbsent(bucket(t.timestamp), () => []).add(t);
    }
    return [
      for (final e in groups.entries) ...[
        SectionLabel(e.key),
        MenuGroup(
          children: [for (final t in e.value) _TxRow(tx: t, state: state)],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    ];
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final zero = wallet.total == 0;
    final state = context.read<AppState>();
    return Panel(
      radius: AppRadii.panel,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOTAL BALANCE', style: AppText.overline.copyWith(fontSize: 13)),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label: 'Total balance ${rupees(wallet.total)}',
            excludeSemantics: true,
            child: Text(rupees(wallet.total), style: AppText.displayAmount),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (zero)
            Text('No tokens available', style: AppText.bodyMuted)
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${rupees(wallet.available)} Available',
                  style: AppText.bodyMuted.copyWith(fontSize: 15),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1.5,
                  height: 18,
                  color: AppColors.ink,
                ),
                InkWell(
                  onTap: () => showInfo(
                    context,
                    'In escrow',
                    '${rupees(wallet.escrow)} is locked for your open requests '
                        'and ${rupees(wallet.staked)} is staked on jobs you '
                        'accepted. It is released when each delivery is '
                        'verified or cancelled.',
                  ),
                  child: Text(
                    '${rupees(wallet.escrow + wallet.staked)} In Escrow (i)',
                    style: AppText.label.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: DisplayButton(
                  label: 'Buy Tokens',
                  icon: Lucide.coins,
                  height: 44,
                  radius: AppRadii.iconButton,
                  textStyle: AppText.displaySmall.copyWith(fontSize: 14),
                  onPressed: () =>
                      Navigator.of(context).push(BuyTokensScreen.route()),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DisplayButton(
                  label: zero ? 'Start Delivering' : 'Withdraw to UPI',
                  icon: AppIcons.send,
                  outlined: true,
                  height: 44,
                  radius: AppRadii.iconButton,
                  textStyle: AppText.displaySmall.copyWith(fontSize: 14),
                  onPressed: zero
                      ? () => state.setRole(AppRole.courier)
                      : () =>
                            Navigator.of(context).push(WithdrawScreen.route()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Zero-balance explainer (edge state 6).
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.onDeliver});

  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    Widget line(String t) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          const SvgIcon(Lucide.circleCheck, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(t, style: AppText.body)),
        ],
      ),
    );
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How Wallet & Tokens Work',
            style: AppText.label.copyWith(fontWeight: FontWeight.w800),
          ),
          line('Tokens are used to place delivery requests'),
          line('Earn actual cash by delivering campus orders'),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
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
      child: AnimatedContainer(
        duration: AppMotion.medium,
        decoration: BoxDecoration(
          color: selected ? AppColors.inkDeep : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.ink, width: AppRadii.stroke),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.surface : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx, required this.state});

  final WalletTx tx;
  final AppState state;

  String get _subtitle {
    final task = tx.taskId == null ? null : state.taskById(tx.taskId!);
    if (task != null) return '${task.shortPickup} → ${task.shortDrop}';
    return switch (tx.type) {
      TxType.purchase => 'Razorpay · test mode',
      TxType.withdrawal => tx.reference.replaceFirst('UPI Payout to ', ''),
      _ => tx.reference,
    };
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (tx.type) {
      TxType.purchase => Lucide.coins,
      TxType.withdrawal || TxType.voucher => Lucide.arrowUpRight,
      _ when tx.tokens >= 0 => Lucide.arrowDownLeft,
      _ => Lucide.arrowUpRight,
    };
    final amount = tx.tokens == 0
        ? '₹0'
        : '${tx.tokens > 0 ? '+' : ''}${rupees(tx.tokens)}';
    return Semantics(
      label: '${tx.title}, $_subtitle, $amount',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconTile(icon: icon, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: AppText.label.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelSmall.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppText.displaySmall.copyWith(fontSize: 15),
                ),
                Text(
                  DateFormat('h:mm a').format(tx.timestamp),
                  style: AppText.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
