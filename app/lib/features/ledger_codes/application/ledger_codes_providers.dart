import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_retry.dart';
import '../../transactions/application/categories_providers.dart';
import '../data/ledger_codes_repository.dart';
import '../domain/ledger_code.dart';

part 'ledger_codes_providers.g.dart';

@Riverpod(retry: noRetry)
Future<List<LedgerCode>> ledgerCodes(Ref ref) => ref.watch(ledgerCodesRepositoryProvider).list();

/// Every change on the ledger codes screen. Null when it worked, or the
/// refusal in the server's words. A change can add, rename or remove a
/// category, so the entry form's list is asked for again too.
@Riverpod(keepAlive: true, retry: noRetry)
class LedgerCodeActions extends _$LedgerCodeActions {
  @override
  void build() {}

  Future<ApiException?> run(Future<void> Function(LedgerCodesRepository repository) call) async {
    try {
      await call(ref.read(ledgerCodesRepositoryProvider));
    } catch (error) {
      return ApiException.from(error);
    }
    if (ref.mounted) {
      ref.invalidate(ledgerCodesProvider);
      ref.invalidate(categoryGroupsProvider);
    }
    return null;
  }
}
