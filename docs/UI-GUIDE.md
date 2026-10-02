# UI Guide

This is a professional accounting system. It uses correct accounting
terminology, and explains that terminology through tooltips rather than by
dumbing the words down. The interface must look considered, not generated.

Interface language: English only. Themes: light and dark, both first class.

---

## Terminology

Use the official term. Always.

Debit, Credit, Journal Entry, Chart of Accounts, Accounts Receivable,
Accounts Payable, Trial Balance, Reconciliation, Fiscal Year, Posted, Draft.

Maryam already works in these terms and the company accountant will too.
Renaming them creates a private vocabulary that does not transfer to any other
accounting software, and makes handover harder.

## Tooltips carry the explanation

Every accounting term, every column header, and every non-obvious field has a
tooltip on hover and on long-press for touch.

- One or two plain sentences. No paragraphs
- Say what it means here, in this company's terms, not the textbook definition.
  Good: "Money we have spent but not yet recovered from the client."
  Bad: "An asset arising from the delivery of goods or services."
- Fields that affect posting say so: "Choosing Rebillable means this appears on
  the client's next invoice instead of reducing profit."
- Tooltips are content, not decoration. They live in one `lib/core/glossary/`
  map so the same term never gets two different explanations
- A `?` icon only where hover is not discoverable, never on every label

## Visual design

- Dark and light themes from day one, both designed rather than inverted.
  System default on first load, user override saved
- One accent colour. Semantic colours for in, out, pending, overdue, reversed
- Never colour alone. Every state has an icon or a label beside it
- Tabular figures for all numbers so columns align
- Generous row height on desktop. Density toggle for long ledger sessions
- Consistent spacing scale. No one-off padding values
- Theme tokens in one file. No hardcoded colours anywhere in feature code

## Layout

Follow the pattern accounting software has settled on, because people expect it.

- Left navigation by module: Dashboard, Transactions, Clients, Invoices,
  Payroll, Recurring, Reports, Settings
- Each module opens on a list view: filters above, table below, primary action
  top right
- Clicking a row opens a form view with a status ribbon showing the lifecycle:
  Draft, Pending, Posted, Reversed
- Breadcrumb back to the list. Never a dead end
- Mobile collapses the table into cards and the nav into a bottom bar

## Entry form

Guided and step by step. Each step shows only what applies to the choices
already made. Nothing is hidden that the user needs, nothing is shown that
does not apply.

### Example: paying a $20 Claude subscription

1. **Direction.** Money Out
2. **Currency.** PKR, USD, GBP, AED, QAR, EUR. Default PKR
3. **Amount.** 20.00 USD
4. **Paid by.** Winibex bank, Office cash, Petty cash, or a person (Ahmad,
   Fazal). Choosing a person creates a payable to that person until the
   company reimburses them. Tooltip explains this
5. **Conversion.** Enter either the rate or the PKR actually charged. The other
   fills itself. Last used rate for the currency appears as a hint, never
   applied automatically
6. **Taxes and charges.** The system suggests the lines configured for this
   kind of payment, for example card advance tax, forex fee, FED on the fee.
   Each line is editable, removable, and more can be added. Running PKR total
   updates live
7. **Category, description, client, project, rebillable**
8. **Receipt.** Required or optional per the receipt rules below. Camera first
   on mobile
9. **Review.** Summary of everything plus a journal preview showing the debit
   and credit lines that will post. Submit from here

### Example: foreign client payment received

Direction Money In, currency USD, amount, received into (Winibex bank, a
pass-through account, or an earning account such as an Upwork ID), rate or
PKR received, then suggested deductions: Section 154A final tax if the company
is marked PSEB registered, platform fee, partner share where the earning account
has a split. Receipt mandatory. Optional link to the invoice being paid.

### Other form rules

- A "View journal entry" link on every posted transaction, read only
- A separate Journal Entry screen for admin, for the rare manual entry that
  does not fit the guided form
- Defaults everywhere: today's date, last used account, the client's default
  rebillable setting, the currency last used with that client

## Receipt rules

| Situation | Receipt |
| --- | --- |
| Any Money In from a client | Required |
| Any foreign currency transaction | Required, since it is the proof of the rate |
| Paid by a person, to be reimbursed | Required |
| Money Out at or above the threshold (setting, default 5,000 PKR) | Required |
| Transfers between company accounts | Optional |
| Payroll | System generates the salary slip, which counts |
| Money Out below the threshold | Optional, flagged when missing |

The threshold is a setting, not code.

## Preventing false entries

Validation is layered. Each layer has a different job.

### Blocked, cannot be saved

