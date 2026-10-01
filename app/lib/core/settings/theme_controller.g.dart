// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// System default on first load, user override saved. UI guide, Visual design.

@ProviderFor(ThemeController)
final themeControllerProvider = ThemeControllerProvider._();

/// System default on first load, user override saved. UI guide, Visual design.
final class ThemeControllerProvider
    extends $NotifierProvider<ThemeController, ThemeMode> {
  /// System default on first load, user override saved. UI guide, Visual design.
  ThemeControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeControllerHash();

  @$internal
  @override
  ThemeController create() => ThemeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeControllerHash() => r'a33d89c87919a983d4065169e01bc72260f79a05';

/// System default on first load, user override saved. UI guide, Visual design.

abstract class _$ThemeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ThemeMode, ThemeMode>, ThemeMode, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
