import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences.g.dart';

/// Overridden in main() with the real instance, and in tests with a fake one.
/// Reading it without an override is a programming error, not a runtime state.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
}
