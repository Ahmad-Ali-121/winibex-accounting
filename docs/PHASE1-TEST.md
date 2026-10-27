# Phase 1 test

The full end-to-end test of everything built in Phase 1, with dummy data and
the exact result to expect at every step. First written 2026-10-19. Rewritten
2026-10-26 for the code after the defect fixes (decisions 056 and 057), so
every figure here is what the fixed code produces.

Run it locally first, where a reset takes one minute. Then run it on
production, then reset production before any real entry goes in.

Time: about three hours the first time.

## Files

| File | Where it goes | What it is |
| --- | --- | --- |
| `docs/PHASE1-TEST.md` | repo | this guide |
| `api/scripts/test/phase1-test-seed.sql` | repo | dummy users, TEST taxes, petty cash float |
| `api/scripts/test/phase1-checks.sql` | repo | id lookups, tamper tests, final checks |
| `api/scripts/test/phase1-api-tests.http` | repo | every API-only test, ready to click |
| `api/scripts/test/phase1-reset.sql` | repo | wipes the database after the test |
| `receipt.pdf`, `receipt.jpg`, `notes.txt` | same folder as the .http file | any small PDF, any photo, any text file. Do not commit them |

## What is tested where

The app does not yet have screens for every Phase 1 feature (D15 below). Those
features work on the server and are tested through the `.http` file.

| Feature | Tested in |
| --- | --- |
| Sign in, forced password change | app, Part 2 |
| Dashboard, accounts list | app, Parts 3, 5, 8 |
| Guided entry form, journal preview, warnings dialog, refusals on screen | app, Part 5 |
| Receipt upload, receipt rule | app, Part 5, and API 6.4 |
| Ledger, search, journal panel, edit history | app, Part 8, and API 6.18 |
| Approval inbox, approve, reject, approval limit | app, Part 7 |
| Flags review list, Mark reviewed | app, Part 8 |
| Flags clearing themselves when a receipt arrives | API, Part 8 |
| Opening entry | API, Part 4 |
| Taxes, charges, withholding, vendors | API, Part 6 |
| Transfers, reversal, reimbursements, cheques, petty cash | API, Part 6 |
| History entries, merge check | API, Part 6 |
| Idempotency, permissions | API, Parts 6, 7, 8 |
| Posted entries cannot be changed or deleted | SQL, step 6.20 |
| Trial balance, gapless numbering, flag records | SQL, Part 9 |

## What the fixes changed

The first version of this guide listed fifteen defects. Fourteen are fixed or
settled. Each row says where to see the fix.

| # | Was | Now | Seen at |
| --- | --- | --- | --- |
| D1 | Every entry got a "No receipt" flag | Only money out with no receipt. Money in, transfers, reimbursements, the opening entry and history never carry it | every step, in the "To review" count |
| D2 | A flag could never be cleared | Attaching a receipt clears "No receipt" by itself. The owner or an admin can mark any flag reviewed with a note | 8.7, 8.8 |
| D3 | A refused save or approval showed nothing | The server's reason is shown on screen | 5.6, 5.14 to 5.16, 7.7 |
| D4 | Every admin saw "Save and post" | Only the owner, and admins allowed to post their own entries. Other admins see "Submit for approval" | 7.9, 7.10 |
| D5 | The rate warning never fired | Fires above 5% | 5.9, 6.4a |
| D6 | A transfer with no fee was refused | Goes through | 6.10a |
| D7 | Withholding from a vendor with no NTN or CNIC went through | Refused before anything is saved | 6.8a |
| D8 | A duplicate cheque number answered 500 | 409 with a clear message | 6.12b |
| D9 | Between 00:00 and 05:00 Pakistan time, today counted as the future | Dates are judged in Pakistan time | any time of day |
| D10 | The form did not reset after saving | Starts again at step 1 with a new key | 5.1 onward |
| D11 | In and Out this month counted transfers, reversals and personal-card costs | Only money that entered or left the company's accounts. Decision 057 | every checkpoint |
| D12 | The journal panel had blank codes and names | Each line shows its code and name | 6.7d, 8.4 |
| D13 | UI-GUIDE asked for receipts the code did not require | Decision 055 kept. UI-GUIDE corrected | 5.7, 5.8 |
| D14 | The unusual-amount warning could answer 500 on a fractional average | Fixed. Covered by an API test, not reachable with this guide's numbers | none |
| D15 | Opening entry, transfers, reversal, reimbursements, people balances, vendors, cheques, tax and charge lines on the form, petty cash status, history merge, adding users, editing a draft, resubmitting a rejected entry have no screen. The form offers USD only as a foreign currency | Still open. Planned after this test | Part 6 |

