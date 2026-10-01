# Schema

MariaDB 11.8. All money columns are `BIGINT` in paisa (1 PKR = 100 paisa).
All timestamps UTC. Soft delete only, via status columns.

Status: Structure approved 2026-10-01. Tax and chart of accounts sections
pending review by the company accountant before Phase 0 migration.

---

## Database engine

The server is MariaDB, not MySQL. Confirmed against the live Hostinger
database on 2026-10-01, see decision 041. This affects the schema in four
places and nowhere else.

**Character set.** Every table is created `utf8mb4` with
`utf8mb4_uca1400_ai_ci`, the MariaDB 11.6+ default. MySQL's
`utf8mb4_0900_ai_ci` does not exist here.

**JSON columns are text.** `JSON` on MariaDB is an alias for LONGTEXT with a
validity check. The driver returns a string. So `audit_log.before_json`,
`audit_log.after_json`, `idempotency_keys.response_json` and
`generated_documents.source_data_json` are stringified on write and parsed on
read, in the repository layer. Nothing queries inside them, and the `->` and
`->>` operators are not available.

**Session settings.** Hostinger does not allow global `sql_mode` or server
time zone changes, so every connection sets `STRICT_ALL_TABLES`,
`time_zone = '+00:00'` and `READ-COMMITTED` itself.

**Big numbers.** Every connection sets `supportBigNumbers`. Without it the
driver rounds a BIGINT past JavaScript's safe integer limit with no error.
Decision 044.

**Reserved words.** `KEY` is reserved, so the settings and idempotency tables
use `setting_key` and `idempotency_key` rather than `key`. No column anywhere
is named with a reserved word, so no query needs backticks to run.

---

## Money and currency

Every transaction stores:

| Column | Meaning |
| --- | --- |
| `currency` | ISO code. PKR when no conversion |
| `foreign_amount` | Original amount in that currency's minor units. Null for PKR |
| `fx_rate` | DECIMAL(18,6). PKR per one unit of foreign currency |
| `fx_rate_source` | `manual`, `bank_advice`, `derived` |
| `gross_amount` | PKR before taxes and charges |
| `tax_total` | PKR, sum of `transaction_taxes` |
| `charges_total` | PKR, sum of `transaction_charges` |
| `amount` | PKR net effect on the account. The number balances use |

The user enters either the rate or the PKR amount and the other is calculated.
Both are stored. When a bank advice shows the actual figure, it wins over a
manually entered rate, because the books must match the bank statement.

`gross_amount`, `tax_total`, `charges_total` and `amount` must reconcile:
for Money Out, `amount = gross + tax + charges`. For Money In,
`amount = gross - tax - charges`. A mismatch blocks the save.

### currencies
| Column | Type | Notes |
| --- | --- | --- |
| code | CHAR(3) PK | PKR, USD, GBP, AED, QAR, EUR |
| name, symbol | | |
| minor_units | TINYINT | 2 for all current currencies |
| is_active | BOOL | |

### exchange_rates
Reference only. Shown as a hint on the entry form, never applied automatically.

| Column | Type |
| --- | --- |
| id, currency_code, rate_date, rate DECIMAL(18,6), source, created_by |

---

## Core tables

### users
| Column | Type | Notes |
| --- | --- | --- |
| id | BIGINT PK | |
| name | VARCHAR(100) | |
| email | VARCHAR(190) UNIQUE | login |
| password_hash | VARCHAR(255) | bcrypt now, argon2id switchable. See decision 042 |
| must_change_password | BOOL | true for the bootstrapped owner, forces a change on first login |
| role | ENUM | `owner`, `admin`, `staff`. See Permissions below |
| approval_limit | BIGINT NULL | admins only, paisa. Null means unlimited |
| auto_approve_own | BOOL | admins only. Own entries post without a second person |
| shares_owner_login | BOOL | true for people who also use the winibexoffice login |
| is_active | BOOL | never delete a user |
| created_at, updated_at | TIMESTAMP | |

`password_hash` holds which algorithm produced it as part of the value, so a
change of algorithm never locks anyone out.

### refresh_tokens
Server-side sessions, so logout and revocation actually work.

