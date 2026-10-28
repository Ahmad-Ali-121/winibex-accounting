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
  /// **'Client will pay this back'**
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
  /// **'Could not reach the server. Check the connection and try again.'**
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
  /// **'Spent for a client 30 days ago and not yet billed to them'**
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
  /// **'Client will pay back'**
  String get termRebillable;

  /// No description provided for @termRebillableTip.
  ///
  /// In en, this message translates to:
  /// **'Spent for a client who will repay it. It is not counted as our cost. It waits as money the client owes until they pay.'**
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
  /// **'Before any tax or bank charges. Those are added after the category.'**
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
  /// **'Spent for a client who will repay it. It is not counted as our cost. It waits as money the client owes until they pay.'**
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

  /// No description provided for @navFlags.
  ///
  /// In en, this message translates to:
  /// **'To review'**
  String get navFlags;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardTitle;

  /// No description provided for @dashboardCashHeld.
  ///
  /// In en, this message translates to:
  /// **'Cash the company holds'**
  String get dashboardCashHeld;

  /// No description provided for @dashboardBeforeHistory.
  ///
  /// In en, this message translates to:
  /// **'From 1 July 2026 onward. Earlier entries are excluded until history is checked.'**
  String get dashboardBeforeHistory;

  /// No description provided for @dashboardInThisMonth.
  ///
  /// In en, this message translates to:
  /// **'In this month'**
  String get dashboardInThisMonth;

  /// No description provided for @dashboardOutThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Out this month'**
  String get dashboardOutThisMonth;

  /// No description provided for @dashboardWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry waiting for approval} other{{count} entries waiting for approval}}'**
  String dashboardWaitingApproval(int count);

  /// No description provided for @dashboardOpenFlags.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry to review} other{{count} entries to review}}'**
  String dashboardOpenFlags(int count);

  /// No description provided for @emptyFlagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get emptyFlagsTitle;

  /// No description provided for @emptyFlagsDetail.
  ///
  /// In en, this message translates to:
  /// **'Warnings people confirmed, and flags like a missing receipt, show up here.'**
  String get emptyFlagsDetail;

  /// No description provided for @flagsConfirmedBy.
  ///
  /// In en, this message translates to:
  /// **'confirmed by {name}'**
  String flagsConfirmedBy(String name);

  /// No description provided for @flagPossibleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get flagPossibleDuplicate;

  /// No description provided for @flagUnusualAmount.
  ///
  /// In en, this message translates to:
  /// **'Unusual amount'**
  String get flagUnusualAmount;

  /// No description provided for @flagBackdated.
  ///
  /// In en, this message translates to:
  /// **'Backdated'**
  String get flagBackdated;

  /// No description provided for @flagBankBelowZero.
  ///
  /// In en, this message translates to:
  /// **'Bank went below zero'**
  String get flagBankBelowZero;

  /// No description provided for @flagLargeCash.
  ///
  /// In en, this message translates to:
  /// **'Large cash payment'**
  String get flagLargeCash;

  /// No description provided for @flagRateDeviation.
  ///
  /// In en, this message translates to:
  /// **'Rate differs from last time'**
  String get flagRateDeviation;

  /// No description provided for @flagRepeatedDescription.
  ///
  /// In en, this message translates to:
  /// **'Same as a recent entry'**
  String get flagRepeatedDescription;

  /// No description provided for @changePasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Change your password'**
  String get changePasswordHeading;

  /// No description provided for @changePasswordForcedHeading.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get changePasswordForcedHeading;

  /// No description provided for @changePasswordSubheading.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one.'**
  String get changePasswordSubheading;

  /// No description provided for @changePasswordForcedSubheading.
  ///
  /// In en, this message translates to:
  /// **'This account still uses its first password. Choose a new one to continue.'**
  String get changePasswordForcedSubheading;

  /// No description provided for @changePasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters.'**
  String get changePasswordRule;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get fieldCurrentPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get fieldConfirmPassword;

  /// No description provided for @changePasswordCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get changePasswordCurrentRequired;

  /// No description provided for @changePasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters.'**
  String get changePasswordTooShort;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get changePasswordSaving;

  /// No description provided for @changePasswordDone.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get changePasswordDone;

  /// No description provided for @actionSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get actionSetPassword;

  /// No description provided for @actionViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get actionViewHistory;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit history'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has changed on this entry.'**
  String get historyEmpty;

  /// No description provided for @historyCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get historyCreated;

  /// No description provided for @historyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get historyUpdated;

  /// No description provided for @historyStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get historyStatusChanged;

  /// Button on a flag in To review. Owner and admins only
  ///
  /// In en, this message translates to:
  /// **'Mark reviewed'**
  String get actionMarkReviewed;

  /// No description provided for @markReviewedTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as reviewed'**
  String get markReviewedTitle;

  /// No description provided for @fieldReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Why it needs nothing more'**
  String get fieldReviewNote;

  /// No description provided for @hintReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Kept with the flag, so anyone can see why it was cleared.'**
  String get hintReviewNote;

  /// No description provided for @flagMarkedReviewed.
  ///
  /// In en, this message translates to:
  /// **'Marked as reviewed.'**
  String get flagMarkedReviewed;

  /// No description provided for @errNetworkEntryKept.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Your entry is kept. Try again when connected.'**
  String get errNetworkEntryKept;

  /// No description provided for @errUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The app could not read the server\'s answer. Try again. If it keeps happening, tell whoever looks after the app.'**
  String get errUnreadable;

  /// No description provided for @errNoteTooShort.
  ///
  /// In en, this message translates to:
  /// **'Write at least 3 characters.'**
  String get errNoteTooShort;

  /// No description provided for @actionPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get actionPickDate;

  /// No description provided for @hintDateFormat.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get hintDateFormat;

  /// No description provided for @hintCategorySearch.
  ///
  /// In en, this message translates to:
  /// **'Type a name or a code, such as welfare or 6110'**
  String get hintCategorySearch;

  /// No description provided for @peopleTitle.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleTitle;

  /// No description provided for @peopleOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can add people or change what they can do.'**
  String get peopleOwnerOnly;

  /// No description provided for @actionAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get actionAddPerson;

  /// No description provided for @actionResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get actionResetPassword;

  /// No description provided for @actionSwitchOff.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get actionSwitchOff;

  /// No description provided for @actionSwitchOn.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get actionSwitchOn;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @roleHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'What each role can do'**
  String get roleHelpTitle;

  /// No description provided for @roleAdminHelp.
  ///
  /// In en, this message translates to:
  /// **'Approves other people\'s entries, moves money between accounts, reverses entries, pays people back, adds vendors, issues cheques and clears flags. Cannot add people or change settings.'**
  String get roleAdminHelp;

  /// No description provided for @roleStaffHelp.
  ///
  /// In en, this message translates to:
  /// **'Records money in and money out and sends it for approval. Cannot approve anything, including their own entries.'**
  String get roleStaffHelp;

  /// No description provided for @officeLoginHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn this on for anyone who also knows the office login password. When the office login approves an entry this person made, the app keeps a quiet note, because it may be the same person approving their own work.'**
  String get officeLoginHelp;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get fieldRole;

  /// No description provided for @fieldApprovalLimit.
  ///
  /// In en, this message translates to:
  /// **'Approval limit (PKR)'**
  String get fieldApprovalLimit;

  /// No description provided for @hintApprovalLimit.
  ///
  /// In en, this message translates to:
  /// **'The biggest entry this person may approve. Leave empty for no limit. Bigger entries wait for the owner.'**
  String get hintApprovalLimit;

  /// No description provided for @fieldPostsOwn.
  ///
  /// In en, this message translates to:
  /// **'Can post their own entries'**
  String get fieldPostsOwn;

  /// No description provided for @hintPostsOwn.
  ///
  /// In en, this message translates to:
  /// **'On: their own entries go straight into the books. Off: someone else must approve them.'**
  String get hintPostsOwn;

  /// No description provided for @fieldSharesOfficeLogin.
  ///
  /// In en, this message translates to:
  /// **'Also uses the office login'**
  String get fieldSharesOfficeLogin;

  /// No description provided for @hintSharesOfficeLogin.
  ///
  /// In en, this message translates to:
  /// **'Turn on if this person knows the office login password. Their entries approved by the office login get a quiet note.'**
  String get hintSharesOfficeLogin;

  /// No description provided for @fieldTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get fieldTemporaryPassword;

  /// No description provided for @hintTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'At least 10 characters. Give it to them in person. They must choose their own password the first time they sign in.'**
  String get hintTemporaryPassword;

  /// No description provided for @peopleApprovesUpTo.
  ///
  /// In en, this message translates to:
  /// **'Approves up to'**
  String get peopleApprovesUpTo;

  /// No description provided for @peopleNoLimit.
  ///
  /// In en, this message translates to:
  /// **'Approves any amount'**
  String get peopleNoLimit;

  /// No description provided for @peoplePostsOwn.
  ///
  /// In en, this message translates to:
  /// **'Posts own entries'**
  String get peoplePostsOwn;

  /// No description provided for @peopleSharesLogin.
  ///
  /// In en, this message translates to:
  /// **'Also uses the office login'**
  String get peopleSharesLogin;

  /// No description provided for @peopleSwitchedOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off, cannot sign in'**
  String get peopleSwitchedOff;

  /// No description provided for @peopleMustChange.
  ///
  /// In en, this message translates to:
  /// **'Has not set their own password yet'**
  String get peopleMustChange;

  /// No description provided for @personAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} is added. Give them the temporary password in person.'**
  String personAdded(String name);

  /// No description provided for @personSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get personSaved;

  /// No description provided for @passwordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset. They are signed out everywhere and must set a new one.'**
  String get passwordReset;

  /// No description provided for @addPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a person'**
  String get addPersonTitle;

  /// No description provided for @editPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Change what this person can do'**
  String get editPersonTitle;

  /// No description provided for @errNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter their name.'**
  String get errNameRequired;

  /// No description provided for @errEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errEmailInvalid;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password for {name}'**
  String resetPasswordTitle(String name);

  /// No description provided for @peopleIntro.
  ///
  /// In en, this message translates to:
  /// **'Who can sign in, and what each person may do. Only the owner can change this.'**
  String get peopleIntro;

  /// No description provided for @roleOwnerShort.
  ///
  /// In en, this message translates to:
  /// **'Full access. Adds people and changes what they can do. The office login.'**
  String get roleOwnerShort;

  /// No description provided for @roleAdminShort.
  ///
  /// In en, this message translates to:
  /// **'Approves entries and moves money. Cannot add people.'**
  String get roleAdminShort;

  /// No description provided for @roleStaffShort.
  ///
  /// In en, this message translates to:
  /// **'Records money in and out. Someone else approves it.'**
  String get roleStaffShort;

  /// No description provided for @roleGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read this before giving someone a login.'**
  String get roleGuideSubtitle;

  /// No description provided for @roleGuideShowTable.
  ///
  /// In en, this message translates to:
  /// **'See exactly who can do what'**
  String get roleGuideShowTable;

  /// No description provided for @roleGuideTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get roleGuideTask;

  /// No description provided for @capRecord.
  ///
  /// In en, this message translates to:
  /// **'Record money in and money out'**
  String get capRecord;

  /// No description provided for @capPostOwn.
  ///
  /// In en, this message translates to:
  /// **'Own entries go straight into the books'**
  String get capPostOwn;

  /// No description provided for @capApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve other people\'s entries'**
  String get capApprove;

  /// No description provided for @capMoveMoney.
  ///
  /// In en, this message translates to:
  /// **'Move money between accounts'**
  String get capMoveMoney;

  /// No description provided for @capReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse a posted entry'**
  String get capReverse;

  /// No description provided for @capPayBack.
  ///
  /// In en, this message translates to:
  /// **'Pay people back'**
  String get capPayBack;

  /// No description provided for @capVendorsCheques.
  ///
  /// In en, this message translates to:
  /// **'Add vendors and issue cheques'**
  String get capVendorsCheques;

  /// No description provided for @capClearFlags.
  ///
  /// In en, this message translates to:
  /// **'Mark flags as reviewed'**
  String get capClearFlags;

  /// No description provided for @capPeople.
  ///
  /// In en, this message translates to:
  /// **'Add people and change what they can do'**
  String get capPeople;

  /// No description provided for @capLimited.
  ///
  /// In en, this message translates to:
  /// **'Depends on settings'**
  String get capLimited;

  /// No description provided for @capLimitedTip.
  ///
  /// In en, this message translates to:
  /// **'For an admin, this depends on their settings: an optional approval limit, and whether their own entries post straight away.'**
  String get capLimitedTip;

  /// No description provided for @a11yYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get a11yYes;

  /// No description provided for @a11yNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get a11yNo;

  /// No description provided for @peopleNobodyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Nobody is deleted. Someone who leaves is switched off, so every entry keeps the name of who made it.'**
  String get peopleNobodyDeleted;

  /// No description provided for @peopleFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full access'**
  String get peopleFullAccess;

  /// No description provided for @peopleOwnNeedApproval.
  ///
  /// In en, this message translates to:
  /// **'Own entries need approval'**
  String get peopleOwnNeedApproval;

  /// No description provided for @peopleNeedsApproval.
  ///
  /// In en, this message translates to:
  /// **'Every entry needs approval'**
  String get peopleNeedsApproval;

  /// No description provided for @peopleOwnerNote.
  ///
  /// In en, this message translates to:
  /// **'This is the office login. It always has full access and changes its own password.'**
  String get peopleOwnerNote;

  /// No description provided for @actionMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get actionMore;

  /// No description provided for @peopleSectionOffice.
  ///
  /// In en, this message translates to:
  /// **'Office login'**
  String get peopleSectionOffice;

  /// No description provided for @peopleSectionAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get peopleSectionAdmins;

  /// No description provided for @peopleSectionStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff members'**
  String get peopleSectionStaff;

  /// No description provided for @peopleSectionOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off'**
  String get peopleSectionOff;

  /// No description provided for @dialogSectionWho.
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get dialogSectionWho;

  /// No description provided for @dialogSectionApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get dialogSectionApprovals;

  /// No description provided for @dialogSectionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get dialogSectionSignIn;

  /// No description provided for @hintEmailIsLogin.
  ///
  /// In en, this message translates to:
  /// **'They sign in with this email.'**
  String get hintEmailIsLogin;

  /// No description provided for @hintEmailFixed.
  ///
  /// In en, this message translates to:
  /// **'The email they sign in with cannot be changed.'**
  String get hintEmailFixed;

  /// No description provided for @currencyCodePkr.
  ///
  /// In en, this message translates to:
  /// **'PKR'**
  String get currencyCodePkr;

  /// No description provided for @hintNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get hintNoLimit;

  /// No description provided for @actionGeneratePassword.
  ///
  /// In en, this message translates to:
  /// **'Make one for me'**
  String get actionGeneratePassword;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @passwordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied. Give it to them in person.'**
  String get passwordCopied;

  /// No description provided for @a11yShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get a11yShowPassword;

  /// No description provided for @a11yHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get a11yHidePassword;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'They will be signed out everywhere. Give them this temporary password; they choose their own the next time they sign in.'**
  String get resetPasswordBody;

  /// No description provided for @switchOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch off {name}?'**
  String switchOffTitle(String name);

  /// No description provided for @switchOffBody.
  ///
  /// In en, this message translates to:
  /// **'They are signed out at once and cannot sign in. Their entries stay in the books with their name. You can switch them back on at any time.'**
  String get switchOffBody;

  /// No description provided for @personSwitchedOff.
  ///
  /// In en, this message translates to:
  /// **'{name} is switched off.'**
  String personSwitchedOff(String name);

  /// No description provided for @personSwitchedOn.
  ///
  /// In en, this message translates to:
  /// **'{name} can sign in again.'**
  String personSwitchedOn(String name);

  /// No description provided for @stepTaxesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Any tax or charges on this?'**
  String get stepTaxesQuestion;

  /// No description provided for @hintTaxesStep.
  ///
  /// In en, this message translates to:
  /// **'Suggested from the amount, the account and the category. Change a figure to what was actually taken, remove a line, or add one.'**
  String get hintTaxesStep;

  /// No description provided for @sectionTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get sectionTaxes;

  /// No description provided for @sectionCharges.
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get sectionCharges;

  /// No description provided for @sectionPayee.
  ///
  /// In en, this message translates to:
  /// **'Who is being paid'**
  String get sectionPayee;

  /// No description provided for @taxesNoneSuggested.
  ///
  /// In en, this message translates to:
  /// **'Nothing suggested for this kind of entry. Add a tax if one was taken.'**
  String get taxesNoneSuggested;

  /// No description provided for @taxKeptBack.
  ///
  /// In en, this message translates to:
  /// **'Kept back from the payee. We owe it to FBR.'**
  String get taxKeptBack;

  /// No description provided for @taxTakenFromUs.
  ///
  /// In en, this message translates to:
  /// **'Taken from us by the bank or the client.'**
  String get taxTakenFromUs;

  /// No description provided for @taxRateLine.
  ///
  /// In en, this message translates to:
  /// **'{rate}% at the {status} rate, on'**
  String taxRateLine(String rate, String status);

  /// No description provided for @taxStatusFiler.
  ///
  /// In en, this message translates to:
  /// **'filer'**
  String get taxStatusFiler;

  /// No description provided for @taxStatusNonFiler.
  ///
  /// In en, this message translates to:
  /// **'non-filer'**
  String get taxStatusNonFiler;

  /// No description provided for @taxChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed from the suggested figure'**
  String get taxChanged;

  /// No description provided for @fieldTaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount taken'**
  String get fieldTaxAmount;

  /// No description provided for @addTaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a tax'**
  String get addTaxTitle;

  /// No description provided for @addTaxNone.
  ///
  /// In en, this message translates to:
  /// **'No other tax is in force for this date and this kind of entry.'**
  String get addTaxNone;

  /// No description provided for @fieldPayee.
  ///
  /// In en, this message translates to:
  /// **'Payee'**
  String get fieldPayee;

  /// No description provided for @hintPayee.
  ///
  /// In en, this message translates to:
  /// **'The tax kept back is reported under their NTN or CNIC, and their filer status sets the rate.'**
  String get hintPayee;

  /// No description provided for @payeeNoTaxId.
  ///
  /// In en, this message translates to:
  /// **'No NTN or CNIC on record for them. Tax cannot be kept back until one is added.'**
  String get payeeNoTaxId;

  /// No description provided for @payeeNoTaxIdShort.
  ///
  /// In en, this message translates to:
  /// **'no NTN or CNIC'**
  String get payeeNoTaxIdShort;

  /// No description provided for @payeeNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No payees added yet. Tax kept back needs one. Payees are added on the Vendors screen.'**
  String get payeeNoneYet;

  /// No description provided for @chargeTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank charge'**
  String get chargeTypeBank;

  /// No description provided for @chargeTypeForex.
  ///
  /// In en, this message translates to:
  /// **'Forex fee'**
  String get chargeTypeForex;

  /// No description provided for @chargeTypeCard.
  ///
  /// In en, this message translates to:
  /// **'Card fee'**
  String get chargeTypeCard;

  /// No description provided for @chargeTypePlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform fee'**
  String get chargeTypePlatform;

  /// No description provided for @chargeTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other charge'**
  String get chargeTypeOther;

  /// No description provided for @fieldChargeType.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get fieldChargeType;

  /// No description provided for @fieldChargeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldChargeAmount;

  /// No description provided for @fieldChargeAccount.
  ///
  /// In en, this message translates to:
  /// **'Ledger account'**
  String get fieldChargeAccount;

  /// No description provided for @hintChargeAccount.
  ///
  /// In en, this message translates to:
  /// **'Leave it on the usual account unless the accountant says otherwise.'**
  String get hintChargeAccount;

  /// No description provided for @totalLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves the account'**
  String get totalLeaves;

  /// No description provided for @totalArrives.
  ///
  /// In en, this message translates to:
  /// **'Reaches the account'**
  String get totalArrives;

  /// No description provided for @hintRateFor.
  ///
  /// In en, this message translates to:
  /// **'Rupees for 1 {currency}. The rupees below must equal the amount times the rate, within one rupee.'**
  String hintRateFor(String currency);

  /// No description provided for @fieldPkrPaid.
  ///
  /// In en, this message translates to:
  /// **'Rupees actually paid'**
  String get fieldPkrPaid;

  /// No description provided for @chargeGoesTo.
  ///
  /// In en, this message translates to:
  /// **'Goes to {account}'**
  String chargeGoesTo(String account);

  /// No description provided for @actionUseAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get actionUseAnotherAccount;

  /// No description provided for @actionBackToUsualAccount.
  ///
  /// In en, this message translates to:
  /// **'Back to {account}'**
  String actionBackToUsualAccount(String account);

  /// No description provided for @actionMoveMoney.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get actionMoveMoney;

  /// No description provided for @moveMoneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Move money between accounts'**
  String get moveMoneyTitle;

  /// No description provided for @moveMoneyHint.
  ///
  /// In en, this message translates to:
  /// **'For money that stays in the company: cash drawn from the bank, petty cash topped up. Both sides are recorded together.'**
  String get moveMoneyHint;

  /// No description provided for @fieldMoveFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fieldMoveFrom;

  /// No description provided for @fieldMoveTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get fieldMoveTo;

  /// No description provided for @moveMoneySameAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose two different accounts.'**
  String get moveMoneySameAccount;

  /// No description provided for @fieldTransferFee.
  ///
  /// In en, this message translates to:
  /// **'Bank fee, if any'**
  String get fieldTransferFee;

  /// No description provided for @hintTransferFee.
  ///
  /// In en, this message translates to:
  /// **'Only if the bank took a fee for the transfer. It is recorded as a bank charge.'**
  String get hintTransferFee;

  /// No description provided for @fieldDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fieldDescriptionOptional;

  /// No description provided for @moveMoneyDone.
  ///
  /// In en, this message translates to:
  /// **'Moved. Recorded as {numbers}.'**
  String moveMoneyDone(String numbers);

  /// No description provided for @actionPaySomeoneBack.
  ///
  /// In en, this message translates to:
  /// **'Pay someone back'**
  String get actionPaySomeoneBack;

  /// No description provided for @actionPayBack.
  ///
  /// In en, this message translates to:
  /// **'Pay back'**
  String get actionPayBack;

  /// No description provided for @payBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay someone back'**
  String get payBackTitle;

  /// No description provided for @payBackHint.
  ///
  /// In en, this message translates to:
  /// **'For someone who paid company costs with their own money. Tick the costs being paid back now.'**
  String get payBackHint;

  /// No description provided for @fieldPayBackPerson.
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get fieldPayBackPerson;

  /// No description provided for @payBackCostsTitle.
  ///
  /// In en, this message translates to:
  /// **'Costs they paid'**
  String get payBackCostsTitle;

  /// No description provided for @payBackNothingOwed.
  ///
  /// In en, this message translates to:
  /// **'Nothing is owed to them.'**
  String get payBackNothingOwed;

  /// No description provided for @fieldPayingBack.
  ///
  /// In en, this message translates to:
  /// **'Paying back'**
  String get fieldPayingBack;

  /// No description provided for @hintPayingBack.
  ///
  /// In en, this message translates to:
  /// **'The full amount, unless only part is paid now.'**
  String get hintPayingBack;

  /// No description provided for @fieldPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get fieldPaidFrom;

  /// No description provided for @payBackDone.
  ///
  /// In en, this message translates to:
  /// **'Paid back. Recorded as {number}. Still owed to them: {owed}.'**
  String payBackDone(String number, String owed);

  /// No description provided for @actionOpeningBalances.
  ///
  /// In en, this message translates to:
  /// **'Opening balances'**
  String get actionOpeningBalances;

  /// No description provided for @pettyLowLead.
  ///
  /// In en, this message translates to:
  /// **'{account} holds'**
  String pettyLowLead(String account);

  /// No description provided for @pettyLowFloat.
  ///
  /// In en, this message translates to:
  /// **', below its float of'**
  String get pettyLowFloat;

  /// No description provided for @pettyLowSuggest.
  ///
  /// In en, this message translates to:
  /// **'. Top up by'**
  String get pettyLowSuggest;

  /// No description provided for @actionTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get actionTopUp;

  /// No description provided for @owedTitle.
  ///
  /// In en, this message translates to:
  /// **'Owed to people'**
  String get owedTitle;

  /// No description provided for @owedHint.
  ///
  /// In en, this message translates to:
  /// **'Company costs people paid with their own money, not yet paid back.'**
  String get owedHint;

  /// No description provided for @owedNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody is owed money.'**
  String get owedNobody;

  /// No description provided for @reverseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse this entry'**
  String get reverseTitle;

  /// No description provided for @fieldReverseReason.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get fieldReverseReason;

  /// No description provided for @hintReverseReason.
  ///
  /// In en, this message translates to:
  /// **'Say what was wrong, such as \"Entered twice\" or \"Wrong account\". It shows in the ledger beside the reversal.'**
  String get hintReverseReason;

  /// No description provided for @reverseDone.
  ///
  /// In en, this message translates to:
  /// **'Reversed. The correction is {number}.'**
  String reverseDone(String number);

  /// No description provided for @openingTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening balances'**
  String get openingTitle;

  /// No description provided for @openingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What the company had and owed at the end of {date}, the day before the books started.'**
  String openingSubtitle(String date);

  /// No description provided for @openingOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner posts the opening balances.'**
  String get openingOwnerOnly;

  /// No description provided for @openingPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted as {number} on {date}. It cannot be changed. A wrong balance is corrected with a journal entry.'**
  String openingPosted(String number, String date);

  /// No description provided for @openingMerged.
  ///
  /// In en, this message translates to:
  /// **'Posted as {number}, and reversed when history was merged.'**
  String openingMerged(String number);

  /// No description provided for @openingHowTo.
  ///
  /// In en, this message translates to:
  /// **'Type each balance as a plain figure, the way the bank statement or the record shows it. Leave an account empty if it held nothing. If an account was overdrawn, ask the accountant before posting.'**
  String get openingHowTo;

  /// No description provided for @openingAssets.
  ///
  /// In en, this message translates to:
  /// **'What the company had'**
  String get openingAssets;

  /// No description provided for @openingAssetsHint.
  ///
  /// In en, this message translates to:
  /// **'Bank and cash, money clients owed, advance tax paid.'**
  String get openingAssetsHint;

  /// No description provided for @openingLiabilities.
  ///
  /// In en, this message translates to:
  /// **'What the company owed'**
  String get openingLiabilities;

  /// No description provided for @openingLiabilitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Loans, unpaid bills, tax kept back and not yet paid to FBR, money owed to people.'**
  String get openingLiabilitiesHint;

  /// No description provided for @openingEquity.
  ///
  /// In en, this message translates to:
  /// **'Owners\' money'**
  String get openingEquity;

  /// No description provided for @openingEquityHint.
  ///
  /// In en, this message translates to:
  /// **'Share capital. The rest is worked out for you.'**
  String get openingEquityHint;

  /// No description provided for @fieldBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get fieldBalance;

  /// No description provided for @actionReviewOpening.
  ///
  /// In en, this message translates to:
  /// **'Review and post'**
  String get actionReviewOpening;

  /// No description provided for @openingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Post these opening balances?'**
  String get openingReviewTitle;

  /// No description provided for @openingReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Whatever is left over goes to 3400 Opening balance equity, worked out by the server. Once posted, this cannot be changed.'**
  String get openingReviewNote;

  /// No description provided for @actionPostOpening.
  ///
  /// In en, this message translates to:
  /// **'Post opening balances'**
  String get actionPostOpening;

  /// No description provided for @openingDone.
  ///
  /// In en, this message translates to:
  /// **'Opening balances posted as {number}.'**
  String openingDone(String number);

  /// No description provided for @navVendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get navVendors;

  /// No description provided for @navCheques.
  ///
  /// In en, this message translates to:
  /// **'Cheques'**
  String get navCheques;

  /// No description provided for @vendorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendorsTitle;

  /// No description provided for @vendorsIntro.
  ///
  /// In en, this message translates to:
  /// **'Everyone the company pays who is not staff: contractors, suppliers, platforms.'**
  String get vendorsIntro;

  /// No description provided for @actionAddVendor.
  ///
  /// In en, this message translates to:
  /// **'Add vendor'**
  String get actionAddVendor;

  /// No description provided for @vendorsFilerHelp.
  ///
  /// In en, this message translates to:
  /// **'Tax kept back from a vendor needs their NTN or CNIC, and the rate depends on whether they are a filer, that is on FBR\'s Active Taxpayers List. A non-filer, or one never checked, gets the higher rate. Check the list every month or so and note the date.'**
  String get vendorsFilerHelp;

  /// No description provided for @hintVendorSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by name, NTN or CNIC'**
  String get hintVendorSearch;

  /// No description provided for @vendorsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vendors yet.'**
  String get vendorsEmpty;

  /// No description provided for @vendorAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} is added.'**
  String vendorAdded(String name);

  /// No description provided for @vendorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get vendorSaved;

  /// No description provided for @vendorKindCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get vendorKindCompany;

  /// No description provided for @vendorKindAop.
  ///
  /// In en, this message translates to:
  /// **'Partnership (AOP)'**
  String get vendorKindAop;

  /// No description provided for @vendorKindIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get vendorKindIndividual;

  /// No description provided for @vendorKindForeign.
  ///
  /// In en, this message translates to:
  /// **'Outside Pakistan'**
  String get vendorKindForeign;

  /// No description provided for @fieldNtn.
  ///
  /// In en, this message translates to:
  /// **'NTN'**
  String get fieldNtn;

  /// No description provided for @fieldCnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get fieldCnic;

  /// No description provided for @filerYes.
  ///
  /// In en, this message translates to:
  /// **'Filer'**
  String get filerYes;

  /// No description provided for @filerNo.
  ///
  /// In en, this message translates to:
  /// **'Non-filer'**
  String get filerNo;

  /// No description provided for @filerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not checked'**
  String get filerUnknown;

  /// No description provided for @filerCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again, last checked {date}'**
  String filerCheckAgain(String date);

  /// No description provided for @vendorNoTaxId.
  ///
  /// In en, this message translates to:
  /// **'No NTN or CNIC'**
  String get vendorNoTaxId;

  /// No description provided for @vendorSwitchedOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off'**
  String get vendorSwitchedOff;

  /// No description provided for @addVendorTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a vendor'**
  String get addVendorTitle;

  /// No description provided for @editVendorTitle.
  ///
  /// In en, this message translates to:
  /// **'Change vendor'**
  String get editVendorTitle;

  /// No description provided for @fieldVendorName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldVendorName;

  /// No description provided for @fieldVendorKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldVendorKind;

  /// No description provided for @fieldCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get fieldCountry;

  /// No description provided for @hintForeignVendor.
  ///
  /// In en, this message translates to:
  /// **'No Pakistani tax is kept back from a vendor outside Pakistan, so no NTN is needed.'**
  String get hintForeignVendor;

  /// No description provided for @hintNoTaxId.
  ///
  /// In en, this message translates to:
  /// **'Without an NTN or CNIC, tax cannot be kept back from them.'**
  String get hintNoTaxId;

  /// No description provided for @fieldFilerStatus.
  ///
  /// In en, this message translates to:
  /// **'Filer status'**
  String get fieldFilerStatus;

  /// No description provided for @hintFilerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Until it is checked, the higher non-filer rate is used.'**
  String get hintFilerUnknown;

  /// No description provided for @hintFilerChecked.
  ///
  /// In en, this message translates to:
  /// **'The date you checked FBR\'s Active Taxpayers List.'**
  String get hintFilerChecked;

  /// No description provided for @fieldCheckedOn.
  ///
  /// In en, this message translates to:
  /// **'Checked on'**
  String get fieldCheckedOn;

  /// No description provided for @fieldEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get fieldEmailOptional;

  /// No description provided for @fieldPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get fieldPhoneOptional;

  /// No description provided for @fieldNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get fieldNotesOptional;

  /// No description provided for @chequesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cheques'**
  String get chequesTitle;

  /// No description provided for @chequesIntro.
  ///
  /// In en, this message translates to:
  /// **'Every cheque written, and where it stands. The payment itself is recorded as a normal entry and linked here.'**
  String get chequesIntro;

  /// No description provided for @actionIssueCheque.
  ///
  /// In en, this message translates to:
  /// **'Record a cheque'**
  String get actionIssueCheque;

  /// No description provided for @chequeStatusesHelp.
  ///
  /// In en, this message translates to:
  /// **'Issued: written and handed over. Presented: the payee has deposited it. Cleared: the money has left the bank. Bounced: the bank refused it. Cancelled: never used.'**
  String get chequeStatusesHelp;

  /// No description provided for @chequeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chequeFilterAll;

  /// No description provided for @chequeIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get chequeIssued;

  /// No description provided for @chequePresented.
  ///
  /// In en, this message translates to:
  /// **'Presented'**
  String get chequePresented;

  /// No description provided for @chequeCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get chequeCleared;

  /// No description provided for @chequeBounced.
  ///
  /// In en, this message translates to:
  /// **'Bounced'**
  String get chequeBounced;

  /// No description provided for @chequeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get chequeCancelled;

  /// No description provided for @chequesOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Written but not yet cleared'**
  String get chequesOutstanding;

  /// No description provided for @chequesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cheques here.'**
  String get chequesEmpty;

  /// No description provided for @chequeNumberShort.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String chequeNumberShort(String number);

  /// No description provided for @chequeClearedOn.
  ///
  /// In en, this message translates to:
  /// **'Cleared on {date}'**
  String chequeClearedOn(String date);

  /// No description provided for @chequeNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked to a payment yet'**
  String get chequeNotLinked;

  /// No description provided for @chequeLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'Payment {number}'**
  String chequeLinkedTo(String number);

  /// No description provided for @actionMarkPresented.
  ///
  /// In en, this message translates to:
  /// **'Mark presented'**
  String get actionMarkPresented;

  /// No description provided for @actionMarkCleared.
  ///
  /// In en, this message translates to:
  /// **'Mark cleared'**
  String get actionMarkCleared;

  /// No description provided for @actionMarkBounced.
  ///
  /// In en, this message translates to:
  /// **'Mark bounced'**
  String get actionMarkBounced;

  /// No description provided for @actionCancelCheque.
  ///
  /// In en, this message translates to:
  /// **'Cancel cheque'**
  String get actionCancelCheque;

  /// No description provided for @actionLinkPayment.
  ///
  /// In en, this message translates to:
  /// **'Link to payment'**
  String get actionLinkPayment;

  /// No description provided for @chequeBounceTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark this cheque as bounced?'**
  String get chequeBounceTitle;

  /// No description provided for @chequeBounceBody.
  ///
  /// In en, this message translates to:
  /// **'The bank refused it, so the payee was not paid. If the payment was already recorded, reverse it from Transactions.'**
  String get chequeBounceBody;

  /// No description provided for @chequeCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this cheque?'**
  String get chequeCancelTitle;

  /// No description provided for @chequeCancelBody.
  ///
  /// In en, this message translates to:
  /// **'For a cheque that was never used. It stays in the register, marked cancelled.'**
  String get chequeCancelBody;

  /// No description provided for @chequeNowStatus.
  ///
  /// In en, this message translates to:
  /// **'Cheque {number} is now {status}.'**
  String chequeNowStatus(String number, String status);

  /// No description provided for @chequeLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to {number}.'**
  String chequeLinked(String number);

  /// No description provided for @chequeClearedTitle.
  ///
  /// In en, this message translates to:
  /// **'When did it clear?'**
  String get chequeClearedTitle;

  /// No description provided for @chequeClearedBody.
  ///
  /// In en, this message translates to:
  /// **'The date the money left the bank, from the bank statement.'**
  String get chequeClearedBody;

  /// No description provided for @fieldClearedOn.
  ///
  /// In en, this message translates to:
  /// **'Cleared on'**
  String get fieldClearedOn;

  /// No description provided for @linkPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Link to a payment'**
  String get linkPaymentTitle;

  /// No description provided for @linkPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Payments recorded from this cheque\'s bank account, newest first.'**
  String get linkPaymentHint;

  /// No description provided for @hintPaymentSearch.
  ///
  /// In en, this message translates to:
  /// **'Search, then press Enter'**
  String get hintPaymentSearch;

  /// No description provided for @linkPaymentNone.
  ///
  /// In en, this message translates to:
  /// **'No payments found from this account.'**
  String get linkPaymentNone;

  /// No description provided for @issueChequeTitle.
  ///
  /// In en, this message translates to:
  /// **'Record a cheque'**
  String get issueChequeTitle;

  /// No description provided for @issueChequeHint.
  ///
  /// In en, this message translates to:
  /// **'Record the cheque here, and the payment itself as a normal entry. Then link the two.'**
  String get issueChequeHint;

  /// No description provided for @fieldChequeAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get fieldChequeAccount;

  /// No description provided for @fieldChequeNumber.
  ///
  /// In en, this message translates to:
  /// **'Cheque number'**
  String get fieldChequeNumber;

  /// No description provided for @fieldPayableTo.
  ///
  /// In en, this message translates to:
  /// **'Payable to'**
  String get fieldPayableTo;

  /// No description provided for @fieldChequeDate.
  ///
  /// In en, this message translates to:
  /// **'Date on the cheque'**
  String get fieldChequeDate;

  /// No description provided for @chequeIssuedDone.
  ///
  /// In en, this message translates to:
  /// **'Cheque {number} recorded.'**
  String chequeIssuedDone(String number);

  /// No description provided for @settingsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can change people, taxes and ledger codes.'**
  String get settingsOwnerOnly;

  /// No description provided for @fixingDraft.
  ///
  /// In en, this message translates to:
  /// **'Changing a saved draft'**
  String get fixingDraft;

  /// No description provided for @fixingSentBack.
  ///
  /// In en, this message translates to:
  /// **'Sent back to be fixed'**
  String get fixingSentBack;

  /// No description provided for @fixingReason.
  ///
  /// In en, this message translates to:
  /// **'Why: {reason}'**
  String fixingReason(String reason);

  /// No description provided for @fixingHint.
  ///
  /// In en, this message translates to:
  /// **'Change what is wrong, then save. It is sent for approval again, or posted if you may post your own entries.'**
  String get fixingHint;

  /// No description provided for @entryDraftExplain.
  ///
  /// In en, this message translates to:
  /// **'A draft, not sent yet. Open it to finish or change it.'**
  String get entryDraftExplain;

  /// No description provided for @entryPendingExplain.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval. If something is wrong, take it back, fix it, and send it again. Only the person who sent it can do this.'**
  String get entryPendingExplain;

  /// No description provided for @entryRejectedExplain.
  ///
  /// In en, this message translates to:
  /// **'Sent back by the approver. Open it to see why, fix it, and send it again.'**
  String get entryRejectedExplain;

  /// No description provided for @actionTakeBack.
  ///
  /// In en, this message translates to:
  /// **'Take back to fix'**
  String get actionTakeBack;

  /// No description provided for @actionFixAndResend.
  ///
  /// In en, this message translates to:
  /// **'Fix and send again'**
  String get actionFixAndResend;

  /// No description provided for @taxesTitle.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get taxesTitle;

  /// No description provided for @taxesIntro.
  ///
  /// In en, this message translates to:
  /// **'The taxes the company pays, and the ones it keeps back from people it pays. Each card says in plain words what the tax does.'**
  String get taxesIntro;

  /// No description provided for @actionAddTax.
  ///
  /// In en, this message translates to:
  /// **'Add tax'**
  String get actionAddTax;

  /// No description provided for @taxesShowOld.
  ///
  /// In en, this message translates to:
  /// **'Show ended and earlier rates'**
  String get taxesShowOld;

  /// No description provided for @taxesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No taxes yet. The accountant\'s rates are added here.'**
  String get taxesEmpty;

  /// No description provided for @taxSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get taxSaved;

  /// No description provided for @taxKindWithholding.
  ///
  /// In en, this message translates to:
  /// **'Withholding, kept back'**
  String get taxKindWithholding;

  /// No description provided for @taxKindFinal.
  ///
  /// In en, this message translates to:
  /// **'Final tax'**
  String get taxKindFinal;

  /// No description provided for @taxKindAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance tax'**
  String get taxKindAdvance;

  /// No description provided for @taxKindSalesTax.
  ///
  /// In en, this message translates to:
  /// **'Sales tax'**
  String get taxKindSalesTax;

  /// No description provided for @taxKindFed.
  ///
  /// In en, this message translates to:
  /// **'FED'**
  String get taxKindFed;

  /// No description provided for @taxKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get taxKindOther;

  /// No description provided for @taxInForce.
  ///
  /// In en, this message translates to:
  /// **'In force'**
  String get taxInForce;

  /// No description provided for @taxStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String taxStarts(String date);

  /// No description provided for @taxEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String taxEnded(String date);

  /// No description provided for @taxRates.
  ///
  /// In en, this message translates to:
  /// **'{filer}% for a filer, {nonFiler}% for a non-filer'**
  String taxRates(String filer, String nonFiler);

  /// No description provided for @taxRatesFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed {filer} for a filer, {nonFiler} for a non-filer'**
  String taxRatesFixed(String filer, String nonFiler);

  /// No description provided for @taxBasisOurs.
  ///
  /// In en, this message translates to:
  /// **'Taken from us, so our own filer status sets the rate.'**
  String get taxBasisOurs;

  /// No description provided for @taxBasisPayee.
  ///
  /// In en, this message translates to:
  /// **'Kept back by us from the payee, so their filer status sets the rate.'**
  String get taxBasisPayee;

  /// No description provided for @taxBasisOursShort.
  ///
  /// In en, this message translates to:
  /// **'Taken from us'**
  String get taxBasisOursShort;

  /// No description provided for @taxBasisPayeeShort.
  ///
  /// In en, this message translates to:
  /// **'Kept back from the payee'**
  String get taxBasisPayeeShort;

  /// No description provided for @taxAppliesIn.
  ///
  /// In en, this message translates to:
  /// **'On money coming in'**
  String get taxAppliesIn;

  /// No description provided for @taxAppliesOut.
  ///
  /// In en, this message translates to:
  /// **'On money going out'**
  String get taxAppliesOut;

  /// No description provided for @taxAppliesBoth.
  ///
  /// In en, this message translates to:
  /// **'On money in and out'**
  String get taxAppliesBoth;

  /// No description provided for @taxBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get taxBoth;

  /// No description provided for @taxPostsTo.
  ///
  /// In en, this message translates to:
  /// **'Posts to {account}'**
  String taxPostsTo(String account);

  /// No description provided for @taxPeriodOpen.
  ///
  /// In en, this message translates to:
  /// **'From {from}'**
  String taxPeriodOpen(String from);

  /// No description provided for @taxPeriod.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String taxPeriod(String from, String to);

  /// No description provided for @taxRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'When the entry form suggests it'**
  String get taxRulesTitle;

  /// No description provided for @taxNoRules.
  ///
  /// In en, this message translates to:
  /// **'Never suggested. Add a rule, or it can only be added to an entry by hand.'**
  String get taxNoRules;

  /// No description provided for @ruleMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get ruleMoneyIn;

  /// No description provided for @ruleMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get ruleMoneyOut;

  /// No description provided for @ruleAnyCurrency.
  ///
  /// In en, this message translates to:
  /// **'Any currency'**
  String get ruleAnyCurrency;

  /// No description provided for @ruleForeignOnly.
  ///
  /// In en, this message translates to:
  /// **'Foreign currency'**
  String get ruleForeignOnly;

  /// No description provided for @ruleRupeesOnly.
  ///
  /// In en, this message translates to:
  /// **'Rupees only'**
  String get ruleRupeesOnly;

  /// No description provided for @ruleAnyAccount.
  ///
  /// In en, this message translates to:
  /// **'Any account'**
  String get ruleAnyAccount;

  /// No description provided for @ruleAnyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get ruleAnyCategory;

  /// No description provided for @actionNewRate.
  ///
  /// In en, this message translates to:
  /// **'Change the rate from a date'**
  String get actionNewRate;

  /// No description provided for @actionAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add a rule'**
  String get actionAddRule;

  /// No description provided for @actionEndTax.
  ///
  /// In en, this message translates to:
  /// **'End this tax'**
  String get actionEndTax;

  /// No description provided for @newRateTitle.
  ///
  /// In en, this message translates to:
  /// **'New rate for {code}'**
  String newRateTitle(String code);

  /// No description provided for @newRateHint.
  ///
  /// In en, this message translates to:
  /// **'For a budget change. Entries before the start date keep the old rate; entries from it get the new one.'**
  String get newRateHint;

  /// No description provided for @fieldNewRateFrom.
  ///
  /// In en, this message translates to:
  /// **'New rate starts on'**
  String get fieldNewRateFrom;

  /// No description provided for @newRateOldEnds.
  ///
  /// In en, this message translates to:
  /// **'The current {code} rate will end on {date}.'**
  String newRateOldEnds(String code, String date);

  /// No description provided for @actionSaveNewRate.
  ///
  /// In en, this message translates to:
  /// **'Save new rate'**
  String get actionSaveNewRate;

  /// No description provided for @fieldRateFiler.
  ///
  /// In en, this message translates to:
  /// **'Rate for a filer'**
  String get fieldRateFiler;

  /// No description provided for @fieldRateNonFiler.
  ///
  /// In en, this message translates to:
  /// **'Rate for a non-filer'**
  String get fieldRateNonFiler;

  /// No description provided for @errRateShape.
  ///
  /// In en, this message translates to:
  /// **'A number, up to four decimal places.'**
  String get errRateShape;

  /// No description provided for @endTaxTitle.
  ///
  /// In en, this message translates to:
  /// **'End {code}?'**
  String endTaxTitle(String code);

  /// No description provided for @endTaxHint.
  ///
  /// In en, this message translates to:
  /// **'For a tax that no longer applies at all. It is not suggested or accepted on entries after this day. Entries before it keep it.'**
  String get endTaxHint;

  /// No description provided for @fieldLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day it applies'**
  String get fieldLastDay;

  /// No description provided for @addRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'When to suggest {code}'**
  String addRuleTitle(String code);

  /// No description provided for @addRuleHint.
  ///
  /// In en, this message translates to:
  /// **'The entry form suggests this tax when an entry matches all of these. \"Any\" means it does not matter.'**
  String get addRuleHint;

  /// No description provided for @fieldRuleCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldRuleCurrency;

  /// No description provided for @fieldRuleAccount.
  ///
  /// In en, this message translates to:
  /// **'Paid from or into'**
  String get fieldRuleAccount;

  /// No description provided for @fieldRuleCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldRuleCategory;

  /// No description provided for @addTaxTitleFull.
  ///
  /// In en, this message translates to:
  /// **'Add a tax'**
  String get addTaxTitleFull;

  /// No description provided for @addTaxHint.
  ///
  /// In en, this message translates to:
  /// **'For a tax the accountant names. To change the rate of one that exists, use \"New rate from a date\" on it instead.'**
  String get addTaxHint;

  /// No description provided for @fieldTaxName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldTaxName;

  /// No description provided for @fieldTaxCode.
  ///
  /// In en, this message translates to:
  /// **'Short code'**
  String get fieldTaxCode;

  /// No description provided for @hintTaxCode.
  ///
  /// In en, this message translates to:
  /// **'Shown on entries, such as 153-IT'**
  String get hintTaxCode;

  /// No description provided for @fieldLawReference.
  ///
  /// In en, this message translates to:
  /// **'Law reference (optional)'**
  String get fieldLawReference;

  /// No description provided for @hintLawReference.
  ///
  /// In en, this message translates to:
  /// **'Such as ITO 2001 s.153'**
  String get hintLawReference;

  /// No description provided for @fieldTaxKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get fieldTaxKind;

  /// No description provided for @fieldTaxAuthority.
  ///
  /// In en, this message translates to:
  /// **'Collected by'**
  String get fieldTaxAuthority;

  /// No description provided for @fieldTaxAppliesTo.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get fieldTaxAppliesTo;

  /// No description provided for @fieldTaxBasis.
  ///
  /// In en, this message translates to:
  /// **'Who it is about'**
  String get fieldTaxBasis;

  /// No description provided for @fieldTaxLedger.
  ///
  /// In en, this message translates to:
  /// **'Posts to'**
  String get fieldTaxLedger;

  /// No description provided for @hintTaxLedger.
  ///
  /// In en, this message translates to:
  /// **'The ledger account the accountant gives for this tax.'**
  String get hintTaxLedger;

  /// No description provided for @hintTaxLedgerNeeded.
  ///
  /// In en, this message translates to:
  /// **'Choose the ledger account it posts to.'**
  String get hintTaxLedgerNeeded;

  /// No description provided for @fieldTaxFrom.
  ///
  /// In en, this message translates to:
  /// **'In force from'**
  String get fieldTaxFrom;

  /// No description provided for @fieldReturnSection.
  ///
  /// In en, this message translates to:
  /// **'Return section (optional)'**
  String get fieldReturnSection;

  /// No description provided for @hintReturnSection.
  ///
  /// In en, this message translates to:
  /// **'The section code the quarterly withholding statement uses.'**
  String get hintReturnSection;

  /// No description provided for @fieldAdjustable.
  ///
  /// In en, this message translates to:
  /// **'Can be claimed back'**
  String get fieldAdjustable;

  /// No description provided for @hintAdjustable.
  ///
  /// In en, this message translates to:
  /// **'On if this tax counts against our income tax later. Off if it is a final cost.'**
  String get hintAdjustable;

  /// No description provided for @errRequired.
  ///
  /// In en, this message translates to:
  /// **'Fill this in.'**
  String get errRequired;

  /// No description provided for @ledgerTitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger codes'**
  String get ledgerTitle;

  /// No description provided for @ledgerIntro.
  ///
  /// In en, this message translates to:
  /// **'The chart of accounts: every amount in the books is filed under one of these codes, grouped under headings.'**
  String get ledgerIntro;

  /// No description provided for @actionAddCode.
  ///
  /// In en, this message translates to:
  /// **'Add code'**
  String get actionAddCode;

  /// No description provided for @ledgerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code or name'**
  String get ledgerSearchHint;

  /// No description provided for @ledgerShowOff.
  ///
  /// In en, this message translates to:
  /// **'Show switched-off codes'**
  String get ledgerShowOff;

  /// No description provided for @ledgerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get ledgerSaved;

  /// No description provided for @ledgerClass1.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get ledgerClass1;

  /// No description provided for @ledgerClass2.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get ledgerClass2;

  /// No description provided for @ledgerClass3.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get ledgerClass3;

  /// No description provided for @ledgerClass4.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get ledgerClass4;

  /// No description provided for @ledgerClass5.
  ///
  /// In en, this message translates to:
  /// **'Cost of services'**
  String get ledgerClass5;

  /// No description provided for @ledgerClass6.
  ///
  /// In en, this message translates to:
  /// **'Administrative expenses'**
  String get ledgerClass6;

  /// No description provided for @ledgerClass7.
  ///
  /// In en, this message translates to:
  /// **'Selling and marketing'**
  String get ledgerClass7;

  /// No description provided for @ledgerClass8.
  ///
  /// In en, this message translates to:
  /// **'Finance costs and other'**
  String get ledgerClass8;

  /// No description provided for @ledgerClass9.
  ///
  /// In en, this message translates to:
  /// **'Taxation'**
  String get ledgerClass9;

  /// No description provided for @ledgerNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No code matches that.'**
  String get ledgerNoMatch;

  /// No description provided for @ledgerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ledger codes yet.'**
  String get ledgerEmpty;

  /// No description provided for @ledgerHeadingExplain.
  ///
  /// In en, this message translates to:
  /// **'A heading only groups the codes under it. Nothing is filed under a heading itself.'**
  String get ledgerHeadingExplain;

  /// No description provided for @ledgerBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get ledgerBuiltIn;

  /// No description provided for @ledgerBuiltInExplain.
  ///
  /// In en, this message translates to:
  /// **'Posting, transfers, tax or the opening entry depend on this code, so its name stays and it stays on.'**
  String get ledgerBuiltInExplain;

  /// No description provided for @ledgerOnEntryForm.
  ///
  /// In en, this message translates to:
  /// **'On the entry form'**
  String get ledgerOnEntryForm;

  /// No description provided for @ledgerOnEntryFormExplain.
  ///
  /// In en, this message translates to:
  /// **'People can pick this as what the money was for when they make an entry.'**
  String get ledgerOnEntryFormExplain;

  /// No description provided for @ledgerSwitchedOff.
  ///
  /// In en, this message translates to:
  /// **'Switched off'**
  String get ledgerSwitchedOff;

  /// No description provided for @ledgerSwitchedOffExplain.
  ///
  /// In en, this message translates to:
  /// **'Not offered for new entries. Entries already filed under it keep it.'**
  String get ledgerSwitchedOffExplain;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @ledgerAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a ledger code'**
  String get ledgerAddTitle;

  /// No description provided for @ledgerAddHint.
  ///
  /// In en, this message translates to:
  /// **'Use a code the accountant gave you. Its first digit says what kind it is, for example 6 for an administrative expense.'**
  String get ledgerAddHint;

  /// No description provided for @fieldLedgerCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get fieldLedgerCode;

  /// No description provided for @ledgerCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Four digits, such as 6960.'**
  String get ledgerCodeHelp;

  /// No description provided for @ledgerGoesUnder.
  ///
  /// In en, this message translates to:
  /// **'Goes under {group}'**
  String ledgerGoesUnder(String group);

  /// No description provided for @errLedgerCodeShape.
  ///
  /// In en, this message translates to:
  /// **'Use four digits that do not start with 0, such as 6960.'**
  String get errLedgerCodeShape;

  /// No description provided for @fieldLedgerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldLedgerName;

  /// No description provided for @errLedgerNameShort.
  ///
  /// In en, this message translates to:
  /// **'Give it a name of at least 3 letters.'**
  String get errLedgerNameShort;

  /// No description provided for @ledgerAddToEntryForm.
  ///
  /// In en, this message translates to:
  /// **'Show it on the entry form'**
  String get ledgerAddToEntryForm;

  /// No description provided for @ledgerAddToEntryFormHint.
  ///
  /// In en, this message translates to:
  /// **'So people can pick it as what the money was for. Leave it off for a code only the accountant uses.'**
  String get ledgerAddToEntryFormHint;

  /// No description provided for @ledgerRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename {code}'**
  String ledgerRenameTitle(String code);

  /// No description provided for @ledgerRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Entries already filed under {code} keep the code and show the new name.'**
  String ledgerRenameHint(String code);

  /// No description provided for @ledgerSwitchOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch off {code}?'**
  String ledgerSwitchOffTitle(String code);

  /// No description provided for @ledgerSwitchOffHint.
  ///
  /// In en, this message translates to:
  /// **'It leaves the entry form and cannot be used for new entries. Entries already filed under it keep it. You can switch it back on later.'**
  String get ledgerSwitchOffHint;

  /// No description provided for @findOpen.
  ///
  /// In en, this message translates to:
  /// **'Find on this screen (Ctrl+F)'**
  String get findOpen;

  /// No description provided for @findHint.
  ///
  /// In en, this message translates to:
  /// **'Find on this screen'**
  String get findHint;

  /// No description provided for @findNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get findNoMatches;

  /// No description provided for @findCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String findCount(int current, int total);

  /// No description provided for @findPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous match (Shift+Enter)'**
  String get findPrevious;

  /// No description provided for @findNext.
  ///
  /// In en, this message translates to:
  /// **'Next match (Enter)'**
  String get findNext;

  /// No description provided for @findClose.
  ///
  /// In en, this message translates to:
  /// **'Close (Esc)'**
  String get findClose;

  /// No description provided for @findScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Finds what this screen shows. To search every entry, use Search on Transactions.'**
  String get findScopeNote;

  /// No description provided for @actionAddHeading.
  ///
  /// In en, this message translates to:
  /// **'Add heading'**
  String get actionAddHeading;

  /// No description provided for @actionImportOrExport.
  ///
  /// In en, this message translates to:
  /// **'Import or export'**
  String get actionImportOrExport;

  /// No description provided for @actionDownloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download the template'**
  String get actionDownloadTemplate;

  /// No description provided for @actionDownloadCurrent.
  ///
  /// In en, this message translates to:
  /// **'Download the current list'**
  String get actionDownloadCurrent;

  /// No description provided for @actionImportFile.
  ///
  /// In en, this message translates to:
  /// **'Import a file'**
  String get actionImportFile;

  /// No description provided for @settingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Set up who can sign in, the taxes the company deals with, and the codes the books are kept in. Only the owner sees this.'**
  String get settingsIntro;

  /// No description provided for @settingsBack.
  ///
  /// In en, this message translates to:
  /// **'All settings'**
  String get settingsBack;

  /// No description provided for @settingsPeopleExplain.
  ///
  /// In en, this message translates to:
  /// **'Who can sign in, and what each person may do.'**
  String get settingsPeopleExplain;

  /// No description provided for @settingsPeopleSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person can sign in} other{{count} people can sign in}}'**
  String settingsPeopleSummary(int count);

  /// No description provided for @settingsTaxesExplain.
  ///
  /// In en, this message translates to:
  /// **'The taxes the company pays or keeps back, their rates, and when the entry form suggests them.'**
  String get settingsTaxesExplain;

  /// No description provided for @settingsTaxesSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No taxes in force yet} =1{1 tax in force} other{{count} taxes in force}}'**
  String settingsTaxesSummary(int count);

  /// No description provided for @settingsLedgerExplain.
  ///
  /// In en, this message translates to:
  /// **'The chart of accounts: the codes and headings every amount is filed under.'**
  String get settingsLedgerExplain;

  /// No description provided for @settingsLedgerSummary.
  ///
  /// In en, this message translates to:
  /// **'{codes} codes under {headings} headings'**
  String settingsLedgerSummary(int codes, int headings);

  /// No description provided for @settingsImportExplain.
  ///
  /// In en, this message translates to:
  /// **'Ledger codes and taxes in and out as spreadsheet files, for the accountant.'**
  String get settingsImportExplain;

  /// No description provided for @settingsImportSummary.
  ///
  /// In en, this message translates to:
  /// **'CSV files that open in Excel or Google Sheets'**
  String get settingsImportSummary;

  /// No description provided for @settingsAuditNote.
  ///
  /// In en, this message translates to:
  /// **'Every change made here is kept in the audit log with who made it and when.'**
  String get settingsAuditNote;

  /// No description provided for @bulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Import and export'**
  String get bulkTitle;

  /// No description provided for @bulkIntro.
  ///
  /// In en, this message translates to:
  /// **'Move ledger codes and taxes in and out as spreadsheet files. Nothing is saved until you have seen what a file will change, row by row, and confirmed it.'**
  String get bulkIntro;

  /// No description provided for @bulkStep1.
  ///
  /// In en, this message translates to:
  /// **'Download the template to start a new list, or the current list to change what is there.'**
  String get bulkStep1;

  /// No description provided for @bulkStep2.
  ///
  /// In en, this message translates to:
  /// **'Fill it in or change it in Excel or Google Sheets. Keep the first two rows: the column names and the example row. Save it as \"CSV UTF-8\".'**
  String get bulkStep2;

  /// No description provided for @bulkStep3.
  ///
  /// In en, this message translates to:
  /// **'Import it. Check what each row will do, then save. Rows with a problem are skipped and say why.'**
  String get bulkStep3;

  /// No description provided for @bulkLedgerExplain.
  ///
  /// In en, this message translates to:
  /// **'One row per code or heading. New codes are added and existing ones are updated. Nothing is deleted: a code is switched off with \"Switched on: no\".'**
  String get bulkLedgerExplain;

  /// No description provided for @bulkTaxesExplain.
  ///
  /// In en, this message translates to:
  /// **'One row per tax and rule. A new rate needs a start date after the current one; the old rate then ends the day before. Taxes not in the file stay as they are.'**
  String get bulkTaxesExplain;

  /// No description provided for @bulkDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {file}.'**
  String bulkDownloaded(String file);

  /// No description provided for @bulkPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check before saving: {file}'**
  String bulkPreviewTitle(String file);

  /// No description provided for @bulkPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing is saved yet. This is what the file will do to each row.'**
  String get bulkPreviewHint;

  /// No description provided for @bulkCountAdd.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String bulkCountAdd(int count);

  /// No description provided for @bulkCountUpdate.
  ///
  /// In en, this message translates to:
  /// **'{count} changed'**
  String bulkCountUpdate(int count);

  /// No description provided for @bulkCountUnchanged.
  ///
  /// In en, this message translates to:
  /// **'{count} no change'**
  String bulkCountUnchanged(int count);

  /// No description provided for @bulkCountSkip.
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String bulkCountSkip(int count);

  /// No description provided for @bulkShowUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Show rows with no change'**
  String get bulkShowUnchanged;

  /// No description provided for @bulkNothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Every row is already as the file says.'**
  String get bulkNothingToShow;

  /// No description provided for @bulkNothingToSave.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to save from this file.'**
  String get bulkNothingToSave;

  /// No description provided for @bulkSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to save} =1{Save 1 change} other{Save {count} changes}}'**
  String bulkSaveChanges(int count);

  /// No description provided for @bulkSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {added} new, {updated} changed, {skipped} skipped.'**
  String bulkSaved(int added, int updated, int skipped);

  /// No description provided for @bulkActionAdd.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get bulkActionAdd;

  /// No description provided for @bulkActionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get bulkActionUpdate;

  /// No description provided for @bulkActionUnchanged.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get bulkActionUnchanged;

  /// No description provided for @bulkActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get bulkActionSkip;

  /// No description provided for @bulkRow.
  ///
  /// In en, this message translates to:
  /// **'Row {number}'**
  String bulkRow(int number);

  /// No description provided for @bulkRows.
  ///
  /// In en, this message translates to:
  /// **'Rows {numbers}'**
  String bulkRows(String numbers);

  /// No description provided for @ledgerHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How the codes are arranged'**
  String get ledgerHowTitle;

  /// No description provided for @ledgerHowDigits.
  ///
  /// In en, this message translates to:
  /// **'The first digit says what kind of account it is: 1 assets, 2 liabilities, 3 equity, 4 income, 5 to 9 costs.'**
  String get ledgerHowDigits;

  /// No description provided for @ledgerHowHeadings.
  ///
  /// In en, this message translates to:
  /// **'Headings, shown with a folder, group the codes under them. Nothing is filed under a heading itself.'**
  String get ledgerHowHeadings;

  /// No description provided for @ledgerHowBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in codes keep their name and stay on, because posting, transfers, tax and the opening balances depend on them.'**
  String get ledgerHowBuiltIn;

  /// No description provided for @ledgerHowSwitchOff.
  ///
  /// In en, this message translates to:
  /// **'Nothing is deleted. A code no longer needed is switched off, and older entries keep it.'**
  String get ledgerHowSwitchOff;

  /// No description provided for @ledgerAddHeadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a heading'**
  String get ledgerAddHeadingTitle;

  /// No description provided for @ledgerAddHeadingHint.
  ///
  /// In en, this message translates to:
  /// **'A heading groups codes, for example 1130 Advances, deposits and prepayments. Use a code the accountant gave you.'**
  String get ledgerAddHeadingHint;

  /// No description provided for @fieldLedgerParent.
  ///
  /// In en, this message translates to:
  /// **'Sits under'**
  String get fieldLedgerParent;

  /// No description provided for @hintLedgerParent.
  ///
  /// In en, this message translates to:
  /// **'The heading it is grouped under. Only headings of the same kind that come before it can hold it.'**
  String get hintLedgerParent;

  /// No description provided for @ledgerParentNearest.
  ///
  /// In en, this message translates to:
  /// **'The nearest heading before it (automatic)'**
  String get ledgerParentNearest;

  /// No description provided for @ledgerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Change {code}'**
  String ledgerEditTitle(String code);

  /// No description provided for @ledgerEditHint.
  ///
  /// In en, this message translates to:
  /// **'The code {code} itself never changes, so entries filed under it keep it and show the new name.'**
  String ledgerEditHint(String code);

  /// No description provided for @ledgerSwitchOffHeadingHint.
  ///
  /// In en, this message translates to:
  /// **'A heading can be switched off once nothing under it is on. You can switch it back on later.'**
  String get ledgerSwitchOffHeadingHint;

  /// No description provided for @taxHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How taxes work here'**
  String get taxHowTitle;

  /// No description provided for @taxHowFiler.
  ///
  /// In en, this message translates to:
  /// **'Each tax has a rate for filers and a higher rate for non-filers: anyone not on FBR\'s Active Taxpayers List.'**
  String get taxHowFiler;

  /// No description provided for @taxHowRates.
  ///
  /// In en, this message translates to:
  /// **'A rate is never edited. \"Change the rate from a date\" ends the old rate the day before, so older entries keep the rate they were made at.'**
  String get taxHowRates;

  /// No description provided for @taxHowRules.
  ///
  /// In en, this message translates to:
  /// **'Rules say when the entry form suggests a tax. The person making the entry can still remove it or change the amount to what was really taken.'**
  String get taxHowRules;

  /// No description provided for @taxHowEntries.
  ///
  /// In en, this message translates to:
  /// **'Posted entries keep the tax they were saved with. Nothing here changes the books.'**
  String get taxHowEntries;

  /// No description provided for @taxRulesExplain.
  ///
  /// In en, this message translates to:
  /// **'When an entry matches one of these, the entry form adds this tax by itself. A rule is switched off, never deleted.'**
  String get taxRulesExplain;

  /// No description provided for @taxFactRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get taxFactRate;

  /// No description provided for @taxFactKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get taxFactKind;

  /// No description provided for @taxFactRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded in'**
  String get taxFactRecorded;

  /// No description provided for @taxFactDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get taxFactDates;

  /// No description provided for @taxPaidTo.
  ///
  /// In en, this message translates to:
  /// **'paid to {authority}'**
  String taxPaidTo(String authority);

  /// No description provided for @taxPercent.
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String taxPercent(String rate);

  /// No description provided for @taxFixed.
  ///
  /// In en, this message translates to:
  /// **'PKR {amount}'**
  String taxFixed(String amount);

  /// No description provided for @taxAuthorityFbr.
  ///
  /// In en, this message translates to:
  /// **'FBR'**
  String get taxAuthorityFbr;

  /// No description provided for @taxAuthorityPra.
  ///
  /// In en, this message translates to:
  /// **'PRA'**
  String get taxAuthorityPra;

  /// No description provided for @taxAuthoritySrb.
  ///
  /// In en, this message translates to:
  /// **'SRB'**
  String get taxAuthoritySrb;

  /// No description provided for @taxAuthorityIct.
  ///
  /// In en, this message translates to:
  /// **'ICT'**
  String get taxAuthorityIct;

  /// No description provided for @taxAuthorityBank.
  ///
  /// In en, this message translates to:
  /// **'the bank'**
  String get taxAuthorityBank;

  /// No description provided for @taxAuthorityOther.
  ///
  /// In en, this message translates to:
  /// **'the tax office'**
  String get taxAuthorityOther;

  /// No description provided for @taxSayKeepBack.
  ///
  /// In en, this message translates to:
  /// **'When we pay someone, we keep back {rate} of the payment ({nonFiler} if they are not a filer) and pay it to {authority} for them.'**
  String taxSayKeepBack(String rate, String nonFiler, String authority);

  /// No description provided for @taxSayCollect.
  ///
  /// In en, this message translates to:
  /// **'When money comes in, the payer adds {rate} ({nonFiler} if they are not a filer), which we pay to {authority}.'**
  String taxSayCollect(String rate, String nonFiler, String authority);

  /// No description provided for @taxSayHeldBoth.
  ///
  /// In en, this message translates to:
  /// **'On money in and out, {rate} ({nonFiler} if the other side is not a filer) is held back and paid to {authority}.'**
  String taxSayHeldBoth(String rate, String nonFiler, String authority);

  /// No description provided for @taxSayTakenIn.
  ///
  /// In en, this message translates to:
  /// **'When money comes in, {rate} of it is taken as tax ({nonFiler} if we are not a filer).'**
  String taxSayTakenIn(String rate, String nonFiler);

  /// No description provided for @taxSayTakenOut.
  ///
  /// In en, this message translates to:
  /// **'When we pay, {rate} more is charged to us as tax ({nonFiler} if we are not a filer).'**
  String taxSayTakenOut(String rate, String nonFiler);

  /// No description provided for @taxSayTakenBoth.
  ///
  /// In en, this message translates to:
  /// **'On money in and out, {rate} is taken from us as tax ({nonFiler} if we are not a filer).'**
  String taxSayTakenBoth(String rate, String nonFiler);

  /// No description provided for @taxSayNotOurCost.
  ///
  /// In en, this message translates to:
  /// **'It is not our cost: we only hold it until it is paid over.'**
  String get taxSayNotOurCost;

  /// No description provided for @taxSayClaimable.
  ///
  /// In en, this message translates to:
  /// **'We can claim it back against our income tax.'**
  String get taxSayClaimable;

  /// No description provided for @taxSayFinalCost.
  ///
  /// In en, this message translates to:
  /// **'It is a final cost: we cannot claim it back.'**
  String get taxSayFinalCost;
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
