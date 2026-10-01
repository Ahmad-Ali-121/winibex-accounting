// One definition per accounting term. Labels and tooltip text come from
// app_en.arb, so wording is edited in one place only.
//
// Usage: TermTooltip(term: Term.debit, child: Text(Term.debit.label(l10n)))

import '../../l10n/generated/app_localizations.dart';

enum Term {
  debit,
  credit,
  journalEntry,
  posted,
  draft,
  reversal,
  accountsReceivable,
  accountsPayable,
  rebillable,
  absorbed,
  passThrough,
  trialBalance,
  chartOfAccounts,
  exchangeRate,
  withholdingTax,
  finalTax154A,
  runway,
  fiscalYear,
  partnerShare;

  String label(AppLocalizations l) => switch (this) {
        Term.debit => l.termDebit,
        Term.credit => l.termCredit,
        Term.journalEntry => l.termJournalEntry,
        Term.posted => l.termPosted,
        Term.draft => l.termDraft,
        Term.reversal => l.termReversal,
        Term.accountsReceivable => l.termAccountsReceivable,
        Term.accountsPayable => l.termAccountsPayable,
        Term.rebillable => l.termRebillable,
        Term.absorbed => l.termAbsorbed,
        Term.passThrough => l.termPassThrough,
        Term.trialBalance => l.termTrialBalance,
        Term.chartOfAccounts => l.termChartOfAccounts,
        Term.exchangeRate => l.termExchangeRate,
        Term.withholdingTax => l.termWithholdingTax,
        Term.finalTax154A => l.termFinalTax154A,
        Term.runway => l.termRunway,
        Term.fiscalYear => l.termFiscalYear,
        Term.partnerShare => l.termPartnerShare,
      };

  String tip(AppLocalizations l) => switch (this) {
        Term.debit => l.termDebitTip,
        Term.credit => l.termCreditTip,
        Term.journalEntry => l.termJournalEntryTip,
        Term.posted => l.termPostedTip,
        Term.draft => l.termDraftTip,
        Term.reversal => l.termReversalTip,
        Term.accountsReceivable => l.termAccountsReceivableTip,
        Term.accountsPayable => l.termAccountsPayableTip,
        Term.rebillable => l.termRebillableTip,
        Term.absorbed => l.termAbsorbedTip,
        Term.passThrough => l.termPassThroughTip,
        Term.trialBalance => l.termTrialBalanceTip,
        Term.chartOfAccounts => l.termChartOfAccountsTip,
        Term.exchangeRate => l.termExchangeRateTip,
        Term.withholdingTax => l.termWithholdingTaxTip,
        Term.finalTax154A => l.termFinalTax154ATip,
        Term.runway => l.termRunwayTip,
        Term.fiscalYear => l.termFiscalYearTip,
        Term.partnerShare => l.termPartnerShareTip,
      };
}
