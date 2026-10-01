// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The session. null data means signed out; a value means signed in.
///
/// AsyncNotifier because the first thing it does is an async restore, and the
/// UI needs to tell "still checking" apart from "definitely signed out" so it
/// can show a splash rather than flashing the login screen on every launch.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// The session. null data means signed out; a value means signed in.
///
/// AsyncNotifier because the first thing it does is an async restore, and the
/// UI needs to tell "still checking" apart from "definitely signed out" so it
/// can show a splash rather than flashing the login screen on every launch.
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, AuthUser?> {
  /// The session. null data means signed out; a value means signed in.
  ///
  /// AsyncNotifier because the first thing it does is an async restore, and the
  /// UI needs to tell "still checking" apart from "definitely signed out" so it
  /// can show a splash rather than flashing the login screen on every launch.
  AuthControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'a058425caf42633fc76e81f30dba38e4f6d03aa0';

/// The session. null data means signed out; a value means signed in.
///
/// AsyncNotifier because the first thing it does is an async restore, and the
/// UI needs to tell "still checking" apart from "definitely signed out" so it
/// can show a splash rather than flashing the login screen on every launch.

abstract class _$AuthController extends $AsyncNotifier<AuthUser?> {
  FutureOr<AuthUser?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthUser?>, AuthUser?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AuthUser?>, AuthUser?>,
        AsyncValue<AuthUser?>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
