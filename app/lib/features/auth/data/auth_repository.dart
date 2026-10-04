import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_store.dart';
import '../domain/auth_user.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    holder: ref.watch(accessTokenHolderProvider),
    tokens: ref.watch(tokenStoreProvider),
  );
}

class AuthRepository {
  AuthRepository({required this.dio, required this.holder, required this.tokens});

  final Dio dio;
  final AccessTokenHolder holder;
  final TokenStore tokens;

  Future<AuthUser> login({required String email, required String password}) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return await _storeSession(response.data as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Tries to resume a session on launch using the stored refresh token (or
  /// the cookie, on web). Returns null when there is nothing to resume, which
  /// is the normal first-run case, not an error.
  Future<AuthUser?> restore() async {
    try {
      final stored = await tokens.readRefresh();
      final response = await dio.post(
        '/auth/refresh',
        data: stored == null ? null : {'refreshToken': stored},
        options: Options(extra: {'retried': true}),
      );
      return await _storeSession(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Changes the signed-in user's password.
  ///
  /// The server verifies the current password, writes the new one, clears the
  /// must-change flag, and revokes every other session. The response carries
  /// the updated user, whose mustChangePassword is now false, which is what
  /// lets the router stop forcing the change screen.
  ///
  /// This caller's own session is untouched by the server, so no token work is
  /// needed here.
  Future<AuthUser> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return AuthUser.fromJson(
        (response.data as Map<String, dynamic>)['user'] as Map<String, dynamic>,
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> logout() async {
    try {
      final stored = await tokens.readRefresh();
      await dio.post(
        '/auth/logout',
        data: stored == null ? null : {'refreshToken': stored},
        options: Options(extra: {'retried': true}),
      );
    } catch (_) {
      // Logging out is best effort. Even if the call fails, the local session
      // is cleared below, so the user is signed out of this device.
    } finally {
      holder.value = null;
      await tokens.clear();
    }
  }

  Future<AuthUser> _storeSession(Map<String, dynamic> data) async {
    holder.value = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (refresh != null) await tokens.writeRefresh(refresh);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
