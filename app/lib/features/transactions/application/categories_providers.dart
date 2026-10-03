import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_retry.dart';
import '../data/transactions_repository.dart';
import '../domain/category.dart';
import '../domain/person.dart';

part 'categories_providers.g.dart';

/// The category picker's contents, grouped by main head.
///
/// Asked for per direction, because money in and money out share almost no
/// categories and showing both would make the list twice as long for no gain.
@Riverpod(retry: noRetry)
Future<List<CategoryGroup>> categoryGroups(Ref ref, {required String direction}) {
  return ref.watch(transactionsRepositoryProvider).categories(direction: direction);
}

/// The people who can be named on an entry.
@Riverpod(retry: noRetry)
Future<List<Person>> people(Ref ref) {
  return ref.watch(transactionsRepositoryProvider).people();
}
