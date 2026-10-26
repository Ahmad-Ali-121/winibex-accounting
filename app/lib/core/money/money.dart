/// Money Class - Used to handle money amounts safely across the app.
///
/// Mirrors `api/core/money.js`.
///
/// WHY WE USE MINOR UNITS (PAISA/CENTS):
/// Money is always stored as a whole integer of minor units (e.g., paisa for PKR,
/// cents for USD).
/// Example: PKR 5,953.00 is stored as 595300 paisa.
/// We NEVER use floating-point numbers (`double`) for money because computers can make
/// rounding errors with decimals (for example, in Dart/JS 0.1 + 0.2 is 0.30000000000000004).
///
/// RULE FOR CALCULATION:
/// The mobile/web app NEVER calculates balances or totals itself.
/// All calculations and totals come directly from the backend API.
/// This class is only used to store, pass, and format money for display on screen.
library;

import 'package:flutter/foundation.dart';

/// `@immutable` means once a Money object is created, its values cannot be changed.
@immutable
class Money {
  /// Standard constructor: Creates a Money instance with a specific amount and currency.
  const Money({required this.minorUnits, required this.currency});

  /// Helper constructor for Pakistani Rupees (PKR).
  /// Example: `Money.pkr(10000)` creates PKR 100.00.
  const Money.pkr(this.minorUnits) : currency = 'PKR';

  /// A quick reference constant for zero money in PKR (PKR 0.00).
  static const zero = Money.pkr(0);

  /// Amount stored in smallest units (e.g., 595300 minor units = 5,953.00 PKR).
  final int minorUnits;

  /// Currency code (e.g., 'PKR', 'USD').
  final String currency;

  /// Creates a `Money` object from JSON data received from the backend API.
  ///
  /// Expected JSON shape: `{ "minor": 595300, "currency": "PKR" }`
  factory Money.fromJson(Map<String, dynamic> json) {
    final minor = json['minor'];

    // Ensure the server sent an integer. If it's not an integer, throw an error
    // because money amounts must always be exact whole minor units.
    if (minor is! int) {
      throw FormatException('A money amount must be a whole number of minor units, got $minor');
    }

    // Default to 'PKR' if currency is not specified in the JSON.
    return Money(minorUnits: minor, currency: json['currency'] as String? ?? 'PKR');
  }

  /// Converts this `Money` object into a JSON Map to send to the backend API.
  Map<String, dynamic> toJson() => {'minor': minorUnits, 'currency': currency};

  /// Returns true if the amount is negative (less than zero).
  bool get isNegative => minorUnits < 0;

  /// Returns true if the amount is zero.
  bool get isZero => minorUnits == 0;

  /// Formats the money into a readable text string for display on screen.
  ///
  /// Examples:
  /// - `Money.pkr(595300).format()` -> `"PKR 5,953.00"`
  /// - `Money.pkr(-595300).format()` -> `"-PKR 5,953.00"`
  /// - `Money.pkr(595300).format(withCurrency: false)` -> `"5,953.00"`
  ///
  /// Note: The formatting works purely on integer digit manipulation without
  /// converting to `double` (e.g., without dividing by 100) to avoid any precision loss.
  String format({bool withCurrency = true, int decimals = 2}) {
    // Check if the amount is negative
    final negative = minorUnits < 0;

    // Convert positive amount to string and pad with zeros if needed (e.g. 5 becomes "005")
    final digits = minorUnits.abs().toString().padLeft(decimals + 1, '0');

    // Split into whole currency units (Rupees) and fractional units (Paisa)
    final whole = digits.substring(0, digits.length - decimals);
    final fraction = digits.substring(digits.length - decimals);

    // Add comma separators every 3 digits for readability (e.g. "10000" becomes "10,000")
    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
      grouped.write(whole[i]);
    }

    // Build final output string
    final sign = negative ? '-' : '';
    final prefix = withCurrency ? '$currency ' : '';
    return decimals == 0 ? '$sign$prefix$grouped' : '$sign$prefix$grouped.$fraction';
  }

  /// Compares two `Money` objects. They are equal if both `minorUnits` and `currency` match.
  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits && other.currency == currency;

  /// Generates a hash code based on `minorUnits` and `currency`.
  @override
  int get hashCode => Object.hash(minorUnits, currency);

  /// Automatically calls `format()` when converting `Money` to a string.
  @override
  String toString() => format();
}
