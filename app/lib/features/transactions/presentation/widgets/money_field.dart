import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';

/// Takes an amount from the person and keeps minor units in the draft.
///
/// Parsing is integer only: the text is split on the decimal point and the two
/// halves are combined, so nothing ever becomes a double on the way in. Shared
/// by the amount step and the tax and charge lines.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.label,
    required this.value,
    required this.currency,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final Money? value;
  final String currency;
  final ValueChanged<Money> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value == null || value!.isZero ? '' : value!.format(withCurrency: false),
      decoration: InputDecoration(labelText: label, prefixText: '$currency ', helperText: helper),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: AppText.amount(context),
      onChanged: (text) => onChanged(
        Money(minorUnits: parseMinorUnits(text), currency: currency),
      ),
    );
  }
}

/// "5,953.5" becomes 595350. No double anywhere in the conversion.
int parseMinorUnits(String text, {int decimals = 2}) {
  final cleaned = text.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return 0;

  final parts = cleaned.split('.');
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first) ?? 0;
  if (parts.length == 1) return whole * 100;

  final fraction = parts[1].padRight(decimals, '0').substring(0, decimals);
  final minor = int.tryParse(fraction) ?? 0;
  return whole * 100 + minor;
}