| Column | Type | Notes |
| --- | --- | --- |
| id | BIGINT PK | |
| user_id | BIGINT FK | |
| token_hash | CHAR(64) | SHA-256 of the token. The token itself is never stored |
| family_id | CHAR(36) | one login session. Reuse of a rotated token revokes the whole family |
| expires_at | TIMESTAMP | |
| revoked_at | TIMESTAMP NULL | |
| replaced_by_id | BIGINT NULL | set on rotation |
| created_at, ip, user_agent | | |

Rotated on every refresh. Logout revokes the family.

### settings
Key-value. Avoids hardcoding policy.

| Column | Type | Notes |
| --- | --- | --- |
| setting_key | VARCHAR(100) PK | named `setting_key`, not `key`, which is reserved |
| value | TEXT | |
| value_type | ENUM | `string`, `int`, `bool`, `date`, `json` |
| description | VARCHAR(255) | |
| updated_by | BIGINT FK NULL | |
| updated_at | TIMESTAMP | |

Seeded keys:

| setting_key | default | purpose |
| --- | --- | --- |
| `base_currency` | PKR | |
| `fiscal_year_start_month` | 7 | July to June |
| `payroll_visible_to_all` | true | flip to false later |
| `next_invoice_number` | 5026 | continues the sheet |
| `receipt_required_above` | 500000 | paisa, so 5,000 PKR |
| `large_cash_warning_above` | 5000000 | paisa, so 50,000 PKR |
| `fx_deviation_warning_percent` | 5 | |
| `pass_through_max_days` | 14 | flag after this |
| `pseb_registered` | true | confirmed. Drives Section 154A suggestion |
| `pra_registered` | false | confirmed |
| `petty_cash_imprest` | set by admin | target float, top-up suggested when below |
| `books_live_from` | 2026-07-01 | first date of live entry. Earlier dates are historical |
| `history_merged` | false | true once history reconciles and the opening entry is reversed |
| `atl_status` | active | Winibex's own status, confirmed. Used only when tax is deducted from Winibex |

### company_profile
Single row. Printed on every document.

| Column | Type |
| --- | --- |
| legal_name, trade_name, ntn, strn_pra, pseb_reg_no, pseb_valid_until, secp_reg_no |
| paid_up_capital | BIGINT, drives the audit exemption note on statements |
| address, phone, email, website, logo_path |
| bank_details_text, default_terms_text |

### accounts
| Column | Type | Notes |
| --- | --- | --- |
| id | BIGINT PK | |
| name | VARCHAR(100) | "Winibex bank", "Office cash" |
| type | ENUM | `bank`, `cash`, `petty_cash`, `cheque`, `pass_through` |
| owner_user_id | BIGINT NULL | set for pass-through accounts |
| opening_date | DATE | earliest date any entry may carry. 2025-03-01, before the sheet's first row |
| is_active | BOOL | |

Pass-through accounts are Fazal's and Ahmad's personal accounts. They hold only
company money in transit. Personal spending never enters this system.

Current balance is never stored. It is the sum of posted journal lines on the
account's ledger code, with historical entries excluded until history is
merged. Starting balances come from the opening entry, not from a column.
Storing a balance invites the drift the spreadsheet already has.

### categories
| Column | Type | Notes |
| --- | --- | --- |
| id | BIGINT PK | |
| name | VARCHAR(100) | "Travelling and conveyance" |
| main_head | ENUM | `revenue`, `cgs`, `admin`, `selling`, `financial`, `taxation`, `balance_sheet` |
| direction | ENUM | `in`, `out` |
| coa_id | BIGINT | which ledger account it posts to |
| is_active | BOOL | |

### chart_of_accounts
| Column | Type | Notes |
| --- | --- | --- |
| id | BIGINT PK | |
| code | VARCHAR(10) UNIQUE | 1000 assets, 2000 liabilities, etc |
| name | VARCHAR(100) | |
| type | ENUM | `asset`, `liability`, `equity`, `income`, `expense` |
| parent_id | BIGINT NULL | |
| fbr_return_head_code | VARCHAR(20) FK NULL | references `fbr_return_heads`. Empty until the accountant supplies the mapping |
| normal_balance | ENUM | `debit`, `credit`. Contra accounts such as 1219 and 1229 are credit despite being assets |
| is_header | BOOL | grouping only, never posted to by any path |
| is_system | BOOL | system accounts cannot be renamed or deactivated |
| allow_manual_posting | BOOL | false for control accounts like receivables |
| is_active | BOOL | |

