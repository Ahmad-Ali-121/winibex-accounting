import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_retry.dart';
import '../../transactions/application/entry_options_providers.dart';
import '../data/vendors_repository.dart';
import '../domain/vendor.dart';

part 'vendors_providers.g.dart';

@Riverpod(retry: noRetry)
Future<List<Vendor>> vendorList(Ref ref) => ref.watch(vendorsRepositoryProvider).list();

/// Adding and changing vendors. Returns null when it worked, or the refusal.
/// Kept alive like the other action providers, so it survives its own request
/// to reload the list.
@Riverpod(keepAlive: true, retry: noRetry)
class VendorActions extends _$VendorActions {
  @override
  void build() {}

  Future<ApiException?> _run(Future<void> Function() call) async {
    try {
      await call();
    } catch (error) {
      return ApiException.from(error);
    }
    if (ref.mounted) {
      ref.invalidate(vendorListProvider);
      // The payee picker on the entry form reads the same vendors.
      ref.invalidate(vendorOptionsProvider);
    }
    return null;
  }

  Future<ApiException?> add(VendorForm form) => _run(() => ref.read(vendorsRepositoryProvider).add(form));

  Future<ApiException?> change(int id, Map<String, dynamic> changes) =>
      _run(() => ref.read(vendorsRepositoryProvider).change(id, changes));
}
