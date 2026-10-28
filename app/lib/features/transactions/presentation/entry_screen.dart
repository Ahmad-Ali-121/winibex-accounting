import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_message.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../application/categories_providers.dart';
import '../application/entry_draft_controller.dart';
import '../domain/entry_draft.dart';
import '../domain/entry_options.dart';
import 'widgets/journal_preview_panel.dart';
import 'widgets/money_field.dart';
import 'widgets/receipt_field.dart';
import 'widgets/taxes_step.dart';
import 'widgets/warnings_dialog.dart';

// The rupee parser moved beside the money field it serves. Exported here so
// anything that imported it from this file still finds it.
export 'widgets/money_field.dart' show parseMinorUnits;

/// Recording money, one question at a time.
///
/// UI-GUIDE: a guided form, not a wall of fields. Each step asks one thing,
/// and the conditional fields appear only when they apply, so a PKR entry
/// never shows an exchange rate box.
class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key, this.canPost = false});

  /// Whether this person may post rather than submit for approval. The server
  /// decides for real; this only changes what the button says.
  final bool canPost;

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  int _step = 0;
  static const _lastStep = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(entryDraftControllerProvider);

    ref.listen(entrySaveProvider, (previous, next) async {
      switch (next) {
        case SaveNeedsConfirmation(:final warnings):
          final confirmed = await showWarningsDialog(context, warnings);
          if (!context.mounted) return;

          if (confirmed) {
            await ref.read(entrySaveProvider.notifier).confirmAndSave(canPost: widget.canPost);
          } else {
            ref.read(entrySaveProvider.notifier).dismiss();
          }

        case SaveSucceeded(:final posted):
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(posted ? l10n.entrySavedPosted : l10n.entrySavedPending)),
          );

          // Start the next entry from nothing, with a new idempotency key. The
          // form used to stay filled in with the old key, so changing one
          // field and saving again was refused as a reused key. D10.
          ref.invalidate(entryDraftControllerProvider);
          if (mounted) setState(() => _step = 0);

        // The review step shows these itself: a disabled button while saving,
        // and the reason when the server refused.
        case SaveInProgress():
        case SaveFailed():
        case SaveIdle():
          break;
      }
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _StepHeader(step: _step, lastStep: _lastStep),
            const SizedBox(height: AppSpacing.xl),
            switch (_step) {
              0 => const _DirectionStep(),
              1 => const _AmountStep(),
              2 => const _PaidByStep(),
              3 => const _CategoryStep(),
              4 => const TaxesStep(),
              5 => const _ReceiptStep(),
              _ => _ReviewStep(canPost: widget.canPost),
            },
            const SizedBox(height: AppSpacing.xl),
            _Navigation(
              step: _step,
              lastStep: _lastStep,
              canContinue: _canLeave(_step, draft),
              onBack: _step == 0 ? null : _back,
              onNext: () => setState(() => _step += 1),
            ),
          ],
        ),
      ),
    );
  }

  /// Leaving the review step clears a refusal that is on screen, because the
  /// person is going back to change something, usually to attach a receipt.
  void _back() {
    if (_step == _lastStep) ref.read(entrySaveProvider.notifier).dismiss();
    setState(() => _step -= 1);
  }

  /// What each step needs before the next one makes sense. Deliberately
  /// light: the server does the real validation and says what is wrong in
  /// words, so this only stops someone walking past an empty field.
  bool _canLeave(int step, EntryDraft draft) => switch (step) {
        0 => true,
        1 => (draft.pkrAmount?.minorUnits ?? 0) > 0 &&
            (!draft.isForeign || (draft.fxRate != null && (draft.foreignAmount?.minorUnits ?? 0) > 0)),
        2 => draft.paidPersonally ? draft.paidByUserId != null : draft.accountId != null,
        3 => draft.categoryId != null && draft.description.trim().isNotEmpty,
        // Every charge needs its amount, and tax kept back needs the payee it
        // was kept back from. Decisions 062 and 064.
        4 => draft.charges.every((charge) => charge.isFilledIn) && (!draft.withholds || draft.vendorId != null),
        // A receipt is never required to move on. The server refuses the
        // posting if the payment is above the threshold without one, and says
        // so in words, which is better than a step that will not let go.
        5 => true,
        _ => true,
      };
}

// ---------------------------------------------------------------------------
// Step 1: direction and date
// ---------------------------------------------------------------------------

