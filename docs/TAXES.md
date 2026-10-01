# Taxes

Status: Verified for tax year 2027 (1 July 2026 to 30 June 2027) against the
FBR Withholding Tax Rate Card for tax year 2027, titled "updated up to June 30,
2026 as per Finance Act, 2026", and secondary sources. The accountant still
signs off before seeding.

## Company status

| Setting | Value | Effect |
| --- | --- | --- |
| `pseb_registered` | true, confirmed by Ahmad | Section 154A at 0.25% on IT export receipts |
| `atl_status` | active, confirmed by Ahmad | Filer rates on tax deducted from Winibex |
| `pra_registered` | false, confirmed by Ahmad | Winibex does not currently charge PRA sales tax |
| Paid-up capital | up to PKR 1 million | See audit note in `CHART-OF-ACCOUNTS.md` |

## Principles

1. Rates are data in the `taxes` table with effective dates. Never code
2. Every tax carries two rates, ATL and non-ATL
3. **Whose ATL status decides the rate depends on who is deducting.**
   When a bank or client deducts from Winibex, Winibex's status applies.
   When Winibex deducts from a vendor or contractor, the vendor's status
   applies, checked on the payment date
4. The system suggests. The user confirms. What was actually deducted wins
5. Each transaction snapshots the rate used and the ATL status it was based on

---

## Taxes deducted from Winibex

### Section 154A, IT export receipts, PSEB registered
| Field | Value |
| --- | --- |
| Kind | Final |
| Rate | 0.25% of proceeds |
| Deducted by | Bank, on inward remittance |
| Posts to | 9100 Final tax |
| Valid | Extended to 30 June 2029 by Finance Act 2026 |
| Conditions | Active PSEB registration, on ATL, approved banking channels |
| Confidence | High |

Fallback if PSEB lapses: 1% of proceeds. The system warns 30 days before the
PSEB certificate expiry date stored in `company_profile`.

### Section 236Y, foreign payments by card
| Field | Value |
| --- | --- |
| Kind | Advance, adjustable |
| Rate | 0.5% ATL, 1% non-ATL, from 1 July 2026. Previously 5% and 10% |
| Deducted by | Bank |
| Confidence | High |

**Belongs to the cardholder.** The bank collects it against the cardholder's
tax number. On a company card it is Winibex's credit (1141). On Ahmad's or
Fazal's personal card it is that person's credit, not the company's. The
company records it as part of the cost and the accountant decides whether it
is reimbursed.

### Section 153(1)(b), services, when a local client withholds
Applies when a Pakistani client that is a withholding agent pays Winibex.
Rate depends on Winibex's ATL status, so the ATL rate applies.

| Service | ATL | Non-ATL | Kind |
| --- | --- | --- | --- |
| IT and IT-enabled services | 4% | 8% | Minimum |

Posts to 1142. Requires a withholding certificate from the client to claim.

---

## Taxes Winibex must deduct from others

As a company, Winibex is a withholding agent from incorporation regardless of
revenue. The rate depends on the payee's ATL status.

### Section 153(1)(b), services, tax year 2027
| Payee provides | ATL | Non-ATL | Kind |
| --- | --- | --- | --- |
| IT and IT-enabled services, by a company or firm | 4% | 8% | Minimum |
| Specified services (listed in the schedule) | 7% | 14% | Minimum |
| Independent software engineers or developers working independently | 15% | 30% | Minimum |
| Other services not listed | 14% | 28% | Minimum |
| Advertising, print and electronic media | 1.5% | 3% | Minimum |

Confidence: High, FBR rate card for tax year 2027.

The independent developer line matters for Winibex: paying an individual
freelance developer is not the 4% IT rate. Accountant to confirm which line
each outsourcing arrangement falls under.

One secondary source states no withholding is required where annual aggregate
payments to a single provider are below PKR 30,000. Medium confidence,
accountant to confirm.

Posts to 2132. Deposited with FBR and reported in the quarterly Section 165
statement.

### Section 149, salaries
Slab based. Phase 4 starts with manual tax per salary line. Accountant
supplies the tax year 2027 slabs.

---

## Sales tax on services, PRA

Winibex is not registered with PRA. For reference only:

| Field | Value |
| --- | --- |
| Standard rate | 16% |
| IT services | 5% reduced rate without input adjustment |
| Confidence | Medium |

Question for the accountant: whether local IT services rendered in Punjab
require Winibex to register with PRA. Exports are outside PRA's scope.

## Corporate income tax on non-export income

The review reported 20% for a small company and 29% otherwise for tax year 2027.
**Not verified.** Most Winibex income is export income under the 154A final
regime, so this mainly affects local revenue. Accountant to confirm the rate and
whether Winibex meets the Income Tax Ordinance definition of a small company.

## Bank charges and FED
Recorded as charged. Posts to 8100.

---

## Tax rules to seed

| Situation | Suggested lines | ATL status used |
| --- | --- | --- |
| Money in, foreign currency, IT revenue | s.154A 0.25% | Winibex |
| Money in, local client, IT services | s.153 IT 4% suffered | Winibex |
| Money out, foreign currency, company card | s.236Y 0.5%, forex fee, FED on fee | Winibex |
| Money out, foreign currency, personal card | s.236Y as charged, posted as cost | Cardholder |
| Money out, local IT company or firm | s.153 IT 4% or 8% withheld | Vendor |
| Money out, individual freelance developer | s.153 independent 15% or 30% withheld | Vendor |
| Salary | s.149 | Employee |

## Compliance outputs the system must produce

| Output | Law | Frequency |
| --- | --- | --- |
| Withholding statement, payee-wise with NTN or CNIC | ITO s.165 | Quarterly: 20 Oct, 20 Jan, 20 Apr, 20 Jul. Nil statement still required |
| Tax deducted summary by section | ITO | Any period |
| Certificates of tax deducted, for payees | ITO | On request |
| Register of certificates received from clients | ITO | Ongoing |

## Questions for the accountant

1. Which s.153 line applies to each outsourcing arrangement, especially
   individual developers
2. Whether s.153 suffered from local clients is minimum tax for Winibex
3. Corporate rate and small company status for non-export income
4. Whether local IT services require PRA registration
5. Salary slabs for s.149
6. Whether the PKR 30,000 annual threshold for s.153 applies
