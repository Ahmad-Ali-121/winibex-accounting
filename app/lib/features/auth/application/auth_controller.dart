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
  ///
  /// The session is not put into loading while this runs. Loading means "still
  /// finding out whether anyone is signed in", which is only true on launch,
  /// and treating a sign-in attempt the same way replaced the whole app with
  /// the splash and lost the sign-in screen's error. Defect F1. A failed
  /// attempt leaves the session exactly as it was: signed out.
  Future<Object?> login({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.login(email: email, password: password);
      state = AsyncData(user);
      return null;
    } catch (error) {
      return error;
    }
  }

  /// Changes the password and updates the held user, so mustChangePassword
  /// flips to false and the router stops forcing the change screen.
  ///
  /// Returns null on success, or the error on failure, the same shape as login
  /// so the screen handles both the same way.
  Future<Object?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final updated = await repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = AsyncData(updated);
      return null;
    } catch (error) {
      // The session is unchanged, so the held user stays as it was. Only the
      // error goes back to the screen.
      return error;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  bool get isSignedIn => state.value != null;
}
