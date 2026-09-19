import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'pill_button.dart';
import 'svg_icon.dart';

/// Bottom sheet for editing a pickup or destination address.
///
/// Suggestions come from local mock data; there is no geocoding or maps.
class AddressEditModal extends StatefulWidget {
  const AddressEditModal({
    super.key,
    required this.title,
    required this.initial,
  });

  final String title;
  final String initial;

  /// Resolves to the chosen address, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initial,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddressEditModal(title: title, initial: initial),
    );
  }

  @override
  State<AddressEditModal> createState() => _AddressEditModalState();
}

class _AddressEditModalState extends State<AddressEditModal> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final address = (value ?? _controller.text).trim();
    if (address.isEmpty) return;
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final suggestions = MockData.savedAddresses
        .where((a) => query.isEmpty || a.toLowerCase().contains(query))
        .toList();

    return Padding(
      // Lifts the sheet above the software keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.authGutter,
            0,
            AppSpacing.authGutter,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(widget.title, style: AppText.sectionTitle),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                autofocus: true,
                style: AppText.fieldText,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                onSubmitted: _submit,
                decoration: const InputDecoration(
                  hintText: 'Street, building or landmark',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const SvgIcon(AppIcons.mapPin),
                    minLeadingWidth: 20,
                    title: Text(suggestions[i], style: AppText.routeValue),
                    onTap: () => _submit(suggestions[i]),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: 'Use this address',
                height: 44,
                onPressed: _controller.text.trim().isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
