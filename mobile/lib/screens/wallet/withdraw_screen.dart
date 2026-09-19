import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../api/omw_api.dart';
import '../../design_system.dart';
import '../../state/app_state.dart';
import 'upi_row.dart';

/// "withdraw-earnings" (Figma 125:646) with the insufficient-balance edge
/// state. POST /api/wallet/withdraw.
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const WithdrawScreen());

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  late final TextEditingController _amount = TextEditingController(text: '500');
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text) ?? 0;

  void _set(int v) {
    _amount.text = '$v';
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    setState(() {});
  }

  Future<void> _withdraw() async {
    final state = context.read<AppState>();
    if (state.upi == null) {
      final ok = await editUpi(context);
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await state.withdraw(_value);
      if (!mounted) return;
      showSnack(context, '${rupees(_value)} sent to ${state.upi}.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = context.watch<AppState>().wallet.available;
    final over = _value > available;
    final under = _value > 0 && _value < AppState.minWithdrawal;
    final valid = _value >= AppState.minWithdrawal && !over;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            PageTitle(
              title: 'Withdraw Earnings',
              eyebrow: 'CASH OUT YOUR HUSTLE.',
              onBack: () => Navigator.of(context).pop(),
              trailing: SquareIconButton(
                icon: Lucide.circleHelp,
                tooltip: 'Help',
                onTap: () => showInfo(
                  context,
                  'Withdrawals',
                  'Withdraw available tokens to your UPI account at ₹1 per '
                      'token. Tokens locked in escrow or runner stakes can\'t '
                      'be withdrawn until those deliveries settle.',
                ),
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const InfoBox(
                    icon: Lucide.wallet,
                    text: 'Withdraw your delivery earnings directly to your UPI account.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Panel(
                    radius: AppRadii.panel,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVAILABLE BALANCE',
                          style: AppText.overline.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(rupees(available), style: AppText.displayAmount),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('ENTER AMOUNT', dark: true),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: over ? AppColors.fillWarm : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(
                        color: AppColors.ink,
                        width: over ? 3 : AppRadii.strokeBold,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('₹ ', style: AppText.displayStat),
                        Expanded(
                          child: Semantics(
                            label: 'Withdrawal amount in rupees',
                            child: TextField(
                              controller: _amount,
                              style: AppText.displayStat,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (over || under) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InlineError(
                      over
                          ? 'Amount exceeds your available balance of ${rupees(available)}.'
                          : 'Minimum withdrawal amount is ₹${AppState.minWithdrawal}.',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (final (label, v) in [
                        ('₹100', 100),
                        ('₹500', 500),
                        ('₹1,000', 1000),
                        ('Max', available),
                      ]) ...[
                        Expanded(
                          child: _Chip(
                            label: label,
                            selected: _value == v,
                            onTap: () => _set(v),
                          ),
                        ),
                        if (label != 'Max')
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('WITHDRAW TO', dark: true),
                  const UpiRow(title: 'UPI'),
                  const SizedBox(height: AppSpacing.lg),
                  InfoBox(
                    text:
                        'Withdrawals are usually processed instantly. Minimum '
                        'withdrawal amount is ₹${AppState.minWithdrawal}. No '
                        'withdrawal fees.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DisplayButton(
                    label: 'Withdraw ${rupees(_value)}',
                    busy: _busy,
                    onPressed: valid ? _withdraw : null,
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

class _Chip extends StatelessWidget {
  const _Chip({
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
        color: selected ? AppColors.inkDeep : AppColors.surface,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.ink, width: AppRadii.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                label,
                style: AppText.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.surface : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
