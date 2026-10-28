import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_retry.dart';
import '../data/cheques_repository.dart';
import '../domain/cheque.dart';

part 'cheques_providers.g.dart';

/// The register, all cheques, or one status. Null is all.
@Riverpod(retry: noRetry)
Future<ChequeRegister> chequeRegister(Ref ref, {String? status}) =>
    ref.watch(chequesRepositoryProvider).list(status: status);

@Riverpod(retry: noRetry)
Future<List<PaymentOption>> chequePayments(Ref ref, {required int accountId, String search = ''}) =>
    ref.watch(chequesRepositoryProvider).payments(accountId: accountId, search: search);

/// Issuing, moving a cheque on, linking it. Null when it worked, or the
/// refusal. Kept alive for the same reason as the other action providers.
@Riverpod(keepAlive: true, retry: noRetry)
class ChequeActions extends _$ChequeActions {
  @override
  void build() {}

  Future<ApiException?> run(Future<void> Function(ChequesRepository repository) call) async {
    try {
      await call(ref.read(chequesRepositoryProvider));
    } catch (error) {
      return ApiException.from(error);
    }
    if (ref.mounted) ref.invalidate(chequeRegisterProvider);
    return null;
  }
}
