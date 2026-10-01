import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/token_store.dart';
import 'api_config.dart';

part 'api_client.g.dart';

/// The access token lives in memory only. It is short-lived and replaced on
/// every refresh, so there is nothing worth persisting, and keeping it out of
/// storage removes one thing that can leak.
class AccessTokenHolder {
  String? value;
}

@Riverpod(keepAlive: true)
AccessTokenHolder accessTokenHolder(Ref ref) => AccessTokenHolder();

/// Signals the app that the session is gone and the login screen is needed.
/// The router listens to this.
@Riverpod(keepAlive: true)
class SessionExpired extends _$SessionExpired {
  @override
  bool build() => false;
  void trigger() => state = true;
  void reset() => state = false;
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final holder = ref.watch(accessTokenHolderProvider);
  final tokens = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      // The browser attaches the refresh cookie itself, but only if asked.
      extra: {'withCredentials': true},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = holder.value;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isAuthCall = error.requestOptions.path.startsWith('/auth/');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        // Only a genuine, non-auth 401 is worth trying to refresh. A failed
        // login is a 401 too, and retrying that would be nonsense.
        if (!isUnauthorized || isAuthCall || alreadyRetried) {
          return handler.next(error);
        }

        final refreshed = await _tryRefresh(dio, holder, tokens);
        if (!refreshed) {
          ref.read(sessionExpiredProvider.notifier).trigger();
          return handler.next(error);
        }

        // Replay the original request once, now that the access token is new.
        try {
          final options = error.requestOptions;
          options.extra['retried'] = true;
          options.headers['Authorization'] = 'Bearer ${holder.value}';
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } catch (_) {
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}

// One refresh at a time. Several requests failing with 401 at once must not
// each fire their own refresh and rotate the token out from under each other.
Completer<bool>? _refreshInFlight;

Future<bool> _tryRefresh(Dio dio, AccessTokenHolder holder, TokenStore tokens) async {
  if (_refreshInFlight != null) return _refreshInFlight!.future;

  final completer = Completer<bool>();
  _refreshInFlight = completer;

  try {
    final stored = await tokens.readRefresh();
    final response = await dio.post(
      '/auth/refresh',
      // Web sends nothing; the cookie carries it. Android sends the stored one.
      data: stored == null ? null : {'refreshToken': stored},
      options: Options(extra: {'retried': true}),
    );

    final data = response.data as Map;
    holder.value = data['accessToken'] as String?;
    final newRefresh = data['refreshToken'] as String?;
    if (newRefresh != null) await tokens.writeRefresh(newRefresh);

    completer.complete(holder.value != null);
  } catch (_) {
    completer.complete(false);
  } finally {
    _refreshInFlight = null;
  }

  return completer.future;
}
