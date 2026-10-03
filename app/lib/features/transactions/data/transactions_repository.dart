import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/category.dart';
import '../domain/entry_draft.dart';
import '../domain/journal_preview.dart';
import '../domain/ledger.dart';
import '../domain/person.dart';

part 'transactions_repository.g.dart';

@riverpod
TransactionsRepository transactionsRepository(Ref ref) {
  return TransactionsRepository(dio: ref.watch(dioProvider));
}

class TransactionsRepository {
  TransactionsRepository({required this.dio});

  final Dio dio;

  Future<List<CategoryGroup>> categories({String? direction}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/categories',
        queryParameters: direction == null ? null : {'direction': direction},
      );
      return (response.data!['groups'] as List<dynamic>)
          .map((item) => CategoryGroup.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<List<Person>> people() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/users');
      return (response.data!['users'] as List<dynamic>)
          .map((item) => Person.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// What tax the form should offer for this situation. A suggestion: the
  /// person may edit or remove any line, and what the bank actually took wins.
  Future<List<DraftTax>> suggestTaxes({
    required String direction,
    required int baseMinorUnits,
    String currency = 'PKR',
    String? date,
    int? categoryId,
    int? vendorId,
    String? accountType,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/taxes/suggest',
        queryParameters: {
          'direction': direction,
          'base': baseMinorUnits,
          'currency': currency,
          if (date != null) 'date': date,
          if (categoryId != null) 'categoryId': categoryId,
          if (vendorId != null) 'vendorId': vendorId,
          if (accountType != null) 'accountType': accountType,
        },
      );
      return (response.data!['suggestions'] as List<dynamic>)
          .map((item) => DraftTax.fromSuggestion(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// The journal entry this draft would post, worked out by the server and
  /// saved nowhere.
  Future<JournalPreview> preview(EntryDraft draft) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/transactions/preview',
        data: draft.toRequest(),
      );
      return JournalPreview.fromJson(response.data!);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Creates the draft entry. Carries the idempotency key the form generated
  /// when it opened, so a retry cannot post a second expense.
  ///
  /// Throws an ApiException with isWarnings true when the server wants
  /// something confirmed first. That is not a failure: the same call with the
  /// warning codes in acknowledgedWarnings goes through.
  Future<int> create(EntryDraft draft) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/transactions',
        data: draft.toRequest(),
        options: Options(headers: {'Idempotency-Key': draft.idempotencyKey}),
      );
      return (response.data!['transaction'] as Map<String, dynamic>)['id'] as int;
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<LedgerPage> ledger(LedgerQuery query) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: query.toQueryParameters(),
      );
      return LedgerPage.fromJson(response.data!);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// The journal lines of a posted entry, for the panel behind "View journal
  /// entry". Fetched on demand: the ledger list carries none of them.
  Future<List<JournalLine>> journal(int id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/transactions/$id/journal');
      return (response.data!['lines'] as List<dynamic>)
          .map((item) => JournalLine.fromJson({
                'coaId': (item as Map<String, dynamic>)['coa_id'] ?? item['coaId'],
                'code': item['code'] ?? '',
                'name': item['name'] ?? '',
                'debit': int.parse('${item['debit']}'),
                'credit': int.parse('${item['credit']}'),
                'memo': item['memo'],
              }),)
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<List<Approval>> approvals() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/approvals');
      return (response.data!['approvals'] as List<dynamic>)
          .map((item) => Approval.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> reject(int id, String reason) async {
    try {
      await dio.post('/transactions/$id/reject', data: {'reason': reason});
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Sends the receipt. Multipart, with the bytes rather than a path, because
  /// on web there is no path. Dio sets the boundary itself: setting the
  /// content type by hand here would produce one the server cannot read.
  Future<void> uploadReceipt({
    required int transactionId,
    required Uint8List bytes,
    required String filename,
    required String mime,
    String documentType = 'receipt',
  }) async {
    try {
      final form = FormData.fromMap({
        'documentType': documentType,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mime),
        ),
      });

      await dio.post('/transactions/$transactionId/attachments', data: form);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> submit(int id) async {
    try {
      await dio.post('/transactions/$id/submit');
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Approving is posting. A separate key, because approving is its own
  /// money-moving request.
  Future<void> approve(int id, String idempotencyKey) async {
    try {
      await dio.post(
        '/transactions/$id/approve',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
