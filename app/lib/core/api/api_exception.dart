import 'package:dio/dio.dart';

/// The server's error shape, as one Dart type:
///   { "error": { "code", "message", "field", "details" } }
///
/// Screens switch on [code], which is stable, never on [message], which is
/// wording and may change.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.field,
    this.status,
  });

  final String code;
  final String message;
  final String? field;
  final int? status;

  /// No response at all: the server is down, or the phone is offline. Told
  /// apart from a server-sent error so the UI can say "check your connection"
  /// rather than "something went wrong on our side".
  bool get isNetwork => status == null;

  static ApiException from(Object error) {
    if (error is ApiException) return error;

    if (error is DioException) {
      final response = error.response;
      final body = response?.data;

      if (body is Map && body['error'] is Map) {
        final err = body['error'] as Map;
        return ApiException(
          code: (err['code'] as String?) ?? 'UNKNOWN',
          message: (err['message'] as String?) ?? 'Request failed.',
          field: err['field'] as String?,
          status: response?.statusCode,
        );
      }

      if (response != null) {
        return ApiException(
          code: 'HTTP_${response.statusCode}',
          message: 'Request failed.',
          status: response.statusCode,
        );
      }

      return const ApiException(code: 'NETWORK', message: 'Could not reach the server.');
    }

    return ApiException(code: 'UNKNOWN', message: error.toString());
  }

  @override
  String toString() => 'ApiException($code, $message)';
}
