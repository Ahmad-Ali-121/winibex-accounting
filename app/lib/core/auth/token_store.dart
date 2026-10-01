import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_store.g.dart';

/// Holds the refresh token between launches.
///
/// On Android this is the Keystore, which is what secure storage uses there.
/// On web there is no secure place for it, so the refresh token is an httpOnly
/// cookie the browser keeps and this stores nothing. That split is why the API
/// accepts the refresh token both in a cookie and in the body.
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;
  static const _refreshKey = 'winibex_refresh';

  Future<String?> readRefresh() async {
    if (kIsWeb) return null;
    return _storage.read(key: _refreshKey);
  }

  Future<void> writeRefresh(String token) async {
    if (kIsWeb) return;
    await _storage.write(key: _refreshKey, value: token);
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    await _storage.delete(key: _refreshKey);
  }
}

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) {
  // v11 made Keystore-backed storage the default, so no AndroidOptions are
  // needed. Earlier versions needed encryptedSharedPreferences here.
  return TokenStore(const FlutterSecureStorage());
}
