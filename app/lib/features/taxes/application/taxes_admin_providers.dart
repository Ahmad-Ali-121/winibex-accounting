import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_retry.dart';
import '../data/taxes_admin_repository.dart';
import '../domain/tax_admin.dart';

part 'taxes_admin_providers.g.dart';

@Riverpod(retry: noRetry)
Future<TaxesOverview> taxesOverview(Ref ref) => ref.watch(taxesAdminRepositoryProvider).overview();

/// Every change on the taxes screen. Null when it worked, or the refusal.
@Riverpod(keepAlive: true, retry: noRetry)
class TaxAdminActions extends _$TaxAdminActions {
  @override
  void build() {}

  Future<ApiException?> run(Future<void> Function(TaxesAdminRepository repository) call) async {
    try {
      await call(ref.read(taxesAdminRepositoryProvider));
    } catch (error) {
      return ApiException.from(error);
    }
    if (ref.mounted) ref.invalidate(taxesOverviewProvider);
    return null;
  }
}
