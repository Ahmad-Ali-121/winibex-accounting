import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Winibex Accounting'**
  String get appName;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get navApprovals;

  /// No description provided for @navClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// No description provided for @navQuotations.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get navQuotations;

  /// No description provided for @navPayroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get navPayroll;

  /// No description provided for @navRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring costs'**
  String get navRecurring;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get actionSaveDraft;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get actionSubmit;

  /// No description provided for @actionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve and post'**
  String get actionApprove;

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actionReject;

  /// No description provided for @actionReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse entry'**
  String get actionReverse;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get actionExportCsv;

  /// No description provided for @actionCopyRow.
  ///
  /// In en, this message translates to:
  /// **'Copy row'**
  String get actionCopyRow;

  /// No description provided for @actionDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get actionDownloadPdf;

  /// No description provided for @actionAttachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Attach receipt'**
  String get actionAttachReceipt;

  /// No description provided for @actionTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get actionTakePhoto;

  /// No description provided for @actionViewJournal.
  ///
  /// In en, this message translates to:
  /// **'View journal entry'**
  String get actionViewJournal;

  /// No description provided for @actionAddTaxLine.
  ///
  /// In en, this message translates to:
  /// **'Add tax line'**
  String get actionAddTaxLine;

  /// No description provided for @actionAddCharge.
  ///
  /// In en, this message translates to:
  /// **'Add charge'**
  String get actionAddCharge;

  /// No description provided for @actionNewTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get actionNewTransaction;

  /// No description provided for @actionNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'New invoice'**
  String get actionNewInvoice;

  /// No description provided for @actionNewQuotation.
  ///
  /// In en, this message translates to:
  /// **'New quotation'**
  String get actionNewQuotation;

  /// No description provided for @actionConvertToInvoice.
  ///
  /// In en, this message translates to:
  /// **'Convert to invoice'**
  String get actionConvertToInvoice;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get actionSignIn;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @actionProceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'Proceed anyway'**
  String get actionProceedAnyway;

  /// No description provided for @actionReviewMatch.
  ///
  /// In en, this message translates to:
  /// **'Review matching entry'**
  String get actionReviewMatch;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get fieldDirection;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get fieldPaidBy;

  /// No description provided for @fieldReceivedInto.
  ///
  /// In en, this message translates to:
  /// **'Received into'**
  String get fieldReceivedInto;

  /// No description provided for @fieldExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get fieldExchangeRate;

  /// No description provided for @fieldPkrAmount.
  ///
  /// In en, this message translates to:
  /// **'PKR amount'**
  String get fieldPkrAmount;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get fieldAccount;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get fieldClient;

  /// No description provided for @fieldProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get fieldProject;

  /// No description provided for @fieldRebillable.
  ///
  /// In en, this message translates to:
  /// **'Rebillable to client'**
  String get fieldRebillable;

  /// No description provided for @fieldReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get fieldReference;

  /// No description provided for @fieldReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get fieldReceipt;

  /// No description provided for @fieldReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get fieldReason;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @directionMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get directionMoneyIn;

  /// No description provided for @directionMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get directionMoneyOut;

  /// No description provided for @directionTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get directionTransfer;

  /// No description provided for @paidByCompany.
  ///
  /// In en, this message translates to:
  /// **'Company account'**
  String get paidByCompany;

  /// No description provided for @paidByPerson.
  ///
  /// In en, this message translates to:
  /// **'{name}, personally'**
  String paidByPerson(String name);

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get statusPending;

  /// No description provided for @statusPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get statusPosted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusReversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get statusReversed;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get statusPartial;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statusSent;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusConverted.
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get statusConverted;

  /// No description provided for @clientStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get clientStatusActive;

  /// No description provided for @clientStatusOnCall.
  ///
  /// In en, this message translates to:
  /// **'On call'**
  String get clientStatusOnCall;

  /// No description provided for @clientStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get clientStatusPaused;

  /// No description provided for @clientStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get clientStatusClosed;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colNumber.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get colNumber;

  /// No description provided for @colDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get colDescription;

  /// No description provided for @colAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get colAccount;

  /// No description provided for @colCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get colCategory;

  /// No description provided for @colDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get colDebit;

  /// No description provided for @colCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get colCredit;

  /// No description provided for @colBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get colBalance;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get colStatus;

  /// No description provided for @colClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get colClient;

  /// No description provided for @colEnteredBy.
  ///
  /// In en, this message translates to:
  /// **'Entered by'**
  String get colEnteredBy;

  /// No description provided for @stepDirection.
  ///
  /// In en, this message translates to:
  /// **'What kind of entry is this?'**
  String get stepDirection;

  /// No description provided for @stepCurrency.
  ///
  /// In en, this message translates to:
  /// **'Which currency?'**
  String get stepCurrency;

  /// No description provided for @stepAmount.
  ///
  /// In en, this message translates to:
  /// **'How much?'**
  String get stepAmount;

  /// No description provided for @stepPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get stepPaidBy;

  /// No description provided for @stepReceivedInto.
  ///
  /// In en, this message translates to:
  /// **'Where did the money land?'**
  String get stepReceivedInto;

  /// No description provided for @stepConversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion to PKR'**
  String get stepConversion;

  /// No description provided for @stepTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes and charges'**
  String get stepTaxes;

  /// No description provided for @stepDetails.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get stepDetails;

  /// No description provided for @stepReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get stepReceipt;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review before submitting'**
  String get stepReview;

  /// No description provided for @hintLastRate.
  ///
  /// In en, this message translates to:
  /// **'Last rate used for {currency}: {rate}'**
  String hintLastRate(String currency, String rate);

  /// No description provided for @hintEnterRateOrPkr.
  ///
  /// In en, this message translates to:
  /// **'Enter the rate or the PKR amount. The other fills in.'**
  String get hintEnterRateOrPkr;

  /// No description provided for @hintPersonPayable.
  ///
  /// In en, this message translates to:
  /// **'The company will owe {name} this amount until it is reimbursed.'**
  String hintPersonPayable(String name);

  /// No description provided for @hintReceiptRequired.
  ///
  /// In en, this message translates to:
  /// **'A receipt is required for this entry.'**
  String get hintReceiptRequired;

  /// No description provided for @hintReceiptOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. Entries without a receipt are flagged for review.'**
  String get hintReceiptOptional;

  /// No description provided for @totalPkrOut.
  ///
  /// In en, this message translates to:
  /// **'Total PKR out'**
  String get totalPkrOut;

  /// No description provided for @totalPkrIn.
  ///
  /// In en, this message translates to:
  /// **'Total PKR received'**
  String get totalPkrIn;

  /// No description provided for @rowsAndTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} entries, {total}'**
  String rowsAndTotal(int count, String total);

  /// No description provided for @confirmPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted. {account} is now {balance}.'**
  String confirmPosted(String account, String balance);

  /// No description provided for @confirmSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted. Waiting for {approver} to approve.'**
  String confirmSubmitted(String approver);

  /// No description provided for @confirmDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get confirmDraftSaved;

  /// No description provided for @confirmReversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed. Both entries stay in the ledger, linked.'**
  String get confirmReversed;

  /// No description provided for @confirmRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected. {name} can see the reason.'**
  String confirmRejected(String name);

  /// No description provided for @errUnbalanced.
  ///
  /// In en, this message translates to:
  /// **'Debits and credits do not match.'**
  String get errUnbalanced;

  /// No description provided for @errMissingCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category before submitting.'**
  String get errMissingCategory;

  /// No description provided for @errMissingAccount.
  ///
  /// In en, this message translates to:
  /// **'Pick an account before submitting.'**
  String get errMissingAccount;

  /// No description provided for @errAmountNotPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero. Direction sets whether money comes in or goes out.'**
  String get errAmountNotPositive;

  /// No description provided for @errFutureDate.
  ///
  /// In en, this message translates to:
  /// **'The date cannot be in the future.'**
  String get errFutureDate;

  /// No description provided for @errBeforeOpening.
  ///
  /// In en, this message translates to:
  /// **'This date is before the account\'s opening date.'**
  String get errBeforeOpening;

  /// No description provided for @errNeedRateOrPkr.
  ///
  /// In en, this message translates to:
  /// **'Enter the exchange rate or the PKR amount.'**
  String get errNeedRateOrPkr;

  /// No description provided for @errRateNotPositive.
  ///
  /// In en, this message translates to:
  /// **'The exchange rate must be above zero.'**
  String get errRateNotPositive;

  /// No description provided for @errTaxExceedsBase.
  ///
  /// In en, this message translates to:
  /// **'A tax line cannot be larger than the amount it is calculated on.'**
  String get errTaxExceedsBase;

  /// No description provided for @errTaxNotInEffect.
  ///
  /// In en, this message translates to:
  /// **'This tax was not in effect on the transaction date.'**
  String get errTaxNotInEffect;

  /// No description provided for @errCashNegative.
  ///
  /// In en, this message translates to:
  /// **'{account} only has {balance}. Cash cannot go below zero.'**
  String errCashNegative(String account, String balance);

  /// No description provided for @errSameAccountTransfer.
  ///
  /// In en, this message translates to:
  /// **'Choose two different accounts for a transfer.'**
  String get errSameAccountTransfer;

  /// No description provided for @errOverpayment.
  ///
  /// In en, this message translates to:
  /// **'This is more than the invoice\'s remaining {remaining}. Record the extra as a customer advance.'**
  String errOverpayment(String remaining);

  /// No description provided for @errReceiptRequired.
  ///
  /// In en, this message translates to:
  /// **'Attach a receipt. It is required for this kind of entry.'**
  String get errReceiptRequired;

  /// No description provided for @errPostedImmutable.
  ///
  /// In en, this message translates to:
  /// **'Posted entries cannot be edited. Reverse it and enter a corrected one.'**
  String get errPostedImmutable;

  /// No description provided for @errDuplicateReference.
  ///
  /// In en, this message translates to:
  /// **'This reference is already used on {account}.'**
  String errDuplicateReference(String account);

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Your entry is kept. Try again when connected.'**
  String get errNetwork;

  /// No description provided for @errSignIn.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errSignIn;

  /// No description provided for @warnPossibleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'An entry for the same amount on {account} was recorded on {date}.'**
  String warnPossibleDuplicate(String account, String date);

  /// No description provided for @warnUnusualAmount.
  ///
  /// In en, this message translates to:
  /// **'This is more than three times the usual amount for {category}.'**
  String warnUnusualAmount(String category);

  /// No description provided for @warnRateDeviation.
  ///
  /// In en, this message translates to:
  /// **'This rate is {percent}% away from the last rate used for {currency}.'**
  String warnRateDeviation(String percent, String currency);

  /// No description provided for @warnBackdated.
  ///
  /// In en, this message translates to:
  /// **'This date is more than 90 days ago.'**
  String get warnBackdated;

  /// No description provided for @warnClosedClient.
  ///
  /// In en, this message translates to:
  /// **'{client} is marked closed.'**
  String warnClosedClient(String client);

  /// No description provided for @warnTaxOverride.
  ///
  /// In en, this message translates to:
  /// **'This tax rate differs from the configured rate.'**
  String get warnTaxOverride;

  /// No description provided for @warnLargeCash.
  ///
  /// In en, this message translates to:
  /// **'Large cash expense. Double check before submitting.'**
  String get warnLargeCash;

  /// No description provided for @flagNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'No receipt'**
  String get flagNoReceipt;

  /// No description provided for @flagThinDescription.
  ///
  /// In en, this message translates to:
  /// **'Description too short'**
  String get flagThinDescription;

  /// No description provided for @flagSelfApproved.
  ///
  /// In en, this message translates to:
  /// **'Created and approved by the same person'**
  String get flagSelfApproved;

  /// No description provided for @flagPassThroughAging.
  ///
  /// In en, this message translates to:
  /// **'Money held in a pass-through account over 14 days'**
  String get flagPassThroughAging;

  /// No description provided for @flagUninvoicedRebillable.
  ///
  /// In en, this message translates to:
  /// **'Rebillable spend not invoiced after 30 days'**
  String get flagUninvoicedRebillable;

  /// No description provided for @emptyTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Record the first money in or money out to start the ledger.'**
  String get emptyTransactions;

  /// No description provided for @emptyApprovals.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for approval.'**
  String get emptyApprovals;

  /// No description provided for @emptyClients.
  ///
  /// In en, this message translates to:
  /// **'No clients yet. Add one to link income and spending to it.'**
  String get emptyClients;

  /// No description provided for @emptyInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet. Create one, or convert an accepted quotation.'**
  String get emptyInvoices;

  /// No description provided for @emptyFlags.
  ///
  /// In en, this message translates to:
  /// **'No flagged entries. Everything has been reviewed.'**
  String get emptyFlags;

  /// No description provided for @emptySearch.
  ///
  /// In en, this message translates to:
  /// **'No entries match \"{query}\".'**
  String emptySearch(String query);

  /// No description provided for @termDebit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get termDebit;

  /// No description provided for @termDebitTip.
  ///
  /// In en, this message translates to:
  /// **'The left side of a journal entry. Increases assets and expenses, decreases liabilities and income.'**
  String get termDebitTip;

  /// No description provided for @termCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get termCredit;

  /// No description provided for @termCreditTip.
  ///
  /// In en, this message translates to:
  /// **'The right side of a journal entry. Increases liabilities and income, decreases assets and expenses.'**
  String get termCreditTip;

  /// No description provided for @termJournalEntry.
  ///
  /// In en, this message translates to:
  /// **'Journal entry'**
  String get termJournalEntry;

  /// No description provided for @termJournalEntryTip.
  ///
  /// In en, this message translates to:
  /// **'The debit and credit lines this transaction records in the books. Debits always equal credits.'**
  String get termJournalEntryTip;

  /// No description provided for @termPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get termPosted;

  /// No description provided for @termPostedTip.
  ///
  /// In en, this message translates to:
  /// **'Recorded in the books. A posted entry cannot be edited, only reversed.'**
  String get termPostedTip;

  /// No description provided for @termDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get termDraft;

  /// No description provided for @termDraftTip.
  ///
  /// In en, this message translates to:
  /// **'Saved but not submitted. Does not affect any balance.'**
  String get termDraftTip;

  /// No description provided for @termReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get termReversal;

  /// No description provided for @termReversalTip.
  ///
  /// In en, this message translates to:
  /// **'An equal and opposite entry that cancels a posted one. Both stay visible so the history is complete.'**
  String get termReversalTip;

  /// No description provided for @termAccountsReceivable.
  ///
  /// In en, this message translates to:
  /// **'Accounts receivable'**
  String get termAccountsReceivable;

  /// No description provided for @termAccountsReceivableTip.
  ///
  /// In en, this message translates to:
  /// **'Money clients owe Winibex for invoices not yet paid.'**
  String get termAccountsReceivableTip;

  /// No description provided for @termAccountsPayable.
  ///
  /// In en, this message translates to:
  /// **'Accounts payable'**
  String get termAccountsPayable;

  /// No description provided for @termAccountsPayableTip.
  ///
  /// In en, this message translates to:
  /// **'Money Winibex owes to suppliers, contractors or people who paid on its behalf.'**
  String get termAccountsPayableTip;

  /// No description provided for @termRebillable.
  ///
  /// In en, this message translates to:
  /// **'Rebillable'**
  String get termRebillable;

  /// No description provided for @termRebillableTip.
  ///
  /// In en, this message translates to:
  /// **'Spent on a client\'s behalf and charged back to them. Appears on their next invoice instead of reducing profit.'**
  String get termRebillableTip;

  /// No description provided for @termAbsorbed.
  ///
  /// In en, this message translates to:
  /// **'Absorbed'**
  String get termAbsorbed;

  /// No description provided for @termAbsorbedTip.
  ///
  /// In en, this message translates to:
  /// **'Spent on a client\'s behalf and not charged back. Comes out of the profit on that client.'**
  String get termAbsorbedTip;

  /// No description provided for @termPassThrough.
  ///
  /// In en, this message translates to:
  /// **'Pass-through account'**
  String get termPassThrough;

  /// No description provided for @termPassThroughTip.
  ///
  /// In en, this message translates to:
  /// **'A personal account where company money lands before being transferred to Winibex. Only company money is tracked here.'**
  String get termPassThroughTip;

  /// No description provided for @termTrialBalance.
  ///
  /// In en, this message translates to:
  /// **'Trial balance'**
  String get termTrialBalance;

  /// No description provided for @termTrialBalanceTip.
  ///
  /// In en, this message translates to:
  /// **'Every account\'s debit or credit total. The two columns must be equal, which proves the books are internally consistent.'**
  String get termTrialBalanceTip;

  /// No description provided for @termChartOfAccounts.
  ///
  /// In en, this message translates to:
  /// **'Chart of accounts'**
  String get termChartOfAccounts;

  /// No description provided for @termChartOfAccountsTip.
  ///
  /// In en, this message translates to:
  /// **'The full list of accounts the books are organised into, from cash and bank to income and expenses.'**
  String get termChartOfAccountsTip;

  /// No description provided for @termExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get termExchangeRate;

  /// No description provided for @termExchangeRateTip.
  ///
  /// In en, this message translates to:
  /// **'PKR per one unit of the foreign currency. Use the rate the bank actually applied.'**
  String get termExchangeRateTip;

  /// No description provided for @termWithholdingTax.
  ///
  /// In en, this message translates to:
  /// **'Withholding tax'**
  String get termWithholdingTax;

  /// No description provided for @termWithholdingTaxTip.
  ///
  /// In en, this message translates to:
  /// **'Tax deducted at source by the payer and deposited with FBR on the recipient\'s behalf.'**
  String get termWithholdingTaxTip;

  /// No description provided for @termFinalTax154A.
  ///
  /// In en, this message translates to:
  /// **'Final tax, Section 154A'**
  String get termFinalTax154A;

  /// No description provided for @termFinalTax154ATip.
  ///
  /// In en, this message translates to:
  /// **'Tax the bank deducts on IT export receipts for PSEB-registered companies. It is the full tax on that income.'**
  String get termFinalTax154ATip;

  /// No description provided for @termRunway.
  ///
  /// In en, this message translates to:
  /// **'Runway'**
  String get termRunway;

  /// No description provided for @termRunwayTip.
  ///
  /// In en, this message translates to:
  /// **'How many months current cash covers fixed costs such as salaries and subscriptions, assuming no new income.'**
  String get termRunwayTip;

  /// No description provided for @termFiscalYear.
  ///
  /// In en, this message translates to:
  /// **'Fiscal year'**
  String get termFiscalYear;

  /// No description provided for @termFiscalYearTip.
  ///
  /// In en, this message translates to:
  /// **'1 July to 30 June, matching the Pakistan tax year.'**
  String get termFiscalYearTip;

  /// No description provided for @termPartnerShare.
  ///
  /// In en, this message translates to:
  /// **'Partner share'**
  String get termPartnerShare;

  /// No description provided for @termPartnerShareTip.
  ///
  /// In en, this message translates to:
  /// **'The portion of earnings kept by the owner of an Upwork or other platform account used for the work.'**
  String get termPartnerShareTip;

  /// Heading on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginHeading;

  /// Line under the login heading
  ///
  /// In en, this message translates to:
  /// **'Winibex internal books'**
  String get loginSubheading;

  /// Validation on the login form
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get loginEmailRequired;

  /// Validation on the login form
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get loginPasswordRequired;

  /// Button label while the request is in flight
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginSigningIn;

  /// Shown after the login rate limit
  ///
  /// In en, this message translates to:
  /// **'Too many sign-in attempts. Try again in a few minutes.'**
  String get errTooManyAttempts;

  /// Generic server failure
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errServer;

  /// Shown when the refresh token is rejected
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again.'**
  String get errSessionExpired;

  /// Shown when must_change_password is true
  ///
  /// In en, this message translates to:
  /// **'Set a new password before continuing.'**
  String get mustChangePassword;

  /// Retry a failed request
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get themeSystem;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Semantics label for the theme button
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get a11yToggleTheme;

  /// Semantics label on a term tooltip
  ///
  /// In en, this message translates to:
  /// **'What does {term} mean?'**
  String a11yWhatIsTerm(String term);

  /// Shown when a deactivated user tries to sign in
  ///
  /// In en, this message translates to:
  /// **'This account has been deactivated. Ask the owner.'**
  String get errAccountInactive;

  /// Navigation label for the accounts screen
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// Heading on the accounts screen
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// Line under the accounts heading
  ///
  /// In en, this message translates to:
  /// **'What the company holds today'**
  String get accountsSubtitle;

  /// No description provided for @accountsColumnAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountsColumnAccount;

  /// No description provided for @accountsColumnLedger.
  ///
  /// In en, this message translates to:
  /// **'LEDGER'**
  String get accountsColumnLedger;

  /// No description provided for @accountsColumnBalance.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get accountsColumnBalance;

  /// Label on the totals row of the accounts table
  ///
  /// In en, this message translates to:
  /// **'Total held'**
  String get accountsTotal;

  /// Tag on an account that is no longer in use
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get accountsInactive;

  /// Shown while history_merged is false
  ///
  /// In en, this message translates to:
  /// **'These balances start from 1 July 2026. Entries before that are excluded until history has been checked against the opening entry.'**
  String get accountsHistoryNotMerged;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypePettyCash.
  ///
  /// In en, this message translates to:
  /// **'Petty cash'**
  String get accountTypePettyCash;

  /// No description provided for @accountTypeCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheques'**
  String get accountTypeCheque;

  /// No description provided for @accountTypePassThrough.
  ///
  /// In en, this message translates to:
  /// **'Pass-through'**
  String get accountTypePassThrough;

  /// No description provided for @emptyAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get emptyAccountsTitle;

  /// No description provided for @emptyAccountsDetail.
  ///
  /// In en, this message translates to:
  /// **'Accounts are set up once, in Settings.'**
  String get emptyAccountsDetail;

  /// No description provided for @navNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get navNewEntry;

  /// Progress above the entry form
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepCounter(int current, int total);

  /// No description provided for @stepDirectionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Did money come in, or go out?'**
  String get stepDirectionQuestion;

  /// No description provided for @stepDateQuestion.
  ///
  /// In en, this message translates to:
  /// **'When did it move?'**
  String get stepDateQuestion;

  /// No description provided for @stepAmountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much?'**
  String get stepAmountQuestion;

  /// No description provided for @stepPaidFromQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which account did it leave?'**
  String get stepPaidFromQuestion;

  /// No description provided for @stepReceivedIntoQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which account did it arrive in?'**
  String get stepReceivedIntoQuestion;

  /// No description provided for @stepPaidByPerson.
  ///
  /// In en, this message translates to:
  /// **'Or someone paid it personally'**
  String get stepPaidByPerson;

  /// No description provided for @stepCategoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get stepCategoryQuestion;

  /// No description provided for @stepReviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Check this before saving'**
  String get stepReviewQuestion;

  /// No description provided for @currencyPkr.
  ///
  /// In en, this message translates to:
  /// **'Rupees'**
  String get currencyPkr;

  /// No description provided for @currencyForeign.
  ///
  /// In en, this message translates to:
  /// **'Foreign currency'**
  String get currencyForeign;

  /// No description provided for @fieldForeignAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount in the original currency'**
  String get fieldForeignAmount;

  /// No description provided for @fieldRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get fieldRate;

  /// No description provided for @fieldPkrReceived.
  ///
  /// In en, this message translates to:
  /// **'Rupees actually received'**
  String get fieldPkrReceived;

  /// No description provided for @fieldHoldsNow.
  ///
  /// In en, this message translates to:
  /// **'Holds'**
  String get fieldHoldsNow;

  /// No description provided for @hintDateIsPaymentDate.
  ///
  /// In en, this message translates to:
  /// **'The date the money moved, not the date you are entering it.'**
  String get hintDateIsPaymentDate;

  /// No description provided for @hintAmountIsGross.
  ///
  /// In en, this message translates to:
  /// **'Before any tax or bank charges. Those come next.'**
  String get hintAmountIsGross;

  /// No description provided for @hintRateOrPkr.
  ///
  /// In en, this message translates to:
  /// **'Enter the rate, or leave it and type the rupees the bank gave.'**
  String get hintRateOrPkr;

  /// No description provided for @hintDescription.
  ///
  /// In en, this message translates to:
  /// **'Enough that you will recognise it in a year.'**
  String get hintDescription;

  /// No description provided for @hintRebillable.
  ///
  /// In en, this message translates to:
  /// **'It will not count as a cost. It sits as money owed until you invoice it.'**
  String get hintRebillable;

  /// No description provided for @hintPaidByPerson.
  ///
  /// In en, this message translates to:
  /// **'No company account moves. The company owes them instead.'**
  String get hintPaidByPerson;

  /// No description provided for @previewNotReady.
  ///
  /// In en, this message translates to:
  /// **'Fill in the amount, the account and the category to see the journal entry.'**
  String get previewNotReady;

  /// No description provided for @journalColumnAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get journalColumnAccount;

  /// No description provided for @journalBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get journalBalanced;

  /// No description provided for @actionSaveAndPost.
  ///
  /// In en, this message translates to:
  /// **'Save and post'**
  String get actionSaveAndPost;

  /// No description provided for @actionSubmitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get actionSubmitForApproval;

  /// No description provided for @actionGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back and check'**
  String get actionGoBack;

  /// No description provided for @actionSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get actionSaveAnyway;

  /// No description provided for @warnTitle.
  ///
  /// In en, this message translates to:
  /// **'Check these first'**
  String get warnTitle;

  /// No description provided for @warnIntro.
  ///
  /// In en, this message translates to:
  /// **'Nothing is wrong with the entry. These are worth a look before it goes in.'**
  String get warnIntro;

  /// No description provided for @entrySavedPosted.
  ///
  /// In en, this message translates to:
  /// **'Saved and posted.'**
  String get entrySavedPosted;

  /// No description provided for @entrySavedPending.
  ///
  /// In en, this message translates to:
  /// **'Submitted. Someone else will approve it.'**
  String get entrySavedPending;

  /// No description provided for @hintSearchLedger.
  ///
  /// In en, this message translates to:
  /// **'Search descriptions, journal numbers and references'**
  String get hintSearchLedger;

  /// Under the ledger list
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String ledgerShowing(int shown, int total);

  /// No description provided for @ledgerFlagged.
  ///
  /// In en, this message translates to:
  /// **'This entry has something to review'**
  String get ledgerFlagged;

  /// No description provided for @ledgerReversedNotice.
  ///
  /// In en, this message translates to:
  /// **'This entry was reversed. Both it and its reversal stay in the book.'**
  String get ledgerReversedNotice;

  /// No description provided for @emptyLedgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyLedgerTitle;

  /// No description provided for @emptyLedgerDetail.
  ///
  /// In en, this message translates to:
  /// **'Entries appear here as soon as they are submitted.'**
  String get emptyLedgerDetail;

  /// No description provided for @emptyApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting'**
  String get emptyApprovalsTitle;

  /// No description provided for @emptyApprovalsDetail.
  ///
  /// In en, this message translates to:
  /// **'Entries submitted for approval show up here.'**
  String get emptyApprovalsDetail;

  /// No description provided for @approvalsYourOwn.
  ///
  /// In en, this message translates to:
  /// **'You entered this, so someone else has to approve it.'**
  String get approvalsYourOwn;

  /// Flag count on an approval card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing to review} other{{count} things to review}}'**
  String approvalsHasFlags(int count);

  /// No description provided for @rejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Send it back'**
  String get rejectTitle;

  /// No description provided for @hintRejectReason.
  ///
  /// In en, this message translates to:
  /// **'They will see this, so say what needs changing.'**
  String get hintRejectReason;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @actionNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get actionNextPage;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @stepReceiptQuestion.
  ///
  /// In en, this message translates to:
  /// **'Attach the receipt'**
  String get stepReceiptQuestion;

  /// No description provided for @hintReceipt.
  ///
  /// In en, this message translates to:
  /// **'A photo or a PDF. A payment over the limit in Settings cannot be posted without one, and you can also add it later.'**
  String get hintReceipt;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Under the name of an attached file
  ///
  /// In en, this message translates to:
  /// **'{kb} KB'**
  String receiptSize(int kb);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
