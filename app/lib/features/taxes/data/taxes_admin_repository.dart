import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/tax_admin.dart';

part 'taxes_admin_repository.g.dart';

@riverpod
TaxesAdminRepository taxesAdminRepository(Ref ref) => TaxesAdminRepository(dio: ref.watch(dioProvider));

/// The owner's tax changes. A rate is never edited: a new rate is a new row
/// from a date. Decision 067. The server checks the role.
class TaxesAdminRepository {
  TaxesAdminRepository({required this.dio});
  final Dio dio;

  Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<TaxesOverview> overview() => _call(() async {
    final response = await dio.get<Map<String, dynamic>>('/taxes/all');
    return TaxesOverview.fromJson(response.data!);
  });

  Future<void> create(Map<String, dynamic> body) => _call(() => dio.post<Map<String, dynamic>>('/taxes', data: body));

  Future<void> newRate(int id, {required String from, required String rateAtl, required String rateNonAtl}) => _call(
    () => dio.post<Map<String, dynamic>>(
      '/taxes/$id/new-rate',
      data: {'effectiveFrom': from, 'rateAtl': rateAtl, 'rateNonAtl': rateNonAtl},
    ),
  );

  Future<void> end(int id, {required String lastDay}) =>
      _call(() => dio.post<Map<String, dynamic>>('/taxes/$id/end', data: {'lastDay': lastDay}));

  Future<void> addRule(int taxId, Map<String, dynamic> body) =>
      _call(() => dio.post<Map<String, dynamic>>('/taxes/$taxId/rules', data: body));

  Future<void> setRule(int ruleId, {required bool isActive}) =>
      _call(() => dio.patch<Map<String, dynamic>>('/tax-rules/$ruleId', data: {'isActive': isActive}));
}
