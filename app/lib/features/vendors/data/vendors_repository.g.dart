// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendors_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(vendorsRepository)
final vendorsRepositoryProvider = VendorsRepositoryProvider._();

final class VendorsRepositoryProvider extends $FunctionalProvider<
    VendorsRepository,
    VendorsRepository,
    VendorsRepository> with $Provider<VendorsRepository> {
  VendorsRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'vendorsRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$vendorsRepositoryHash();

  @$internal
  @override
  $ProviderElement<VendorsRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VendorsRepository create(Ref ref) {
    return vendorsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VendorsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VendorsRepository>(value),
    );
  }
}

String _$vendorsRepositoryHash() => r'a5e836c51380b3e4513c4573722357e762eb9505';
