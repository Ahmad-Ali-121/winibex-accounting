// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheques_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chequesRepository)
final chequesRepositoryProvider = ChequesRepositoryProvider._();

final class ChequesRepositoryProvider extends $FunctionalProvider<
    ChequesRepository,
    ChequesRepository,
    ChequesRepository> with $Provider<ChequesRepository> {
  ChequesRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'chequesRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chequesRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChequesRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChequesRepository create(Ref ref) {
    return chequesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChequesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChequesRepository>(value),
    );
  }
}

String _$chequesRepositoryHash() => r'8e7cfad526e21f1037ef90c6beaf7650d1f3d3d4';
