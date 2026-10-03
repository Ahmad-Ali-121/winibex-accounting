// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardSummary)
final dashboardSummaryProvider = DashboardSummaryProvider._();

final class DashboardSummaryProvider extends $FunctionalProvider<
        AsyncValue<DashboardSummary>,
        DashboardSummary,
        FutureOr<DashboardSummary>>
    with $FutureModifier<DashboardSummary>, $FutureProvider<DashboardSummary> {
  DashboardSummaryProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'dashboardSummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dashboardSummaryHash();

  @$internal
  @override
  $FutureProviderElement<DashboardSummary> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardSummary> create(Ref ref) {
    return dashboardSummary(ref);
  }
}

String _$dashboardSummaryHash() => r'9f5c6ba44d4e478d056954bc1be2558b02f75d39';
