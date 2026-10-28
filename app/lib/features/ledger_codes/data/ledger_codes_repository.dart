import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/ledger_code.dart';

part 'ledger_codes_repository.g.dart';

@riverpod
LedgerCodesRepository ledgerCodesRepository(Ref ref) => LedgerCodesRepository(dio: ref.watch(dioProvider));

/// The owner's changes to the chart of accounts. Decisions 068 and 069. The
/// server checks the role and every rule; this only carries the request.
class LedgerCodesRepository {
  LedgerCodesRepository({required this.dio});
  final Dio dio;

  Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<List<LedgerCode>> list() => _call(() async {
    final response = await dio.get<Map<String, dynamic>>('/ledger-codes');
    return (response.data!['codes'] as List<dynamic>)
        .map((item) => LedgerCode.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  });

  /// [parentCode] null lets the server pick the nearest heading before it.
  Future<void> create({
    required String code,
    required String name,
    required bool isHeading,
    required bool addToEntryForm,
    String? parentCode,
  }) => _call(
    () => dio.post<Map<String, dynamic>>(
      '/ledger-codes',
      data: {
        'code': code,
        'name': name,
        'kind': isHeading ? 'heading' : 'code',
        'parentCode': parentCode,
        'addToEntryForm': addToEntryForm,
      },
    ),
  );

  /// Only what changed is sent.
  Future<void> update(int id, {String? name, String? parentCode}) => _call(
    () => dio.patch<Map<String, dynamic>>(
      '/ledger-codes/$id',
      data: {if (name != null) 'name': name, if (parentCode != null) 'parentCode': parentCode},
    ),
  );

  Future<void> setActive(int id, {required bool isActive}) =>
      _call(() => dio.post<Map<String, dynamic>>('/ledger-codes/$id/active', data: {'isActive': isActive}));
}
