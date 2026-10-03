import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_retry.dart';
import '../data/accounts_repository.dart';
import '../domain/account.dart';

part 'accounts_providers.g.dart';

/// Balances, straight from the server.
///
/// Read-only, so a functional provider rather than a notifier. Anything that
/// writes money invalidates this instead of adjusting a balance locally: the
/// server is the only thing that knows what an account holds.
///
/// retry: noRetry, because Riverpod 3 otherwise retries a failure by itself
/// and the screen stays on its skeleton while it does, telling the person
/// nothing. A failed read shows an error panel with a Try again button.
@Riverpod(retry: noRetry)
Future<AccountsSummary> accounts(Ref ref, {bool includeInactive = false}) {
  return ref.watch(accountsRepositoryProvider).list(includeInactive: includeInactive);
}

@Riverpod(retry: noRetry)
Future<PettyCashStatus> pettyCash(Ref ref) {
  return ref.watch(accountsRepositoryProvider).pettyCash();
}
