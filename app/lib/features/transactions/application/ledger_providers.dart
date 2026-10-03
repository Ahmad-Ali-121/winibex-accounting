import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_retry.dart';
import '../../../core/api/idempotency_key.dart';
import '../../accounts/application/accounts_providers.dart';
import '../data/transactions_repository.dart';
import '../domain/journal_preview.dart';
import '../domain/ledger.dart';

part 'ledger_providers.g.dart';

/// What the ledger is filtered to.
///
/// One object rather than four providers, so changing the search box and the
/// account filter together refetches once.
@riverpod
class LedgerFilters extends _$LedgerFilters {
  @override
  LedgerQuery build() => const LedgerQuery();

  void setSearch(String search) => state = state.copyWith(search: search);
  void setAccount(int? accountId) =>
      state = accountId == null ? state.copyWith(clearAccount: true) : state.copyWith(accountId: accountId);
  void setStatus(String? status) =>
      state = status == null ? state.copyWith(clearStatus: true) : state.copyWith(status: status);
  void nextPage() => state = state.copyWith(page: state.page + 1);
  void previousPage() => state = state.copyWith(page: state.page > 1 ? state.page - 1 : 1);
  void clear() => state = const LedgerQuery();
}

/// A page of the ledger, searched and filtered by the server. Decision 022:
/// the app holds one page, so searching what it holds would miss the rest.
@Riverpod(retry: noRetry)
Future<LedgerPage> ledgerPage(Ref ref) {
  final filters = ref.watch(ledgerFiltersProvider);
  return ref.watch(transactionsRepositoryProvider).ledger(filters);
}

/// The journal lines behind one posted entry, fetched when it is opened.
@Riverpod(retry: noRetry)
Future<List<JournalLine>> entryJournal(Ref ref, {required int transactionId}) {
  return ref.watch(transactionsRepositoryProvider).journal(transactionId);
}

@Riverpod(retry: noRetry)
Future<List<Approval>> approvals(Ref ref) {
  return ref.watch(transactionsRepositoryProvider).approvals();
}

/// Approving and rejecting.
///
/// Never retried automatically: approving is posting, and a write that may
/// have landed must not be repeated on a guess.
@Riverpod(retry: noRetry)
class ApprovalActions extends _$ApprovalActions {
  @override
  void build() {}

  Future<void> approve(int id) async {
    await ref.read(transactionsRepositoryProvider).approve(id, newIdempotencyKey());
    if (!ref.mounted) return;
    _refresh();
  }

  Future<void> reject(int id, String reason) async {
    await ref.read(transactionsRepositoryProvider).reject(id, reason);
    if (!ref.mounted) return;
    _refresh();
  }

  /// Balances and the ledger both changed. Ask again rather than adjusting
  /// anything here.
  void _refresh() {
    ref.invalidate(approvalsProvider);
    ref.invalidate(ledgerPageProvider);
    ref.invalidate(accountsProvider);
  }
}
