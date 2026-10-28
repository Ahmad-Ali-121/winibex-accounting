// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taxes_admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taxesOverview)
final taxesOverviewProvider = TaxesOverviewProvider._();

final class TaxesOverviewProvider extends $FunctionalProvider<
        AsyncValue<TaxesOverview>, TaxesOverview, FutureOr<TaxesOverview>>
    with $FutureModifier<TaxesOverview>, $FutureProvider<TaxesOverview> {
  TaxesOverviewProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'taxesOverviewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$taxesOverviewHash();

  @$internal
  @override
  $FutureProviderElement<TaxesOverview> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TaxesOverview> create(Ref ref) {
    return taxesOverview(ref);
  }
}

String _$taxesOverviewHash() => r'ea9be3a8e06068b2b2bc21bb054cb0591c60ada8';

/// Every change on the taxes screen. Null when it worked, or the refusal.

@ProviderFor(TaxAdminActions)
final taxAdminActionsProvider = TaxAdminActionsProvider._();

/// Every change on the taxes screen. Null when it worked, or the refusal.
final class TaxAdminActionsProvider
    extends $NotifierProvider<TaxAdminActions, void> {
  /// Every change on the taxes screen. Null when it worked, or the refusal.
  TaxAdminActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'taxAdminActionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$taxAdminActionsHash();

  @$internal
  @override
  TaxAdminActions create() => TaxAdminActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$taxAdminActionsHash() => r'772cc90d80ff048a3533c00d1a722ef895a70f59';

/// Every change on the taxes screen. Null when it worked, or the refusal.

abstract class _$TaxAdminActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
