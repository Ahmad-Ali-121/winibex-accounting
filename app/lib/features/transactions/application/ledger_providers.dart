import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
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
///
/// Each returns null when it worked, or the refusal when it did not, so the
/// screen can say why. An admin over their approval limit, or a payment with
/// no receipt, used to fail without a word on screen. Defect D3.
///
/// Kept alive: it is read, never watched, so an auto-disposing provider could
/// be disposed during the request, find itself unmounted, and skip reloading
/// the inbox, which would leave an approved entry on screen.
@Riverpod(keepAlive: true, retry: noRetry)
class ApprovalActions extends _$ApprovalActions {
  @override
  void build() {}

  Future<ApiException?> approve(int id) async {
    try {
      await ref.read(transactionsRepositoryProvider).approve(id, newIdempotencyKey());
    } catch (error) {
      return ApiException.from(error);
    }
    if (ref.mounted) _refresh();
    return null;
  }

  Future<ApiException?> reject(int id, String reason) async {
    try {
      await ref.read(transactionsRepositoryProvider).reject(id, reason);
    } catch (error) {
      return ApiException.from(error);
    }
    if (ref.mounted) _refresh();
    return null;
  }

  /// Balances and the ledger both changed. Ask again rather than adjusting
  /// anything here.
  void _refresh() {
    ref.invalidate(approvalsProvider);
    ref.invalidate(ledgerPageProvider);
    ref.invalidate(accountsProvider);
  }
}

/// The edit history of one entry, fetched when the history panel opens.
@Riverpod(retry: noRetry)
Future<List<HistoryEvent>> entryHistory(Ref ref, {required int transactionId}) {
  return ref.watch(transactionsRepositoryProvider).history(transactionId);
}
