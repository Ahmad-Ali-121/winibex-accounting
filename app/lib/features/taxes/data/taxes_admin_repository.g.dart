// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taxes_admin_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taxesAdminRepository)
final taxesAdminRepositoryProvider = TaxesAdminRepositoryProvider._();

final class TaxesAdminRepositoryProvider extends $FunctionalProvider<
    TaxesAdminRepository,
    TaxesAdminRepository,
    TaxesAdminRepository> with $Provider<TaxesAdminRepository> {
  TaxesAdminRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'taxesAdminRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$taxesAdminRepositoryHash();

  @$internal
  @override
  $ProviderElement<TaxesAdminRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaxesAdminRepository create(Ref ref) {
    return taxesAdminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaxesAdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaxesAdminRepository>(value),
    );
  }
}

String _$taxesAdminRepositoryHash() =>
    r'42fc49edb43c91fa2dcb5da92040452ea555888b';