One limit remains, by design for now: the D7 check runs only when a vendor
is named on the entry.

Correction, 2026-10-27: this guide once said a changed entry after a refused
posting is refused by the server. It was not; it was posted with the old
figures (F7). Fixed in decision 059: the app now edits the draft it already
created, and the server refuses a key reused with different content.

If a step behaves differently from what is written here, that is a new
finding. Note the step number and what you saw.

## Checkpoints

The figures the app must show at each checkpoint, in PKR.

| After | Winibex bank | Office cash | Petty cash | Total held | In this month | Out this month | To review |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Part 3 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 | none |
| Part 4 | 500,000.00 | 50,000.00 | 10,000.00 | 560,000.00 | 0.00 | 0.00 | none |
| Part 5 | 787,150.00 | 38,100.00 | 9,700.00 | 834,950.00 | 320,250.00 | 42,800.00 | 10 |
| Part 6 | 427,147.00 | 35,147.00 | 13,900.00 | 476,194.00 | 170,250.00 | 251,556.00 | 13 |
| Part 7 | 415,147.00 | 35,147.00 | 10,100.00 | 460,394.00 | 170,250.00 | 267,356.00 | 17 |
| Part 8 | 415,147.00 | 35,147.00 | 10,100.00 | 460,394.00 | 170,250.00 | 267,356.00 | 15 |

Every other account (pass-through, cheques, platforms) stays at 0.00
throughout.

How to check In and Out yourself: the opening entry and the Careem rides are
dated July, so the company held 557,500.00 at the start of the test month.
Cash at the start of the month, plus In, minus Out, always equals Total held.
After Part 7: 557,500 + 170,250 - 267,356 = 460,394.

This only holds if the whole test runs in one month other than July 2026.

---

## Part 1. Setup

**1.1 Pick a day.** Do Parts 4 to 9 on one calendar day. Several checks look
for entries "within three days" and "this month", so splitting across days or
months changes the numbers. The day must be 9 October 2026 or later, so that
10 July is more than 90 days back (step 5.17). Any time of day works now (D9).

**1.2 Start the system.**

Local, three PowerShell windows:

```powershell
# Window 1, database, from the repo root
cd C:\Users\ahmad\Desktop\winibex-accounting
docker compose down -v
docker compose up -d
docker compose exec mariadb mariadb-admin ping -uroot -pwinibex_root_local --wait=60 --silent
cd api
npm run migrate:up

# Window 2, API
cd C:\Users\ahmad\Desktop\winibex-accounting\api
npm run dev

# Window 3, app. Port 8080 exactly, or CORS refuses every request.
cd C:\Users\ahmad\Desktop\winibex-accounting\app
flutter run -d chrome --web-port=8080
```

`docker compose down -v` starts you from an empty database. That is the point.
`migrate:up` must list six migrations, 000 to 005.

Production: nothing to start. App at https://accounting.winibex.com, API at
https://api-accounting.winibex.com. Before the test, migration 005 must be
applied in phpMyAdmin and the fixed code pushed, in that order (PROGRESS.md).
Check with `SELECT * FROM schema_migrations;`: six rows.

**1.3 Put the files in place.** Copy the four test files into
`api/scripts/test/`. Put `receipt.pdf`, `receipt.jpg` and `notes.txt` in the
same folder. Keep the receipt files under 10 MB.

**1.4 Install REST Client.** In VS Code, Extensions, search "REST Client" by
Huachao Mao, install. Open `phase1-api-tests.http`. A "Send Request" link
appears above each request.

**1.5 Load the dummy data.**

Local: open `phase1-test-seed.sql`, remove the two dashes at the start of the
last line (the owner password line), save. Then:

```powershell
cd C:\Users\ahmad\Desktop\winibex-accounting
Get-Content api\scripts\test\phase1-test-seed.sql | docker compose exec -T mariadb mariadb -uroot -pwinibex_root_local winibex
```

No output means it worked. The local owner password is now
`Winibex-Test-2026`.

Production: in hPanel open phpMyAdmin, pick the accounting database, SQL tab,
paste `phase1-test-seed.sql` exactly as delivered (last line still commented
out), Go. Expect "3 rows inserted" for users and 1 row for each tax and rule.
Then run this on its own, which is also pending item 4 in PROGRESS.md:

