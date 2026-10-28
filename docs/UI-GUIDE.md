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
- Fields that affect posting say so: "Client will pay this back" explains
  that the spend is not our cost and waits as money the client owes. The tick
  is the one way to record rebillable spend; the category says what it was.
  Decision 062
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

### As built

Seven steps, decision 064: direction and date; amount and currency (PKR, USD,
GBP, AED, QAR, EUR, with the rate and rupees for a foreign one); paid from
(an account, or a person); category, description and "Client will pay this
back"; taxes and charges; receipt; review with the journal preview. The tax
step suggests lines from the server, lets a figure be changed to what was
actually taken, removes or adds lines, asks for the payee when tax is kept
back, and shows what leaves or reaches the account. A charge goes to the
usual account for its type unless another cost account is picked.

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
has a split. Receipt optional; the bank advice can be attached. Optional link
to the invoice being paid.

### Other form rules

- A "View journal entry" link on every posted transaction, read only
- A separate Journal Entry screen for admin, for the rare manual entry that
  does not fit the guided form
- Defaults everywhere: today's date, last used account, the client's default
  rebillable setting, the currency last used with that client

## Receipt rules

Corrected 2026-10-26 to match decision 055, which decision 057 kept. Decision
021 is superseded on this point.

| Situation | Receipt |
| --- | --- |
| Money Out at or above the threshold (setting, default 5,000 PKR), including one paid by a person | Required before it can post |
| Money Out below the threshold | Optional. Flagged "No receipt" until one is attached |
| Money In, from a client or otherwise, in any currency | Optional. Not flagged. Attach the bank advice where there is one |
| Paying a person back | Not needed. The receipt belongs on the original cost |
| Transfers between company accounts | Not needed |
| The opening entry and manual journal entries | Not needed |
| Historical entries | Not needed |
| Payroll | System generates the salary slip, which counts |

The threshold is a setting, not code. A receipt may be attached after posting.
Attaching one clears the entry's "No receipt" flag by itself. Decision 056.

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
- Foreign amount x rate more than PKR 1 away from the PKR amount entered.
  The refusal gives the figure it should be. Decision 061
- A tax that is switched off, or that belongs to the other direction
  (a sales tax on money out, a purchases tax on money in)
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

- No receipt on money out below the threshold. Clears itself when a receipt
  is attached
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

Any flag or confirmed warning can be marked reviewed by the owner or an admin,
with a note saying why it needs nothing more. Staff cannot. The note and who
wrote it stay with the flag. Decision 056.

Warnings must name the specific record they matched against and link to it. A
warning the user cannot investigate becomes a warning they dismiss by reflex.

## People and permissions

Settings opens on People. Only the owner sees it; anyone else sees one line
saying only the owner can add people. Decision 063.

- "What each role can do" sits above the list: three tiles, one line each,
  always visible, each role with its own icon (owner solid, admin tinted,
  staff neutral, so rank reads before the label). "See exactly who can do
  what" opens a table of tasks against Owner, Admin and Staff: a tick, a dash,
  or "depends on settings" for an admin's limit and own-entry posting
- People are grouped: Office login, Admins, Staff, then Switched off, each
  with a count. Two cards per row on a wide screen, one on a phone
- A card per person: initials, name, email, a role badge, and chips with an
  icon each saying what is special about them: "Approves up to PKR 50,000.00",
  "Posts own entries", "Every entry needs approval", "Also uses the office
  login", "Has not set their own password yet", "Switched off". A switched-off
  card is dimmed
- Edit is a button; Reset password and Switch off sit in a menu, because they
  are rarer and stronger. Switching off asks first. None on the office login
- Add person is three short sections: who (name, email), role (two cards to
  pick from, with what each means), approvals for an admin (limit in whole
  rupees with separators as you type, empty means no limit; own entries post
  or not), sign-in (uses the office login; temporary password with "Make one
  for me", show and copy). Generated passwords avoid 0, O, 1, l and I
- Nobody is deleted, so every entry keeps the name of who made it

## Moving money and the opening balances

On the Accounts screen, for the owner and admins (decision 065):

- **Move money**: from, to, amount, an optional bank fee, the date. Both
  sides are recorded together
- **Pay someone back**: who, the costs they paid (ticked, each in full unless
  changed), which account it is paid from
- **Petty cash below its float**: says what it holds, the float, and the
  server's suggested top-up, with a Top up button that opens Move money
  filled in
- **Owed to people**: each person the company owes, with Pay back beside them
- **Opening balances**, owner only: a screen of balance sheet accounts, each
  balance typed as a plain figure; once posted it is shown read only

A posted entry's journal panel has **Reverse entry** for the owner and admins.
It asks why. A transfer is reversed whole. A reversal and the opening entry
are not offered.

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
