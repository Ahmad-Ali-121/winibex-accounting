# Chart of Accounts

Status: Proposed. Must be reviewed by the company accountant before seeding.

## Framework

Pakistan has no FBR-mandated chart of accounts. Companies structure their own,
in a way that produces statements under the reporting framework that applies to
them, and that maps cleanly onto the FBR annual income tax return.

Winibex PVT LTD has paid-up capital up to PKR 1 million, confirmed by Ahmad.
That places it well within the small-sized entity limits (paid-up capital not
exceeding PKR 25 million, turnover not exceeding PKR 100 million), so it may use
the Revised AFRS for Small-Sized Entities issued by ICAP, IFRS for SMEs, or full
IFRS. This chart is structured for AFRS for SSEs. The accountant confirms the
choice.

**Audit.** Per SECP guidance, a private company with paid-up capital up to
PKR 1 million that is not a subsidiary of a public company is exempt from
statutory audit. Annual financial statements must still be prepared and
approved by the board, and are signed with an affidavit by the chief executive.
The system therefore still produces full statements every year. If paid-up
capital rises above PKR 1 million, audit applies. The accountant confirms this
against the current text of the Companies Act 2017.

**Retention.** Section 220 of the Companies Act 2017 requires books and vouchers
to be kept for at least ten financial years.

Each account below carries an `fbr_return_head` in the database so the annual
return figures come straight out of the Trial Balance.

## Conventions

- Four-digit codes. First digit is the class
- Headers (ending 00 or 10) are grouping only and never posted to
- Accounts marked **system** cannot be renamed or deactivated
- Accounts marked **control** cannot take manual journal entries. They are
  written only by their own module

| Class | Type | Normal balance |
| --- | --- | --- |
| 1 | Assets | Debit |
| 2 | Liabilities | Credit |
| 3 | Equity | Credit |
| 4 | Income | Credit |
| 5 | Cost of services | Debit |
| 6 | Administrative expenses | Debit |
| 7 | Selling and marketing | Debit |
| 8 | Finance costs and other | Debit |
| 9 | Taxation | Debit |

---

## 1000 Assets

### 1100 Current assets

**1110 Cash and cash equivalents**
| Code | Name | Notes |
| --- | --- | --- |
| 1111 | Cash in hand, office | system |
| 1112 | Petty cash | system |
| 1113 | Bank, Winibex current account | system |
| 1114 | Cheques in hand, uncleared | |
| 1115 | Funds in transit, Fazal | pass-through, system |
| 1116 | Funds in transit, Ahmad | pass-through, system |
| 1117 | Funds held on platforms | Upwork and similar balances not yet withdrawn |
| 1118 | Funds in transit, internal | system, control. Both legs of a transfer between company accounts pass through it, so each leg balances on its own and a half-finished transfer is visible. Returns to zero when both legs post. Decision 053 |

**1120 Trade receivables**
| Code | Name | Notes |
| --- | --- | --- |
| 1121 | Trade receivables, local | control |
| 1122 | Trade receivables, foreign | control |
| 1123 | Rebillable expenses recoverable | control. Rebillable spend sits here, not in expenses |

**1130 Advances, deposits and prepayments**
| Code | Name | Notes |
| --- | --- | --- |
| 1131 | Advances to employees | |
| 1132 | Advances to suppliers | |
| 1133 | Prepaid expenses | annual hosting and domains, released monthly |
| 1134 | Security deposits | |

**1140 Tax assets**
| Code | Name | Notes |
| --- | --- | --- |
| 1141 | Advance income tax, adjustable | card and banking advance taxes |
| 1142 | Income tax withheld by customers | Section 153 deducted by local clients |
| 1143 | Sales tax input, PRA | only where input adjustment is allowed |

### 1200 Non-current assets

**1210 Property and equipment**
| Code | Name | Notes |
| --- | --- | --- |
| 1211 | Computers and IT equipment | the office laptop |
| 1212 | Furniture and fixtures | |
| 1213 | Office equipment | |
| 1219 | Accumulated depreciation | contra, credit balance |

**1220 Intangible assets**
| Code | Name | Notes |
| --- | --- | --- |
| 1221 | Software and licences | perpetual licences only |
| 1222 | Website and domain | |
| 1229 | Accumulated amortisation | contra |

---

## 2000 Liabilities

### 2100 Current liabilities

**2110 Trade and other payables**
| Code | Name | Notes |
| --- | --- | --- |
| 2111 | Payable to suppliers | control |
| 2112 | Payable to contractors | outsourcing |
| 2113 | Accrued expenses | |
| 2114 | Payable to employees, reimbursements | control. "Due to Ahmad" lives here |
| 2115 | Partner share payable | earning account owners such as Jake |