Full seed, codes, and worked posting examples are in
`docs/CHART-OF-ACCOUNTS.md`. Structured for the Revised AFRS for Small-Sized
Entities framework that applies to Winibex as a small private company, and
mapped to the heads of the FBR annual return.

---

## Transactions

### transactions
| Column | Type | Notes |
| --- | --- | --- |
| id | BIGINT PK | |
| date | DATE | date of payment, not entry date |
| account_id | BIGINT FK | |
| direction | ENUM | `in`, `out` |
| amount | BIGINT | PKR paisa |
| currency, foreign_amount, fx_rate | see above | |
| method | ENUM | `cash`, `account`, `cheque`, `online` |
| description | VARCHAR(255) | |
| category_id | BIGINT FK | |
| client_id | BIGINT FK NULL | |
| project_id | BIGINT FK NULL | |
| is_rebillable | BOOL | client pays this back |
| rebilled_invoice_id | BIGINT NULL | set once recovered |
| fund_source | ENUM | `operations`, `investor` |
| paid_by_type | ENUM | `company`, `person` |
| paid_by_user_id | BIGINT NULL | set when a person paid personally |
| received_by_user_id | BIGINT NULL | set when money landed with a person |
| vendor_id | BIGINT FK NULL | who was paid, for withholding and statements |
| cheque_id | BIGINT FK NULL | links to the cheque register |
| gross_amount, tax_total, charges_total | BIGINT | see Money and currency |
| reference | VARCHAR(50) NULL | cheque or voucher number |
| transfer_group_id | CHAR(36) NULL | links the two legs of a transfer |
| status | ENUM | `draft`, `pending`, `posted`, `rejected`, `reversed` |
| entry_type | ENUM | `normal`, `opening`, `historical`. See Opening entry and history |
| rejection_reason | VARCHAR(255) NULL | |
| reversal_of_id | BIGINT NULL | this entry reverses that one |
| reversed_by_id | BIGINT NULL | that entry reverses this one |
| reversal_reason | VARCHAR(255) NULL | required when reversing |
| created_by, approved_by | BIGINT FK | |
| posted_at | TIMESTAMP NULL | |
| approval_method | ENUM NULL | `owner`, `admin`, `auto`. How it reached posted |
| possible_self_approval | BOOL | silent marker, see Permissions rule 4 |
| created_at, updated_at | TIMESTAMP | |

### Lifecycle

```
draft  →  pending  →  posted  →  reversed
  ↑          ↓
  └──────  rejected
```

- `draft` is editable by its creator
- `pending` is awaiting admin approval, editable only back to draft
- `posted` is **immutable for everyone, including admin**. No update statement
  may touch a posted row's money fields. Enforced in the service layer and by
  a database trigger
- `reversed` means a reversing entry exists. Both rows stay visible and link to
  each other

Only `posted` rows affect a balance. `draft` and `pending` are visible but
excluded from every balance, report and export.

A correction is never an edit. It is a reversing entry of equal and opposite
value plus a new correct entry. `reversal_reason` is required and appears in
the ledger.

A transfer between accounts is two rows sharing `transfer_group_id`: one `out`
on the source, one `in` on the destination. Never a single row.

### Opening entry and history

The books go live on 1 July 2026 (`books_live_from`). History from March 2025
is entered gradually afterwards.

- **Opening entry.** One journal entry dated 2026-07-01, `entry_type = opening`,
  holding each account's real balance on 30 June 2026: bank per statement,
  cash, petty cash, open receivables, the director loan, payables. The balancing
  figure goes to 3400 Opening balance equity
- **Live entries.** Dated on or after 2026-07-01, `entry_type = normal`. They
  count in every balance and report
- **Historical entries.** Any entry dated before 2026-07-01 is automatically
  `entry_type = historical`. While `history_merged` is false they are excluded
  from live balances and current-year reports, because the opening entry
  already contains their effect. They appear only in reports for periods
  before 2026-07-01
- **Merge check.** Compares, account by account, the historical closing
  balances at 2026-06-30 with the opening entry. Any difference points to
  history that is still missing or wrong
- **Merge.** Allowed only when every difference is zero. The opening entry is
  reversed with the reason "history merged", `history_merged` becomes true,
  and historical entries count from then on. 3400 must end at zero

