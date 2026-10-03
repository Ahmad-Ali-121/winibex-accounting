import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/account.dart';

part 'accounts_repository.g.dart';

@riverpod
AccountsRepository accountsRepository(Ref ref) {
  return AccountsRepository(dio: ref.watch(dioProvider));
}

class AccountsRepository {
  AccountsRepository({required this.dio});

  final Dio dio;

  Future<AccountsSummary> list({bool includeInactive = false}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/accounts',
        queryParameters: includeInactive ? {'includeInactive': 'true'} : null,
      );
      return AccountsSummary.fromJson(response.data!);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<Account> get(int id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/accounts/$id');
      return Account.fromJson(response.data!['account'] as Map<String, dynamic>);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<PettyCashStatus> pettyCash() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/accounts/petty-cash');
      return PettyCashStatus.fromJson(response.data!);
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
