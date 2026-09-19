import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../api/omw_api.dart';
import '../../design_system.dart';
import '../../models/omw_models.dart';
import '../../state/app_state.dart';
import 'upi_row.dart';

/// "buy-tokens" (Figma 125:253).
class BuyTokensScreen extends StatefulWidget {
  const BuyTokensScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const BuyTokensScreen());

  @override
  State<BuyTokensScreen> createState() => _BuyTokensScreenState();
}

class _BuyTokensScreenState extends State<BuyTokensScreen> {
  TokenPack _pack = TokenPack.all.firstWhere((p) => p.popular);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            PageTitle(
              title: 'Buy Tokens',
              eyebrow: 'POWER MORE FAVORS.',
              onBack: () => Navigator.of(context).pop(),
              trailing: Image.asset(
                AppImages.mascotWave,
                width: 84,
                height: 78,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Semantics(
                    button: true,
                    label: 'About tokens',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      onTap: () => showInfo(
                        context,
                        'About tokens',
                        'Tokens are used to place delivery requests on OMW. '
                            'Your bounty is held in escrow and paid to the '
                            'courier only after the delivery code is verified.',
                      ),
                      child: const InfoBox(
                        outlined: true,
                        text: 'Tokens are used to place delivery requests on OMW.',
                        trailing: SvgIcon(Lucide.chevronRight, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final p in TokenPack.all) ...[
                    _PackCard(
                      pack: p,
                      selected: p == _pack,
                      onTap: () => setState(() => _pack = p),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  const UpiRow(),
                  const SizedBox(height: AppSpacing.xl),
                  DisplayButton(
                    label:
                        'Buy ${_pack.tokens} Tokens for ${rupees(_pack.priceInr)}',
                    onPressed: () =>
                        Navigator.of(context)
                            .push(ConfirmPurchaseScreen.route(_pack)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SecureNote('Secure payment via Razorpay · test mode'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.selected,
    required this.onTap,
  });

  final TokenPack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.surface : AppColors.ink;
    final radius = BorderRadius.circular(AppRadii.card);
    Widget chip(String t, {bool solid = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: solid ? fg : null,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: fg, width: AppRadii.hairline),
      ),
      child: Text(
        t,
        style: AppText.badge.copyWith(
          color: solid ? (selected ? AppColors.ink : AppColors.surface) : fg,
          fontSize: 10,
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${pack.tokens} tokens for ${rupees(pack.priceInr)}'
          '${pack.savePercent != null ? ', save ${pack.savePercent}%' : ''}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        decoration: BoxDecoration(
          color: selected ? AppColors.inkDeep : AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.ink, width: AppRadii.stroke),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? null : AppColors.fillWarm,
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                  child: SvgIcon(Lucide.coins, size: 22, color: fg),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${pack.tokens} Tokens',
                            style: AppText.displayItem.copyWith(color: fg),
                          ),
                          if (pack.popular) chip('MOST POPULAR', solid: true),
                          if (pack.savePercent != null)
                            chip('Save ${pack.savePercent}%'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '₹${pack.perToken.toStringAsFixed(1)} per token',
                        style: AppText.body.copyWith(
                          color: selected
                              ? AppColors.surface.withValues(alpha: 0.7)
                              : AppColors.inkAt(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  rupees(pack.priceInr),
                  style: AppText.displayItem.copyWith(color: fg, fontSize: 19),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgIcon(Lucide.lock, size: 16, color: AppColors.inkAt(0.6)),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppText.labelSmall.copyWith(fontSize: 13)),
      ],
    );
  }
}

/// "confirm-purchase" (Figma 125:521). Payment goes through the backend's
/// Razorpay test-network flow (create-order → verify-payment); no real money
/// moves.
class ConfirmPurchaseScreen extends StatefulWidget {
  const ConfirmPurchaseScreen({super.key, required this.pack});

  final TokenPack pack;

  static Route<void> route(TokenPack pack) =>
      MaterialPageRoute(builder: (_) => ConfirmPurchaseScreen(pack: pack));

  @override
  State<ConfirmPurchaseScreen> createState() => _ConfirmPurchaseScreenState();
}

class _ConfirmPurchaseScreenState extends State<ConfirmPurchaseScreen> {
  bool _busy = false;

  Future<void> _pay() async {
    final state = context.read<AppState>();
    if (state.upi == null) {
      final ok = await editUpi(context);
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final r = await state.buyTokens(widget.pack);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        PaymentResultScreen.route(pack: widget.pack, result: r),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context)
          .push(PaymentResultScreen.route(pack: widget.pack, error: e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pack;
    Widget row(String k, String v, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: strong
                  ? AppText.label.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    )
                  : AppText.label.copyWith(color: AppColors.inkAt(0.6)),
            ),
          ),
          Text(
            v,
            style: strong
                ? AppText.displayItem.copyWith(fontSize: 19)
                : AppText.label.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            PageTitle(
              title: 'Confirm Purchase',
              eyebrow: 'REVIEW AND PAY.',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Panel(
                    radius: AppRadii.panel,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              const IconTile(icon: Lucide.coins, size: 40),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          '${p.tokens} Tokens',
                                          style: AppText.displayItem,
                                        ),
                                        if (p.popular)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.ink,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadii.pill,
                                                  ),
                                            ),
                                            child: Text(
                                              'MOST POPULAR',
                                              style: AppText.badge.copyWith(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '₹${p.perToken.toStringAsFixed(1)} per token',
                                      style: AppText.bodyMuted,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                rupees(p.priceInr),
                                style: AppText.displayItem.copyWith(
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                          child: Column(
                            children: [
                              row('Amount', rupees(p.priceInr)),
                              row('GST (18%)', rupees(p.gstInr)),
                              const Divider(color: AppColors.divider),
                              row(
                                'Total Payable',
                                rupees(p.totalInr),
                                strong: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const UpiRow(),
                  const SizedBox(height: AppSpacing.xl),
                  DisplayButton(
                    label: 'Pay ${rupees(p.totalInr)}',
                    busy: _busy,
                    onPressed: _pay,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SecureNote(
                    'Secured by Razorpay · test mode, no real charge',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.fillWarm,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHAT YOU GET?',
                          style: AppText.label.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        for (final t in [
                          '${p.tokens} tokens credited instantly',
                          'Use tokens to place delivery requests',
                          'No expiry on tokens',
                          'Safe & secure payments',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Row(
                              children: [
                                const SvgIcon(Lucide.circleCheck, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    t,
                                    style: AppText.body.copyWith(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "payment-successful" (Figma 125:605) and "Payment Failed" (edge state 7).
class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.pack,
    this.result,
    this.error,
  });

  final TokenPack pack;
  final PurchaseResult? result;
  final String? error;

  static Route<void> route({
    required TokenPack pack,
    PurchaseResult? result,
    String? error,
  }) => MaterialPageRoute(
    builder: (_) =>
        PaymentResultScreen(pack: pack, result: result, error: error),
  );

  void _toWallet(BuildContext context) {
    context.read<AppState>().openWallet();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final ok = result != null;
    final total = context.watch<AppState>().wallet.total;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SquareIconButton(
                icon: Lucide.circleX,
                tooltip: 'Close',
                onTap: () =>
                    ok ? _toWallet(context) : Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (ok)
              Image.asset(
                AppImages.mascotSuccess,
                height: 200,
                fit: BoxFit.contain,
                semanticLabel: 'Mascot celebrating',
              )
            else
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 2.5),
                  ),
                  child: const SvgIcon(Lucide.circleAlert, size: 36),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                ok ? 'Payment Successful!' : 'Payment Failed',
                textAlign: TextAlign.center,
                style: AppText.displayTitle.copyWith(fontSize: 26),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ok
                  ? '${result!.tokens} tokens have been added to your wallet.'
                  : 'Your transaction of ${rupees(pack.totalInr)} could not be '
                        'completed. No tokens have been added to your wallet.',
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (ok)
              Panel(
                radius: AppRadii.panel,
                stroke: AppRadii.strokeBold,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: const BoxDecoration(
                        color: AppColors.fillWarm,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadii.panel - 2),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.ink,
                            width: AppRadii.strokeBold,
                          ),
                        ),
                      ),
                      child: Text(
                        '+ ${result!.tokens} Tokens',
                        textAlign: TextAlign.center,
                        style: AppText.displayStat,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          _KV('Total Balance', '$total Tokens'),
                          const Divider(color: AppColors.divider),
                          _KV(
                            'Transaction ID',
                            '#${result!.transactionId}',
                            trailing: IconButton(
                              tooltip: 'Copy transaction ID',
                              icon: const SvgIcon(Lucide.copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: result!.transactionId),
                                );
                                showSnack(context, 'Transaction ID copied.');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happened?',
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${error ?? 'The payment was not completed.'} Don\'t worry '
                      '— no money was deducted.',
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            if (ok)
              DisplayButton(
                label: 'Go to Wallet',
                onPressed: () => _toWallet(context),
              )
            else ...[
              DisplayButton(
                label: 'Try Payment Again',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.md),
              DisplayButton(
                label: 'Choose Another Method',
                outlined: true,
                onPressed: () => Navigator.of(context)
                  ..pop()
                  ..pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v, {this.trailing});

  final String k;
  final String v;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: AppText.label.copyWith(color: AppColors.inkAt(0.6)),
            ),
          ),
          Flexible(
            child: Text(
              v,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