Structure
- Debits not equal to credits
- Missing date, account, category, currency or amount
- Zero or negative amount. Direction carries the sign, never the number
- Posting to an inactive account, category or tax

Dates
- Date in the future
- Date before the account's opening date

Currency and tax
- Foreign currency with neither a rate nor a PKR amount
- Rate of zero or below
- A tax line larger than the amount it is calculated on
- A tax that was not in effect on the transaction date

Money that cannot exist
- Cash or petty cash going below zero. You cannot spend cash you do not have
- A transfer where source and destination are the same account
- Transfer legs that do not match, unless the difference is recorded as a fee
- Reimbursing a person more than the company owes them

Invoices and payroll
- A payment larger than the invoice's remaining balance. Record the excess as
  a customer advance instead
- An invoice payment with no linked cash transaction
- A reused invoice number, or a cheque number already used on the same account
- Withholding from a local vendor with neither an NTN nor a CNIC recorded
- Approving your own entry. Admins with auto-approve post directly instead
- Approving an entry above your approval limit, where an admin has one
- A historical entry dated on or after 1 July 2026. History is, by
  definition, before the books went live
- An opening entry dated anything other than 1 July 2026, or a second
  opening entry when one already exists
- Merging history while any account still shows a difference
- A payroll run for a month already paid
- A salary line for an employee after their exit date

Receipts and records
- A required receipt missing, per the receipt rules
- Any edit to a posted entry

### Warned, can proceed after confirming

- Same amount, same account, within three days of another entry
- Same description and amount within 30 days
- Amount more than three times the usual for that category
- Rate more than 5 percent away from the last rate used for that currency
- A tax rate manually changed from the configured rate
- Date more than 90 days in the past. Not raised for historical entries, which
  are old by definition
- Posting to a closed client or completed project
- Bank account going below zero
- Cash expense at or above 50,000 PKR
- Recurring cost amount more than 20 percent away from its estimate
- Rebillable spend on a client with no active project
- Vendor ATL status not checked in the last 30 days
- Paying a local service vendor with no withholding line
- Bank statement line with no matching entry after reconciliation

### Flagged, visible in a review list

- No receipt where optional
- Description under five characters
- Category unusual for that client
- Rebillable spend not yet invoiced after 30 days
- Money owed to a person outstanding more than 30 days
- Money sitting in a pass-through account more than 14 days
- Submission pending approval more than 7 days
- Invoice overdue
- Manual tax override used
- Withholding certificate not received from a client 30 days after payment
- PSEB certificate expiring within 30 days
- Quarterly withholding statement due within 10 days and not filed
- Petty cash below its imprest float

Warnings must name the specific record they matched against and link to it. A
warning the user cannot investigate becomes a warning they dismiss by reflex.

## Posting and corrections

- Draft is editable. Posted is not, for anyone, including admin
- A mistake is corrected by reversing the entry and posting a new one
- The reversal and the original both stay visible and are linked both ways
- Reversal requires a reason, and that reason appears in the ledger

## Documents

Every document is generated from data already in the system, never typed
separately, and uses one company template with logo, NTN, PSEB number and
address.

- Quotation: what a project will cost. Converts to an invoice in one click
- Invoice
- Payment receipt: issued to a client after payment, shows currency, rate and
  any tax deducted
- Payment voucher: internal record of money out
- Salary slip
- Client statement of account: everything invoiced, paid and outstanding

Each document has a preview before it is finalised, a PDF download, and a
gapless number.

## Feedback

- Confirmations state the result: "Posted. Winibex bank is now 94,851."
- Errors say what to do next: "Pick a category before posting."
- Pending items say who is waiting: "Waiting for Ahmad to approve."
- Nothing silently discards work. A half-filled form survives a refresh

## Numbers

- Thousands separators always
- Currency code always shown, never a bare number
- Negatives in red with a minus sign and parentheses in reports
- Foreign amounts show both: "$433 (120,000 PKR)"
- Round only at display, never in storage or calculation

## Tables

- Server-side search on every table, searching all rows and not just the page
- `find_in_page` for finding text already on screen
- Column sort and visibility saved per user
- Copy row and export to CSV on every list
- Row count and total always visible: "118 entries, 1,284,502 PKR"
- Pagination server side. Never load 5,000 rows to show 50

## Accessibility and polish

- Keyboard path through the entry form, tab order follows reading order
- Enter saves, Escape cancels, consistently
- Loading states are skeletons, not spinners over blank screens
- Every screen has a designed empty state saying what it is for

## The test

Before a screen is called done: can Maryam use it without being trained, using
only the tooltips, and would an accountant recognise the terminology as correct?
Both must be yes.
