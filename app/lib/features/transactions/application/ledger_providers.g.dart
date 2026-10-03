// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the ledger is filtered to.
///
/// One object rather than four providers, so changing the search box and the
/// account filter together refetches once.

@ProviderFor(LedgerFilters)
final ledgerFiltersProvider = LedgerFiltersProvider._();

/// What the ledger is filtered to.
///
/// One object rather than four providers, so changing the search box and the
/// account filter together refetches once.
final class LedgerFiltersProvider
    extends $NotifierProvider<LedgerFilters, LedgerQuery> {
  /// What the ledger is filtered to.
  ///
  /// One object rather than four providers, so changing the search box and the
  /// account filter together refetches once.
  LedgerFiltersProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerFiltersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerFiltersHash();

  @$internal
  @override
  LedgerFilters create() => LedgerFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerQuery>(value),
    );
  }
}

String _$ledgerFiltersHash() => r'e9b72ba4058b64c4b70748b1ff7218fefe372caa';

/// What the ledger is filtered to.
///
/// One object rather than four providers, so changing the search box and the
/// account filter together refetches once.

abstract class _$LedgerFilters extends $Notifier<LedgerQuery> {
  LedgerQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LedgerQuery, LedgerQuery>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<LedgerQuery, LedgerQuery>, LedgerQuery, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// A page of the ledger, searched and filtered by the server. Decision 022:
/// the app holds one page, so searching what it holds would miss the rest.

@ProviderFor(ledgerPage)
final ledgerPageProvider = LedgerPageProvider._();

/// A page of the ledger, searched and filtered by the server. Decision 022:
/// the app holds one page, so searching what it holds would miss the rest.

final class LedgerPageProvider extends $FunctionalProvider<
        AsyncValue<LedgerPage>, LedgerPage, FutureOr<LedgerPage>>
    with $FutureModifier<LedgerPage>, $FutureProvider<LedgerPage> {
  /// A page of the ledger, searched and filtered by the server. Decision 022:
  /// the app holds one page, so searching what it holds would miss the rest.
  LedgerPageProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'ledgerPageProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerPageHash();

  @$internal
  @override
  $FutureProviderElement<LedgerPage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LedgerPage> create(Ref ref) {
    return ledgerPage(ref);
  }
}

String _$ledgerPageHash() => r'723851bfe1c1100861e55193dd1b13a4d7514040';

/// The journal lines behind one posted entry, fetched when it is opened.

@ProviderFor(entryJournal)
final entryJournalProvider = EntryJournalFamily._();

/// The journal lines behind one posted entry, fetched when it is opened.

final class EntryJournalProvider extends $FunctionalProvider<
        AsyncValue<List<JournalLine>>,
        List<JournalLine>,
        FutureOr<List<JournalLine>>>
    with
        $FutureModifier<List<JournalLine>>,
        $FutureProvider<List<JournalLine>> {
  /// The journal lines behind one posted entry, fetched when it is opened.
  EntryJournalProvider._(
      {required EntryJournalFamily super.from, required int super.argument})
      : super(
          retry: noRetry,
          name: r'entryJournalProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$entryJournalHash();

  @override
  String toString() {
    return r'entryJournalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<JournalLine>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<JournalLine>> create(Ref ref) {
    final argument = this.argument as int;
    return entryJournal(
      ref,
      transactionId: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EntryJournalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryJournalHash() => r'063fb1126106c84505faad9e5b851a21ccb55181';

/// The journal lines behind one posted entry, fetched when it is opened.

final class EntryJournalFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<JournalLine>>, int> {
  EntryJournalFamily._()
      : super(
          retry: noRetry,
          name: r'entryJournalProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The journal lines behind one posted entry, fetched when it is opened.

  EntryJournalProvider call({
    required int transactionId,
  }) =>
      EntryJournalProvider._(argument: transactionId, from: this);

  @override
  String toString() => r'entryJournalProvider';
}

@ProviderFor(approvals)
final approvalsProvider = ApprovalsProvider._();

final class ApprovalsProvider extends $FunctionalProvider<
        AsyncValue<List<Approval>>, List<Approval>, FutureOr<List<Approval>>>
    with $FutureModifier<List<Approval>>, $FutureProvider<List<Approval>> {
  ApprovalsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'approvalsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$approvalsHash();

  @$internal
  @override
  $FutureProviderElement<List<Approval>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Approval>> create(Ref ref) {
    return approvals(ref);
  }
}

String _$approvalsHash() => r'30d9b5febae84e39702af3424e2f6b14fe120221';

/// Approving and rejecting.
///
/// Never retried automatically: approving is posting, and a write that may
/// have landed must not be repeated on a guess.

@ProviderFor(ApprovalActions)
final approvalActionsProvider = ApprovalActionsProvider._();

/// Approving and rejecting.
///
/// Never retried automatically: approving is posting, and a write that may
/// have landed must not be repeated on a guess.
final class ApprovalActionsProvider
    extends $NotifierProvider<ApprovalActions, void> {
  /// Approving and rejecting.
  ///
  /// Never retried automatically: approving is posting, and a write that may
  /// have landed must not be repeated on a guess.
  ApprovalActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'approvalActionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$approvalActionsHash();

  @$internal
  @override
  ApprovalActions create() => ApprovalActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$approvalActionsHash() => r'e95c9b961bd4af170ec704c7d6b0d09ea3ded989';

/// Approving and rejecting.
///
/// Never retried automatically: approving is posting, and a write that may
/// have landed must not be repeated on a guess.

abstract class _$ApprovalActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
