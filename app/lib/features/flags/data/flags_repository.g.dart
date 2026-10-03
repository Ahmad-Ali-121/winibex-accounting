// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flags_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(flagsRepository)
final flagsRepositoryProvider = FlagsRepositoryProvider._();

final class FlagsRepositoryProvider extends $FunctionalProvider<FlagsRepository,
    FlagsRepository, FlagsRepository> with $Provider<FlagsRepository> {
  FlagsRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'flagsRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$flagsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FlagsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FlagsRepository create(Ref ref) {
    return flagsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlagsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlagsRepository>(value),
    );
  }
}

String _$flagsRepositoryHash() => r'd04449dd0e0e6e1684b7fa1bde5827bc7fda6c1b';
