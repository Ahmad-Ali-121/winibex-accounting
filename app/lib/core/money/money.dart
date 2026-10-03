/// Money, as one type.
///
/// Mirrors `api/core/money.js`. An amount is a whole number of minor units:
/// paisa for PKR, cents for USD. Never a double, anywhere, including JSON
/// parsing. 0.1 + 0.2 is not 0.3 in Dart either.
///
/// The app never adds money to produce a total it then shows as a balance.
/// Totals come from the API. The only arithmetic here is for display.
library;

import 'package:flutter/foundation.dart';

@immutable
class Money {
  const Money({required this.minorUnits, required this.currency});

  const Money.pkr(this.minorUnits) : currency = 'PKR';

  static const zero = Money.pkr(0);

  /// Whole minor units. 595300 is PKR 5,953.00.
  final int minorUnits;
  final String currency;

  /// The shape every money field takes in the API, from docs/API.md:
  ///   { "minor": 595300, "currency": "PKR" }
  factory Money.fromJson(Map<String, dynamic> json) {
    final minor = json['minor'];
    if (minor is! int) {
      // A double here would mean the server sent a decimal, which it never
      // does. Failing loudly beats rounding quietly.
      throw FormatException('A money amount must be a whole number of minor units, got $minor');
    }
    return Money(minorUnits: minor, currency: json['currency'] as String? ?? 'PKR');
  }

  Map<String, dynamic> toJson() => {'minor': minorUnits, 'currency': currency};

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;

  /// "PKR 5,953.00", or "-PKR 5,953.00". Formatting lives here and nowhere
  /// else, so a change to grouping or to how negatives read happens once.
  ///
  /// Built from the integer, digit by digit. Dividing by 100 to format would
  /// put every amount through a double on the way to the screen.
  String format({bool withCurrency = true, int decimals = 2}) {
    final negative = minorUnits < 0;
    final digits = minorUnits.abs().toString().padLeft(decimals + 1, '0');

    final whole = digits.substring(0, digits.length - decimals);
    final fraction = digits.substring(digits.length - decimals);

    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
      grouped.write(whole[i]);
    }

    final sign = negative ? '-' : '';
    final prefix = withCurrency ? '$currency ' : '';
    return decimals == 0 ? '$sign$prefix$grouped' : '$sign$prefix$grouped.$fraction';
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits && other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => format();
}
