// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(moneyRepository)
final moneyRepositoryProvider = MoneyRepositoryProvider._();

final class MoneyRepositoryProvider extends $FunctionalProvider<MoneyRepository,
    MoneyRepository, MoneyRepository> with $Provider<MoneyRepository> {
  MoneyRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'moneyRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$moneyRepositoryHash();

  @$internal
  @override
  $ProviderElement<MoneyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MoneyRepository create(Ref ref) {
    return moneyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MoneyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MoneyRepository>(value),
    );
  }
}

String _$moneyRepositoryHash() => r'9e1a0a258c082ef677940b432c5458d77098a155';
