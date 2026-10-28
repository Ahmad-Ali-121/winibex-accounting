// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bulkRepository)
final bulkRepositoryProvider = BulkRepositoryProvider._();

final class BulkRepositoryProvider
    extends $FunctionalProvider<BulkRepository, BulkRepository, BulkRepository>
    with $Provider<BulkRepository> {
  BulkRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bulkRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bulkRepositoryHash();

  @$internal
  @override
  $ProviderElement<BulkRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BulkRepository create(Ref ref) {
    return bulkRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BulkRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BulkRepository>(value),
    );
  }
}

String _$bulkRepositoryHash() => r'9be1c346a0a2afcbeb8b0ae1d2e5462c85768f35';
