import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../domain/vendor.dart';

part 'vendors_repository.g.dart';

@riverpod
VendorsRepository vendorsRepository(Ref ref) => VendorsRepository(dio: ref.watch(dioProvider));

/// Vendors. Anyone signed in can read them; only the owner and admins can add
/// or change one, because the filer status quietly decides a tax rate. The
/// server checks the role.
class VendorsRepository {
  VendorsRepository({required this.dio});
  final Dio dio;

  Future<List<Vendor>> list({bool includeInactive = true}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/vendors',
        queryParameters: {'includeInactive': includeInactive ? 'true' : 'false'},
      );
      return (response.data!['vendors'] as List<dynamic>)
          .map((item) => Vendor.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> add(VendorForm form) async {
    try {
      await dio.post<Map<String, dynamic>>('/vendors', data: form.toRequest());
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<void> change(int id, Map<String, dynamic> changes) async {
    try {
      await dio.patch<Map<String, dynamic>>('/vendors/$id', data: changes);
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}
