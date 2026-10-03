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
    this.details,
  });

  final String code;
  final String message;
  final String? field;
  final int? status;

  /// Whatever the error carries beyond its message. A VALIDATION_WARNINGS
  /// response puts the warnings here, each naming the record it matched, which
  /// is what makes a warning worth reading rather than dismissing.
  final Map<String, dynamic>? details;

  /// No response at all: the server is down, or the phone is offline. Told
  /// apart from a server-sent error so the UI can say "check your connection"
  /// rather than "something went wrong on our side".
  bool get isNetwork => status == null;

  /// Warnings are not failures. The entry is fine; the person is being asked
  /// to confirm something before it is saved. docs/API.md.
  bool get isWarnings => code == 'VALIDATION_WARNINGS';

  List<ApiWarning> get warnings {
    final raw = details?['warnings'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ApiWarning.fromJson)
        .toList(growable: false);
  }

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
          details: err['details'] is Map
              ? Map<String, dynamic>.from(err['details'] as Map)
              : null,
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

/// One warning from a 409. [message] already names what it matched, so the
/// dialog shows it as it stands rather than rewording it.
class ApiWarning {
  const ApiWarning({required this.code, required this.message, this.transactionId});

  factory ApiWarning.fromJson(Map<String, dynamic> json) => ApiWarning(
        code: json['code'] as String? ?? 'UNKNOWN',
        message: json['message'] as String? ?? '',
        transactionId: json['transactionId'] as int?,
      );

  final String code;
  final String message;

  /// The entry this warning matched against, so the person can open it rather
  /// than take the warning's word for it.
  final int? transactionId;
}
