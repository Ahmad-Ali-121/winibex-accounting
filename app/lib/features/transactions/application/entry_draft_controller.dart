import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_retry.dart';
import '../../../core/api/idempotency_key.dart';
import '../../../core/money/money.dart';
import '../../accounts/application/accounts_providers.dart';
import '../data/transactions_repository.dart';
import '../domain/entry_draft.dart';
import '../domain/journal_preview.dart';

part 'entry_draft_controller.g.dart';

/// The entry form's state, and the actions that change it.
///
/// Every setter rebuilds the draft and nothing else. Asking the server for
/// tax suggestions is an explicit step rather than something that happens on
/// every keystroke: the form would otherwise send a request per character
/// typed into the amount field.
@Riverpod(retry: noRetry)
class EntryDraftController extends _$EntryDraftController {
  @override
  EntryDraft build() {
    return EntryDraft(
      idempotencyKey: newIdempotencyKey(),
      date: DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  /// The form's own numbering for charge lines. Never sent to the server.
  int _nextChargeId = 1;

  /// Opens a draft already on the server, to be fixed and saved again. The
  /// form then edits that draft rather than creating a new one. Decision 067.
  Future<ApiException?> openExisting(int id) async {
    try {
      final draft = await ref
          .read(transactionsRepositoryProvider)
          .openDraft(id, idempotencyKey: newIdempotencyKey());
      if (!ref.mounted) return null;
      _nextChargeId = draft.charges.length + 1;
      state = draft;
      return null;
    } catch (error) {
      return ApiException.from(error);
    }
  }

  /// Anything a tax depends on has changed: the lines are thrown away and the
  /// tax step suggests them again from the new figures. A tax worked out on
  /// the old amount must never be saved with the new one. Decision 064.
  EntryDraft _taxesStale(EntryDraft draft) => draft.copyWith(taxes: const [], taxesChecked: false);

  void setDirection(EntryDirection direction) {
    if (direction == state.direction) return;
    // Categories do not cross between money in and money out, so the chosen
    // one cannot survive the switch. Clearing it beats posting revenue to an
    // expense account because the field looked filled in.
    state = _taxesStale(state.copyWith(direction: direction, clearCategory: true));
  }

  void setDate(String date) {
    if (date == state.date) return;
    // A rate in force on one date may not be on another.
    state = _taxesStale(state.copyWith(date: date));
  }

  void setAccount(int accountId) {
    if (!state.paidPersonally && accountId == state.accountId) return;
    state = _taxesStale(state.copyWith(
      accountId: accountId,
      paidByType: PaidByType.company,
      clearPaidBy: true,
    ),);
  }

  /// A cost someone paid on their own card. No company account moves, and the
  /// company owes them instead. Decision 020.
  void setPaidByPerson(int userId) {
    if (state.paidPersonally && userId == state.paidByUserId) return;
    state = _taxesStale(state.copyWith(
      paidByType: PaidByType.person,
      paidByUserId: userId,
      clearAccount: true,
    ),);
  }

  void setCategory(int categoryId) {
    if (categoryId == state.categoryId) return;
    state = _taxesStale(state.copyWith(categoryId: categoryId));
  }

  void setDescription(String description) => state = state.copyWith(description: description);
  void setMethod(String method) => state = state.copyWith(method: method);
  void setRebillable(bool value) => state = state.copyWith(isRebillable: value);

  void setPkrAmount(Money amount) {
    if (amount == state.pkrAmount) return;
    state = _taxesStale(state.copyWith(pkrAmount: amount));
  }

  /// Any of the six. Switching between two foreign currencies keeps the
  /// figure typed and changes only its currency, so the box and the request
  /// never disagree about what the number is in.
  void setCurrency(String currency) {
    if (currency == state.currency) return;
    if (currency == 'PKR') {
      state = _taxesStale(state.copyWith(currency: 'PKR', clearForeign: true));
      return;
    }
    final typed = state.foreignAmount;
    state = _taxesStale(state.copyWith(
      currency: currency,
      foreignAmount: typed == null ? null : Money(minorUnits: typed.minorUnits, currency: currency),
    ),);
  }

  /// A foreign entry carries the original amount and the rate, or the books
  /// cannot show what the bank actually did. Decision 017.
  void setForeign({required Money amount, String? rate, Money? pkr}) {
    state = state.copyWith(
      foreignAmount: amount,
      fxRate: rate,
      pkrAmount: pkr ?? state.pkrAmount,
    );
  }

  // --- taxes ------------------------------------------------------------------

  void setTaxes(List<DraftTax> taxes) => state = state.copyWith(taxes: taxes);

  void removeTax(int taxId) =>
      state = state.copyWith(taxes: state.taxes.where((tax) => tax.taxId != taxId).toList());

  /// The person typed what was actually taken. What the bank took wins over
  /// the suggestion, and the line is marked as changed. TAXES.md, principle 4.
  void setTaxAmount(int taxId, Money amount) {
    state = state.copyWith(taxes: [
      for (final tax in state.taxes)
        tax.taxId == taxId ? tax.copyWith(amount: amount, isOverride: true) : tax,
    ],);
  }

  String get _direction => state.direction == EntryDirection.moneyIn ? 'in' : 'out';

  Future<List<DraftTax>> _workOut({List<int>? taxIds, String? accountType}) {
    final draft = state;
    return ref.read(transactionsRepositoryProvider).suggestTaxes(
          direction: _direction,
          baseMinorUnits: draft.pkrAmount!.minorUnits,
          currency: draft.currency,
          date: draft.date,
          categoryId: draft.categoryId,
          vendorId: draft.vendorId,
          accountType: accountType,
          taxIds: taxIds,
        );
  }

  /// Asks the server what tax applies. A suggestion only: every line it
  /// returns can be changed or removed, and what the bank actually took wins.
  /// Returns the refusal, or null when it worked.
  Future<ApiException?> suggestTaxes({String? accountType}) async {
    if ((state.pkrAmount?.minorUnits ?? 0) <= 0) return null;
    try {
      final suggestions = await _workOut(accountType: accountType);
      if (!ref.mounted) return null;
      state = state.copyWith(taxes: suggestions, taxesChecked: true);
      return null;
    } catch (error) {
      if (!ref.mounted) return null;
      // Nothing to suggest is still an answer: the person can add lines by
      // hand. Marked checked so the step does not ask again on every visit.
      state = state.copyWith(taxesChecked: true);
      return ApiException.from(error);
    }
  }

  /// A tax the person adds by hand. The server works out its line; the app
  /// never multiplies a rate. Decision 064.
  Future<ApiException?> addTax(int taxId) async {
    if ((state.pkrAmount?.minorUnits ?? 0) <= 0) return null;
    if (state.taxes.any((tax) => tax.taxId == taxId)) return null;
    try {
      final lines = await _workOut(taxIds: [taxId]);
      if (!ref.mounted) return null;
      state = state.copyWith(taxes: [...state.taxes, ...lines], taxesChecked: true);
      return null;
    } catch (error) {
      return ApiException.from(error);
    }
  }

  /// The payee decides the rate of any tax kept back from them, so choosing
  /// one works the same taxes out again at that payee's rate. A figure typed
  /// over a line is replaced by the new one.
  Future<ApiException?> setVendor(int? vendorId) async {
    state = vendorId == null ? state.copyWith(clearVendor: true) : state.copyWith(vendorId: vendorId);
    final ids = state.taxes.map((tax) => tax.taxId).toList();
    if (ids.isEmpty || (state.pkrAmount?.minorUnits ?? 0) <= 0) return null;
    try {
      final lines = await _workOut(taxIds: ids);
      if (!ref.mounted) return null;
      state = state.copyWith(taxes: lines);
      return null;
    } catch (error) {
      return ApiException.from(error);
    }
  }

  // --- charges ----------------------------------------------------------------

  void addCharge({String type = 'bank_charge'}) {
    state = state.copyWith(charges: [
      ...state.charges,
      DraftCharge(id: _nextChargeId++, type: type, amount: Money.zero),
    ],);
  }

  void updateCharge(DraftCharge charge) {
    state = state.copyWith(charges: [
      for (final line in state.charges) line.id == charge.id ? charge : line,
    ],);
  }

  void removeCharge(int id) =>
      state = state.copyWith(charges: state.charges.where((line) => line.id != id).toList());

  // --- receipt and warnings ---------------------------------------------------

  void setReceipt(DraftAttachment receipt) => state = state.copyWith(receipt: receipt);
  void clearReceipt() => state = state.copyWith(clearReceipt: true);

  void acknowledge(List<String> codes) =>
      state = state.copyWith(acknowledgedWarnings: [...state.acknowledgedWarnings, ...codes]);
}

/// The journal entry the current draft would post.
///
/// Separate from the controller so the review step can watch it and show
/// loading and error states on its own, without the form fields rebuilding
/// every time the preview is refreshed.
@Riverpod(retry: noRetry)
Future<JournalPreview?> journalPreview(Ref ref) async {
  final draft = ref.watch(entryDraftControllerProvider);
  if (!draft.canPreview) return null;

  return ref.watch(transactionsRepositoryProvider).preview(draft);
}

/// What happened to the save: nothing yet, in flight, warnings to confirm, a
/// refusal to show, or a saved id.
sealed class SaveOutcome {
  const SaveOutcome();
}

class SaveIdle extends SaveOutcome {
  const SaveIdle();
}

/// A request is in flight. The button is disabled, so a second press cannot
/// start a second save while the first is still going.
class SaveInProgress extends SaveOutcome {
  const SaveInProgress();
}

/// The server refused, or could not be reached. The review step shows why.
///
/// When the refusal came at posting rather than at creation, for example a
/// payment above the threshold with no receipt, the entry already exists as a
/// draft. Pressing the button again finishes that same draft: unchanged, it is
/// posted as it is; changed, it is edited first and then posted. Defect D3,
/// and F7 for the changed case.
class SaveFailed extends SaveOutcome {
  const SaveFailed(this.error);
  final ApiException error;
}

class SaveNeedsConfirmation extends SaveOutcome {
  const SaveNeedsConfirmation(this.warnings);
  final List<ApiWarning> warnings;
}

class SaveSucceeded extends SaveOutcome {
  const SaveSucceeded(this.transactionId, {required this.posted});
  final int transactionId;

  /// True when the person could approve it themselves and it is already in the
  /// book. False means it is waiting for someone else.
  final bool posted;
}

/// Saving, as its own notifier.
///
/// Never retried automatically. A write that may have landed must not be
/// repeated on a guess: the idempotency key exists for the case where the
/// answer was lost rather than the request.
@Riverpod(retry: noRetry)
class EntrySave extends _$EntrySave {
  @override
  SaveOutcome build() => const SaveIdle();

  /// The draft this form has already created on the server, if any, and what
  /// was last sent for it. Tied to the form's idempotency key, so a new form
  /// (a new key) never finishes an old draft.
  _SentDraft? _sent;

  /// Creates the entry, then posts it when [canPost], otherwise submits it for
  /// someone else to approve.
  ///
  /// A 409 of warnings is not a failure. It comes back as SaveNeedsConfirmation
  /// with each warning naming the record it matched, and the same call with
  /// those codes acknowledged goes through.
  Future<void> save({required bool canPost}) async {
    if (state is SaveInProgress) return;

    final repository = ref.read(transactionsRepositoryProvider);
    final draft = ref.read(entryDraftControllerProvider);
    state = const SaveInProgress();

    try {
      // The first press creates the draft. A later press for the same form,
      // after a refusal, finishes the draft that already exists: edited first
      // if the person changed anything, so what posts is what the screen
      // shows. Sending the old key with new content is what posted 6,000 for
      // an entry that read 6,500. Defect F7, decision 059.
      final body = jsonEncode(draft.toRequest());
      var sent = _sent;

      // A draft opened from the server already exists. The first save edits
      // it; an empty body forces that edit. Decision 067.
      if (sent == null && draft.existingId != null) {
        sent = _SentDraft(idempotencyKey: draft.idempotencyKey, id: draft.existingId!, body: '');
      }

      if (sent == null || sent.idempotencyKey != draft.idempotencyKey) {
        final id = await repository.create(draft);
        sent = _SentDraft(idempotencyKey: draft.idempotencyKey, id: id, body: body);
        _sent = sent;
      } else if (sent.body != body) {
        await repository.update(sent.id, draft);
        sent = sent.copyWith(body: body);
        _sent = sent;
      }

      // Before posting, not after. A payment above the threshold is refused
      // without its receipt, and the receipt has to be there by then. A
      // receipt already sent for this draft is not sent a second time.
      final receipt = draft.receipt;
      if (receipt != null && !identical(receipt, sent.receipt)) {
        await repository.uploadReceipt(
          transactionId: sent.id,
          bytes: receipt.bytes,
          filename: receipt.filename,
          mime: receipt.mime,
        );
        sent = sent.copyWith(receipt: receipt);
        _sent = sent;
      }

      if (canPost) {
        await repository.approve(sent.id, newIdempotencyKey());
      } else {
        await repository.submit(sent.id);
      }

      if (!ref.mounted) return;

      // Balances changed, so ask for them again rather than adjusting
      // anything here. The server is the only thing that knows.
      ref.invalidate(accountsProvider);
      state = SaveSucceeded(sent.id, posted: canPost);
    } on ApiException catch (error) {
      if (!ref.mounted) return;

      if (error.isWarnings) {
        state = SaveNeedsConfirmation(error.warnings);
        return;
      }
      // Rethrowing here is what left the person looking at a button that
      // seemed to do nothing. The refusal is now state the screen shows. D3.
      state = SaveFailed(error);
    } catch (error) {
      if (!ref.mounted) return;
      state = SaveFailed(ApiException.from(error));
    }
  }

  /// The person read the warnings and chose to go ahead.
  Future<void> confirmAndSave({required bool canPost}) async {
    final outcome = state;
    if (outcome is! SaveNeedsConfirmation) return;

    ref.read(entryDraftControllerProvider.notifier).acknowledge(
          outcome.warnings.map((warning) => warning.code).toList(),
        );

    state = const SaveIdle();
    await save(canPost: canPost);
  }

  void dismiss() => state = const SaveIdle();
}

/// What the server already holds for the open form: the draft's id, the body
/// it was last given, and the receipt already attached.
class _SentDraft {
  const _SentDraft({
    required this.idempotencyKey,
    required this.id,
    required this.body,
    this.receipt,
  });

  final String idempotencyKey;
  final int id;
  final String body;
  final DraftAttachment? receipt;

  _SentDraft copyWith({String? body, DraftAttachment? receipt}) => _SentDraft(
        idempotencyKey: idempotencyKey,
        id: id,
        body: body ?? this.body,
        receipt: receipt ?? this.receipt,
      );
}
