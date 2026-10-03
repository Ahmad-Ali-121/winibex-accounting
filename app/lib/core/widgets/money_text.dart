import 'package:flutter/material.dart';

import '../money/money.dart';
import '../theme/app_theme.dart';

/// Every amount on screen goes through this.
///
/// Two reasons. Onest's default digits are proportional, so a number rendered
/// with an ordinary TextStyle will not line up in a column. And negatives are
/// red ink by accounting convention, which is a colour decision that belongs
/// in one place rather than at every call site.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.size = 14,
    this.weight = FontWeight.w500,
    this.withCurrency = false,
    this.muted = false,
  });

  /// A large figure, for a dashboard or a total row.
  const MoneyText.figure(this.amount, {super.key, this.withCurrency = true})
      : size = 20,
        weight = FontWeight.w600,
        muted = false;

  final Money amount;
  final double size;
  final FontWeight weight;
  final bool withCurrency;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final color = switch (amount) {
      final value when value.isNegative => colors.negative,
      _ when muted => colors.textMuted,
      _ => colors.text,
    };

    return Text(
      amount.format(withCurrency: withCurrency),
      style: AppText.amount(context, size: size, weight: weight).copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
