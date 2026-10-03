import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_retry.dart';
import '../data/flags_repository.dart';

part 'flags_providers.g.dart';

@Riverpod(retry: noRetry)
Future<List<EntryFlag>> openFlags(Ref ref) => ref.watch(flagsRepositoryProvider).load();
