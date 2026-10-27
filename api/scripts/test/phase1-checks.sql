-- Phase 1 test, database checks. Used by docs/PHASE1-TEST.md.
--
-- Run ONE section at a time in phpMyAdmin (SQL tab), or in a MySQL client
-- against the local `winibex` database. Money columns are paisa:
-- 100 paisa = PKR 1, so 41514700 is PKR 415,147.00.

-- ===========================================================================
-- SECTION A. Look up the ids for the .http file (Part 1, step 1.6)
-- Copy each id into the matching @variable at the top of phase1-api-tests.http.
-- ===========================================================================

-- A1. Accounts. You need Winibex bank, Office cash, Petty cash.
SELECT a.id, a.name, a.type, c.code
  FROM accounts a JOIN chart_of_accounts c ON c.id = a.coa_id
 ORDER BY a.id;

-- A2. Categories by ledger code. You need the ids for these codes:
--     5100, 6200, 6400, 6600 (all money-out categories)
SELECT c.id, c.name, c.direction, a.code
  FROM categories c JOIN chart_of_accounts a ON a.id = c.coa_id
 WHERE c.is_active = 1
 ORDER BY a.code, c.direction;

-- A3. Ledger ids for the two charge lines.
SELECT id, code, name FROM chart_of_accounts WHERE code IN ('8100', '8200');

-- A4. Users. You need the id of Test Staff.
SELECT id, name, email, role, approval_limit, auto_approve_own, shares_owner_login
  FROM users ORDER BY id;

-- A5. The TEST taxes. You need the id of TEST-236Y and TEST-153.
SELECT id, short_code, rate_atl, rate_non_atl, status_basis FROM taxes ORDER BY id;

-- A6. The tax rules. Expect three rows. If "TEST outsourcing withholding" is
--     missing, there is no active money-out category on ledger 5100.
SELECT r.id, r.name, t.short_code, r.direction, r.currency_is_foreign, r.category_id
  FROM tax_rules r JOIN taxes t ON t.id = r.tax_id ORDER BY r.id;


-- ===========================================================================
-- SECTION B. The database refuses to change the book (Part 6, step 6.20)
-- Run each statement on its own. EVERY ONE MUST FAIL with the message shown.
-- If any of them succeeds, stop and report it: the immutability triggers
-- from migration 004 are missing.
-- ===========================================================================

-- B1. Expected error: Posted entries are immutable. Reverse and re-enter instead.
UPDATE transactions SET description = 'tampered'
 WHERE description = 'Claude Pro subscription October' AND status = 'posted';

-- B2. Expected error: Transactions are never deleted. Reverse the entry instead.
DELETE FROM transactions
 WHERE description = 'Claude Pro subscription October' AND status = 'posted';

-- B3. Expected error: Journal lines cannot be changed. Post a reversing entry.
UPDATE journal_lines SET memo = 'tampered'
 WHERE transaction_id = (SELECT id FROM transactions
                          WHERE description = 'Claude Pro subscription October'
                            AND status = 'posted');

-- B4. Expected error: Journal lines are never deleted. Post a reversing entry.
DELETE FROM journal_lines
 WHERE transaction_id = (SELECT id FROM transactions
                          WHERE description = 'Claude Pro subscription October'
                            AND status = 'posted');


-- ===========================================================================
-- SECTION C. Final checks (Part 9). Expected results are in the comments.
-- ===========================================================================

-- C1. Trial balance. Debits equal credits across every journal line.
--     Expected: total_debit 144305900, total_credit 144305900, difference 0
SELECT SUM(debit) AS total_debit, SUM(credit) AS total_credit,
       SUM(debit) - SUM(credit) AS difference
  FROM journal_lines;

-- C2. Every ledger code's live balance (historical entries left out, as the
--     app does until history is merged). net_debit is debit minus credit.
--     Expected, in paisa:
--       1111 Cash in hand, office            3514700
--       1112 Petty cash                       1010000
--       1113 Bank                            41514700
--       1118 Funds in transit, internal             0   (must be zero)
--       1123 Rebillable expenses              2000000
--       1141 Advance income tax                  2800
--       2114 Payable to employees                   0   (Test Staff fully repaid)
--       2132 Withholding payable, s.153       -400000
--       2210 Loan from director             -20000000
--       3400 Opening balance equity         -36000000
--       4110 Export revenue                 -17025000
--       4210 Local website revenue                  0   (posted then reversed)
--       5100 Outsourcing                     10000000
--       6110 Staff welfare                     410000
--       6200 Rent and utilities              10000000
--       6400 Software subscriptions           1715300
--       6410 Hosting and domains               750000
--       6500 Travelling and conveyance         250000
--       6600 Office supplies                  1020000
--       6700 Repairs and maintenance          1200000
--       8100 Bank charges and FED                9500
--       8200 Forex and card fees                28000
--     If you used a different category than the guide in Part 5, the expense
--     codes move around but 1111, 1112, 1113, 1118, 2114, 2132, 2210 and 3400
--     must still match exactly.
SELECT c.code, c.name, SUM(j.debit) - SUM(j.credit) AS net_debit
  FROM journal_lines j
  JOIN transactions t ON t.id = j.transaction_id
  JOIN chart_of_accounts c ON c.id = j.coa_id
 WHERE t.status IN ('posted', 'reversed')
   AND t.entry_type <> 'historical'
 GROUP BY c.code, c.name
 ORDER BY c.code;

