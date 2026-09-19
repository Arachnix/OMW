import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Four large code boxes ("Enter Delivery Code", Figma 120:218) backed by a
/// single hidden text field, so paste, backspace and the numeric keyboard
/// all work natively.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.controller,
    this.length = 4,
    this.error = false,
    this.enabled = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool error;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(() => setState(() {}));
  }

  void _changed() {
    setState(() {});
    final v = widget.controller.text;
    if (v.length == widget.length) widget.onCompleted?.call(v);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return Semantics(
      label: 'Delivery code, ${widget.length} digits',
      textField: true,
      child: GestureDetector(
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden input that owns the keyboard.
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.enabled,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  _box(i, text),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(int i, String text) {
    final filled = i < text.length;
    final active = _focus.hasFocus && i == text.length;
    final strong = filled || active || widget.error;
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.error ? AppColors.fillWarm : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(
          color: strong ? AppColors.ink : AppColors.divider,
          width: widget.error || active ? 2.5 : AppRadii.strokeBold,
        ),
      ),
      child: filled
          ? Text(text[i], style: AppText.displayStat.copyWith(fontSize: 28))
          : active
          ? Container(width: 2, height: 26, color: AppColors.ink)
          : null,
    );
  }
}
