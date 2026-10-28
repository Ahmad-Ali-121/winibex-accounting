// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_options_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Taxes that can be added by hand to an entry on [date] going [direction].

@ProviderFor(taxOptions)
final taxOptionsProvider = TaxOptionsFamily._();

/// Taxes that can be added by hand to an entry on [date] going [direction].

final class TaxOptionsProvider extends $FunctionalProvider<
        AsyncValue<List<TaxOption>>, List<TaxOption>, FutureOr<List<TaxOption>>>
    with $FutureModifier<List<TaxOption>>, $FutureProvider<List<TaxOption>> {
  /// Taxes that can be added by hand to an entry on [date] going [direction].
  TaxOptionsProvider._(
      {required TaxOptionsFamily super.from,
      required ({
        String date,
        String direction,
      })
          super.argument})
      : super(
          retry: noRetry,
          name: r'taxOptionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$taxOptionsHash();

  @override
  String toString() {
    return r'taxOptionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<TaxOption>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TaxOption>> create(Ref ref) {
    final argument = this.argument as ({
      String date,
      String direction,
    });
    return taxOptions(
      ref,
      date: argument.date,
      direction: argument.direction,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TaxOptionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taxOptionsHash() => r'c05d4b49bf78fac719fb849c41ff8707cac757a5';

/// Taxes that can be added by hand to an entry on [date] going [direction].

final class TaxOptionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<List<TaxOption>>,
            ({
              String date,
              String direction,
            })> {
  TaxOptionsFamily._()
      : super(
          retry: noRetry,
          name: r'taxOptionsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Taxes that can be added by hand to an entry on [date] going [direction].

  TaxOptionsProvider call({
    required String date,
    required String direction,
  }) =>
      TaxOptionsProvider._(argument: (
        date: date,
        direction: direction,
      ), from: this);

  @override
  String toString() => r'taxOptionsProvider';
}

/// Everyone Winibex pays, for the payee picker on the tax step.

@ProviderFor(vendorOptions)
final vendorOptionsProvider = VendorOptionsProvider._();

/// Everyone Winibex pays, for the payee picker on the tax step.

final class VendorOptionsProvider extends $FunctionalProvider<
        AsyncValue<List<VendorOption>>,
        List<VendorOption>,
        FutureOr<List<VendorOption>>>
    with
        $FutureModifier<List<VendorOption>>,
        $FutureProvider<List<VendorOption>> {
  /// Everyone Winibex pays, for the payee picker on the tax step.
  VendorOptionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'vendorOptionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$vendorOptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<VendorOption>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<VendorOption>> create(Ref ref) {
    return vendorOptions(ref);
  }
}

String _$vendorOptionsHash() => r'621975ee60238913dfcf19dd9f9fbcce01d35333';

/// The cost accounts a charge may go to: every expense account behind a
/// money-out category, once each, in code order. The server checks the
/// choice again. Decision 064.

@ProviderFor(chargeAccounts)
final chargeAccountsProvider = ChargeAccountsProvider._();

/// The cost accounts a charge may go to: every expense account behind a
/// money-out category, once each, in code order. The server checks the
/// choice again. Decision 064.

final class ChargeAccountsProvider extends $FunctionalProvider<
        AsyncValue<List<ChargeAccount>>,
        List<ChargeAccount>,
        FutureOr<List<ChargeAccount>>>
    with
        $FutureModifier<List<ChargeAccount>>,
        $FutureProvider<List<ChargeAccount>> {
  /// The cost accounts a charge may go to: every expense account behind a
  /// money-out category, once each, in code order. The server checks the
  /// choice again. Decision 064.
  ChargeAccountsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'chargeAccountsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chargeAccountsHash();

  @$internal
  @override
  $FutureProviderElement<List<ChargeAccount>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChargeAccount>> create(Ref ref) {
    return chargeAccounts(ref);
  }
}

String _$chargeAccountsHash() => r'eb4e9c25a14279067481dae69b031dc46770a75f';