-- C3. Journal numbers have no gaps.
--     Expected: numbered 31, distinct_numbers 31, first 1, last 31.
--     Numbers are JV-1, JV-2 and so on, so first and last are read as numbers:
--     compared as text, JV-9 would sort after JV-31.
SELECT COUNT(*) AS numbered, COUNT(DISTINCT journal_number) AS distinct_numbers,
       MIN(CAST(SUBSTRING(journal_number, 4) AS UNSIGNED)) AS first,
       MAX(CAST(SUBSTRING(journal_number, 4) AS UNSIGNED)) AS last
  FROM transactions WHERE journal_number IS NOT NULL;

-- C4. Rows by status and type.
--     Expected: posted/normal 28, posted/opening 1, posted/historical 1,
--               reversed/normal 1, rejected/normal 1. No draft, no pending.
--     32 rows in all. The only rejected one is the courier entry (step 7.6).
SELECT status, entry_type, COUNT(*) AS n
  FROM transactions GROUP BY status, entry_type ORDER BY status, entry_type;

-- C5. How each entry reached the book.
--     Expected: auto 27, owner 3, admin 1
SELECT approval_method, COUNT(*) AS n
  FROM transactions WHERE status IN ('posted', 'reversed')
 GROUP BY approval_method;

-- C6. The shared-login marker. Expected: exactly one row,
--     "Snacks for team meeting", created by Test Staff.
SELECT t.journal_number, t.description, u.name AS created_by
  FROM transactions t JOIN users u ON u.id = t.created_by
 WHERE t.possible_self_approval = 1;

-- C7. The reversal pair links both ways. Expected: one row, the website
--     advance, with reversed_by_id pointing at a row whose reversal_of_id
--     points back, and the reason "Test reversal, wrong client".
SELECT o.journal_number AS original, o.status, r.journal_number AS reversal,
       r.reversal_reason, r.description
  FROM transactions o JOIN transactions r ON r.id = o.reversed_by_id
 WHERE r.reversal_of_id = o.id;

-- C8. Receipts stored. Expected: 10 rows, each with a sha256 and a
--     retain_until at least ten years ahead. The last one is the receipt
--     added to "Printer paper and pens" after it posted (step 8.8b).
SELECT a.id, t.description, a.mime, a.size_bytes, a.retain_until, LEFT(a.sha256, 12) AS sha
  FROM attachments a JOIN transactions t ON t.id = a.transaction_id
 ORDER BY a.id;

-- C9. The tax snapshot on every entry that carries a tax line. Expected 2 rows:
--     Claude Team seat ...     TEST-236Y 0.5000 atl     company bank 2800
--     Test Filer Software ...  TEST-153  4.0000 atl     vendor  us   400000
--     There is no row for Test No-ID Freelancer: step 6.8a was refused
--     before anything was saved.
SELECT t.description, x.short_code, tt.rate_applied, tt.atl_status_used,
       tt.atl_party, tt.deducted_by, tt.tax_amount
  FROM transaction_taxes tt
  JOIN taxes x ON x.id = tt.tax_id
  JOIN transactions t ON t.id = tt.transaction_id
 ORDER BY tt.id;

-- C10. Flags, open and resolved (decision 056). Expected, 26 rows in all:
--     resolved 0  flag     NO_RECEIPT            10
--     resolved 0  warning  BACKDATED              1
--     resolved 0  warning  LARGE_CASH             1
--     resolved 0  warning  RATE_DEVIATION         2
--     resolved 0  warning  UNUSUAL_AMOUNT         1
--     resolved 1  flag     NO_RECEIPT            10   (all "Receipt attached", by_person 0)
--     resolved 1  flag     THIN_DESCRIPTION       1   (by_person 1, your note)
--     15 open, which is what the dashboard shows.
SELECT resolved, severity, code, COUNT(*) AS n,
       SUM(resolved_by IS NOT NULL) AS by_person
  FROM entry_flags
 GROUP BY resolved, severity, code
 ORDER BY resolved, severity, code;

-- C11. Every resolved flag says who and why; no open flag carries either.
--     Expected: 0. Migration 005 enforces this with a CHECK constraint.
SELECT COUNT(*) AS inconsistent
  FROM entry_flags
 WHERE (resolved = 1 AND (resolved_at IS NULL OR resolution_note IS NULL))
    OR (resolved = 0 AND (resolved_by IS NOT NULL OR resolved_at IS NOT NULL OR resolution_note IS NOT NULL));
