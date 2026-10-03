import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_retry.dart';
import '../data/dashboard_repository.dart';

part 'dashboard_providers.g.dart';

@Riverpod(retry: noRetry)
Future<DashboardSummary> dashboardSummary(Ref ref) =>
    ref.watch(dashboardRepositoryProvider).load();
