// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Winibex Accounting';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navApprovals => 'Approvals';

  @override
  String get navClients => 'Clients';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navQuotations => 'Quotations';

  @override
  String get navPayroll => 'Payroll';

  @override
  String get navRecurring => 'Recurring costs';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaveDraft => 'Save draft';

  @override
  String get actionSubmit => 'Submit for approval';

  @override
  String get actionApprove => 'Approve and post';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionReverse => 'Reverse entry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionExportCsv => 'Export CSV';

  @override
  String get actionCopyRow => 'Copy row';

  @override
  String get actionDownloadPdf => 'Download PDF';

  @override
  String get actionAttachReceipt => 'Attach receipt';

  @override
  String get actionTakePhoto => 'Take photo';

  @override
  String get actionViewJournal => 'View journal entry';

  @override
  String get actionAddTaxLine => 'Add tax line';

  @override
  String get actionAddCharge => 'Add charge';

  @override
  String get actionNewTransaction => 'New transaction';

  @override
  String get actionNewInvoice => 'New invoice';

  @override
  String get actionNewQuotation => 'New quotation';

  @override
  String get actionConvertToInvoice => 'Convert to invoice';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionProceedAnyway => 'Proceed anyway';

  @override
  String get actionReviewMatch => 'Review matching entry';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldDirection => 'Direction';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldPaidBy => 'Paid by';

  @override
  String get fieldReceivedInto => 'Received into';

  @override
  String get fieldExchangeRate => 'Exchange rate';

  @override
  String get fieldPkrAmount => 'PKR amount';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldAccount => 'Account';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldClient => 'Client';

  @override
  String get fieldProject => 'Project';

  @override
  String get fieldRebillable => 'Rebillable to client';

  @override
  String get fieldReference => 'Reference';

  @override
  String get fieldReceipt => 'Receipt';

  @override
  String get fieldReason => 'Reason';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get directionMoneyIn => 'Money in';

  @override
  String get directionMoneyOut => 'Money out';

  @override
  String get directionTransfer => 'Transfer';

  @override
  String get paidByCompany => 'Company account';

  @override
  String paidByPerson(String name) {
    return '$name, personally';
  }

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPending => 'Pending approval';

  @override
  String get statusPosted => 'Posted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusReversed => 'Reversed';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusPartial => 'Partially paid';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusSent => 'Sent';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusConverted => 'Converted';

  @override
  String get clientStatusActive => 'Active';

  @override
  String get clientStatusOnCall => 'On call';

  @override
  String get clientStatusPaused => 'Paused';

  @override
  String get clientStatusClosed => 'Closed';

  @override
  String get colDate => 'Date';

  @override
  String get colNumber => 'No.';

  @override
  String get colDescription => 'Description';

  @override
  String get colAccount => 'Account';

  @override
  String get colCategory => 'Category';

  @override
  String get colDebit => 'Debit';

  @override
  String get colCredit => 'Credit';

  @override
  String get colBalance => 'Balance';

  @override
  String get colStatus => 'Status';

  @override
  String get colClient => 'Client';

  @override
  String get colEnteredBy => 'Entered by';

  @override
  String get stepDirection => 'What kind of entry is this?';

  @override
  String get stepCurrency => 'Which currency?';

  @override
  String get stepAmount => 'How much?';

  @override
  String get stepPaidBy => 'Who paid?';

  @override
  String get stepReceivedInto => 'Where did the money land?';

  @override
  String get stepConversion => 'Conversion to PKR';

  @override
  String get stepTaxes => 'Taxes and charges';

  @override
  String get stepDetails => 'What was it for?';

  @override
  String get stepReceipt => 'Receipt';

  @override
  String get stepReview => 'Review before submitting';

  @override
  String hintLastRate(String currency, String rate) {
    return 'Last rate used for $currency: $rate';
  }

  @override
  String get hintEnterRateOrPkr =>
      'Enter the rate or the PKR amount. The other fills in.';

  @override
  String hintPersonPayable(String name) {
    return 'The company will owe $name this amount until it is reimbursed.';
  }

  @override
  String get hintReceiptRequired => 'A receipt is required for this entry.';

  @override
  String get hintReceiptOptional =>
      'Optional. Entries without a receipt are flagged for review.';

  @override
  String get totalPkrOut => 'Total PKR out';

  @override
  String get totalPkrIn => 'Total PKR received';

  @override
  String rowsAndTotal(int count, String total) {
    return '$count entries, $total';
  }

  @override
  String confirmPosted(String account, String balance) {
    return 'Posted. $account is now $balance.';
  }

  @override
  String confirmSubmitted(String approver) {
    return 'Submitted. Waiting for $approver to approve.';
  }

  @override
  String get confirmDraftSaved => 'Draft saved.';

  @override
  String get confirmReversed =>
      'Reversed. Both entries stay in the ledger, linked.';

  @override
  String confirmRejected(String name) {
    return 'Rejected. $name can see the reason.';
  }

  @override
  String get errUnbalanced => 'Debits and credits do not match.';

  @override
  String get errMissingCategory => 'Pick a category before submitting.';

  @override
  String get errMissingAccount => 'Pick an account before submitting.';

  @override
  String get errAmountNotPositive =>
      'Enter an amount above zero. Direction sets whether money comes in or goes out.';

  @override
  String get errFutureDate => 'The date cannot be in the future.';

  @override
  String get errBeforeOpening =>
      'This date is before the account\'s opening date.';

  @override
  String get errNeedRateOrPkr => 'Enter the exchange rate or the PKR amount.';

  @override
  String get errRateNotPositive => 'The exchange rate must be above zero.';

  @override
  String get errTaxExceedsBase =>
      'A tax line cannot be larger than the amount it is calculated on.';

  @override
  String get errTaxNotInEffect =>
      'This tax was not in effect on the transaction date.';

  @override
  String errCashNegative(String account, String balance) {
    return '$account only has $balance. Cash cannot go below zero.';
  }

  @override
  String get errSameAccountTransfer =>
      'Choose two different accounts for a transfer.';

  @override
  String errOverpayment(String remaining) {
    return 'This is more than the invoice\'s remaining $remaining. Record the extra as a customer advance.';
  }

  @override
  String get errReceiptRequired =>
      'Attach a receipt. It is required for this kind of entry.';

  @override
  String get errPostedImmutable =>
      'Posted entries cannot be edited. Reverse it and enter a corrected one.';

  @override
  String errDuplicateReference(String account) {
    return 'This reference is already used on $account.';
  }

  @override
  String get errNetwork =>
      'Could not reach the server. Your entry is kept. Try again when connected.';

  @override
  String get errSignIn => 'Email or password is incorrect.';

  @override
  String warnPossibleDuplicate(String account, String date) {
    return 'An entry for the same amount on $account was recorded on $date.';
  }

  @override
  String warnUnusualAmount(String category) {
    return 'This is more than three times the usual amount for $category.';
  }

  @override
  String warnRateDeviation(String percent, String currency) {
    return 'This rate is $percent% away from the last rate used for $currency.';
  }

  @override
  String get warnBackdated => 'This date is more than 90 days ago.';

  @override
  String warnClosedClient(String client) {
    return '$client is marked closed.';
  }

  @override
  String get warnTaxOverride =>
      'This tax rate differs from the configured rate.';

  @override
  String get warnLargeCash =>
      'Large cash expense. Double check before submitting.';

  @override
  String get flagNoReceipt => 'No receipt';

  @override
  String get flagThinDescription => 'Description too short';

  @override
  String get flagSelfApproved => 'Created and approved by the same person';

  @override
  String get flagPassThroughAging =>
      'Money held in a pass-through account over 14 days';

  @override
  String get flagUninvoicedRebillable =>
      'Rebillable spend not invoiced after 30 days';

  @override
  String get emptyTransactions =>
      'No transactions yet. Record the first money in or money out to start the ledger.';

  @override
  String get emptyApprovals => 'Nothing waiting for approval.';

  @override
  String get emptyClients =>
      'No clients yet. Add one to link income and spending to it.';

  @override
  String get emptyInvoices =>
      'No invoices yet. Create one, or convert an accepted quotation.';

  @override
  String get emptyFlags => 'No flagged entries. Everything has been reviewed.';

  @override
  String emptySearch(String query) {
    return 'No entries match \"$query\".';
  }

  @override
  String get termDebit => 'Debit';

  @override
  String get termDebitTip =>
      'The left side of a journal entry. Increases assets and expenses, decreases liabilities and income.';

  @override
  String get termCredit => 'Credit';

  @override
  String get termCreditTip =>
      'The right side of a journal entry. Increases liabilities and income, decreases assets and expenses.';

  @override
  String get termJournalEntry => 'Journal entry';

  @override
  String get termJournalEntryTip =>
      'The debit and credit lines this transaction records in the books. Debits always equal credits.';

  @override
  String get termPosted => 'Posted';

  @override
  String get termPostedTip =>
      'Recorded in the books. A posted entry cannot be edited, only reversed.';

  @override
  String get termDraft => 'Draft';

  @override
  String get termDraftTip =>
      'Saved but not submitted. Does not affect any balance.';

  @override
  String get termReversal => 'Reversal';

  @override
  String get termReversalTip =>
      'An equal and opposite entry that cancels a posted one. Both stay visible so the history is complete.';

  @override
  String get termAccountsReceivable => 'Accounts receivable';

  @override
  String get termAccountsReceivableTip =>
      'Money clients owe Winibex for invoices not yet paid.';

  @override
  String get termAccountsPayable => 'Accounts payable';

  @override
  String get termAccountsPayableTip =>
      'Money Winibex owes to suppliers, contractors or people who paid on its behalf.';

  @override
  String get termRebillable => 'Rebillable';

  @override
  String get termRebillableTip =>
      'Spent on a client\'s behalf and charged back to them. Appears on their next invoice instead of reducing profit.';

  @override
  String get termAbsorbed => 'Absorbed';

  @override
  String get termAbsorbedTip =>
      'Spent on a client\'s behalf and not charged back. Comes out of the profit on that client.';

  @override
  String get termPassThrough => 'Pass-through account';

  @override
  String get termPassThroughTip =>
      'A personal account where company money lands before being transferred to Winibex. Only company money is tracked here.';

  @override
  String get termTrialBalance => 'Trial balance';

  @override
  String get termTrialBalanceTip =>
      'Every account\'s debit or credit total. The two columns must be equal, which proves the books are internally consistent.';

  @override
  String get termChartOfAccounts => 'Chart of accounts';

  @override
  String get termChartOfAccountsTip =>
      'The full list of accounts the books are organised into, from cash and bank to income and expenses.';

  @override
  String get termExchangeRate => 'Exchange rate';

  @override
  String get termExchangeRateTip =>
      'PKR per one unit of the foreign currency. Use the rate the bank actually applied.';

  @override
  String get termWithholdingTax => 'Withholding tax';

  @override
  String get termWithholdingTaxTip =>
      'Tax deducted at source by the payer and deposited with FBR on the recipient\'s behalf.';

  @override
  String get termFinalTax154A => 'Final tax, Section 154A';

  @override
  String get termFinalTax154ATip =>
      'Tax the bank deducts on IT export receipts for PSEB-registered companies. It is the full tax on that income.';

  @override
  String get termRunway => 'Runway';

  @override
  String get termRunwayTip =>
      'How many months current cash covers fixed costs such as salaries and subscriptions, assuming no new income.';

  @override
  String get termFiscalYear => 'Fiscal year';

  @override
  String get termFiscalYearTip =>
      '1 July to 30 June, matching the Pakistan tax year.';

  @override
  String get termPartnerShare => 'Partner share';

  @override
  String get termPartnerShareTip =>
      'The portion of earnings kept by the owner of an Upwork or other platform account used for the work.';

  @override
  String get loginHeading => 'Sign in';

  @override
  String get loginSubheading => 'Winibex internal books';

  @override
  String get loginEmailRequired => 'Enter your email address.';

  @override
  String get loginPasswordRequired => 'Enter your password.';

  @override
  String get loginSigningIn => 'Signing in...';

  @override
  String get errTooManyAttempts =>
      'Too many sign-in attempts. Try again in a few minutes.';

  @override
  String get errServer => 'Something went wrong. Try again.';

  @override
  String get errSessionExpired => 'Your session has expired. Sign in again.';

  @override
  String get mustChangePassword => 'Set a new password before continuing.';

  @override
  String get actionRetry => 'Try again';

  @override
  String get themeSystem => 'Match system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get a11yToggleTheme => 'Change theme';

  @override
  String a11yWhatIsTerm(String term) {
    return 'What does $term mean?';
  }

  @override
  String get errAccountInactive =>
      'This account has been deactivated. Ask the owner.';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsSubtitle => 'What the company holds today';

  @override
  String get accountsColumnAccount => 'ACCOUNT';

  @override
  String get accountsColumnLedger => 'LEDGER';

  @override
  String get accountsColumnBalance => 'BALANCE';

  @override
  String get accountsTotal => 'Total held';

  @override
  String get accountsInactive => 'Closed';

  @override
  String get accountsHistoryNotMerged =>
      'These balances start from 1 July 2026. Entries before that are excluded until history has been checked against the opening entry.';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypePettyCash => 'Petty cash';

  @override
  String get accountTypeCheque => 'Cheques';

  @override
  String get accountTypePassThrough => 'Pass-through';

  @override
  String get emptyAccountsTitle => 'No accounts yet';

  @override
  String get emptyAccountsDetail => 'Accounts are set up once, in Settings.';

  @override
  String get navNewEntry => 'New entry';

  @override
  String stepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stepDirectionQuestion => 'Did money come in, or go out?';

  @override
  String get stepDateQuestion => 'When did it move?';

  @override
  String get stepAmountQuestion => 'How much?';

  @override
  String get stepPaidFromQuestion => 'Which account did it leave?';

  @override
  String get stepReceivedIntoQuestion => 'Which account did it arrive in?';

  @override
  String get stepPaidByPerson => 'Or someone paid it personally';

  @override
  String get stepCategoryQuestion => 'What was it for?';

  @override
  String get stepReviewQuestion => 'Check this before saving';

  @override
  String get currencyPkr => 'Rupees';

  @override
  String get currencyForeign => 'Foreign currency';

  @override
  String get fieldForeignAmount => 'Amount in the original currency';

  @override
  String get fieldRate => 'Exchange rate';

  @override
  String get fieldPkrReceived => 'Rupees actually received';

  @override
  String get fieldHoldsNow => 'Holds';

  @override
  String get hintDateIsPaymentDate =>
      'The date the money moved, not the date you are entering it.';

  @override
  String get hintAmountIsGross =>
      'Before any tax or bank charges. Those come next.';

  @override
  String get hintRateOrPkr =>
      'Enter the rate, or leave it and type the rupees the bank gave.';

  @override
  String get hintDescription => 'Enough that you will recognise it in a year.';

  @override
  String get hintRebillable =>
      'It will not count as a cost. It sits as money owed until you invoice it.';

  @override
  String get hintPaidByPerson =>
      'No company account moves. The company owes them instead.';

  @override
  String get previewNotReady =>
      'Fill in the amount, the account and the category to see the journal entry.';

  @override
  String get journalColumnAccount => 'ACCOUNT';

  @override
  String get journalBalanced => 'Balanced';

  @override
  String get actionSaveAndPost => 'Save and post';

  @override
  String get actionSubmitForApproval => 'Submit for approval';

  @override
  String get actionGoBack => 'Go back and check';

  @override
  String get actionSaveAnyway => 'Save anyway';

  @override
  String get warnTitle => 'Check these first';

  @override
  String get warnIntro =>
      'Nothing is wrong with the entry. These are worth a look before it goes in.';

  @override
  String get entrySavedPosted => 'Saved and posted.';

  @override
  String get entrySavedPending => 'Submitted. Someone else will approve it.';

  @override
  String get hintSearchLedger =>
      'Search descriptions, journal numbers and references';

  @override
  String ledgerShowing(int shown, int total) {
    return 'Showing $shown of $total';
  }

  @override
  String get ledgerFlagged => 'This entry has something to review';

  @override
  String get ledgerReversedNotice =>
      'This entry was reversed. Both it and its reversal stay in the book.';

  @override
  String get emptyLedgerTitle => 'Nothing here yet';

  @override
  String get emptyLedgerDetail =>
      'Entries appear here as soon as they are submitted.';

  @override
  String get emptyApprovalsTitle => 'Nothing waiting';

  @override
  String get emptyApprovalsDetail =>
      'Entries submitted for approval show up here.';

  @override
  String get approvalsYourOwn =>
      'You entered this, so someone else has to approve it.';

  @override
  String approvalsHasFlags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things to review',
      one: '1 thing to review',
    );
    return '$_temp0';
  }

  @override
  String get rejectTitle => 'Send it back';

  @override
  String get hintRejectReason =>
      'They will see this, so say what needs changing.';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get actionNextPage => 'Next page';

  @override
  String get actionClose => 'Close';

  @override
  String get stepReceiptQuestion => 'Attach the receipt';

  @override
  String get hintReceipt =>
      'A photo or a PDF. A payment over the limit in Settings cannot be posted without one, and you can also add it later.';

  @override
  String get actionRemove => 'Remove';

  @override
  String receiptSize(int kb) {
    return '$kb KB';
  }

  @override
  String get navFlags => 'To review';

  @override
  String get dashboardTitle => 'Overview';

  @override
  String get dashboardCashHeld => 'Cash the company holds';

  @override
  String get dashboardBeforeHistory =>
      'From 1 July 2026 onward. Earlier entries are excluded until history is checked.';

  @override
  String get dashboardInThisMonth => 'In this month';

  @override
  String get dashboardOutThisMonth => 'Out this month';

  @override
  String dashboardWaitingApproval(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries waiting for approval',
      one: '1 entry waiting for approval',
    );
    return '$_temp0';
  }

  @override
  String dashboardOpenFlags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries to review',
      one: '1 entry to review',
    );
    return '$_temp0';
  }

  @override
  String get emptyFlagsTitle => 'Nothing to review';

  @override
  String get emptyFlagsDetail =>
      'Warnings people confirmed, and flags like a missing receipt, show up here.';

  @override
  String flagsConfirmedBy(String name) {
    return 'confirmed by $name';
  }

  @override
  String get flagPossibleDuplicate => 'Possible duplicate';

  @override
  String get flagUnusualAmount => 'Unusual amount';

  @override
  String get flagBackdated => 'Backdated';

  @override
  String get flagBankBelowZero => 'Bank went below zero';

  @override
  String get flagLargeCash => 'Large cash payment';

  @override
  String get flagRateDeviation => 'Rate differs from last time';

  @override
  String get flagRepeatedDescription => 'Same as a recent entry';
}