class _DirectionStep extends ConsumerWidget {
  const _DirectionStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(entryDraftControllerProvider);
    final controller = ref.read(entryDraftControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(l10n.stepDirectionQuestion),
        SegmentedButton<EntryDirection>(
          segments: [
            ButtonSegment(value: EntryDirection.moneyIn, label: Text(l10n.directionMoneyIn)),
            ButtonSegment(value: EntryDirection.moneyOut, label: Text(l10n.directionMoneyOut)),
          ],
          selected: {draft.direction},
          onSelectionChanged: (selection) => controller.setDirection(selection.first),
        ),
        const SizedBox(height: AppSpacing.xl),
        _Question(l10n.stepDateQuestion),
        DateField(
          value: draft.date,
          onChanged: controller.setDate,
          label: l10n.fieldDate,
          hint: l10n.hintDateFormat,
          pickTooltip: l10n.actionPickDate,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.hintDateIsPaymentDate, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: amount and currency
// ---------------------------------------------------------------------------

class _AmountStep extends ConsumerWidget {
  const _AmountStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(entryDraftControllerProvider);
    final controller = ref.read(entryDraftControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(l10n.stepAmountQuestion),
        // The six currencies the books hold, PKR first. UI-GUIDE, step 2.
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final code in entryCurrencies) ButtonSegment(value: code, label: Text(code)),
          ],
          selected: {draft.currency},
          onSelectionChanged: (selection) => controller.setCurrency(selection.first),
        ),
        const SizedBox(height: AppSpacing.lg),

        // A foreign entry carries the original amount as well as the PKR, or
        // the books cannot show what the bank actually did.
        if (draft.isForeign) ...[
          MoneyField(
            key: ValueKey('foreign-${draft.currency}'),
            label: l10n.fieldForeignAmount,
            value: draft.foreignAmount,
            currency: draft.currency,
            onChanged: (amount) => controller.setForeign(
              amount: Money(minorUnits: amount.minorUnits, currency: draft.currency),
              rate: draft.fxRate,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            initialValue: draft.fxRate,
            decoration: InputDecoration(
              labelText: l10n.fieldRate,
              helperText: l10n.hintRateFor(draft.currency),
              helperMaxLines: 2,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            onChanged: (value) => controller.setForeign(
              amount: draft.foreignAmount ?? Money(minorUnits: 0, currency: draft.currency),
              rate: value.isEmpty ? null : value,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        MoneyField(
          label: !draft.isForeign
              ? l10n.fieldAmount
              : draft.direction == EntryDirection.moneyIn
                  ? l10n.fieldPkrReceived
                  : l10n.fieldPkrPaid,
          value: draft.pkrAmount,
          currency: 'PKR',
          onChanged: controller.setPkrAmount,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.hintAmountIsGross, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: where the money came from or went
// ---------------------------------------------------------------------------

class _PaidByStep extends ConsumerWidget {
  const _PaidByStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(entryDraftControllerProvider);
    final controller = ref.read(entryDraftControllerProvider.notifier);
    final accounts = ref.watch(accountsProvider());
    final people = ref.watch(peopleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(draft.direction == EntryDirection.moneyIn
            ? l10n.stepReceivedIntoQuestion
            : l10n.stepPaidFromQuestion,),

        switch (accounts) {
          AsyncData(:final value) => RadioGroup<int>(
              groupValue: draft.paidPersonally ? null : draft.accountId,
              onChanged: (id) => id == null ? null : controller.setAccount(id),
              child: Column(
                children: [
                  for (final account in value.accounts)
                    RadioListTile<int>(
                      value: account.id,
                      title: Text(account.name),
                      subtitle: _AccountSubtitle(account: account),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          AsyncError() => Text(l10n.errServer, style: Theme.of(context).textTheme.bodySmall),
          _ => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LinearProgressIndicator(),
            ),
        },

        // Only money out can have been paid by a person. Money arriving into
        // someone's personal account is a pass-through account, which is in
        // the list above.
        if (draft.direction == EntryDirection.moneyOut) ...[
          const Divider(height: AppSpacing.xl),
          Text(l10n.stepPaidByPerson, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.hintPaidByPerson, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          switch (people) {
            AsyncData(:final value) => RadioGroup<int>(
                groupValue: draft.paidPersonally ? draft.paidByUserId : null,
                onChanged: (id) => id == null ? null : controller.setPaidByPerson(id),
                child: Column(
                  children: [
                    for (final person in value)
                      RadioListTile<int>(
                        value: person.id,
                        title: Text(person.name),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            _ => const SizedBox.shrink(),
          },
        ],
      ],
    );
  }
}

class _AccountSubtitle extends StatelessWidget {
  const _AccountSubtitle({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context).fieldHoldsNow,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: AppSpacing.xs),
        MoneyText(account.balance, size: 12.5, weight: FontWeight.w400, muted: true),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: what it was for
// ---------------------------------------------------------------------------

class _CategoryStep extends ConsumerWidget {
  const _CategoryStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(entryDraftControllerProvider);
    final controller = ref.read(entryDraftControllerProvider.notifier);

    final direction = draft.direction == EntryDirection.moneyIn ? 'in' : 'out';
    final groups = ref.watch(categoryGroupsProvider(direction: direction));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(l10n.stepCategoryQuestion),

        // Searchable, code first, in code order. In the Phase 1 test 1,200 of
        // staff welfare (6110) went to salaries (6100), one line above it in a
        // long list. Typing "welfare" or "6110" leaves only the right line.
        // O7, decision 061.
        switch (groups) {
          AsyncData(:final value) => DropdownMenu<int>(
              initialSelection: draft.categoryId,
              expandedInsets: EdgeInsets.zero,
              menuHeight: AppSizes.menuMaxHeight,
              label: Text(l10n.fieldCategory),
              hintText: l10n.hintCategorySearch,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              dropdownMenuEntries: [
                for (final category in [
                  for (final group in value) ...group.categories,
                ]..sort((a, b) => a.ledgerCode.compareTo(b.ledgerCode)))
                  DropdownMenuEntry(
                    value: category.id,
                    label: '${category.ledgerCode}  ${category.name}',
                  ),
              ],
              onSelected: (id) => id == null ? null : controller.setCategory(id),
            ),
          AsyncError() => Text(l10n.errServer, style: Theme.of(context).textTheme.bodySmall),
          _ => const LinearProgressIndicator(),
        },

        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          initialValue: draft.description,
          decoration: InputDecoration(
            labelText: l10n.fieldDescription,
            helperText: l10n.hintDescription,
          ),
          maxLength: 255,
          onChanged: controller.setDescription,
        ),

        if (draft.direction == EntryDirection.moneyOut)
          CheckboxListTile(
            value: draft.isRebillable,
            onChanged: (value) => controller.setRebillable(value ?? false),
            title: Text(l10n.fieldRebillable),
            subtitle: Text(l10n.hintRebillable),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5: the receipt
// ---------------------------------------------------------------------------

class _ReceiptStep extends ConsumerWidget {
  const _ReceiptStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(l10n.stepReceiptQuestion),
        Text(l10n.hintReceipt, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        const ReceiptField(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 6: review
// ---------------------------------------------------------------------------

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.canPost});

  final bool canPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final outcome = ref.watch(entrySaveProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(l10n.stepReviewQuestion),
        const JournalPreviewPanel(),
        const SizedBox(height: AppSpacing.xl),
        if (outcome is SaveFailed) ...[
          _RefusalBanner(
            message: errorMessageFor(
              outcome.error,
              network: l10n.errNetworkEntryKept,
              server: l10n.errServer,
              unreadable: l10n.errUnreadable,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        FilledButton(
          onPressed: outcome is SaveInProgress
              ? null
              : () => ref.read(entrySaveProvider.notifier).save(canPost: canPost),
          child: Text(canPost ? l10n.actionSaveAndPost : l10n.actionSubmitForApproval),
        ),
      ],
    );
  }
}

/// Why the server refused, in its words, where the person is looking: right
/// above the button they just pressed. D3.
class _RefusalBanner extends StatelessWidget {
  const _RefusalBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.negative),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.negative),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.negative),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.lastStep});

  final int step;
  final int lastStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stepCounter(step + 1, lastStep + 1),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i <= lastStep; i++)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                  color: i <= step ? colors.accent : colors.rule,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({
    required this.step,
    required this.lastStep,
    required this.canContinue,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int lastStep;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        if (onBack != null)
          OutlinedButton(onPressed: onBack, child: Text(l10n.actionBack)),
        const Spacer(),
        if (step < lastStep)
          FilledButton(
            onPressed: canContinue ? onNext : null,
            child: Text(l10n.actionNext),
          ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