```sql
UPDATE users SET must_change_password = 1 WHERE role = 'owner';
```

**1.6 Look up the ids.** Run Section A of `phase1-checks.sql`.

Local, open a database shell and paste the queries one at a time:

```powershell
docker compose exec mariadb mariadb -uroot -pwinibex_root_local winibex
```

Production: phpMyAdmin, SQL tab.

Copy each id into the settings block at the top of `phase1-api-tests.http`:

| Variable | From | Row |
| --- | --- | --- |
| `@bankId` | A1 | Winibex bank, code 1113 |
| `@cashId` | A1 | Office cash, code 1111 |
| `@pettyId` | A1 | Petty cash, code 1112 |
| `@cat5100` `@cat6200` `@cat6400` `@cat6600` | A2 | the money-out category on that code |
| `@coa8100` `@coa8200` | A3 | the chart_of_accounts id, not the code |
| `@staffId` | A4 | Test Staff |
| `@tax236y` `@tax153` | A5 | TEST-236Y and TEST-153 |

Also set `@api` (local or production), `@today` (the test day, YYYY-MM-DD)
and `@ownerPassword` (the password you will set in step 2.8).

A6 must list three rules. If "TEST outsourcing withholding" is missing, there
is no money-out category on 5100; steps 6.6b and 6.6c will then return an
empty suggestion list, and nothing else changes.

While you are in A2, note which categories exist for 4110, 4210, 5200, 6110,
6410, 6500 and 6700. The app steps use them. If one is missing, use any other
category of the same direction and carry on: account balances do not depend
on the category, though the "Unusual amount" warning in 5.4 does.

**1.7 DevTools, for anything odd.** Refusals now show on screen. If something
does not match this guide, press F12 in Chrome, open the Network tab, type
`api` in the filter box, click the request and open Response. You will see
`{ "error": { "code": ..., "message": ... } }`. Send that with your report.

---

## Part 2. Sign in and password (app)

| Step | Do | Expect |
| --- | --- | --- |
| 2.1 | Open the app | Sign-in screen |
| 2.2 | `winibexoffice@gmail.com` with a wrong password | "That email or password is not right." |
| 2.3 | Correct owner password (local: `Winibex-Test-2026`) | "Set a new password" screen: "This account still uses its first password. Choose a new one to continue." No way past it to the dashboard |
| 2.4 | New password `Short-123` (9 characters) in both boxes | "Use at least 10 characters." |
| 2.5 | New `Winibex-Owner-2026`, confirm `Winibex-Owner-2027` | "The two passwords do not match." |
| 2.6 | Current password wrong, new password valid in both boxes | "Your current password is not right." |
| 2.7 | New password the same as the current one | "The new password must be different from the old one." |
| 2.8 | Correct current, a new password of 10 or more characters, same in both | "Password changed." and the dashboard opens. Put this password in `@ownerPassword` |
| 2.9 | Sign out (icon top right), sign in with the new password | Dashboard opens directly, no forced change |
| 2.10 | Press F5 | Still signed in |

The login rate limit is tested in step 8.11, at the end, because it locks the
Test Staff login for 15 minutes.

---

## Part 3. The empty system (app, owner)

| Step | Screen | Expect |
| --- | --- | --- |
| 3.1 | Dashboard ("Overview") | Cash the company holds PKR 0.00. In this month PKR 0.00. Out this month PKR 0.00. No "waiting for approval" tile, no "to review" tile. The note "From 1 July 2026 onward. Earlier entries are excluded until history is checked." |
| 3.2 | Accounts | Every account PKR 0.00, each with its ledger code (Winibex bank 1113, Office cash 1111, Petty cash 1112). Total held PKR 0.00. The notice "These balances start from 1 July 2026..." |
| 3.3 | Transactions | "Nothing here yet" |
| 3.4 | Approvals | "Nothing waiting" |
| 3.5 | To review | "Nothing to review" |
| 3.6 | Theme icon top right | Switches light and dark. Both readable |

Clients, Invoices, Payroll, Recurring, Reports and Settings are placeholders
for later phases. Not tested.

---

## Part 4. The opening entry (API)

The books start on 1 July 2026 with every balance as at 30 June. Dummy
figures: bank 500,000, office cash 50,000, petty cash 10,000, director loan
200,000 owed.

In `phase1-api-tests.http` send 0.1 to 0.4, then 4.1 to 4.4. The expected
result is written above each request.

What 4.2 posts, the first journal entry (JV-1):

