import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/money/money.dart';

part 'dashboard_repository.g.dart';

@riverpod
DashboardRepository dashboardRepository(Ref ref) =>
    DashboardRepository(dio: ref.watch(dioProvider));

class DashboardRepository {
  DashboardRepository({required this.dio});
  final Dio dio;

  Future<DashboardSummary> load() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/dashboard');
      return DashboardSummary.fromJson(response.data!);
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.cashHeld,
    required this.monthIn,
    required this.monthOut,
    required this.monthNet,
    required this.pendingCount,
    required this.openFlagCount,
    required this.historyMerged,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        cashHeld: Money.fromJson(json['cashHeld'] as Map<String, dynamic>),
        monthIn: Money.fromJson(json['monthIn'] as Map<String, dynamic>),
        monthOut: Money.fromJson(json['monthOut'] as Map<String, dynamic>),
        monthNet: Money.fromJson(json['monthNet'] as Map<String, dynamic>),
        pendingCount: json['pendingCount'] as int? ?? 0,
        openFlagCount: json['openFlagCount'] as int? ?? 0,
        historyMerged: json['historyMerged'] as bool? ?? false,
      );

  final Money cashHeld;
  final Money monthIn;
  final Money monthOut;
  final Money monthNet;
  final int pendingCount;
  final int openFlagCount;
  final bool historyMerged;
}
