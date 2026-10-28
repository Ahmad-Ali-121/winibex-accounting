import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/money/money.dart';
import '../domain/cheque.dart';

part 'cheques_repository.g.dart';

@riverpod
ChequesRepository chequesRepository(Ref ref) => ChequesRepository(dio: ref.watch(dioProvider));

/// The cheque register. Writing to it is the owner's and admins'; the server
/// checks the role and the order a cheque moves in.
class ChequesRepository {
  ChequesRepository({required this.dio});
  final Dio dio;

  Future<ChequeRegister> list({String? status}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/cheques',
        queryParameters: status == null ? null : {'status': status},
      );
      return ChequeRegister.fromJson(response.data!);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> issue({
    required int accountId,
    required String chequeNumber,
    required String payee,
    required Money amount,
    required String issueDate,
    String? note,
  }) async {
    try {
      await dio.post<Map<String, dynamic>>('/cheques', data: {
        'accountId': accountId,
        'chequeNumber': chequeNumber.trim(),
        'payee': payee.trim(),
        'amount': amount.toJson(),
        'issueDate': issueDate,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> setStatus(int id, String status, {String? clearedOn}) async {
    try {
      await dio.patch<Map<String, dynamic>>('/cheques/$id/status', data: {
        'status': status,
        if (clearedOn != null) 'clearedOn': clearedOn,
      },);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> link(int id, int transactionId) async {
    try {
      await dio.patch<Map<String, dynamic>>('/cheques/$id/transaction', data: {'transactionId': transactionId});
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Posted money out on [accountId], newest first, optionally searched: the
  /// payments a cheque could stand for.
  Future<List<PaymentOption>> payments({required int accountId, String search = ''}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/transactions', queryParameters: {
        'accountId': accountId,
        'direction': 'out',
        'status': 'posted',
        'pageSize': 50,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },);
      return (response.data!['transactions'] as List<dynamic>)
          .map((item) => PaymentOption.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
