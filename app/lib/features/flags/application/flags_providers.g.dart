// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flags_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openFlags)
final openFlagsProvider = OpenFlagsProvider._();

final class OpenFlagsProvider extends $FunctionalProvider<
        AsyncValue<List<EntryFlag>>, List<EntryFlag>, FutureOr<List<EntryFlag>>>
    with $FutureModifier<List<EntryFlag>>, $FutureProvider<List<EntryFlag>> {
  OpenFlagsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'openFlagsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$openFlagsHash();

  @$internal
  @override
  $FutureProviderElement<List<EntryFlag>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<EntryFlag>> create(Ref ref) {
    return openFlags(ref);
  }
}

String _$openFlagsHash() => r'49f6479c6b2b73550118f906794d1df66d7e1b3e';
