import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

part 'auth_controller.g.dart';

/// The session. null data means signed out; a value means signed in.
///
/// AsyncNotifier because the first thing it does is an async restore, and the
/// UI needs to tell "still checking" apart from "definitely signed out" so it
/// can show a splash rather than flashing the login screen on every launch.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AuthUser?> build() async {
    return ref.watch(authRepositoryProvider).restore();
  }

  /// Returns null on success, or the error on failure. The screen uses the
  /// return value rather than reading state back after an await, which is
  /// unsafe once the widget may have rebuilt.
  Future<Object?> login({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => repo.login(email: email, password: password));
    state = result;
    return result.hasError ? result.error : null;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  bool get isSignedIn => state.value != null;
}
