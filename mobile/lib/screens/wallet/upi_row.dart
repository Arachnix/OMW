import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system.dart';
import '../../state/app_state.dart';

final _upiPattern = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');

/// Asks for (or edits) the user's UPI ID. Resolves to true when saved.
Future<bool> editUpi(BuildContext context) async {
  final state = context.read<AppState>();
  final controller = TextEditingController(text: state.upi ?? '');
  final formKey = GlobalKey<FormState>();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.ink, width: AppRadii.stroke),
      ),
      title: Text('UPI ID', style: AppText.heading),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: AppText.fieldText,
          decoration: const InputDecoration(hintText: 'name@bank'),
          validator: (v) => _upiPattern.hasMatch((v ?? '').trim())
              ? null
              : 'Enter a UPI ID like name@okaxis',
          onFieldSubmitted: (_) {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialog).pop(true);
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: Text('Cancel', style: AppText.label),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialog).pop(true);
            }
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: Text(
            'Save',
            style: AppText.label.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
  if (saved == true) await state.setUpi(controller.text);
  controller.dispose();
  return saved == true;
}

/// "Pay via UPI / vismay@okaxis >" row (Figma 125:253, 125:521, 125:646).
class UpiRow extends StatelessWidget {
  const UpiRow({super.key, this.title = 'Pay via UPI'});

  final String title;

  @override
  Widget build(BuildContext context) {
    final upi = context.watch<AppState>().upi;
    final radius = BorderRadius.circular(AppRadii.card);
    return Semantics(
      button: true,
      label: '$title, ${upi ?? 'add UPI ID'}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.ink, width: AppRadii.stroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => editUpi(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const IconTile(icon: Lucide.creditCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        upi ?? 'Add your UPI ID',
                        style: AppText.labelSmall.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SvgIcon(Lucide.chevronRight, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
