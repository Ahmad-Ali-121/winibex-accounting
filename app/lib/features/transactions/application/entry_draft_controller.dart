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
/// Every setter rebuilds the draft and nothing else. Asking the server for a
/// preview, or for tax suggestions, is an explicit step rather than something
/// that happens on every keystroke: the form would otherwise send a request
/// per character typed into the amount field.
@Riverpod(retry: noRetry)
class EntryDraftController extends _$EntryDraftController {
  @override
  EntryDraft build() {
    return EntryDraft(
      idempotencyKey: newIdempotencyKey(),
      date: DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  void setDirection(EntryDirection direction) {
    // Categories do not cross between money in and money out, so the chosen
    // one cannot survive the switch. Clearing it beats posting revenue to an
    // expense account because the field looked filled in.
    state = state.copyWith(direction: direction, categoryId: null, taxes: const []);
  }

  void setDate(String date) => state = state.copyWith(date: date);

  void setAccount(int accountId) => state = state.copyWith(
        accountId: accountId,
        paidByType: PaidByType.company,
        clearPaidBy: true,
      );

  /// A cost someone paid on their own card. No company account moves, and the
  /// company owes them instead. Decision 020.
  void setPaidByPerson(int userId) => state = state.copyWith(
        paidByType: PaidByType.person,
        paidByUserId: userId,
        clearAccount: true,
      );

  void setCategory(int categoryId) => state = state.copyWith(categoryId: categoryId);
  void setDescription(String description) => state = state.copyWith(description: description);
  void setMethod(String method) => state = state.copyWith(method: method);
  void setVendor(int? vendorId) => state = state.copyWith(vendorId: vendorId);
  void setRebillable(bool value) => state = state.copyWith(isRebillable: value);

  void setPkrAmount(Money amount) => state = state.copyWith(pkrAmount: amount);

  void setCurrency(String currency) {
    if (currency == 'PKR') {
      state = state.copyWith(currency: 'PKR', clearForeign: true);
      return;
    }
    state = state.copyWith(currency: currency);
  }

  /// A foreign entry carries the original amount and the rate, or the books
  /// cannot show what the bank actually did. Decision 017: the person may
  /// enter the PKR the bank gave instead, and the rate is derived from it.
  void setForeign({required Money amount, String? rate, Money? pkr}) {
    state = state.copyWith(
      foreignAmount: amount,
      fxRate: rate,
      pkrAmount: pkr ?? state.pkrAmount,
    );
  }

  void setTaxes(List<DraftTax> taxes) => state = state.copyWith(taxes: taxes);
  void removeTax(int taxId) =>
      state = state.copyWith(taxes: state.taxes.where((tax) => tax.taxId != taxId).toList());
  void setCharges(List<DraftCharge> charges) => state = state.copyWith(charges: charges);

  void setReceipt(DraftAttachment receipt) => state = state.copyWith(receipt: receipt);
  void clearReceipt() => state = state.copyWith(clearReceipt: true);

  void acknowledge(List<String> codes) =>
      state = state.copyWith(acknowledgedWarnings: [...state.acknowledgedWarnings, ...codes]);

  /// Asks the server what tax applies. A suggestion only: every line it
  /// returns can be edited or removed, and what the bank actually took wins.
  Future<void> suggestTaxes({String? accountType}) async {
    final draft = state;
    if ((draft.pkrAmount?.minorUnits ?? 0) <= 0) return;

    final suggestions = await ref.read(transactionsRepositoryProvider).suggestTaxes(
          direction: draft.direction == EntryDirection.moneyIn ? 'in' : 'out',
          baseMinorUnits: draft.pkrAmount!.minorUnits,
          currency: draft.currency,
          date: draft.date,
          categoryId: draft.categoryId,
          vendorId: draft.vendorId,
          accountType: accountType,
        );

    if (!ref.mounted) return;
    state = state.copyWith(taxes: suggestions);
  }
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

/// What happened to the save: nothing yet, warnings to confirm, or a saved id.
sealed class SaveOutcome {
  const SaveOutcome();
}

class SaveIdle extends SaveOutcome {
  const SaveIdle();
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

  /// Creates the entry, then posts it when [canPost], otherwise submits it for
  /// someone else to approve.
  ///
  /// A 409 of warnings is not a failure. It comes back as SaveNeedsConfirmation
  /// with each warning naming the record it matched, and the same call with
  /// those codes acknowledged goes through.
  Future<void> save({required bool canPost}) async {
    final repository = ref.read(transactionsRepositoryProvider);
    final draft = ref.read(entryDraftControllerProvider);

    try {
      final id = await repository.create(draft);

      // Before posting, not after. A payment above the threshold is refused
      // without its receipt, and the receipt has to be there by then.
      final receipt = draft.receipt;
      if (receipt != null) {
        await repository.uploadReceipt(
          transactionId: id,
          bytes: receipt.bytes,
          filename: receipt.filename,
          mime: receipt.mime,
        );
      }

      if (canPost) {
        await repository.approve(id, newIdempotencyKey());
      } else {
        await repository.submit(id);
      }

      if (!ref.mounted) return;

      // Balances changed, so ask for them again rather than adjusting
      // anything here. The server is the only thing that knows.
      ref.invalidate(accountsProvider);
      state = SaveSucceeded(id, posted: canPost);
    } on ApiException catch (error) {
      if (!ref.mounted) return;

      if (error.isWarnings) {
        state = SaveNeedsConfirmation(error.warnings);
        return;
      }
      rethrow;
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
