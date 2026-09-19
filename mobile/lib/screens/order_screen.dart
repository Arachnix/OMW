import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import '../widgets/address_edit_modal.dart';
import '../widgets/broadcast_confirmation_sheet.dart';
import '../widgets/omw_card.dart';
import '../widgets/parcel_option_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/route_card.dart';
import '../widgets/svg_icon.dart';

/// Sender home: the "onmyway-courier-screen" Figma frame.
class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  Future<void> _editAddress(
    BuildContext context, {
    required bool pickup,
  }) async {
    final state = context.read<AppState>();
    final result = await AddressEditModal.show(
      context,
      title: pickup ? 'Pickup Spot' : 'Delivery Destination',
      initial: pickup ? state.pickup : state.destination,
    );
    if (result == null) return;
    pickup ? state.setPickup(result) : state.setDestination(result);
  }

  Future<void> _broadcast(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final state = context.read<AppState>();
    final request = await state.broadcast();
    if (request == null || !context.mounted) return;
    final viewActivity = await BroadcastConfirmationSheet.show(
      context,
      request,
    );
    if (viewActivity == true) state.setSenderTab(SenderTab.activity);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      children: [
        OmwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardEyebrow(
                label: 'FAST COURIER MATCH',
                trailing: EtaBadge(minutes: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              RouteStops(
                pickup: state.pickup,
                destination: state.destination,
                onEditPickup: () => _editAddress(context, pickup: true),
                onEditDestination: () => _editAddress(context, pickup: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ParcelCargo(
          selected: state.parcel,
          onSelect: state.selectParcel,
          onClear: state.parcel == null ? null : state.clearParcel,
        ),
        const SizedBox(height: AppSpacing.lg),
        _OfferCard(offer: state.offer),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: 'Broadcast Delivery Request for ₹${state.offer}',
          leading: const Icon(
            Icons.play_arrow_outlined,
            color: AppColors.surface,
            size: 20,
          ),
          busy: state.broadcasting,
          onPressed: state.canBroadcast ? () => _broadcast(context) : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Text(
            state.parcel == null
                ? 'Choose a parcel size to continue'
                : 'Courier keeps 100% of fair value bids • Zero deduction',
            key: ValueKey(state.parcel == null),
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.inkAt(0.7)),
          ),
        ),
      ],
    );
  }
}

class _ParcelCargo extends StatelessWidget {
  const _ParcelCargo({
    required this.selected,
    required this.onSelect,
    required this.onClear,
  });

  final ParcelType? selected;
  final ValueChanged<ParcelType> onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Parcel Cargo', style: AppText.sectionTitle),
              ),
            ),
            AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: onClear == null ? 0.3 : 1,
              child: IconButton(
                onPressed: onClear,
                tooltip: 'Clear parcel selection',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const SvgIcon(AppIcons.circleX, size: 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final type in ParcelType.values) ...[
                if (type != ParcelType.values.first)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ParcelOptionCard(
                    type: type,
                    selected: type == selected,
                    onTap: () => onSelect(type),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// "delivery-offer-card" (Figma 180:176): tap-to-edit price with an
/// underline, plus the "Delivery source" dropdown.
class _OfferCard extends StatefulWidget {
  const _OfferCard({required this.offer});

  final int offer;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.offer}',
  );
  final FocusNode _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _commit();
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant _OfferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Offer changed elsewhere (e.g. a new parcel size): mirror it.
    if (oldWidget.offer != widget.offer && !_focus.hasFocus) {
      _controller.text = '${widget.offer}';
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    if (!mounted) return;
    final error = context.read<AppState>().setOffer(_controller.text);
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    return OmwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'YOUR DELIVERY OFFER',
              textAlign: TextAlign.center,
              style: AppText.cardEyebrow,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Set your price for this delivery',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.inkAt(0.6)),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: _EditablePrice(
              controller: _controller,
              focus: _focus,
              hasError: _error != null,
            ),
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _DeliverySourceDropdown(),
        ],
      ),
    );
  }
}

/// "editable-price-wrapper": the price is itself the input. A 2px cursor at
/// 60% ink and a 1.5px underline at 20% ink mark it as editable.
class _EditablePrice extends StatelessWidget {
  const _EditablePrice({
    required this.controller,
    required this.focus,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final underline = hasError
        ? AppColors.error
        : AppColors.inkAt(focus.hasFocus ? 0.6 : 0.2);
    return Semantics(
      label: 'Offer amount in rupees',
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₹', style: AppText.price),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 40),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: controller,
                      focusNode: focus,
                      style: AppText.price,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      cursorColor: AppColors.inkAt(0.6),
                      cursorWidth: 2,
                      cursorHeight: 30,
                      cursorRadius: const Radius.circular(1),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      // Losing focus commits the value (see _OfferCardState).
                      onSubmitted: (_) => focus.unfocus(),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedContainer(
              duration: AppMotion.fast,
              height: AppRadii.stroke,
              decoration: BoxDecoration(
                color: underline,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "delivery-source-dropdown": collapsible multi-select of where the order
/// comes from.
class _DeliverySourceDropdown extends StatefulWidget {
  const _DeliverySourceDropdown();

  @override
  State<_DeliverySourceDropdown> createState() =>
      _DeliverySourceDropdownState();
}

class _DeliverySourceDropdownState extends State<_DeliverySourceDropdown> {
  // Figma shows the list expanded.
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final radius = BorderRadius.circular(AppRadii.card);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillMuted,
        borderRadius: radius,
        border: Border.all(color: AppColors.ink),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: _open,
              label: 'Delivery source',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: radius,
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Delivery source',
                          style: AppText.inputLabel,
                        ),
                      ),
                      AnimatedRotation(
                        duration: AppMotion.medium,
                        curve: AppMotion.curve,
                        turns: _open ? 0 : -0.25,
                        // Inter has no ▾ glyph; Material's filled caret matches it.
                        child: const Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Divider(color: AppColors.inkAt(0.1)),
                          for (final source in DeliverySource.values)
                            _SourceOption(
                              label: source.label,
                              checked: state.sources.contains(source),
                              onTap: () => state.toggleSource(source),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: checked ? AppColors.ink : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppRadii.stroke,
                  ),
                ),
                child: checked
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.surface,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: AppText.routeValue)),
            ],
          ),
        ),
      ),
    );
  }
}