| Ledger | Debit | Credit |
| --- | --- | --- |
| 1113 Bank | 500,000 | |
| 1111 Cash in hand, office | 50,000 | |
| 1112 Petty cash | 10,000 | |
| 2210 Loan from director | | 200,000 |
| 3400 Opening balance equity | | 360,000 |

3400 is worked out by the system: what the company holds minus what it owes.

**4.5 In the app:**

- Accounts: Winibex bank 500,000.00, Office cash 50,000.00, Petty cash
  10,000.00, Total held 560,000.00
- Dashboard: Cash held 560,000.00. In and Out this month 0.00, because the
  opening entry is not trading. No "to review" tile: the opening entry needs
  no receipt (D1)
- Transactions: one row, "Opening balances at 30 June 2026 (TEST)", dated
  2026-07-01, JV-1

---

## Part 5. Everyday entries (app, owner)

How the form works: six steps. 1 direction and date, 2 amount, 3 account or
person, 4 category, description and the rebillable tick, 5 receipt, 6 review
with the journal preview. The category list shows "name  code"; pick by code.

After "Saved and posted." the form starts again at "Step 1 of 6" with every
field empty (D10). Check that once, after 5.1, then just carry on. When a step
says **leave the form**, click Transactions, then New entry. If the form still
shows the old entry, press F5.

The review step must show the journal lines with both columns equal before
you press the button. The line codes and amounts below are what it must show.

"To review" in the last column is the dashboard count after the step. Only
steps that change it list it.

### 5.1 to 5.4 Small cash spending, then an unusual one

| Step | Enter | Review shows | After Save and post | To review |
| --- | --- | --- | --- | --- |
| 5.1 | Money out, today, Rupees 1,200, Office cash, 6600, "Printer paper and pens", no receipt | 6600 Dr 1,200.00, 1111 Cr 1,200.00 | "Saved and posted." The form is back at Step 1 of 6, empty. Office cash 48,800.00 | 1 |
| 5.2 | Money out, 1,500, Office cash, 6600, "Whiteboard markers and stapler" | 6600 Dr 1,500.00, 1111 Cr 1,500.00 | Office cash 47,300.00 | 2 |
| 5.3 | Money out, 1,800, Office cash, 6600, "Toner refill for office printer" | 6600 Dr 1,800.00, 1111 Cr 1,800.00 | Office cash 45,500.00 | 3 |
| 5.4 | Money out, 4,900, Office cash, 6600, "Office chair cushion and desk organiser" | 6600 Dr 4,900.00, 1111 Cr 4,900.00 | A warnings dialog first, see below | 5 |

Each of these is money out with no receipt, so each gets one "No receipt"
flag. Below 5,000 that is allowed; the flag is how it gets looked at later.

5.4 dialog: "Nothing is wrong with the entry. These are worth a look before it
goes in." and "More than three times the usual for this category, which
averages PKR 1,500 over 3 entries." Press **Save anyway**. "Saved and posted."
Office cash 40,600.00. Two items to review from this one: the confirmed
warning and "No receipt".

### 5.5 A payment with a receipt

Money out, today, 5,600, Winibex bank, 6400, "Claude Pro subscription
October". Step 5: Choose a file, pick `receipt.jpg`; its name and size show.
Review: 6400 Dr 5,600.00, 1113 Cr 5,600.00. Save and post. Bank 494,400.00.
To review stays at 5: the receipt cleared the "No receipt" flag as it arrived.

### 5.6 The receipt rule, and a refusal on screen (stay on the form)

Money out, today, 7,500, Winibex bank, 6410, "Hostinger renewal". Skip the
receipt. Review: 6410 Dr 7,500.00, 1113 Cr 7,500.00. Press Save and post.

A red box appears above the button: "A payment of this size needs a receipt
attached before it can be posted." (D3). The entry exists as a Draft.

Do not change anything else. Press Back to step 5, attach `receipt.pdf`, Next
to review. The red box is gone. Save and post. "Saved and posted." The same
entry posts; the idempotency key makes sure no second draft is made.

Then check Transactions: exactly one "Hostinger renewal" row, no Draft tag.
Bank 486,900.00. To review still 5.

### 5.7 Money in, and a double press

Money in, today, Rupees 150,000, Winibex bank, 4210, "Website project advance
from test client ABC". Review: 1113 Dr 150,000.00, 4210 Cr 150,000.00.

Double-click Save and post, fast. The button greys out while it saves, so the
second click does nothing. "Saved and posted." once. Transactions shows one
"Website project advance" row. Bank 636,900.00.