No posted row is edited at any point. Inclusion of history is decided by the
setting, not by changing rows.

### journal_lines
| Column | Type |
| --- | --- |
| id | BIGINT PK |
| transaction_id | BIGINT FK |
| coa_id | BIGINT FK |
| debit | BIGINT |
| credit | BIGINT |

Written by the API, never by the UI. Sum of debits must equal sum of credits
per transaction or the insert rolls back.

### taxes
Odoo-style tax records. Rates are data with effective dates, never code,
because Pakistan rates change every budget.

| Column | Type | Notes |
| --- | --- | --- |
| id, name | | "Section 154A IT export final tax" |
| short_code | VARCHAR(20) | shown on documents |
| authority | ENUM | `fbr`, `pra`, `srb`, `ict`, `bank`, `other` |
| law_reference | VARCHAR(50) | "ITO 2001 s.154A" |
| kind | ENUM | `withholding`, `final`, `advance`, `sales_tax`, `fed`, `other` |
| applies_to | ENUM | `sales`, `purchases`, `both` |
| computation | ENUM | `percent`, `fixed` |
| rate_atl | DECIMAL(9,4) | |
| rate_non_atl | DECIMAL(9,4) | |
| status_basis | ENUM | `company` when deducted from Winibex, `counterparty` when Winibex deducts |
| return_section | VARCHAR(20) | section code used in the s.165 statement |
| is_inclusive | BOOL | price already includes it |
| is_adjustable | BOOL | advance tax creditable later versus a final cost |
| coa_id | BIGINT FK | where it posts |
| effective_from, effective_to | DATE | |
| is_active | BOOL | |
| notes | TEXT | conditions such as PSEB or ATL |

Seed values and sources are in `docs/TAXES.md`.

### tax_rules
Which taxes the entry form suggests for which situation.

| Column | Type |
| --- | --- |
| id, name, tax_id, direction, currency_is_foreign BOOL NULL, account_type NULL, category_id NULL, client_country NULL, priority |

### transaction_taxes
| Column | Type | Notes |
| --- | --- | --- |
| id, transaction_id, tax_id | | |
| base_amount | BIGINT | PKR |
| rate_applied | DECIMAL(9,4) | snapshot, so later rate changes do not alter history |
| atl_status_used | ENUM | `atl`, `non_atl`. Snapshot of the status the rate was based on |
| atl_party | ENUM | `company`, `vendor`, `client`, `employee`, `cardholder` |
| statement_id | BIGINT NULL | set once included in a filed s.165 statement |
| tax_amount | BIGINT | PKR |
| is_override | BOOL | user changed it from the configured rate |
| deducted_by | ENUM | `bank`, `customer`, `us`, `platform` |

### transaction_charges
Non-tax deductions.

| Column | Type | Notes |
| --- | --- | --- |
| id, transaction_id | | |
| type | ENUM | `bank_charge`, `forex_fee`, `platform_fee`, `card_fee`, `other` |
| amount | BIGINT | PKR |
| coa_id | BIGINT FK | |
| note | VARCHAR(255) | |

### reimbursements
When a person pays for company spending personally, the company owes them.
This clears that debt.

| Column | Type | Notes |
| --- | --- | --- |
| id, person_user_id | | |
| transaction_id | | the payment back to the person |
| amount | BIGINT | |

### reimbursement_items
| Column | Type |
| --- | --- |
| id, reimbursement_id, covered_transaction_id, amount |

The amount owed to each person is computed, never stored: their personally
paid posted transactions minus reimbursements.

### idempotency_keys
| Column | Type | Notes |
| --- | --- | --- |
| idempotency_key | CHAR(36) PK | from the client. Named `idempotency_key`, not `key`, which is reserved |
| user_id, endpoint | | |
| response_json | JSON | returned on repeat. Text on MariaDB, so stringify and parse |
| created_at | TIMESTAMP | purged after 24 hours, the one table that is purged |

### attachments
| Column | Type |
| --- | --- |
| id, transaction_id NULL, document_type, file_path, mime, size_bytes, sha256, uploaded_by, created_at, retain_until |

`document_type`: `receipt`, `bank_advice`, `bank_statement`, `tax_certificate`,
`invoice_received`, `contract`, `other`. `retain_until` is at least ten
financial years after the entry date. Files on disk, not in the database.

