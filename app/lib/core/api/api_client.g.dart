// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accessTokenHolder)
final accessTokenHolderProvider = AccessTokenHolderProvider._();

final class AccessTokenHolderProvider extends $FunctionalProvider<
    AccessTokenHolder,
    AccessTokenHolder,
    AccessTokenHolder> with $Provider<AccessTokenHolder> {
  AccessTokenHolderProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accessTokenHolderProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accessTokenHolderHash();

  @$internal
  @override
  $ProviderElement<AccessTokenHolder> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccessTokenHolder create(Ref ref) {
    return accessTokenHolder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccessTokenHolder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccessTokenHolder>(value),
    );
  }
}

String _$accessTokenHolderHash() => r'7a899a8bacf1f8b46ebd99e98f992f85e89bdd27';

/// Signals the app that the session is gone and the login screen is needed.
/// The router listens to this.

@ProviderFor(SessionExpired)
final sessionExpiredProvider = SessionExpiredProvider._();

/// Signals the app that the session is gone and the login screen is needed.
/// The router listens to this.
final class SessionExpiredProvider
    extends $NotifierProvider<SessionExpired, bool> {
  /// Signals the app that the session is gone and the login screen is needed.
  /// The router listens to this.
  SessionExpiredProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sessionExpiredProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sessionExpiredHash();

  @$internal
  @override
  SessionExpired create() => SessionExpired();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sessionExpiredHash() => r'c6ead4a021e86fe7258a3ac7beb5ad12cfafdcc6';

/// Signals the app that the session is gone and the login screen is needed.
/// The router listens to this.

abstract class _$SessionExpired extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(dio)
final dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dioProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'baa4fbb6f044f09df9bf3c917da6c19b45665042';
