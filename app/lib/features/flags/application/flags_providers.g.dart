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

/// Marking a flag reviewed. Returns null when it worked, or the refusal, so the
/// screen can say why. Never retried on a guess. Decision 056, defect D2.
///
/// Kept alive: it is read, never watched, so an auto-disposing provider could
/// be disposed during the request and then skip reloading the list.

@ProviderFor(FlagActions)
final flagActionsProvider = FlagActionsProvider._();

/// Marking a flag reviewed. Returns null when it worked, or the refusal, so the
/// screen can say why. Never retried on a guess. Decision 056, defect D2.
///
/// Kept alive: it is read, never watched, so an auto-disposing provider could
/// be disposed during the request and then skip reloading the list.
final class FlagActionsProvider extends $NotifierProvider<FlagActions, void> {
  /// Marking a flag reviewed. Returns null when it worked, or the refusal, so the
  /// screen can say why. Never retried on a guess. Decision 056, defect D2.
  ///
  /// Kept alive: it is read, never watched, so an auto-disposing provider could
  /// be disposed during the request and then skip reloading the list.
  FlagActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'flagActionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$flagActionsHash();

  @$internal
  @override
  FlagActions create() => FlagActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$flagActionsHash() => r'f4e93d2f926d7a52d8506b8f1b10817c2d0d23c8';

/// Marking a flag reviewed. Returns null when it worked, or the refusal, so the
/// screen can say why. Never retried on a guess. Decision 056, defect D2.
///
/// Kept alive: it is read, never watched, so an auto-disposing provider could
/// be disposed during the request and then skip reloading the list.

abstract class _$FlagActions extends $Notifier<void> {
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