### audit_log
| Column | Type |
| --- | --- |
| id, user_id, table_name, record_id, action, before_json, after_json, ip, created_at |

Every insert, update, status change on money tables. Append only.
`before_json` and `after_json` are JSON columns, which on MariaDB are text.
The audit helper stringifies on write and parses on read.

### entry_flags
Validation findings attached to a transaction. Warnings and flags live here so
they can be reviewed later rather than only shown once at entry time.

| Column | Type | Notes |
| --- | --- | --- |
| id, transaction_id | | |
| severity | ENUM | `warning`, `flag` |
| code | VARCHAR(50) | `possible_duplicate`, `no_receipt`, `unusual_amount`, `closed_client`, `backdated`, `thin_description` |
| detail | VARCHAR(255) | includes the matched record where relevant |
| acknowledged_by | BIGINT NULL | |
| acknowledged_at | TIMESTAMP NULL | |
| resolved | BOOL | |

Blocking rules are not stored here. They prevent the insert entirely:
unbalanced journal lines, missing category or account, zero or negative amount,
future date, a payment with no linked cash transaction, any write to a posted
row.

### period_locks
Built now, unused for the moment. Locking is off by default so months stay
open, which is safe because posted entries are already immutable. This exists
so enabling it later is a settings change, not a migration.

| Column | Type | Notes |
| --- | --- | --- |
| id, period_month, period_year | | |
| locked_by, locked_at | | |
| note | VARCHAR(255) | |

### sequences
Gapless numbering for journal entries and invoices. A gap in a numbered series
is the first thing an auditor asks about.

| Column | Type | Notes |
| --- | --- | --- |
| name | VARCHAR(50) PK | `journal`, `invoice`, `quotation`, `receipt`, `voucher` |
| prefix | VARCHAR(10) | |
| next_value | BIGINT | allocated inside the same DB transaction as the insert |

Allocation is `SELECT ... FOR UPDATE` inside the caller's transaction, so a
rolled-back caller leaves the counter untouched. MariaDB's native SEQUENCE
objects are deliberately not used: they allocate outside the transaction and
would leave gaps.

---

### vendors
Anyone Winibex pays other than employees: contractors, freelancers,
suppliers, platforms. Required for withholding and the s.165 statement.

| Column | Type | Notes |
| --- | --- | --- |
| id, name | | |
| kind | ENUM | `company`, `aop`, `individual`, `foreign` |
| ntn, cnic | VARCHAR NULL | at least one required for local payees before withholding |
| strn | VARCHAR NULL | |
| atl_status | ENUM | `atl`, `non_atl`, `unknown` |
| atl_checked_on | DATE NULL | warn if older than 30 days at payment time |
| default_tax_id | BIGINT NULL | |
| country, email, phone | | |
| is_active | BOOL | |

---

## Tax compliance

### withholding_certificates
Proof of tax a client withheld from Winibex. Without it, the credit in 1142
cannot be claimed.

| Column | Type |
| --- | --- |
| id, client_id, transaction_id, tax_section, tax_amount, certificate_number, certificate_date, received_date, attachment_id |

### withholding_statements
The quarterly s.165 statement of tax Winibex deducted.

| Column | Type | Notes |
| --- | --- | --- |
| id, period_quarter, period_year | | |
| due_date | DATE | 20 Oct, 20 Jan, 20 Apr, 20 Jul |
| status | ENUM | `draft`, `filed` |
| filed_on, filing_reference | NULL | |
| is_nil | BOOL | a nil statement is still compulsory |

### fbr_return_heads
| Column | Type | Notes |
| --- | --- | --- |
| code | VARCHAR(20) PK | return line code |
| name | VARCHAR(200) | |
| schedule | VARCHAR(100) | |
| tax_year_from, tax_year_to | INT | return formats change |

---

## Banking

### cheques
| Column | Type | Notes |
| --- | --- | --- |
| id, account_id, cheque_number | | UNIQUE (account_id, cheque_number) |
| payee, amount, issue_date | | |
| status | ENUM | `issued`, `presented`, `cleared`, `bounced`, `cancelled` |
| cleared_on | DATE NULL | |
| transaction_id | BIGINT NULL | |

### bank_statement_lines
Imported from the bank's CSV.

