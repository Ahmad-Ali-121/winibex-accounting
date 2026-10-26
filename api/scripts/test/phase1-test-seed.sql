-- Phase 1 test data. DUMMY ONLY.
--
-- Run once, after migrations 000 to 004 and before the test in
-- docs/PHASE1-TEST.md. Run it in phpMyAdmin (SQL tab) on production, or in
-- any MySQL client against the local `winibex` database.
--
-- Never run this after the final reset. Never run it on a database that
-- holds real entries. Every name here starts with "Test" or "TEST" so it is
-- obvious in any list.

-- ---------------------------------------------------------------------------
-- 1. Three test logins. The password for all three is: Winibex-Test-2026
--
--    Test Admin          admin, no approval limit, cannot post own entries
--    Test Limited Admin  admin, approval limit PKR 10,000, posts own entries
--    Test Staff          staff, also uses the shared owner login (Maryam's case)
--
--    If a test login is refused with the right password, run
--    `npm run hash:password` in api/, type Winibex-Test-2026, and paste the
--    printed hash over the one below.
-- ---------------------------------------------------------------------------

INSERT INTO users
  (name, email, password_hash, role, is_active, shares_owner_login,
   approval_limit, auto_approve_own, must_change_password)
VALUES
  ('Test Admin', 'admin@winibex.test',
   '$2a$12$B/QTRIIZGCYXFTu5AXa75.rBZ13keJVQxB4doy4W9dXR8kEL9ygny',
   'admin', 1, 0, NULL, 0, 0),
  ('Test Limited Admin', 'limited@winibex.test',
   '$2a$12$B/QTRIIZGCYXFTu5AXa75.rBZ13keJVQxB4doy4W9dXR8kEL9ygny',
   'admin', 1, 0, 1000000, 1, 0),
  ('Test Staff', 'staff@winibex.test',
   '$2a$12$B/QTRIIZGCYXFTu5AXa75.rBZ13keJVQxB4doy4W9dXR8kEL9ygny',
   'staff', 1, 1, NULL, 0, 0);

-- ---------------------------------------------------------------------------
-- 2. Three TEST taxes. These rates are dummies for testing the engine only.
--    The real rates wait for the accountant (PROGRESS.md, pending item 1).
-- ---------------------------------------------------------------------------

INSERT INTO taxes
  (name, short_code, authority, law_reference, kind, applies_to, computation,
   rate_atl, rate_non_atl, status_basis, is_inclusive, is_adjustable, coa_id,
   effective_from, notes)
SELECT 'TEST card advance tax', 'TEST-236Y', 'fbr', 'ITO 2001 s.236Y', 'advance',
       'purchases', 'percent', 0.5000, 1.0000, 'company', 0, 1, id,
       '2026-07-01', 'Dummy rate for the Phase 1 test. Not a real seed.'
  FROM chart_of_accounts WHERE code = '1141';

INSERT INTO taxes
  (name, short_code, authority, law_reference, kind, applies_to, computation,
   rate_atl, rate_non_atl, status_basis, is_inclusive, is_adjustable, coa_id,
   effective_from, notes)
SELECT 'TEST export final tax', 'TEST-154A', 'fbr', 'ITO 2001 s.154A', 'final',
       'sales', 'percent', 1.0000, 2.0000, 'company', 0, 0, id,
       '2026-07-01', 'Dummy rate for the Phase 1 test. Not a real seed.'
  FROM chart_of_accounts WHERE code = '9100';

INSERT INTO taxes
  (name, short_code, authority, law_reference, kind, applies_to, computation,
   rate_atl, rate_non_atl, status_basis, is_inclusive, is_adjustable, coa_id,
   effective_from, notes)
SELECT 'TEST withholding on services', 'TEST-153', 'fbr', 'ITO 2001 s.153', 'withholding',
       'purchases', 'percent', 4.0000, 8.0000, 'counterparty', 0, 0, id,
       '2026-07-01', 'Dummy rate for the Phase 1 test. Not a real seed.'
  FROM chart_of_accounts WHERE code = '2132';

-- When each TEST tax is suggested.

INSERT INTO tax_rules (name, tax_id, direction, currency_is_foreign, priority)
SELECT 'TEST foreign card payment', id, 'out', 1, 10
  FROM taxes WHERE short_code = 'TEST-236Y';

INSERT INTO tax_rules (name, tax_id, direction, currency_is_foreign, priority)
SELECT 'TEST foreign client receipt', id, 'in', 1, 10
  FROM taxes WHERE short_code = 'TEST-154A';

INSERT INTO tax_rules (name, tax_id, direction, currency_is_foreign, category_id, priority)
SELECT 'TEST outsourcing withholding', t.id, 'out', 0, c.id, 20
  FROM taxes t
  CROSS JOIN categories c
  JOIN chart_of_accounts a ON a.id = c.coa_id
 WHERE t.short_code = 'TEST-153'
   AND a.code = '5100'
   AND c.direction = 'out'
 LIMIT 1;

-- ---------------------------------------------------------------------------
-- 3. Petty cash float of PKR 20,000, so the top-up suggestion has a target.
-- ---------------------------------------------------------------------------

INSERT INTO settings (setting_key, value, value_type, description)
VALUES ('petty_cash_imprest', '2000000', 'int', 'Target petty cash float, paisa')
ON DUPLICATE KEY UPDATE value = '2000000';

-- ---------------------------------------------------------------------------
-- 4. LOCAL ONLY. Gives the owner the same known password and forces a change
--    at first sign-in, so Part 2 of the test can run. Remove the two dashes
--    at the start of the next line to use it.
--
--    On production do NOT run this. Keep the real owner password and run
--    only:  UPDATE users SET must_change_password = 1 WHERE role = 'owner';
-- ---------------------------------------------------------------------------

-- UPDATE users SET password_hash = '$2a$12$B/QTRIIZGCYXFTu5AXa75.rBZ13keJVQxB4doy4W9dXR8kEL9ygny', must_change_password = 1 WHERE role = 'owner';
