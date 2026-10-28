import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_retry.dart';
import '../data/people_repository.dart';
import '../domain/team_member.dart';

part 'people_providers.g.dart';

@Riverpod(retry: noRetry)
Future<List<TeamMember>> team(Ref ref) => ref.watch(peopleRepositoryProvider).list();

/// Adding, changing and resetting. Each returns null when it worked, or the
/// refusal, so the screen can say why. Kept alive for the same reason as the
/// other action providers: read, never watched, and it must survive its own
/// request to reload the list afterwards.
@Riverpod(keepAlive: true, retry: noRetry)
class PeopleActions extends _$PeopleActions {
  @override
  void build() {}

  Future<ApiException?> _run(Future<void> Function() call) async {
    try {
      await call();
    } catch (error) {
      return ApiException.from(error);
    }
    if (ref.mounted) ref.invalidate(teamProvider);
    return null;
  }

  Future<ApiException?> add(TeamMemberForm form) =>
      _run(() => ref.read(peopleRepositoryProvider).add(form));

  Future<ApiException?> change(int id, Map<String, dynamic> changes) =>
      _run(() => ref.read(peopleRepositoryProvider).change(id, changes));

  Future<ApiException?> resetPassword(int id, String temporaryPassword) =>
      _run(() => ref.read(peopleRepositoryProvider).resetPassword(id, temporaryPassword));
}
