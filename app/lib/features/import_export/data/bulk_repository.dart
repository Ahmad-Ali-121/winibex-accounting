import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/import_plan.dart';

part 'bulk_repository.g.dart';

@riverpod
BulkRepository bulkRepository(Ref ref) => BulkRepository(dio: ref.watch(dioProvider));

/// Templates, exports and imports of ledger codes and taxes. The server reads
/// the file and decides what each row does; the app only carries it.
/// Decision 069.
class BulkRepository {
  BulkRepository({required this.dio});
  final Dio dio;

  Future<T> _call<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<BulkFile> template(BulkKind kind) => _call(() async {
    final response = await dio.get<Map<String, dynamic>>('/${kind.path}/template');
    return BulkFile.fromJson(response.data!);
  });

  Future<BulkFile> exportList(BulkKind kind) => _call(() async {
    final response = await dio.get<Map<String, dynamic>>('/${kind.path}/export');
    return BulkFile.fromJson(response.data!);
  });

  /// [apply] false: what the file would do, nothing saved. True: saves it.
  Future<ImportPlan> importFile(BulkKind kind, String csv, {required bool apply}) => _call(() async {
    final response = await dio.post<Map<String, dynamic>>('/${kind.path}/import', data: {'csv': csv, 'apply': apply});
    return ImportPlan.fromJson(response.data!);
  });
}
