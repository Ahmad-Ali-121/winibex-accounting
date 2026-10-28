import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/money/money.dart';
import '../domain/money_moves.dart';

part 'money_repository.g.dart';

@riverpod
MoneyRepository moneyRepository(Ref ref) => MoneyRepository(dio: ref.watch(dioProvider));

/// Moving money between accounts, paying people back, reversing an entry, and
/// the opening entry. Every request that moves money carries an idempotency
/// key, the same one on a retry, so a lost answer cannot move money twice.
class MoneyRepository {
  MoneyRepository({required this.dio});
  final Dio dio;

  Options _keyed(String key) => Options(headers: {'Idempotency-Key': key});

  /// Both legs, posted together. Returns their journal numbers.
  Future<List<String>> transfer({
    required String date,
    required int fromAccountId,
    required int toAccountId,
    required Money amount,
    Money? fee,
    String? description,
    List<String> acknowledged = const [],
    required String key,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/transfers',
        options: _keyed(key),
        data: {
          'date': date,
          'fromAccountId': fromAccountId,
          'toAccountId': toAccountId,
          'amount': amount.toJson(),
          if (fee != null && fee.minorUnits > 0) 'fee': fee.toJson(),
          if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
          if (acknowledged.isNotEmpty) 'acknowledged_warnings': acknowledged,
        },
      );
      final transfer = response.data!['transfer'] as Map<String, dynamic>;
      return [
        (transfer['from'] as Map<String, dynamic>)['journalNumber'] as String? ?? '',
        (transfer['to'] as Map<String, dynamic>)['journalNumber'] as String? ?? '',
      ];
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Returns the journal number of the reversing entry.
  Future<String> reverse({required int transactionId, required String reason, required String key}) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/transactions/$transactionId/reverse',
        options: _keyed(key),
        data: {'reason': reason},
      );
      return response.data!['journalNumber'] as String? ?? '';
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<List<PersonOwed>> peopleOwed() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/people/balances');
      return (response.data!['people'] as List<dynamic>)
          .map((item) => PersonOwed.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<List<OwedCost>> owedCosts(int userId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/people/$userId/outstanding');
      return (response.data!['items'] as List<dynamic>)
          .map((item) => OwedCost.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Pays a person back for the costs listed. Returns the journal number and
  /// what the company still owes them afterwards, both from the server.
  Future<(String, Money)> payBack({
    required int personUserId,
    required int accountId,
    required String date,
    required List<(int, Money)> items,
    List<String> acknowledged = const [],
    required String key,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/reimbursements',
        options: _keyed(key),
        data: {
          'personUserId': personUserId,
          'accountId': accountId,
          'date': date,
          'items': [
            for (final (transactionId, amount) in items) {'transactionId': transactionId, 'amount': amount.toJson()},
          ],
          if (acknowledged.isNotEmpty) 'acknowledged_warnings': acknowledged,
        },
      );
      final paid = response.data!['reimbursement'] as Map<String, dynamic>;
      return (
        paid['journalNumber'] as String? ?? '',
        Money.fromJson(paid['owedAfter'] as Map<String, dynamic>),
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<OpeningInfo> openingInfo() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/opening-entry');
      return OpeningInfo.fromJson(response.data!);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// [balances] is ledger code and amount, each on the account's own normal
  /// side. The server works out the balancing figure. Returns the journal
  /// number.
  Future<String> postOpening({
    required List<(String, Money)> balances,
    List<String> acknowledged = const [],
    required String key,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/opening-entry',
        options: _keyed(key),
        data: {
          'balances': [
            for (final (code, amount) in balances) {'code': code, 'amount': amount.minorUnits},
          ],
          if (acknowledged.isNotEmpty) 'acknowledged_warnings': acknowledged,
        },
      );
      return (response.data!['openingEntry'] as Map<String, dynamic>)['journalNumber'] as String? ?? '';
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
