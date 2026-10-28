// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_draft_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The entry form's state, and the actions that change it.
///
/// Every setter rebuilds the draft and nothing else. Asking the server for
/// tax suggestions is an explicit step rather than something that happens on
/// every keystroke: the form would otherwise send a request per character
/// typed into the amount field.

@ProviderFor(EntryDraftController)
final entryDraftControllerProvider = EntryDraftControllerProvider._();

/// The entry form's state, and the actions that change it.
///
/// Every setter rebuilds the draft and nothing else. Asking the server for
/// tax suggestions is an explicit step rather than something that happens on
/// every keystroke: the form would otherwise send a request per character
/// typed into the amount field.
final class EntryDraftControllerProvider
    extends $NotifierProvider<EntryDraftController, EntryDraft> {
  /// The entry form's state, and the actions that change it.
  ///
  /// Every setter rebuilds the draft and nothing else. Asking the server for
  /// tax suggestions is an explicit step rather than something that happens on
  /// every keystroke: the form would otherwise send a request per character
  /// typed into the amount field.
  EntryDraftControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'entryDraftControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$entryDraftControllerHash();

  @$internal
  @override
  EntryDraftController create() => EntryDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntryDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntryDraft>(value),
    );
  }
}

String _$entryDraftControllerHash() =>
    r'4743de3257ee100f1248c10cebee5d755e6ee193';

/// The entry form's state, and the actions that change it.
///
/// Every setter rebuilds the draft and nothing else. Asking the server for
/// tax suggestions is an explicit step rather than something that happens on
/// every keystroke: the form would otherwise send a request per character
/// typed into the amount field.

abstract class _$EntryDraftController extends $Notifier<EntryDraft> {
  EntryDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EntryDraft, EntryDraft>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<EntryDraft, EntryDraft>, EntryDraft, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// The journal entry the current draft would post.
///
/// Separate from the controller so the review step can watch it and show
/// loading and error states on its own, without the form fields rebuilding
/// every time the preview is refreshed.

@ProviderFor(journalPreview)
final journalPreviewProvider = JournalPreviewProvider._();

/// The journal entry the current draft would post.
///
/// Separate from the controller so the review step can watch it and show
/// loading and error states on its own, without the form fields rebuilding
/// every time the preview is refreshed.

final class JournalPreviewProvider extends $FunctionalProvider<
        AsyncValue<JournalPreview?>, JournalPreview?, FutureOr<JournalPreview?>>
    with $FutureModifier<JournalPreview?>, $FutureProvider<JournalPreview?> {
  /// The journal entry the current draft would post.
  ///
  /// Separate from the controller so the review step can watch it and show
  /// loading and error states on its own, without the form fields rebuilding
  /// every time the preview is refreshed.
  JournalPreviewProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'journalPreviewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$journalPreviewHash();

  @$internal
  @override
  $FutureProviderElement<JournalPreview?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<JournalPreview?> create(Ref ref) {
    return journalPreview(ref);
  }
}

String _$journalPreviewHash() => r'c18455a353892f6ae61757c9739485855af6ff49';

/// Saving, as its own notifier.
///
/// Never retried automatically. A write that may have landed must not be
/// repeated on a guess: the idempotency key exists for the case where the
/// answer was lost rather than the request.

@ProviderFor(EntrySave)
final entrySaveProvider = EntrySaveProvider._();

/// Saving, as its own notifier.
///
/// Never retried automatically. A write that may have landed must not be
/// repeated on a guess: the idempotency key exists for the case where the
/// answer was lost rather than the request.
final class EntrySaveProvider
    extends $NotifierProvider<EntrySave, SaveOutcome> {
  /// Saving, as its own notifier.
  ///
  /// Never retried automatically. A write that may have landed must not be
  /// repeated on a guess: the idempotency key exists for the case where the
  /// answer was lost rather than the request.
  EntrySaveProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'entrySaveProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$entrySaveHash();

  @$internal
  @override
  EntrySave create() => EntrySave();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveOutcome value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveOutcome>(value),
    );
  }
}

String _$entrySaveHash() => r'0989fead4c536165893a1b8ab79fc7c2bf30d2cb';

/// Saving, as its own notifier.
///
/// Never retried automatically. A write that may have landed must not be
/// repeated on a guess: the idempotency key exists for the case where the
/// answer was lost rather than the request.

abstract class _$EntrySave extends $Notifier<SaveOutcome> {
  SaveOutcome build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SaveOutcome, SaveOutcome>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SaveOutcome, SaveOutcome>, SaveOutcome, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