| Column | Type |
| --- | --- |
| id, account_id, import_batch_id, line_date, description, reference, debit, credit, running_balance, matched_transaction_id NULL, status (`unmatched`, `matched`, `ignored`) |

### bank_reconciliations
| Column | Type |
| --- | --- |
| id, account_id, statement_date, statement_balance, book_balance, difference, reconciled_by, reconciled_at, notes |

---

## Assets and advances

### fixed_assets
| Column | Type | Notes |
| --- | --- | --- |
| id, name, coa_id | | |
| purchase_date, cost, salvage_value | | |
| useful_life_months | INT | |
| method | ENUM | `straight_line`, `reducing_balance` |
| purchase_transaction_id | | |
| disposal_date, disposal_proceeds | NULL | |

Accumulated depreciation is computed from posted depreciation entries, never
stored.

### depreciation_runs
| Column | Type |
| --- | --- |
| id, period_month, period_year, transaction_id, posted_by, posted_at |

### employee_advances
| Column | Type | Notes |
| --- | --- | --- |
| id, employee_id, transaction_id | | |
| amount, date | | |
| monthly_recovery | BIGINT | deducted through payroll |
| status | ENUM | `open`, `recovered`, `written_off` |

Balance is computed from the advance and its payroll recoveries.

---

## Foreign exchange

### fx_revaluations
Open foreign receivables and payables revalued at the closing rate at each
reporting date. Reversed on the first day of the next period, so settlement
posts the real gain or loss.

| Column | Type |
| --- | --- |
| id, revaluation_date, source_table, source_id, currency, foreign_amount, original_pkr, closing_rate, revalued_pkr, difference, transaction_id, reversal_transaction_id |

---

## Clients

### clients
| Column | Type | Notes |
| --- | --- | --- |
| id, name | | |
| contact_name, email, phone, country | | |
| status | ENUM | `active`, `on_call`, `paused`, `closed` |
| source | ENUM | `upwork`, `local`, `referral`, `other` |
| default_rebillable | BOOL | default for new spend on this client |
| closed_date | DATE NULL | |
| notes | TEXT | |

Closed clients keep full history. Never delete.

### projects
| Column | Type | Notes |
| --- | --- | --- |
| id, client_id, name | | |
| billing_type | ENUM | `fixed`, `retainer`, `hourly` |
| rate | BIGINT NULL | fixed price, monthly, or hourly rate |
| currency | CHAR(3) | |
| status | ENUM | `active`, `paused`, `completed`, `cancelled` |
| start_date, end_date | DATE | |

### time_entries
For hourly clients like Oil Ninja.

| Column | Type |
| --- | --- |
| id, project_id, user_id, date, hours DECIMAL(5,2), note, invoiced_id NULL |

---

## Upwork and partner splits

### earning_accounts
Any external profile money arrives through.

| Column | Type | Notes |
| --- | --- | --- |
| id, label | | "Jake profile", "Fazal profile" |
| platform | ENUM | `upwork`, `fiverr`, `other` |
| owner_name | VARCHAR(100) | whose ID it is |
| split_percent | DECIMAL(5,2) | partner's share, Jake is 50.00 |
| deposit_account_id | BIGINT FK | where the net lands |
| is_active | BOOL | |

### earning_receipts
| Column | Type | Notes |
| --- | --- | --- |
| id, earning_account_id, transaction_id | | |
| gross_amount | BIGINT | what the client paid |
| platform_fee | BIGINT | Upwork's cut |
| partner_share | BIGINT | what the ID owner took |
| net_amount | BIGINT | what reached Winibex |
| project_id | BIGINT NULL | |

The spreadsheet records only `net_amount`, so the partner share is currently
invisible. This table makes it a real cost that appears in reports.

---

## Invoices

### invoices
| Column | Type | Notes |
| --- | --- | --- |
| id, invoice_number VARCHAR(20) UNIQUE | | continues 5026 |
| client_id, project_id NULL | | |
| issue_date, due_date | DATE | |
| credit_terms_days | INT | |
| currency | CHAR(3) | |
| subtotal, tax, total | BIGINT | invoice currency |
| amount_paid | BIGINT | invoice currency |
| status | ENUM | `draft`, `sent`, `partial`, `paid`, `overdue`, `void` |
| notes | TEXT | |

