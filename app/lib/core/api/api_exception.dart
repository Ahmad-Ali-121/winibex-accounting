import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  ///
  /// Decided by the code, not by a missing status. An answer the app could not
  /// read also has no status, and calling that a lost connection is how the
  /// approvals screen said "Could not reach the server" about a list it had
  /// received. Defect F6b.
  bool get isNetwork => code == 'NETWORK';

  /// The server answered, but the app could not read the answer: a field
  /// missing or of the wrong type. A bug, on one side or the other.
  bool get isUnreadable => code == 'UNREADABLE';

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

    // Anything else is the app failing to read what it was given, usually a
    // fromJson meeting a field it did not expect. Printed in debug builds, so
    // the console names the actual field rather than leaving a guess. F6b.
    debugPrint('Could not read the server answer: $error');
    return ApiException(code: 'UNREADABLE', message: error.toString());
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