| Code | Name | Notes |
| --- | --- | --- |
| 2120 | Salaries payable | control |
| 2140 | Advances from customers | overpayments and deposits |

**2130 Tax liabilities**
| Code | Name | Notes |
| --- | --- | --- |
| 2131 | Withholding payable, salaries (s.149) | |
| 2132 | Withholding payable, services and suppliers (s.153) | when Winibex withholds from vendors |
| 2133 | Sales tax payable, PRA | |
| 2134 | Income tax payable | |

### 2200 Non-current liabilities
| Code | Name | Notes |
| --- | --- | --- |
| 2210 | Loan from director, Hammad Malik | |
| 2220 | Loans from other investors | |

---

## 3000 Equity

| Code | Name | Notes |
| --- | --- | --- |
| 3100 | Share capital | |
| 3200 | Retained earnings or accumulated loss | |
| 3300 | Current year profit or loss | system, computed |
| 3400 | Opening balance equity | system. Takes the balancing figure of the 1 July 2026 opening entry. Returns to zero when history is merged and the opening entry is reversed |

---

## 4000 Income

| Code | Name | Notes |
| --- | --- | --- |
| 4110 | Software and app development, export | foreign clients |
| 4120 | Digital marketing services, export | |
| 4210 | Website development, local | |
| 4220 | Social media and ads management, local | |
| 4230 | Design services | |
| 4310 | Exchange gain | |
| 4320 | Bank profit | |

Export and local revenue are separate accounts because they are taxed under
different regimes. Mixing them makes the Section 154A claim hard to support.

---

## 5000 Cost of services

| Code | Name | Notes |
| --- | --- | --- |
| 5100 | Outsourcing and subcontractors | |
| 5200 | Client advertising spend, absorbed | rebillable spend goes to 1123 instead |
| 5300 | Project software and tools | tools bought for one client |
| 5400 | Platform fees | Upwork fees and connects |
| 5500 | Partner profit share | see open question below |
| 5600 | Project travel | |

---

## 6000 Administrative expenses

| Code | Name | Notes |
| --- | --- | --- |
| 6100 | Salaries and wages | |
| 6110 | Staff welfare | Eidi, birthday cakes, office food |
| 6200 | Rent and utilities | |
| 6300 | Telecommunication and internet | USA number |
| 6400 | Software subscriptions | Claude, ChatGPT, Canva, Odoo |
| 6410 | Hosting and domains | |
| 6500 | Travelling and conveyance | |
| 6600 | Office supplies, printing and stationery | |
| 6700 | Repairs and maintenance | |
| 6800 | Legal, registration and professional fees | SECP, PSEB, AOP registration |
| 6900 | Entertainment | |
| 6950 | Depreciation and amortisation | system |

## 7000 Selling and marketing

| Code | Name | Notes |
| --- | --- | --- |
| 7100 | Own advertising | Winibex's own ads, not client ads |
| 7200 | Business development | client meetings, event travel |

## 8000 Finance costs and other

| Code | Name | Notes |
| --- | --- | --- |
| 8100 | Bank charges and FED | |
| 8200 | Forex and card fees | |
| 8300 | Exchange loss | |

## 9000 Taxation

| Code | Name | Notes |
| --- | --- | --- |
| 9100 | Final tax, Section 154A | not adjustable, so it is a tax expense |
| 9200 | Current income tax, normal regime | |
| 9300 | Minimum tax | where tax suffered cannot be adjusted |

---

## Worked postings

Illustrative figures only. Rates and tax lines come from `docs/TAXES.md` and
what the bank actually deducted.

### 1a. $20 Claude subscription paid on the company card

Rate 280. Bank deducts Section 236Y at 0.5%, a forex fee, and FED on the fee.

| Account | Debit | Credit |
| --- | --- | --- |
| 6400 Software subscriptions | 5,600 | |
| 8200 Forex and card fees | 280 | |
| 8100 Bank charges and FED | 45 | |
| 1141 Advance income tax, adjustable | 28 | |
| 1113 Bank | | 5,953 |

### 1b. The same subscription paid on Ahmad's personal card

The 236Y advance tax is collected against Ahmad's tax number, so it is his
credit, not the company's. The company books the whole amount as cost.

| Account | Debit | Credit |
| --- | --- | --- |
| 6400 Software subscriptions | 5,600 | |
| 8200 Forex and card fees, including the 236Y not claimable by the company | 308 | |
| 8100 Bank charges and FED | 45 | |
| 2114 Payable to employees (Ahmad) | | 5,953 |

Later, reimbursing Ahmad:

| Account | Debit | Credit |
| --- | --- | --- |
| 2114 Payable to employees (Ahmad) | 5,953 | |
| 1113 Bank | | 5,953 |