`balance_due` is computed, not stored. Status is derived from payments and
due date, never set by hand.

### invoice_items
| Column | Type |
| --- | --- |
| id, invoice_id, description, quantity DECIMAL(10,2), unit_price BIGINT, amount BIGINT |

### invoice_payments
| Column | Type | Notes |
| --- | --- | --- |
| id, invoice_id, transaction_id | | must link to a real deposit |
| date | DATE | |
| amount_foreign, amount_pkr, fx_rate | | |

A payment with no `transaction_id` is not allowed. This is what keeps
receivables and cash from disagreeing.

## Documents

### quotations
| Column | Type | Notes |
| --- | --- | --- |
| id, quotation_number | | from `sequences` |
| client_id, project_id NULL | | |
| issue_date, valid_until | DATE | |
| currency | CHAR(3) | |
| subtotal, tax_total, total | BIGINT | |
| status | ENUM | `draft`, `sent`, `accepted`, `declined`, `expired`, `converted` |
| converted_invoice_id | BIGINT NULL | |
| notes, terms | TEXT | |

### quotation_items
Same shape as `invoice_items`.

### invoice_taxes
Same shape as `transaction_taxes`, against `invoice_id`.

### payment_receipts
Issued to a client after payment.

| Column | Type |
| --- | --- |
| id, receipt_number, invoice_payment_id NULL, transaction_id, client_id, issued_date, issued_by |

### generated_documents
Every PDF the system produces, kept for re-download and audit.

| Column | Type | Notes |
| --- | --- | --- |
| id, doc_type | | `quotation`, `invoice`, `receipt`, `voucher`, `salary_slip`, `statement` |
| doc_number | VARCHAR(30) | |
| source_table, source_id | | |
| version | INT | regenerations increment, old files kept |
| file_path | VARCHAR(255) | |
| generated_by, generated_at | | |
| sent_to, sent_at | NULL | |
| source_data_json | JSON | exact data the PDF was built from. Text on MariaDB |
| sha256 | CHAR(64) | of the PDF file |

---

## Payroll

### employees
| Column | Type | Notes |
| --- | --- | --- |
| id, user_id NULL, name, designation | | |
| join_date, exit_date NULL | DATE | Adeen: exit 2026-08-31 |
| is_active | BOOL | |

### salary_history
| Column | Type | Notes |
| --- | --- | --- |
| id, employee_id, monthly_amount BIGINT, effective_from DATE, note | | increments |

Never overwrite a salary. Add a row with a new `effective_from`.

### payroll_runs
| Column | Type | Notes |
| --- | --- | --- |
| id, period_month, period_year | | |
| status | ENUM | `draft`, `approved`, `paid` |
| total_gross, total_tax, total_net | BIGINT | |
| created_by, approved_by, approved_at | | |

### payroll_lines
| Column | Type |
| --- | --- |
| id, payroll_run_id, employee_id, gross, tax_deduction, net, transaction_id NULL |

---

## Recurring costs

### recurring_costs
| Column | Type | Notes |
| --- | --- | --- |
| id, name, vendor | | "Claude", "Odoo", "USA number" |
| estimated_amount | BIGINT | actual confirmed on payment |
| currency | CHAR(3) | |
| cycle | ENUM | `monthly`, `quarterly`, `yearly` |
| next_due_date | DATE | |
| account_id, category_id | FK | |
| is_active | BOOL | paused tools stay for history |

### recurring_instances
| Column | Type | Notes |
| --- | --- | --- |
| id, recurring_cost_id, due_date | | |
| status | ENUM | `pending`, `confirmed`, `skipped` |
| transaction_id | BIGINT NULL | set on confirm |

A daily cron creates instances. Nothing posts to the ledger until confirmed.

---

## Investor funds

### investors
| Column | Type |
| --- | --- |
| id, name, notes |

### investor_transactions
| Column | Type | Notes |
| --- | --- | --- |
| id, investor_id, transaction_id | | |
| type | ENUM | `contribution`, `repayment` |
| amount | BIGINT | |
| date | DATE | |

Contributions post as a liability, not income. Hammad Malik's 100,000 and
500,000 are debts the company owes, and the Balance Sheet must show that.

---

## Permissions

