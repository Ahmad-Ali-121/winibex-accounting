import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/money/money.dart';

part 'flags_repository.g.dart';

@riverpod
FlagsRepository flagsRepository(Ref ref) => FlagsRepository(dio: ref.watch(dioProvider));

class FlagsRepository {
  FlagsRepository({required this.dio});
  final Dio dio;

  Future<List<EntryFlag>> load() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/flags');
      return (response.data!['flags'] as List<dynamic>)
          .map((item) => EntryFlag.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}

/// Something raised against an entry and not yet dealt with: a warning someone
/// confirmed, or a flag the system raised, such as a missing receipt.
class EntryFlag {
  const EntryFlag({
    required this.id,
    required this.transactionId,
    required this.severity,
    required this.code,
    required this.detail,
    required this.entryDescription,
    required this.entryAmount,
    this.journalNumber,
    this.acknowledgedByName,
  });

  factory EntryFlag.fromJson(Map<String, dynamic> json) {
    final transaction = json['transaction'] as Map<String, dynamic>;
    return EntryFlag(
      id: json['id'] as int,
      transactionId: json['transactionId'] as int,
      severity: json['severity'] as String,
      code: json['code'] as String,
      detail: json['detail'] as String? ?? '',
      entryDescription: transaction['description'] as String? ?? '',
      entryAmount: Money.fromJson(transaction['amount'] as Map<String, dynamic>),
      journalNumber: transaction['journalNumber'] as String?,
      acknowledgedByName: json['acknowledgedByName'] as String?,
    );
  }

  final int id;
  final int transactionId;

  /// warning: someone confirmed it. flag: the system raised it.
  final String severity;
  final String code;
  final String detail;
  final String entryDescription;
  final Money entryAmount;
  final String? journalNumber;
  final String? acknowledgedByName;

  bool get isWarning => severity == 'warning';
}