Whether the company reimburses the 236Y portion at all, and which expense
account it sits in, is a question for the accountant. Paying recurring tools on
a company card avoids the problem.

### 2. Foreign client pays a $500 invoice into the bank

Rate 278. Bank deducts Section 154A final tax.

| Account | Debit | Credit |
| --- | --- | --- |
| 1113 Bank | 138,652.50 | |
| 9100 Final tax, s.154A | 347.50 | |
| 1122 Trade receivables, foreign | | 139,000 |

### 3. Rebillable ad spend for a client

Spend:
| Account | Debit | Credit |
| --- | --- | --- |
| 1123 Rebillable expenses recoverable | 50,000 | |
| 1113 Bank | | 50,000 |

Invoiced to the client:
| Account | Debit | Credit |
| --- | --- | --- |
| 1121 Trade receivables, local | 50,000 | |
| 1123 Rebillable expenses recoverable | | 50,000 |

Profit is never touched. That is the whole point of rebillable.

### 4. Absorbed ad spend

| Account | Debit | Credit |
| --- | --- | --- |
| 5200 Client advertising spend, absorbed | 50,000 | |
| 1113 Bank | | 50,000 |

### 5. Upwork earning through Jake's ID

Gross converts to PKR 120,000. Upwork fee 10 percent, Jake takes 50 percent of
what remains, the rest lands with Winibex.

| Account | Debit | Credit |
| --- | --- | --- |
| 1113 Bank | 54,000 | |
| 5400 Platform fees | 12,000 | |
| 5500 Partner profit share | 54,000 | |
| 4110 Software and app development, export | | 120,000 |

If Jake has not yet been paid his share, credit 2115 Partner share payable
instead, and settle it later. Today the sheet records only the 54,000, so
66,000 of real cost and the true revenue figure are invisible.

### 6. Investor money in

| Account | Debit | Credit |
| --- | --- | --- |
| 1113 Bank | 500,000 | |
| 2210 Loan from director, Hammad Malik | | 500,000 |

Never income. The Balance Sheet must show the company owes this.

### 7. Monthly salary

| Account | Debit | Credit |
| --- | --- | --- |
| 6100 Salaries and wages | 90,000 | |
| 2131 Withholding payable, salaries | | 0 or as computed |
| 1113 Bank | | 90,000 |

---

### 8. A transfer between two company accounts

PKR 50,000 drawn from the bank into office cash, with a PKR 50 bank fee.
Two entries sharing one `transfer_group_id`, never one.

Out of the bank:
| Account | Debit | Credit |
| --- | --- | --- |
| 1118 Funds in transit, internal | 50,000 | |
| 8100 Bank charges and FED | 50 | |
| 1113 Bank | | 50,050 |

Into office cash:
| Account | Debit | Credit |
| --- | --- | --- |
| 1111 Cash in hand, office | 50,000 | |
| 1118 Funds in transit, internal | | 50,000 |

1118 is back at zero once both legs post. The fee is why the two legs are
allowed to differ: the bank loses 50,050 and the cash tin gains 50,000.

### 9. Paying a local vendor with Section 153 withheld

PKR 100,000 to an IT company on the Active Taxpayers List, 4% withheld.

| Account | Debit | Credit |
| --- | --- | --- |
| 5100 Outsourcing and subcontractors | 100,000 | |
| 2132 Withholding payable, s.153 | | 4,000 |
| 1113 Bank | | 96,000 |

The cost is the full 100,000. Only 96,000 leaves the bank, and the 4,000 is
owed to FBR until it is deposited and reported on the quarterly s.165
statement. This is the posting the old reconciliation rule could not express,
which is why `withheld_total` exists. Decision 052.

## Year-end foreign exchange

Open foreign currency receivables and payables are revalued at the closing rate
on each reporting date. The difference posts to 4310 Exchange gain or 8300
Exchange loss, and reverses on the first day of the next period, so the real
gain or loss posts when the money is actually received. See `fx_revaluations`
in `docs/SCHEMA.md`.

## Questions for the accountant

1. AFRS for SSEs, IFRS for SMEs, or full IFRS
1a. Confirm the audit exemption for paid-up capital up to PKR 1 million
1b. Treatment of 236Y on personal cards, and whether it is reimbursed
1c. Whether a cheque written but not yet cleared should sit in 1114 Cheques in
   hand until it clears, rather than leaving the bank on the day it was
   written. Today it leaves the bank immediately and the cheque register makes
   the uncleared ones visible
2. Partner profit share: a cost of services (5500) or a deduction from revenue
3. Whether Section 153 tax suffered on local receipts is adjustable or minimum
   tax for Winibex in the current year
4. Depreciation method and rates for 1211 to 1213
5. Whether subscriptions paid annually should be prepaid and released monthly
6. The mapping from each account to the FBR return head