| Role | Who | Approve | Own entries | Other rights |
| --- | --- | --- | --- | --- |
| owner | winibexoffice account, exactly one, shared by Ahmad and Maryam | Any amount | Auto-post | Settings, users, roles, payroll visibility, plus everything an admin can do |
| admin | Named logins the owner adds later, any number | Any amount, or up to `approval_limit` if set | Auto-post if `auto_approve_own` | Everything except users and settings |
| staff | Personal logins: Maryam, Fazal, and Ahmad once the build is done | None | Need an admin or the owner to approve | Submit, see own submissions |

There is no separate approver role. Only admins and the owner approve.

Rules enforced in the service layer:

1. Nobody approves their own entry under the same login. The owner and admins
   with `auto_approve_own` post their own entries directly, recorded as
   `approval_method = auto`
2. Every staff entry needs the owner or an admin, at any amount
3. An admin's `approval_limit`, if set, is checked against the entry's PKR
   `amount`. Null means unlimited
4. When the owner login approves an entry created by a user marked
   `shares_owner_login`, the transaction gets `possible_self_approval = true`.
   A silent record, no review queue. It exists because Maryam can enter under
   her personal login and approve under the shared one
5. Every change to a role, limit or auto-approve flag is audit-logged and only
   the owner can make it

## Migrations

One migration per phase, applied in order through phpMyAdmin and recorded in
`schema_migrations`. A table arrives in the migration of the phase that first
uses it, so the accountant's review can still change tax and chart tables
before they exist.

| Migration | Contents |
| --- | --- |
| 001 | users, refresh_tokens, settings, company_profile, currencies, chart_of_accounts, fbr_return_heads, categories, accounts, sequences, audit_log, idempotency_keys, schema_migrations |
| 002 | transactions and everything Phase 1 needs, plus the posted-row immutability trigger |
| Later | one per phase |

Every migration file is plain SQL, numbered, idempotent where it can be, and
records itself in `schema_migrations` as its last statement. Tables are created
`ENGINE = InnoDB` with `utf8mb4` and `utf8mb4_uca1400_ai_ci`.

## Retention

Companies Act 2017 section 220 requires books of account and vouchers to be
kept for at least ten financial years, and electronic books must be
reproducible in hard copy. Therefore:

- No job ever deletes from `transactions`, `journal_lines`, `audit_log`,
  `attachments` or any table holding money
- Every report and ledger exports to PDF, CSV and Excel
- Backups are retained long enough to cover the ten years

## Indexes

InnoDB automatically indexes every foreign key column. These are added on top,
for the queries the app actually runs:

| Table | Index |
| --- | --- |
| transactions | (account_id, status, date) |
| transactions | (client_id, date) |
| transactions | (status, created_at) for the approval inbox |
| transactions | (date) |
| journal_lines | (coa_id, transaction_id) |
| audit_log | (table_name, record_id, created_at) |
| entry_flags | (resolved, severity) |
| transaction_taxes | (tax_id, statement_id) |
| invoices | (client_id, status, due_date) |
| bank_statement_lines | (account_id, status, line_date) |
| idempotency_keys | (created_at) for expiry |

`idempotency_keys.idempotency_key` is the primary key, so it needs no separate
unique index.

## Constraints

MariaDB 11.8 enforces CHECK constraints. Proved against the real engine in
step 0.1 rather than assumed.

- `journal_lines`: `debit >= 0 AND credit >= 0 AND (debit = 0 OR credit = 0) AND (debit > 0 OR credit > 0)`
- `transactions`: `amount > 0`, `gross_amount > 0`
- `transaction_taxes`: `tax_amount >= 0`, `rate_applied >= 0`
- `invoice_payments`: `amount_pkr > 0`
- UNIQUE on `invoices.invoice_number`, `quotations.quotation_number`,
  `payment_receipts.receipt_number`, `cheques (account_id, cheque_number)`

## Open questions

Flagged, not decided.

1. Invoice numbering: continue from 5026, or restart with a year prefix
2. Email invoices from the system, or download and send manually
3. Whether petty cash below a threshold skips approval
4. Whether to store per-client default categories
5. ~~Import timing~~ Answered by decision 037: books go live 2026-07-01,
   history entered afterwards and merged when it reconciles
6. Whether partner share on earning accounts is a cost of services or a
   reduction of revenue. Accountant to decide, the schema supports either
