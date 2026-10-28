// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendors_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(vendorList)
final vendorListProvider = VendorListProvider._();

final class VendorListProvider extends $FunctionalProvider<
        AsyncValue<List<Vendor>>, List<Vendor>, FutureOr<List<Vendor>>>
    with $FutureModifier<List<Vendor>>, $FutureProvider<List<Vendor>> {
  VendorListProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'vendorListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$vendorListHash();

  @$internal
  @override
  $FutureProviderElement<List<Vendor>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Vendor>> create(Ref ref) {
    return vendorList(ref);
  }
}

String _$vendorListHash() => r'bd338e8473a7aca6b2450f0314f0ccae2a7bd465';

/// Adding and changing vendors. Returns null when it worked, or the refusal.
/// Kept alive like the other action providers, so it survives its own request
/// to reload the list.

@ProviderFor(VendorActions)
final vendorActionsProvider = VendorActionsProvider._();

/// Adding and changing vendors. Returns null when it worked, or the refusal.
/// Kept alive like the other action providers, so it survives its own request
/// to reload the list.
final class VendorActionsProvider
    extends $NotifierProvider<VendorActions, void> {
  /// Adding and changing vendors. Returns null when it worked, or the refusal.
  /// Kept alive like the other action providers, so it survives its own request
  /// to reload the list.
  VendorActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'vendorActionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$vendorActionsHash();

  @$internal
  @override
  VendorActions create() => VendorActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$vendorActionsHash() => r'0b5fcd7c63f12a71355d036471e35a8da7b8548e';

/// Adding and changing vendors. Returns null when it worked, or the refusal.
/// Kept alive like the other action providers, so it survives its own request
/// to reload the list.

abstract class _$VendorActions extends $Notifier<void> {
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
