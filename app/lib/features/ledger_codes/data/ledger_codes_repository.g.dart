// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_codes_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerCodesRepository)
final ledgerCodesRepositoryProvider = LedgerCodesRepositoryProvider._();

final class LedgerCodesRepositoryProvider extends $FunctionalProvider<
    LedgerCodesRepository,
    LedgerCodesRepository,
    LedgerCodesRepository> with $Provider<LedgerCodesRepository> {
  LedgerCodesRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerCodesRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerCodesRepositoryHash();

  @$internal
  @override
  $ProviderElement<LedgerCodesRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerCodesRepository create(Ref ref) {
    return ledgerCodesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerCodesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerCodesRepository>(value),
    );
  }
}

String _$ledgerCodesRepositoryHash() =>
    r'9f2ddbaa6abd0c2677bc0a4e03f54372289d44ad';