No receipt is asked for and no flag is raised: money in needs no receipt
(decision 057).

### 5.8 and 5.9 Foreign currency

| Step | Enter | Review shows | After |
| --- | --- | --- | --- |
| 5.8 | Money in, today, Foreign currency, amount in the original currency 500.00, exchange rate 280.50, rupees actually received 140,250, Winibex bank, 4110, "Test export client invoice 1001" | 1113 Dr 140,250.00, 4110 Cr 140,250.00 | Bank 777,150.00 |
| 5.9 | Money in, Foreign currency, 100.00, rate 300, rupees 30,000, Winibex bank, 4110, "Test export client invoice 1002" | 1113 Dr 30,000.00, 4110 Cr 30,000.00 | Warnings dialog, see below |

5.9 dialog: "That rate is 6.95% away from 280.5, used on <today>." (D5). Press
**Save anyway**. Bank 807,150.00. To review 6.

### 5.10 Rebillable spend

Money out, 20,000, Winibex bank, 5200, tick "The client pays this back",
"Meta ads for test client ABC, to rebill", receipt `receipt.jpg`.

Review: **1123 Dr 20,000.00**, 1113 Cr 20,000.00. Not 5200: rebillable spend
waits in 1123 until it is invoiced, so it never touches profit. Save and
post. Bank 787,150.00.

### 5.11 A cost paid on a personal card

Money out, 5,953. At step 3, under "Or someone paid it personally", pick Test
Staff. Category 6400, "ChatGPT Plus on Test Staff personal card", receipt
`receipt.pdf`.

Review: 6400 Dr 5,953.00, **2114 Cr 5,953.00**. Save and post. No company
account moves: Accounts shows the same three balances as after 5.10, and Out
this month does not change either (D11). The company now owes Test Staff
5,953, paid back in step 6.14.

### 5.12 A possible duplicate

Money out, today, 5,600, Winibex bank, 6400, "Claude Pro subscription
October" (exactly as 5.5). Save and post. The dialog lists two warnings,
each naming the entry it matched:

- "Same amount on the same account as JV-6, <today>, Claude Pro
  subscription October."
- "Same description and amount as JV-6, <today>, Claude Pro subscription
  October."

Press **Go back and check**. Nothing is saved. Leave the form. Transactions
still has one Claude Pro row.

### 5.13 A description that says nothing

Money out, 300, Petty cash, 6110, description `tea`. Save and post. It
posts; Petty cash 9,700.00. In Transactions the row carries a flag icon. To
review 8: "Description too short" and "No receipt".

### 5.14 to 5.16 Blocked entries

None of these may save. Each time, a red box above the button shows the
reason (D3). Leave the form after each.

| Step | Enter | Red box says |
| --- | --- | --- |
| 5.14 | Money out, today, 15,000, Petty cash, 6600, "Test overspend petty cash" | "That leaves petty cash below zero. It holds PKR 9,700 today." |
| 5.15 | Date tomorrow, money out, 1,000, Office cash, 6600, "Future dated test" | "An entry cannot be dated in the future." |
| 5.16 | Date 2026-06-15, money out, 1,000, Office cash, 6600, "Before go-live test" | "An entry dated before 2026-07-01 is historical, not a live entry." |

After all three, Transactions has no new rows and To review is still 8.

### 5.17 A backdated entry

Date 2026-07-10, money out, 2,500, Office cash, 6500, "Careem rides for
client meeting July". Dialog: "That is N days ago." where N is the number of
days from 10 July to today (on 26 October, 108). Save anyway. Office cash
38,100.00. It does not count in "this month". To review 10: "Backdated" and
"No receipt".

### 5.18 The bank going below zero

Money out, today, 900,000, Winibex bank, 5100, "Overdraft warning test".
Dialog: "That takes the account below zero. It holds PKR 787,150 today."
A bank can be overdrawn, so this is a warning, not a block. Press **Go back
and check**. Nothing saved. Leave the form.

### 5.19 Checkpoint

| Screen | Expect |
| --- | --- |
| Accounts | Winibex bank 787,150.00, Office cash 38,100.00, Petty cash 9,700.00, Total held 834,950.00 |
| Dashboard | Cash 834,950.00. In this month 320,250.00. Out this month 42,800.00. "10 entries to review". No waiting tile |
| Transactions | "Showing 14 of 14". JV-1 to JV-14, no Draft rows |

