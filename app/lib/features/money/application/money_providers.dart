import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_retry.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../transactions/application/ledger_providers.dart';
import '../data/money_repository.dart';
import '../domain/money_moves.dart';

part 'money_providers.g.dart';

/// Everyone the company owes money to, most owed first is the server's order.
@Riverpod(retry: noRetry)
Future<List<PersonOwed>> peopleOwed(Ref ref) => ref.watch(moneyRepositoryProvider).peopleOwed();

/// The costs behind what one person is owed.
@Riverpod(retry: noRetry)
Future<List<OwedCost>> owedCosts(Ref ref, {required int userId}) =>
    ref.watch(moneyRepositoryProvider).owedCosts(userId);

@Riverpod(retry: noRetry)
Future<OpeningInfo> openingInfo(Ref ref) => ref.watch(moneyRepositoryProvider).openingInfo();

/// After money moves, every figure that could have changed is asked for
/// again. Nothing is adjusted on this side.
void refreshAfterMoneyMoved(WidgetRef ref) {
  ref.invalidate(accountsProvider);
  ref.invalidate(pettyCashProvider);
  ref.invalidate(peopleOwedProvider);
  ref.invalidate(owedCostsProvider);
  ref.invalidate(ledgerPageProvider);
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(openingInfoProvider);
}
