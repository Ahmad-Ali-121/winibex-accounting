import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_retry.dart';
import '../data/transactions_repository.dart';
import '../domain/entry_options.dart';
import 'categories_providers.dart';

part 'entry_options_providers.g.dart';

/// Taxes that can be added by hand to an entry on [date] going [direction].
@Riverpod(retry: noRetry)
Future<List<TaxOption>> taxOptions(Ref ref, {required String date, required String direction}) {
  return ref.watch(transactionsRepositoryProvider).taxesInForce(date: date, direction: direction);
}

/// Everyone Winibex pays, for the payee picker on the tax step.
@Riverpod(retry: noRetry)
Future<List<VendorOption>> vendorOptions(Ref ref) {
  return ref.watch(transactionsRepositoryProvider).vendors();
}

/// The cost accounts a charge may go to: every expense account behind a
/// money-out category, once each, in code order. The server checks the
/// choice again. Decision 064.
@Riverpod(retry: noRetry)
Future<List<ChargeAccount>> chargeAccounts(Ref ref) async {
  final groups = await ref.watch(categoryGroupsProvider(direction: 'out').future);
  final byId = <int, ChargeAccount>{};
  for (final group in groups) {
    for (final category in group.categories) {
      final id = category.ledgerId;
      if (id == null || category.ledgerType != 'expense') continue;
      byId[id] = ChargeAccount(id: id, code: category.ledgerCode, name: category.ledgerName);
    }
  }
  return byId.values.toList()..sort((a, b) => a.code.compareTo(b.code));
}