In is 150,000 + 140,250 + 30,000. Out is 1,200 + 1,500 + 1,800 + 4,900 +
5,600 + 7,500 + 20,000 + 300. Not in Out: the personal card (5.11) and the
July Careem rides (5.17).

---

## Part 6. Features that only have an API so far

In `phase1-api-tests.http` send 6.2a to 6.21d in order. The expected status
and body are written above every request.

What each block proves, and the balances after it:

| Block | Proves | Bank | Office cash | Petty cash | To review |
| --- | --- | --- | --- | --- | --- |
| 6.2 | Dashboard and accounts match step 5.19 | 787,150 | 38,100 | 9,700 | 10 |
| 6.3, 6.4 | Worked example 1a: a $20 card payment with 236Y tax, forex fee and FED. Preview equals the posted lines. The rate warning (D5). No posting without a receipt | 781,197 | | | 11 |
| 6.5 | Vendors, filer status, the check date rule | | | | |
| 6.6 | Tax suggestions pick the right party's filer status and rate | | | | |
| 6.7 | Worked example 9: s.153 withheld, only the net leaves the bank. Journal lines carry code and name (D12) | 685,197 | | | |
| 6.8 | Withholding needs a vendor tax number. Refused, nothing saved (D7) | | | | |
| 6.9 | Worked example 8: transfer with a fee, two legs through 1118 | 625,147 | 98,100 | | |
| 6.10 | Transfer with no fee goes through (D6) | | 93,100 | 14,700 | |
| 6.11 | Large cash warning, then confirm | | 38,100 | | 12 |
| 6.12 | Cheque register: allowed status moves, a clear duplicate refusal (D8), link to the payment | 580,147 | | | |
| 6.13 | Reversal: reason required, exact mirror, only once | 430,147 | | | |
| 6.14 | Paying back a person, never more than owed | 427,147 | 35,147 | | |
| 6.15 | Petty cash float and top-up suggestion | | | | |
| 6.16 | History before go-live: excluded from balances, merge refused | | | | |
| 6.17 | Idempotency: one request, one entry | | | 13,900 | 13 |
| 6.18 | Server-side search and filters, dashboard checkpoint | | | | |
| 6.19 | What staff cannot do | | | | |
| 6.21 | Receipt upload refusals, receipts need a login | | | | |

Blank cells mean no change. Journal numbers run on without gaps: JV-15 at
6.4 to JV-27 at 6.17.

Why the count moves where it does: 6.4 and 6.11 each add one confirmed
warning (their receipts clear their "No receipt" flags), and 6.17 adds one "No
receipt". Transfers, the reversal, reimbursements and the historical entry
add nothing.

**6.20 The database refuses tampering.** Run Section B of
`phase1-checks.sql`, one statement at a time. All four must fail:

| Statement | Error message |
| --- | --- |
| B1 update a posted transaction | Posted entries are immutable. Reverse and re-enter instead. |
| B2 delete a posted transaction | Transactions are never deleted. Reverse the entry instead. |
| B3 update a journal line | Journal lines cannot be changed. Post a reversing entry. |
| B4 delete a journal line | Journal lines are never deleted. Post a reversing entry. |

If any of them succeeds, stop: the triggers from migration 004 are missing.

**6.22 Back in the app** (refresh each screen):

- Accounts: Winibex bank 427,147.00, Office cash 35,147.00, Petty cash
  13,900.00, Total held 476,194.00
- Dashboard: Cash 476,194.00, In this month 170,250.00, Out this month
  251,556.00, "13 entries to review"
- Transactions: the website advance struck through, and a new row "Reversal
  of JV-8: Test reversal, wrong client". Both stay. There is no "Test No-ID
  Freelancer" row: step 6.8a was refused before anything was saved

In dropped by 150,000 because the reversal cancels the website advance on the
same side. Out rose by 5,953 + 96,000 + 50 + 55,000 + 45,000 + 3,000 + 2,953
+ 800. The 50 is the transfer fee; the transfers themselves are not counted.

---

## Part 7. Approvals with four people (app)

Sign out before each change of person. All test logins use the password
`Winibex-Test-2026`.

