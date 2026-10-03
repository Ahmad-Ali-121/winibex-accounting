// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Balances, straight from the server.
///
/// Read-only, so a functional provider rather than a notifier. Anything that
/// writes money invalidates this instead of adjusting a balance locally: the
/// server is the only thing that knows what an account holds.
///
/// retry: noRetry, because Riverpod 3 otherwise retries a failure by itself
/// and the screen stays on its skeleton while it does, telling the person
/// nothing. A failed read shows an error panel with a Try again button.

@ProviderFor(accounts)
final accountsProvider = AccountsFamily._();

/// Balances, straight from the server.
///
/// Read-only, so a functional provider rather than a notifier. Anything that
/// writes money invalidates this instead of adjusting a balance locally: the
/// server is the only thing that knows what an account holds.
///
/// retry: noRetry, because Riverpod 3 otherwise retries a failure by itself
/// and the screen stays on its skeleton while it does, telling the person
/// nothing. A failed read shows an error panel with a Try again button.

final class AccountsProvider extends $FunctionalProvider<
        AsyncValue<AccountsSummary>, AccountsSummary, FutureOr<AccountsSummary>>
    with $FutureModifier<AccountsSummary>, $FutureProvider<AccountsSummary> {
  /// Balances, straight from the server.
  ///
  /// Read-only, so a functional provider rather than a notifier. Anything that
  /// writes money invalidates this instead of adjusting a balance locally: the
  /// server is the only thing that knows what an account holds.
  ///
  /// retry: noRetry, because Riverpod 3 otherwise retries a failure by itself
  /// and the screen stays on its skeleton while it does, telling the person
  /// nothing. A failed read shows an error panel with a Try again button.
  AccountsProvider._(
      {required AccountsFamily super.from, required bool super.argument})
      : super(
          retry: noRetry,
          name: r'accountsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountsHash();

  @override
  String toString() {
    return r'accountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AccountsSummary> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AccountsSummary> create(Ref ref) {
    final argument = this.argument as bool;
    return accounts(
      ref,
      includeInactive: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AccountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountsHash() => r'8cddd65dad48d216380fde022d6202965a25db76';

/// Balances, straight from the server.
///
/// Read-only, so a functional provider rather than a notifier. Anything that
/// writes money invalidates this instead of adjusting a balance locally: the
/// server is the only thing that knows what an account holds.
///
/// retry: noRetry, because Riverpod 3 otherwise retries a failure by itself
/// and the screen stays on its skeleton while it does, telling the person
/// nothing. A failed read shows an error panel with a Try again button.

final class AccountsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AccountsSummary>, bool> {
  AccountsFamily._()
      : super(
          retry: noRetry,
          name: r'accountsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Balances, straight from the server.
  ///
  /// Read-only, so a functional provider rather than a notifier. Anything that
  /// writes money invalidates this instead of adjusting a balance locally: the
  /// server is the only thing that knows what an account holds.
  ///
  /// retry: noRetry, because Riverpod 3 otherwise retries a failure by itself
  /// and the screen stays on its skeleton while it does, telling the person
  /// nothing. A failed read shows an error panel with a Try again button.

  AccountsProvider call({
    bool includeInactive = false,
  }) =>
      AccountsProvider._(argument: includeInactive, from: this);

  @override
  String toString() => r'accountsProvider';
}

@ProviderFor(pettyCash)
final pettyCashProvider = PettyCashProvider._();

final class PettyCashProvider extends $FunctionalProvider<
        AsyncValue<PettyCashStatus>, PettyCashStatus, FutureOr<PettyCashStatus>>
    with $FutureModifier<PettyCashStatus>, $FutureProvider<PettyCashStatus> {
  PettyCashProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'pettyCashProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pettyCashHash();

  @$internal
  @override
  $FutureProviderElement<PettyCashStatus> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PettyCashStatus> create(Ref ref) {
    return pettyCash(ref);
  }
}

String _$pettyCashHash() => r'37a7d7f83c8fdfc217e22cbdcabad36dd2b9f558';
