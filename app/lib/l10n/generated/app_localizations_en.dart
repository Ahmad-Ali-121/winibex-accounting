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
  String get fieldRebillable => 'Client will pay this back';

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
      'Could not reach the server. Check the connection and try again.';

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
      'Spent for a client 30 days ago and not yet billed to them';

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
  String get termRebillable => 'Client will pay back';

  @override
  String get termRebillableTip =>
      'Spent for a client who will repay it. It is not counted as our cost. It waits as money the client owes until they pay.';

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
      'Before any tax or bank charges. Those are added after the category.';

  @override
  String get hintRateOrPkr =>
      'Enter the rate, or leave it and type the rupees the bank gave.';

  @override
  String get hintDescription => 'Enough that you will recognise it in a year.';

  @override
  String get hintRebillable =>
      'Spent for a client who will repay it. It is not counted as our cost. It waits as money the client owes until they pay.';

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

  @override
  String get changePasswordHeading => 'Change your password';

  @override
  String get changePasswordForcedHeading => 'Set a new password';

  @override
  String get changePasswordSubheading =>
      'Enter your current password and choose a new one.';

  @override
  String get changePasswordForcedSubheading =>
      'This account still uses its first password. Choose a new one to continue.';

  @override
  String get changePasswordRule => 'At least 10 characters.';

  @override
  String get fieldCurrentPassword => 'Current password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldConfirmPassword => 'Confirm new password';

  @override
  String get changePasswordCurrentRequired => 'Enter your current password.';

  @override
  String get changePasswordTooShort => 'Use at least 10 characters.';

  @override
  String get changePasswordMismatch => 'The two passwords do not match.';

  @override
  String get changePasswordSaving => 'Saving';

  @override
  String get changePasswordDone => 'Password changed.';

  @override
  String get actionSetPassword => 'Set password';

  @override
  String get actionViewHistory => 'View history';

  @override
  String get historyTitle => 'Edit history';

  @override
  String get historyEmpty => 'Nothing has changed on this entry.';

  @override
  String get historyCreated => 'Created';

  @override
  String get historyUpdated => 'Edited';

  @override
  String get historyStatusChanged => 'Status changed';

  @override
  String get actionMarkReviewed => 'Mark reviewed';

  @override
  String get markReviewedTitle => 'Mark as reviewed';

  @override
  String get fieldReviewNote => 'Why it needs nothing more';

  @override
  String get hintReviewNote =>
      'Kept with the flag, so anyone can see why it was cleared.';

  @override
  String get flagMarkedReviewed => 'Marked as reviewed.';

  @override
  String get errNetworkEntryKept =>
      'Could not reach the server. Your entry is kept. Try again when connected.';

  @override
  String get errUnreadable =>
      'The app could not read the server\'s answer. Try again. If it keeps happening, tell whoever looks after the app.';

  @override
  String get errNoteTooShort => 'Write at least 3 characters.';

  @override
  String get actionPickDate => 'Pick a date';

  @override
  String get hintDateFormat => 'YYYY-MM-DD';

  @override
  String get hintCategorySearch =>
      'Type a name or a code, such as welfare or 6110';

  @override
  String get peopleTitle => 'People';

  @override
  String get peopleOwnerOnly =>
      'Only the owner can add people or change what they can do.';

  @override
  String get actionAddPerson => 'Add person';

  @override
  String get actionResetPassword => 'Reset password';

  @override
  String get actionSwitchOff => 'Switch off';

  @override
  String get actionSwitchOn => 'Switch on';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleHelpTitle => 'What each role can do';

  @override
  String get roleAdminHelp =>
      'Approves other people\'s entries, moves money between accounts, reverses entries, pays people back, adds vendors, issues cheques and clears flags. Cannot add people or change settings.';

  @override
  String get roleStaffHelp =>
      'Records money in and money out and sends it for approval. Cannot approve anything, including their own entries.';

  @override
  String get officeLoginHelp =>
      'Turn this on for anyone who also knows the office login password. When the office login approves an entry this person made, the app keeps a quiet note, because it may be the same person approving their own work.';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldRole => 'Role';

  @override
  String get fieldApprovalLimit => 'Approval limit (PKR)';

  @override
  String get hintApprovalLimit =>
      'The biggest entry this person may approve. Leave empty for no limit. Bigger entries wait for the owner.';

  @override
  String get fieldPostsOwn => 'Can post their own entries';

  @override
  String get hintPostsOwn =>
      'On: their own entries go straight into the books. Off: someone else must approve them.';

  @override
  String get fieldSharesOfficeLogin => 'Also uses the office login';

  @override
  String get hintSharesOfficeLogin =>
      'Turn on if this person knows the office login password. Their entries approved by the office login get a quiet note.';

  @override
  String get fieldTemporaryPassword => 'Temporary password';

  @override
  String get hintTemporaryPassword =>
      'At least 10 characters. Give it to them in person. They must choose their own password the first time they sign in.';

  @override
  String get peopleApprovesUpTo => 'Approves up to';

  @override
  String get peopleNoLimit => 'Approves any amount';

  @override
  String get peoplePostsOwn => 'Posts own entries';

  @override
  String get peopleSharesLogin => 'Also uses the office login';

  @override
  String get peopleSwitchedOff => 'Switched off, cannot sign in';

  @override
  String get peopleMustChange => 'Has not set their own password yet';

  @override
  String personAdded(String name) {
    return '$name is added. Give them the temporary password in person.';
  }

  @override
  String get personSaved => 'Saved.';

  @override
  String get passwordReset =>
      'Password reset. They are signed out everywhere and must set a new one.';

  @override
  String get addPersonTitle => 'Add a person';

  @override
  String get editPersonTitle => 'Change what this person can do';

  @override
  String get errNameRequired => 'Enter their name.';

  @override
  String get errEmailInvalid => 'Enter a valid email address.';

  @override
  String resetPasswordTitle(String name) {
    return 'Reset password for $name';
  }

  @override
  String get peopleIntro =>
      'Who can sign in, and what each person may do. Only the owner can change this.';

  @override
  String get roleOwnerShort =>
      'Full access. Adds people and changes what they can do. The office login.';

  @override
  String get roleAdminShort =>
      'Approves entries and moves money. Cannot add people.';

  @override
  String get roleStaffShort =>
      'Records money in and out. Someone else approves it.';

  @override
  String get roleGuideSubtitle => 'Read this before giving someone a login.';

  @override
  String get roleGuideShowTable => 'See exactly who can do what';

  @override
  String get roleGuideTask => 'Task';

  @override
  String get capRecord => 'Record money in and money out';

  @override
  String get capPostOwn => 'Own entries go straight into the books';

  @override
  String get capApprove => 'Approve other people\'s entries';

  @override
  String get capMoveMoney => 'Move money between accounts';

  @override
  String get capReverse => 'Reverse a posted entry';

  @override
  String get capPayBack => 'Pay people back';

  @override
  String get capVendorsCheques => 'Add vendors and issue cheques';

  @override
  String get capClearFlags => 'Mark flags as reviewed';

  @override
  String get capPeople => 'Add people and change what they can do';

  @override
  String get capLimited => 'Depends on settings';

  @override
  String get capLimitedTip =>
      'For an admin, this depends on their settings: an optional approval limit, and whether their own entries post straight away.';

  @override
  String get a11yYes => 'Yes';

  @override
  String get a11yNo => 'No';

  @override
  String get peopleNobodyDeleted =>
      'Nobody is deleted. Someone who leaves is switched off, so every entry keeps the name of who made it.';

  @override
  String get peopleFullAccess => 'Full access';

  @override
  String get peopleOwnNeedApproval => 'Own entries need approval';

  @override
  String get peopleNeedsApproval => 'Every entry needs approval';

  @override
  String get peopleOwnerNote =>
      'This is the office login. It always has full access and changes its own password.';

  @override
  String get actionMore => 'More actions';

  @override
  String get peopleSectionOffice => 'Office login';

  @override
  String get peopleSectionAdmins => 'Admins';

  @override
  String get peopleSectionStaff => 'Staff members';

  @override
  String get peopleSectionOff => 'Switched off';

  @override
  String get dialogSectionWho => 'Who';

  @override
  String get dialogSectionApprovals => 'Approvals';

  @override
  String get dialogSectionSignIn => 'Sign-in';

  @override
  String get hintEmailIsLogin => 'They sign in with this email.';

  @override
  String get hintEmailFixed => 'The email they sign in with cannot be changed.';

  @override
  String get currencyCodePkr => 'PKR';

  @override
  String get hintNoLimit => 'No limit';

  @override
  String get actionGeneratePassword => 'Make one for me';

  @override
  String get actionCopy => 'Copy';

  @override
  String get passwordCopied => 'Password copied. Give it to them in person.';

  @override
  String get a11yShowPassword => 'Show password';

  @override
  String get a11yHidePassword => 'Hide password';

  @override
  String get resetPasswordBody =>
      'They will be signed out everywhere. Give them this temporary password; they choose their own the next time they sign in.';

  @override
  String switchOffTitle(String name) {
    return 'Switch off $name?';
  }

  @override
  String get switchOffBody =>
      'They are signed out at once and cannot sign in. Their entries stay in the books with their name. You can switch them back on at any time.';

  @override
  String personSwitchedOff(String name) {
    return '$name is switched off.';
  }

  @override
  String personSwitchedOn(String name) {
    return '$name can sign in again.';
  }

  @override
  String get stepTaxesQuestion => 'Any tax or charges on this?';

  @override
  String get hintTaxesStep =>
      'Suggested from the amount, the account and the category. Change a figure to what was actually taken, remove a line, or add one.';

  @override
  String get sectionTaxes => 'Taxes';

  @override
  String get sectionCharges => 'Charges';

  @override
  String get sectionPayee => 'Who is being paid';

  @override
  String get taxesNoneSuggested =>
      'Nothing suggested for this kind of entry. Add a tax if one was taken.';

  @override
  String get taxKeptBack => 'Kept back from the payee. We owe it to FBR.';

  @override
  String get taxTakenFromUs => 'Taken from us by the bank or the client.';

  @override
  String taxRateLine(String rate, String status) {
    return '$rate% at the $status rate, on';
  }

  @override
  String get taxStatusFiler => 'filer';

  @override
  String get taxStatusNonFiler => 'non-filer';

  @override
  String get taxChanged => 'Changed from the suggested figure';

  @override
  String get fieldTaxAmount => 'Amount taken';

  @override
  String get addTaxTitle => 'Add a tax';

  @override
  String get addTaxNone =>
      'No other tax is in force for this date and this kind of entry.';

  @override
  String get fieldPayee => 'Payee';

  @override
  String get hintPayee =>
      'The tax kept back is reported under their NTN or CNIC, and their filer status sets the rate.';

  @override
  String get payeeNoTaxId =>
      'No NTN or CNIC on record for them. Tax cannot be kept back until one is added.';

  @override
  String get payeeNoTaxIdShort => 'no NTN or CNIC';

  @override
  String get payeeNoneYet =>
      'No payees added yet. Tax kept back needs one. Payees are added on the Vendors screen.';

  @override
  String get chargeTypeBank => 'Bank charge';

  @override
  String get chargeTypeForex => 'Forex fee';

  @override
  String get chargeTypeCard => 'Card fee';

  @override
  String get chargeTypePlatform => 'Platform fee';

  @override
  String get chargeTypeOther => 'Other charge';

  @override
  String get fieldChargeType => 'Charge';

  @override
  String get fieldChargeAmount => 'Amount';

  @override
  String get fieldChargeAccount => 'Ledger account';

  @override
  String get hintChargeAccount =>
      'Leave it on the usual account unless the accountant says otherwise.';

  @override
  String get totalLeaves => 'Leaves the account';

  @override
  String get totalArrives => 'Reaches the account';

  @override
  String hintRateFor(String currency) {
    return 'Rupees for 1 $currency. The rupees below must equal the amount times the rate, within one rupee.';
  }

  @override
  String get fieldPkrPaid => 'Rupees actually paid';

  @override
  String chargeGoesTo(String account) {
    return 'Goes to $account';
  }

  @override
  String get actionUseAnotherAccount => 'Use another account';

  @override
  String actionBackToUsualAccount(String account) {
    return 'Back to $account';
  }

  @override
  String get actionMoveMoney => 'Move money';

  @override
  String get moveMoneyTitle => 'Move money between accounts';

  @override
  String get moveMoneyHint =>
      'For money that stays in the company: cash drawn from the bank, petty cash topped up. Both sides are recorded together.';

  @override
  String get fieldMoveFrom => 'From';

  @override
  String get fieldMoveTo => 'To';

  @override
  String get moveMoneySameAccount => 'Choose two different accounts.';

  @override
  String get fieldTransferFee => 'Bank fee, if any';

  @override
  String get hintTransferFee =>
      'Only if the bank took a fee for the transfer. It is recorded as a bank charge.';

  @override
  String get fieldDescriptionOptional => 'Note (optional)';

  @override
  String moveMoneyDone(String numbers) {
    return 'Moved. Recorded as $numbers.';
  }

  @override
  String get actionPaySomeoneBack => 'Pay someone back';

  @override
  String get actionPayBack => 'Pay back';

  @override
  String get payBackTitle => 'Pay someone back';

  @override
  String get payBackHint =>
      'For someone who paid company costs with their own money. Tick the costs being paid back now.';

  @override
  String get fieldPayBackPerson => 'Who';

  @override
  String get payBackCostsTitle => 'Costs they paid';

  @override
  String get payBackNothingOwed => 'Nothing is owed to them.';

  @override
  String get fieldPayingBack => 'Paying back';

  @override
  String get hintPayingBack => 'The full amount, unless only part is paid now.';

  @override
  String get fieldPaidFrom => 'Paid from';

  @override
  String payBackDone(String number, String owed) {
    return 'Paid back. Recorded as $number. Still owed to them: $owed.';
  }

  @override
  String get actionOpeningBalances => 'Opening balances';

  @override
  String pettyLowLead(String account) {
    return '$account holds';
  }

  @override
  String get pettyLowFloat => ', below its float of';

  @override
  String get pettyLowSuggest => '. Top up by';

  @override
  String get actionTopUp => 'Top up';

  @override
  String get owedTitle => 'Owed to people';

  @override
  String get owedHint =>
      'Company costs people paid with their own money, not yet paid back.';

  @override
  String get owedNobody => 'Nobody is owed money.';

  @override
  String get reverseTitle => 'Reverse this entry';

  @override
  String get fieldReverseReason => 'Why';

  @override
  String get hintReverseReason =>
      'Say what was wrong, such as \"Entered twice\" or \"Wrong account\". It shows in the ledger beside the reversal.';

  @override
  String reverseDone(String number) {
    return 'Reversed. The correction is $number.';
  }

  @override
  String get openingTitle => 'Opening balances';

  @override
  String openingSubtitle(String date) {
    return 'What the company had and owed at the end of $date, the day before the books started.';
  }

  @override
  String get openingOwnerOnly => 'Only the owner posts the opening balances.';

  @override
  String openingPosted(String number, String date) {
    return 'Posted as $number on $date. It cannot be changed. A wrong balance is corrected with a journal entry.';
  }

  @override
  String openingMerged(String number) {
    return 'Posted as $number, and reversed when history was merged.';
  }

  @override
  String get openingHowTo =>
      'Type each balance as a plain figure, the way the bank statement or the record shows it. Leave an account empty if it held nothing. If an account was overdrawn, ask the accountant before posting.';

  @override
  String get openingAssets => 'What the company had';

  @override
  String get openingAssetsHint =>
      'Bank and cash, money clients owed, advance tax paid.';

  @override
  String get openingLiabilities => 'What the company owed';

  @override
  String get openingLiabilitiesHint =>
      'Loans, unpaid bills, tax kept back and not yet paid to FBR, money owed to people.';

  @override
  String get openingEquity => 'Owners\' money';

  @override
  String get openingEquityHint =>
      'Share capital. The rest is worked out for you.';

  @override
  String get fieldBalance => 'Balance';

  @override
  String get actionReviewOpening => 'Review and post';

  @override
  String get openingReviewTitle => 'Post these opening balances?';

  @override
  String get openingReviewNote =>
      'Whatever is left over goes to 3400 Opening balance equity, worked out by the server. Once posted, this cannot be changed.';

  @override
  String get actionPostOpening => 'Post opening balances';

  @override
  String openingDone(String number) {
    return 'Opening balances posted as $number.';
  }

  @override
  String get navVendors => 'Vendors';

  @override
  String get navCheques => 'Cheques';

  @override
  String get vendorsTitle => 'Vendors';

  @override
  String get vendorsIntro =>
      'Everyone the company pays who is not staff: contractors, suppliers, platforms.';

  @override
  String get actionAddVendor => 'Add vendor';

  @override
  String get vendorsFilerHelp =>
      'Tax kept back from a vendor needs their NTN or CNIC, and the rate depends on whether they are a filer, that is on FBR\'s Active Taxpayers List. A non-filer, or one never checked, gets the higher rate. Check the list every month or so and note the date.';

  @override
  String get hintVendorSearch => 'Search by name, NTN or CNIC';

  @override
  String get vendorsEmpty => 'No vendors yet.';

  @override
  String vendorAdded(String name) {
    return '$name is added.';
  }

  @override
  String get vendorSaved => 'Saved.';

  @override
  String get vendorKindCompany => 'Company';

  @override
  String get vendorKindAop => 'Partnership (AOP)';

  @override
  String get vendorKindIndividual => 'Individual';

  @override
  String get vendorKindForeign => 'Outside Pakistan';

  @override
  String get fieldNtn => 'NTN';

  @override
  String get fieldCnic => 'CNIC';

  @override
  String get filerYes => 'Filer';

  @override
  String get filerNo => 'Non-filer';

  @override
  String get filerUnknown => 'Not checked';

  @override
  String filerCheckAgain(String date) {
    return 'Check again, last checked $date';
  }

  @override
  String get vendorNoTaxId => 'No NTN or CNIC';

  @override
  String get vendorSwitchedOff => 'Switched off';

  @override
  String get addVendorTitle => 'Add a vendor';

  @override
  String get editVendorTitle => 'Change vendor';

  @override
  String get fieldVendorName => 'Name';

  @override
  String get fieldVendorKind => 'Type';

  @override
  String get fieldCountry => 'Country';

  @override
  String get hintForeignVendor =>
      'No Pakistani tax is kept back from a vendor outside Pakistan, so no NTN is needed.';

  @override
  String get hintNoTaxId =>
      'Without an NTN or CNIC, tax cannot be kept back from them.';

  @override
  String get fieldFilerStatus => 'Filer status';

  @override
  String get hintFilerUnknown =>
      'Until it is checked, the higher non-filer rate is used.';

  @override
  String get hintFilerChecked =>
      'The date you checked FBR\'s Active Taxpayers List.';

  @override
  String get fieldCheckedOn => 'Checked on';

  @override
  String get fieldEmailOptional => 'Email (optional)';

  @override
  String get fieldPhoneOptional => 'Phone (optional)';

  @override
  String get fieldNotesOptional => 'Notes (optional)';

  @override
  String get chequesTitle => 'Cheques';

  @override
  String get chequesIntro =>
      'Every cheque written, and where it stands. The payment itself is recorded as a normal entry and linked here.';

  @override
  String get actionIssueCheque => 'Record a cheque';

  @override
  String get chequeStatusesHelp =>
      'Issued: written and handed over. Presented: the payee has deposited it. Cleared: the money has left the bank. Bounced: the bank refused it. Cancelled: never used.';

  @override
  String get chequeFilterAll => 'All';

  @override
  String get chequeIssued => 'Issued';

  @override
  String get chequePresented => 'Presented';

  @override
  String get chequeCleared => 'Cleared';

  @override
  String get chequeBounced => 'Bounced';

  @override
  String get chequeCancelled => 'Cancelled';

  @override
  String get chequesOutstanding => 'Written but not yet cleared';

  @override
  String get chequesEmpty => 'No cheques here.';

  @override
  String chequeNumberShort(String number) {
    return 'No. $number';
  }

  @override
  String chequeClearedOn(String date) {
    return 'Cleared on $date';
  }

  @override
  String get chequeNotLinked => 'Not linked to a payment yet';

  @override
  String chequeLinkedTo(String number) {
    return 'Payment $number';
  }

  @override
  String get actionMarkPresented => 'Mark presented';

  @override
  String get actionMarkCleared => 'Mark cleared';

  @override
  String get actionMarkBounced => 'Mark bounced';

  @override
  String get actionCancelCheque => 'Cancel cheque';

  @override
  String get actionLinkPayment => 'Link to payment';

  @override
  String get chequeBounceTitle => 'Mark this cheque as bounced?';

  @override
  String get chequeBounceBody =>
      'The bank refused it, so the payee was not paid. If the payment was already recorded, reverse it from Transactions.';

  @override
  String get chequeCancelTitle => 'Cancel this cheque?';

  @override
  String get chequeCancelBody =>
      'For a cheque that was never used. It stays in the register, marked cancelled.';

  @override
  String chequeNowStatus(String number, String status) {
    return 'Cheque $number is now $status.';
  }

  @override
  String chequeLinked(String number) {
    return 'Linked to $number.';
  }

  @override
  String get chequeClearedTitle => 'When did it clear?';

  @override
  String get chequeClearedBody =>
      'The date the money left the bank, from the bank statement.';

  @override
  String get fieldClearedOn => 'Cleared on';

  @override
  String get linkPaymentTitle => 'Link to a payment';

  @override
  String get linkPaymentHint =>
      'Payments recorded from this cheque\'s bank account, newest first.';

  @override
  String get hintPaymentSearch => 'Search, then press Enter';

  @override
  String get linkPaymentNone => 'No payments found from this account.';

  @override
  String get issueChequeTitle => 'Record a cheque';

  @override
  String get issueChequeHint =>
      'Record the cheque here, and the payment itself as a normal entry. Then link the two.';

  @override
  String get fieldChequeAccount => 'Bank account';

  @override
  String get fieldChequeNumber => 'Cheque number';

  @override
  String get fieldPayableTo => 'Payable to';

  @override
  String get fieldChequeDate => 'Date on the cheque';

  @override
  String chequeIssuedDone(String number) {
    return 'Cheque $number recorded.';
  }
}