| Step | Who | Do | Expect |
| --- | --- | --- | --- |
| 7.1 | staff@winibex.test | New entry: money out, 2,200, Petty cash, 6110, "Snacks for team meeting" | The last button reads **Submit for approval**, not Save and post. "Submitted. Someone else will approve it." |
| 7.2 | Test Staff | New entry: money out, 1,000, Petty cash, 6600, "Courier charges for contract documents". Submit | Same message |
| 7.3 | Test Staff | New entry: money out, 12,000, Winibex bank, 6700, "Laptop screen repair", receipt `receipt.jpg`. Submit | Same message |
| 7.4 | Test Staff | Look at Transactions, Approvals, Dashboard | The three rows show "Waiting". Approvals lists three cards, each "You entered this, so someone else has to approve it." with no Approve button. Dashboard "3 entries waiting for approval". Petty cash still 13,900.00 |
| 7.5 | Owner | Dashboard, then Approvals. Approve "Snacks for team meeting" | "3 entries waiting for approval" and "15 entries to review" (7.1 and 7.2 have no receipt). Cards oldest first: Snacks, Courier, Laptop. Snacks leaves the list. Petty cash 11,700.00 |
| 7.6 | Owner | Reject "Courier charges..." with reason "Attach the courier slip and resubmit" | Dialog "Send it back". The card leaves the list. In Transactions the row shows "Rejected" |
| 7.6 | .http | Send 7.6a and 7.6b | 7.6a finds the courier entry, 7.6b refuses to reverse an entry that never posted |
| 7.7 | limited@winibex.test | Approvals, Approve "Laptop screen repair" | A message at the bottom: "That entry is above your approval limit." (D3). The card stays |
| 7.8 | admin@winibex.test | Approvals, Approve "Laptop screen repair" | It leaves the list. Bank 415,147.00 |
| 7.9 | Test Admin | New entry: money out, 700, Petty cash, 6110, "Admin own entry test" | The last button reads **Submit for approval**, because this admin may not post their own entries (D4). "Submitted. Someone else will approve it." In Approvals the card says "You entered this, so someone else has to approve it." |
| 7.9 | .http | Send 0.3 again, then 7.9a, 7.9b, 7.9c | 7.9a finds it pending, 7.9b refused for Test Admin, 7.9c refused for staff |
| 7.9 | Owner | Approvals, approve "Admin own entry test" | Posts. Petty cash 11,000.00 |
| 7.10 | limited@winibex.test | New entry: money out, 900, Petty cash, 6110, "Limited admin own entry" | This admin may post own entries, so the button reads **Save and post**. "Saved and posted." Petty cash 10,100.00 |

Back as the owner, the dashboard shows "17 entries to review": 13 from Part 6,
plus "No receipt" on snacks, courier, the admin's entry and the limited
admin's entry. The courier flag stays open although the entry was rejected;
that is how the code works today (open question N in DECISIONS.md).

Then run C6 in Section C of `phase1-checks.sql`. Exactly one row: "Snacks
for team meeting", created by Test Staff. That is the silent marker for an
entry made by someone who also uses the shared owner login and then approved
under it.

---

## Part 8. Final look in the app (owner)

| Step | Screen | Expect |
| --- | --- | --- |
| 8.1 | Accounts | Winibex bank 415,147.00, Office cash 35,147.00, Petty cash 10,100.00, every other account 0.00, Total held 460,394.00 |
| 8.2 | Dashboard | Cash 460,394.00. In this month 170,250.00. Out this month 267,356.00. No waiting tile. "17 entries to review" |
| 8.3 | Transactions | "Showing 32 of 32". Today's entries first, then 2026-07-10 Careem, 2026-07-01 opening, 2026-05-10 historical. One "Rejected" row, the courier. No Draft rows. Search `Claude` and press Enter: 2 rows. Clear the search |
| 8.4 | Open "Claude Team seat, company card, worked example 1a" | Journal panel with five lines, each with its code and name (D12): 6400 Software subscriptions Dr 5,600.00, 8200 Forex and card fees Dr 280.00, 8100 Bank charges and FED Dr 45.00, 1141 Advance income tax Dr 28.00, 1113 Bank Cr 5,953.00 |
| 8.5 | Open the website advance, View history | Three events: Created, Status changed (to posted), Status changed (to reversed, reason "Test reversal, wrong client"). The panel also says "This entry was reversed. Both it and its reversal stay in the book." |
| 8.6 | To review | 17 items, each naming its entry. "No receipt" on 11: printer paper, markers, toner, cushion, tea, Careem, the idempotency test, snacks, courier, the admin's entry, the limited admin's entry. Also "Description too short" on tea, "Unusual amount" on the cushion, "Rate differs from last time" on invoice 1002 and on the Claude Team seat, "Backdated" on Careem, "Large cash payment" on the cash rent. The confirmed warnings say "confirmed by" and the owner's name. Each item has a **Mark reviewed** button |
| 8.7 | On "tea", the "Description too short" item, press Mark reviewed | Dialog "Mark as reviewed". Type `ok` and confirm: the dialog closes, nothing is sent and the item stays, because a note needs at least 3 characters. Type `Office tea for the team, nothing more to record` and confirm. "Marked as reviewed." The item leaves the list; tea's "No receipt" item stays. Dashboard "16 entries to review" |
| 8.8 | .http | Send 8.8a to 8.8e | A receipt attached to the printer paper entry clears its "No receipt" flag by itself. 15 open, 11 resolved |
| 8.9 | .http | Send 8.9a to 8.9d | Staff refused, a short note refused, an already resolved flag refused, a missing flag 404 |
| 8.10 | Refresh To review, then sign out and sign in as staff@winibex.test, open To review (if it is not in the menu, type `/flags` after the app address) | Owner: 15 items, printer paper gone. Staff: the same 15, with no Mark reviewed button. Sign out |
| 8.11 | Sign in as staff@winibex.test with a wrong password, six times | By the sixth try: "Too many sign-in attempts. Try again in a few minutes." The owner can still sign in, because the limit counts per address and email |
| 8.12 | As the owner, type `/transactions` at the end of the app address and press Enter | The ledger opens directly. On production this proves the .htaccess fallback |

