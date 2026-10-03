// Money formatting. No widgets, no network, so these run instantly and are the
// first place to look when a figure appears wrong on screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:winibex_accounting/core/money/money.dart';

void main() {
  test('minor units are formatted with grouping and two decimals', () {
    expect(const Money.pkr(595300).format(), 'PKR 5,953.00');
    expect(const Money.pkr(50000000).format(), 'PKR 500,000.00');
    expect(const Money.pkr(0).format(), 'PKR 0.00');
    expect(const Money.pkr(5).format(), 'PKR 0.05');
    expect(const Money.pkr(99).format(), 'PKR 0.99');
  });

  test('the currency can be left off, for a column that has a header', () {
    expect(const Money.pkr(595300).format(withCurrency: false), '5,953.00');
  });

  test('negatives keep their sign in front of the currency', () {
    expect(const Money.pkr(-595300).format(), '-PKR 5,953.00');
    expect(const Money.pkr(-50).format(withCurrency: false), '-0.50');
    expect(const Money.pkr(-595300).isNegative, isTrue);
  });

  test('a figure past what a double holds exactly is still exact', () {
    // 90,071,992,547,409.91 in paisa. A double loses the last digit here.
    expect(const Money.pkr(9007199254740991).format(withCurrency: false), '90,071,992,547,409.91');
  });

  test('the JSON shape from the API round trips', () {
    final money = Money.fromJson({'minor': 595300, 'currency': 'PKR'});
    expect(money.minorUnits, 595300);
    expect(money.currency, 'PKR');
    expect(money.toJson(), {'minor': 595300, 'currency': 'PKR'});
  });

  test('a decimal in a money field is refused rather than rounded', () {
    expect(
      () => Money.fromJson({'minor': 5953.5, 'currency': 'PKR'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('a foreign amount carries its own currency', () {
    expect(const Money(minorUnits: 2000, currency: 'USD').format(), 'USD 20.00');
  });

  test('two amounts are equal only if the currency matches too', () {
    expect(const Money.pkr(100), const Money(minorUnits: 100, currency: 'PKR'));
    expect(const Money.pkr(100) == const Money(minorUnits: 100, currency: 'USD'), isFalse);
  });
}
