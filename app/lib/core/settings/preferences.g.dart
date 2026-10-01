// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridden in main() with the real instance, and in tests with a fake one.
/// Reading it without an override is a programming error, not a runtime state.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Overridden in main() with the real instance, and in tests with a fake one.
/// Reading it without an override is a programming error, not a runtime state.

final class SharedPreferencesProvider extends $FunctionalProvider<
    SharedPreferences,
    SharedPreferences,
    SharedPreferences> with $Provider<SharedPreferences> {
  /// Overridden in main() with the real instance, and in tests with a fake one.
  /// Reading it without an override is a programming error, not a runtime state.
  SharedPreferencesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sharedPreferencesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'1c2dd1a84771b17e16cc7c9461dd6736a2a28921';
