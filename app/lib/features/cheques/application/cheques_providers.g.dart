// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheques_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The register, all cheques, or one status. Null is all.

@ProviderFor(chequeRegister)
final chequeRegisterProvider = ChequeRegisterFamily._();

/// The register, all cheques, or one status. Null is all.

final class ChequeRegisterProvider extends $FunctionalProvider<
        AsyncValue<ChequeRegister>, ChequeRegister, FutureOr<ChequeRegister>>
    with $FutureModifier<ChequeRegister>, $FutureProvider<ChequeRegister> {
  /// The register, all cheques, or one status. Null is all.
  ChequeRegisterProvider._(
      {required ChequeRegisterFamily super.from,
      required String? super.argument})
      : super(
          retry: noRetry,
          name: r'chequeRegisterProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chequeRegisterHash();

  @override
  String toString() {
    return r'chequeRegisterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ChequeRegister> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ChequeRegister> create(Ref ref) {
    final argument = this.argument as String?;
    return chequeRegister(
      ref,
      status: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChequeRegisterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chequeRegisterHash() => r'3bfe536763ca7532b3765eb2548fe851bc3e1a3c';

/// The register, all cheques, or one status. Null is all.

final class ChequeRegisterFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ChequeRegister>, String?> {
  ChequeRegisterFamily._()
      : super(
          retry: noRetry,
          name: r'chequeRegisterProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The register, all cheques, or one status. Null is all.

  ChequeRegisterProvider call({
    String? status,
  }) =>
      ChequeRegisterProvider._(argument: status, from: this);

  @override
  String toString() => r'chequeRegisterProvider';
}

@ProviderFor(chequePayments)
final chequePaymentsProvider = ChequePaymentsFamily._();

final class ChequePaymentsProvider extends $FunctionalProvider<
        AsyncValue<List<PaymentOption>>,
        List<PaymentOption>,
        FutureOr<List<PaymentOption>>>
    with
        $FutureModifier<List<PaymentOption>>,
        $FutureProvider<List<PaymentOption>> {
  ChequePaymentsProvider._(
      {required ChequePaymentsFamily super.from,
      required ({
        int accountId,
        String search,
      })
          super.argument})
      : super(
          retry: noRetry,
          name: r'chequePaymentsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chequePaymentsHash();

  @override
  String toString() {
    return r'chequePaymentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PaymentOption>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentOption>> create(Ref ref) {
    final argument = this.argument as ({
      int accountId,
      String search,
    });
    return chequePayments(
      ref,
      accountId: argument.accountId,
      search: argument.search,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChequePaymentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chequePaymentsHash() => r'8605dec671c2835a5311af6b8c1fe0605327194e';

final class ChequePaymentsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<List<PaymentOption>>,
            ({
              int accountId,
              String search,
            })> {
  ChequePaymentsFamily._()
      : super(
          retry: noRetry,
          name: r'chequePaymentsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ChequePaymentsProvider call({
    required int accountId,
    String search = '',
  }) =>
      ChequePaymentsProvider._(argument: (
        accountId: accountId,
        search: search,
      ), from: this);

  @override
  String toString() => r'chequePaymentsProvider';
}

/// Issuing, moving a cheque on, linking it. Null when it worked, or the
/// refusal. Kept alive for the same reason as the other action providers.

@ProviderFor(ChequeActions)
final chequeActionsProvider = ChequeActionsProvider._();

/// Issuing, moving a cheque on, linking it. Null when it worked, or the
/// refusal. Kept alive for the same reason as the other action providers.
final class ChequeActionsProvider
    extends $NotifierProvider<ChequeActions, void> {
  /// Issuing, moving a cheque on, linking it. Null when it worked, or the
  /// refusal. Kept alive for the same reason as the other action providers.
  ChequeActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'chequeActionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chequeActionsHash();

  @$internal
  @override
  ChequeActions create() => ChequeActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$chequeActionsHash() => r'c8d03f38b9d5b01180a6a8ff88bdaa4f5ee2bce1';

/// Issuing, moving a cheque on, linking it. Null when it worked, or the
/// refusal. Kept alive for the same reason as the other action providers.

abstract class _$ChequeActions extends $Notifier<void> {
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
