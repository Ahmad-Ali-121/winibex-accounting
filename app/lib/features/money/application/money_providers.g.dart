// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everyone the company owes money to, most owed first is the server's order.

@ProviderFor(peopleOwed)
final peopleOwedProvider = PeopleOwedProvider._();

/// Everyone the company owes money to, most owed first is the server's order.

final class PeopleOwedProvider extends $FunctionalProvider<
        AsyncValue<List<PersonOwed>>,
        List<PersonOwed>,
        FutureOr<List<PersonOwed>>>
    with $FutureModifier<List<PersonOwed>>, $FutureProvider<List<PersonOwed>> {
  /// Everyone the company owes money to, most owed first is the server's order.
  PeopleOwedProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'peopleOwedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$peopleOwedHash();

  @$internal
  @override
  $FutureProviderElement<List<PersonOwed>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<PersonOwed>> create(Ref ref) {
    return peopleOwed(ref);
  }
}

String _$peopleOwedHash() => r'498ce5bd723c4fcfbdb49a0c824ba35583c1f57f';

/// The costs behind what one person is owed.

@ProviderFor(owedCosts)
final owedCostsProvider = OwedCostsFamily._();

/// The costs behind what one person is owed.

final class OwedCostsProvider extends $FunctionalProvider<
        AsyncValue<List<OwedCost>>, List<OwedCost>, FutureOr<List<OwedCost>>>
    with $FutureModifier<List<OwedCost>>, $FutureProvider<List<OwedCost>> {
  /// The costs behind what one person is owed.
  OwedCostsProvider._(
      {required OwedCostsFamily super.from, required int super.argument})
      : super(
          retry: noRetry,
          name: r'owedCostsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$owedCostsHash();

  @override
  String toString() {
    return r'owedCostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<OwedCost>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<OwedCost>> create(Ref ref) {
    final argument = this.argument as int;
    return owedCosts(
      ref,
      userId: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OwedCostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$owedCostsHash() => r'02be476a0a4482a84c3873da9552e76fe4ee34d2';

/// The costs behind what one person is owed.

final class OwedCostsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<OwedCost>>, int> {
  OwedCostsFamily._()
      : super(
          retry: noRetry,
          name: r'owedCostsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The costs behind what one person is owed.

  OwedCostsProvider call({
    required int userId,
  }) =>
      OwedCostsProvider._(argument: userId, from: this);

  @override
  String toString() => r'owedCostsProvider';
}

@ProviderFor(openingInfo)
final openingInfoProvider = OpeningInfoProvider._();

final class OpeningInfoProvider extends $FunctionalProvider<
        AsyncValue<OpeningInfo>, OpeningInfo, FutureOr<OpeningInfo>>
    with $FutureModifier<OpeningInfo>, $FutureProvider<OpeningInfo> {
  OpeningInfoProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'openingInfoProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$openingInfoHash();

  @$internal
  @override
  $FutureProviderElement<OpeningInfo> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<OpeningInfo> create(Ref ref) {
    return openingInfo(ref);
  }
}

String _$openingInfoHash() => r'17ae927f842e3d234d490aa2960920fe7349e69e';
