// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'people_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(team)
final teamProvider = TeamProvider._();

final class TeamProvider extends $FunctionalProvider<
        AsyncValue<List<TeamMember>>,
        List<TeamMember>,
        FutureOr<List<TeamMember>>>
    with $FutureModifier<List<TeamMember>>, $FutureProvider<List<TeamMember>> {
  TeamProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'teamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$teamHash();

  @$internal
  @override
  $FutureProviderElement<List<TeamMember>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamMember>> create(Ref ref) {
    return team(ref);
  }
}

String _$teamHash() => r'1fb4b072bd0d4a3b36bdff18ce4adc091ca73a86';

/// Adding, changing and resetting. Each returns null when it worked, or the
/// refusal, so the screen can say why. Kept alive for the same reason as the
/// other action providers: read, never watched, and it must survive its own
/// request to reload the list afterwards.

@ProviderFor(PeopleActions)
final peopleActionsProvider = PeopleActionsProvider._();

/// Adding, changing and resetting. Each returns null when it worked, or the
/// refusal, so the screen can say why. Kept alive for the same reason as the
/// other action providers: read, never watched, and it must survive its own
/// request to reload the list afterwards.
final class PeopleActionsProvider
    extends $NotifierProvider<PeopleActions, void> {
  /// Adding, changing and resetting. Each returns null when it worked, or the
  /// refusal, so the screen can say why. Kept alive for the same reason as the
  /// other action providers: read, never watched, and it must survive its own
  /// request to reload the list afterwards.
  PeopleActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'peopleActionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$peopleActionsHash();

  @$internal
  @override
  PeopleActions create() => PeopleActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$peopleActionsHash() => r'90c43fc8d9a17a2fcccc00ffd8e2a72b69b9ac8c';

/// Adding, changing and resetting. Each returns null when it worked, or the
/// refusal, so the screen can say why. Kept alive for the same reason as the
/// other action providers: read, never watched, and it must survive its own
/// request to reload the list afterwards.

abstract class _$PeopleActions extends $Notifier<void> {
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
