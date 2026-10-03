// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The category picker's contents, grouped by main head.
///
/// Asked for per direction, because money in and money out share almost no
/// categories and showing both would make the list twice as long for no gain.

@ProviderFor(categoryGroups)
final categoryGroupsProvider = CategoryGroupsFamily._();

/// The category picker's contents, grouped by main head.
///
/// Asked for per direction, because money in and money out share almost no
/// categories and showing both would make the list twice as long for no gain.

final class CategoryGroupsProvider extends $FunctionalProvider<
        AsyncValue<List<CategoryGroup>>,
        List<CategoryGroup>,
        FutureOr<List<CategoryGroup>>>
    with
        $FutureModifier<List<CategoryGroup>>,
        $FutureProvider<List<CategoryGroup>> {
  /// The category picker's contents, grouped by main head.
  ///
  /// Asked for per direction, because money in and money out share almost no
  /// categories and showing both would make the list twice as long for no gain.
  CategoryGroupsProvider._(
      {required CategoryGroupsFamily super.from,
      required String super.argument})
      : super(
          retry: noRetry,
          name: r'categoryGroupsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$categoryGroupsHash();

  @override
  String toString() {
    return r'categoryGroupsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CategoryGroup>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<CategoryGroup>> create(Ref ref) {
    final argument = this.argument as String;
    return categoryGroups(
      ref,
      direction: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryGroupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryGroupsHash() => r'ee3560bcd96a25dd5718dc32dbea5588b1987fb0';

/// The category picker's contents, grouped by main head.
///
/// Asked for per direction, because money in and money out share almost no
/// categories and showing both would make the list twice as long for no gain.

final class CategoryGroupsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CategoryGroup>>, String> {
  CategoryGroupsFamily._()
      : super(
          retry: noRetry,
          name: r'categoryGroupsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The category picker's contents, grouped by main head.
  ///
  /// Asked for per direction, because money in and money out share almost no
  /// categories and showing both would make the list twice as long for no gain.

  CategoryGroupsProvider call({
    required String direction,
  }) =>
      CategoryGroupsProvider._(argument: direction, from: this);

  @override
  String toString() => r'categoryGroupsProvider';
}

/// The people who can be named on an entry.

@ProviderFor(people)
final peopleProvider = PeopleProvider._();

/// The people who can be named on an entry.

final class PeopleProvider extends $FunctionalProvider<AsyncValue<List<Person>>,
        List<Person>, FutureOr<List<Person>>>
    with $FutureModifier<List<Person>>, $FutureProvider<List<Person>> {
  /// The people who can be named on an entry.
  PeopleProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'peopleProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$peopleHash();

  @$internal
  @override
  $FutureProviderElement<List<Person>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Person>> create(Ref ref) {
    return people(ref);
  }
}

String _$peopleHash() => r'259e696249f2e9b6b5004e2d438e0e4643a2130b';
