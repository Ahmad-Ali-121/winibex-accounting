import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/money_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../application/categories_providers.dart';
import '../application/entry_draft_controller.dart';
import '../domain/entry_draft.dart';
import 'widgets/journal_preview_panel.dart';
import 'widgets/receipt_field.dart';
import 'widgets/warnings_dialog.dart';

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
  static const _lastStep = 5;

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
              4 => const _ReceiptStep(),
              _ => _ReviewStep(canPost: widget.canPost),
            },
            const SizedBox(height: AppSpacing.xl),
            _Navigation(
              step: _step,
              lastStep: _lastStep,
              canContinue: _canLeave(_step, draft),
              onBack: _step == 0 ? null : () => setState(() => _step -= 1),
              onNext: () => setState(() => _step += 1),
            ),
          ],
        ),
      ),
    );
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
        // A receipt is never required to move on. The server refuses the
        // posting if the payment is above the threshold without one, and says
        // so in words, which is better than a step that will not let go.
        4 => true,
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
        _DateField(
          value: draft.date,
          onChanged: controller.setDate,
          label: l10n.fieldDate,
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
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'PKR', label: Text(l10n.currencyPkr)),
            ButtonSegment(value: 'USD', label: Text(l10n.currencyForeign)),
          ],
          selected: {draft.isForeign ? 'USD' : 'PKR'},
          onSelectionChanged: (selection) => controller.setCurrency(selection.first),
        ),
        const SizedBox(height: AppSpacing.lg),

        // A foreign entry carries the original amount as well as the PKR, or
        // the books cannot show what the bank actually did.
        if (draft.isForeign) ...[
          _MoneyField(
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
              helperText: l10n.hintRateOrPkr,
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

        _MoneyField(
          label: draft.isForeign ? l10n.fieldPkrReceived : l10n.fieldAmount,
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

        switch (groups) {
          AsyncData(:final value) => DropdownButtonFormField<int>(
              initialValue: draft.categoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.fieldCategory),
              items: [
                for (final group in value) ...[
                  for (final category in group.categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(
                        '${category.name}  ${category.ledgerCode}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ],
              onChanged: (id) => id == null ? null : controller.setCategory(id),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Question(l10n.stepReviewQuestion),
        const JournalPreviewPanel(),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => ref.read(entrySaveProvider.notifier).save(canPost: canPost),
          child: Text(canPost ? l10n.actionSaveAndPost : l10n.actionSubmitForApproval),
        ),
      ],
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

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged, required this.label});

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, hintText: 'YYYY-MM-DD'),
      keyboardType: TextInputType.datetime,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
      onChanged: onChanged,
    );
  }
}

/// Takes rupees from the person and keeps paisa in the draft.
///
/// Parsing is integer only: the text is split on the decimal point and the two
/// halves are combined, so nothing ever becomes a double on the way in.
class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.value,
    required this.currency,
    required this.onChanged,
  });

  final String label;
  final Money? value;
  final String currency;
  final ValueChanged<Money> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value == null || value!.isZero ? '' : value!.format(withCurrency: false),
      decoration: InputDecoration(labelText: label, prefixText: '$currency '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: AppText.amount(context),
      onChanged: (text) => onChanged(
        Money(minorUnits: parseMinorUnits(text), currency: currency),
      ),
    );
  }
}

/// "5,953.5" becomes 595350. No double anywhere in the conversion.
int parseMinorUnits(String text, {int decimals = 2}) {
  final cleaned = text.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return 0;

  final parts = cleaned.split('.');
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first) ?? 0;
  if (parts.length == 1) return whole * 100;

  final fraction = parts[1].padRight(decimals, '0').substring(0, decimals);
  final minor = int.tryParse(fraction) ?? 0;
  return whole * 100 + minor;
}
