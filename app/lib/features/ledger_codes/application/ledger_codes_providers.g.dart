// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_codes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerCodes)
final ledgerCodesProvider = LedgerCodesProvider._();

final class LedgerCodesProvider extends $FunctionalProvider<
        AsyncValue<List<LedgerCode>>,
        List<LedgerCode>,
        FutureOr<List<LedgerCode>>>
    with $FutureModifier<List<LedgerCode>>, $FutureProvider<List<LedgerCode>> {
  LedgerCodesProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'ledgerCodesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerCodesHash();

  @$internal
  @override
  $FutureProviderElement<List<LedgerCode>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<LedgerCode>> create(Ref ref) {
    return ledgerCodes(ref);
  }
}

String _$ledgerCodesHash() => r'327ecd2e2a9d0e9bb8158b67e9cb69fed3dc8bc4';

/// Every change on the ledger codes screen. Null when it worked, or the
/// refusal in the server's words. A change can add, rename or remove a
/// category, so the entry form's list is asked for again too.

@ProviderFor(LedgerCodeActions)
final ledgerCodeActionsProvider = LedgerCodeActionsProvider._();

/// Every change on the ledger codes screen. Null when it worked, or the
/// refusal in the server's words. A change can add, rename or remove a
/// category, so the entry form's list is asked for again too.
final class LedgerCodeActionsProvider
    extends $NotifierProvider<LedgerCodeActions, void> {
  /// Every change on the ledger codes screen. Null when it worked, or the
  /// refusal in the server's words. A change can add, rename or remove a
  /// category, so the entry form's list is asked for again too.
  LedgerCodeActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'ledgerCodeActionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerCodeActionsHash();

  @$internal
  @override
  LedgerCodeActions create() => LedgerCodeActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$ledgerCodeActionsHash() => r'1324ebe3bb62617934988caa90d6cade3e93e88a';

/// Every change on the ledger codes screen. Null when it worked, or the
/// refusal in the server's words. A change can add, rename or remove a
/// category, so the entry form's list is asked for again too.

abstract class _$LedgerCodeActions extends $Notifier<void> {
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
