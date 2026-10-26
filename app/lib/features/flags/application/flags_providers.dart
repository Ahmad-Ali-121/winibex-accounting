import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_retry.dart';
import '../data/flags_repository.dart';

part 'flags_providers.g.dart';

@Riverpod(retry: noRetry)
Future<List<EntryFlag>> openFlags(Ref ref) => ref.watch(flagsRepositoryProvider).load();

/// Marking a flag reviewed. Returns null when it worked, or the refusal, so the
/// screen can say why. Never retried on a guess. Decision 056, defect D2.
///
/// Kept alive: it is read, never watched, so an auto-disposing provider could
/// be disposed during the request and then skip reloading the list.
@Riverpod(keepAlive: true, retry: noRetry)
class FlagActions extends _$FlagActions {
  @override
  void build() {}

  Future<ApiException?> resolve(int id, String note) async {
    try {
      await ref.read(flagsRepositoryProvider).resolve(id, note);
    } catch (error) {
      return ApiException.from(error);
    }
    // The list is the server's, so ask again rather than removing the row here.
    if (ref.mounted) ref.invalidate(openFlagsProvider);
    return null;
  }
}
