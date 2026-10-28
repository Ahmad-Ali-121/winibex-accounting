import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/team_member.dart';

part 'people_repository.g.dart';

@riverpod
PeopleRepository peopleRepository(Ref ref) => PeopleRepository(dio: ref.watch(dioProvider));

/// People and permissions. Every call is the owner's; the server refuses
/// anyone else.
class PeopleRepository {
  PeopleRepository({required this.dio});
  final Dio dio;

  Future<List<TeamMember>> list() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/people');
      return (response.data!['people'] as List<dynamic>)
          .map((item) => TeamMember.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> add(TeamMemberForm form) async {
    try {
      await dio.post<Map<String, dynamic>>('/people', data: form.toAddRequest());
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> change(int id, Map<String, dynamic> changes) async {
    try {
      await dio.patch<Map<String, dynamic>>('/people/$id', data: changes);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> resetPassword(int id, String temporaryPassword) async {
    try {
      await dio.post<Map<String, dynamic>>(
        '/people/$id/reset-password',
        data: {'temporaryPassword': temporaryPassword},
      );
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