In and Out this month, explained (D11, decision 057). In is 150,000 + 140,250
+ 30,000 from Part 5, less the 150,000 reversal: 170,250. Out is everything
that left the bank, office cash or petty cash this month, including the 50
transfer fee and the two reimbursements (5,953), and not the transfers
themselves, the personal card, the July Careem rides or the May historical
entry: 267,356. The check: 557,500 + 170,250 - 267,356 = 460,394.

---

## Part 9. Database checks

Run Section C of `phase1-checks.sql`. The expected result is in the comment
above each query. The ones that matter most:

| Check | Expect |
| --- | --- |
| C1 trial balance | total_debit 144305900, total_credit 144305900, difference 0 |
| C2 ledger balances | 1113 = 41514700, 1111 = 3514700, 1112 = 1010000, 1118 = 0, 2114 = 0, 3400 = -36000000, and the rest as listed |
| C3 numbering | 31 numbered entries, 31 distinct, first JV-1, last JV-31. No gaps, even though several postings failed along the way |
| C4 status | posted/normal 28, posted/opening 1, posted/historical 1, reversed/normal 1, rejected/normal 1 |
| C5 approval method | auto 27, owner 3, admin 1 |
| C8 receipts | 10 files, each with a fingerprint and kept ten years |
| C9 tax snapshot | two rows, rates as charged on the day |
| C10 flags | 26 rows: 15 open (10 "No receipt", 5 confirmed warnings), 11 resolved (10 by a receipt, 1 by you) |
| C11 flag records | 0 inconsistent |

---

## Part 10. Reset

Nothing from the test may stay in the books. Posted entries cannot be
deleted (step 6.20 proved it), so the reset drops every table and rebuilds.

**Local:**

```powershell
cd C:\Users\ahmad\Desktop\winibex-accounting
docker compose down -v
docker compose up -d
docker compose exec mariadb mariadb-admin ping -uroot -pwinibex_root_local --wait=60 --silent
cd api
npm run migrate:up
```

Then empty the local upload folder (the `UPLOAD_DIR` in `api\.env`).

**Production:**

1. phpMyAdmin, accounting database, optional Export first. SQL tab, paste
   `phase1-reset.sql`, Go. The final SHOW TABLES must return nothing
2. Apply the migrations again in order: 000, 001, 002, 003, 004, 005. SQL
   tab, paste each file, Go. Then `SELECT * FROM schema_migrations;` shows six
   rows
3. Owner password: run `npm run hash:password` locally, enter the real
   password, then in phpMyAdmin:
   `UPDATE users SET password_hash = '<the printed hash>', must_change_password = 1 WHERE role = 'owner';`
4. Hostinger File Manager: open the `UPLOAD_DIR` folder and delete the test
   receipt folders inside it
5. Do not run `phase1-test-seed.sql` again. The TEST taxes and test users
   are gone with the reset, and that is how it should stay
6. Sign in at https://accounting.winibex.com. Forced password change, then
   Accounts all 0.00, Transactions empty. The books are ready for the real
   opening entry

---

## Reporting

For anything that does not match, send the step number, what you entered,
what you saw, and for API steps the response body.
