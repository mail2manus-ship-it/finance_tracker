import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';

/// Large, prominent amount entry field -- the single most-used input in
/// the app, so it gets its own oversized styling to support the "add an
/// expense in under 10 seconds" goal from the spec.
class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;

  const AmountField({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: Validators.amount,
      autofocus: true,
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: accentColor,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        prefixText: '${AppConstants.defaultCurrencySymbol} ',
        prefixStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: accentColor.withValues(alpha: 0.7),
        ),
        hintText: '0.00',
      ),
    );
  }
}
