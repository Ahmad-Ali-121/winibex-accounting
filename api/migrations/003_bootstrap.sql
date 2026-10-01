-- 003_bootstrap
--
-- There is no sign-up screen, so the first login has to be put in by hand.
-- That is all this file does. Everything else it creates is a safe default
-- that the owner edits in the UI afterwards.
--
-- The password hash below is bcrypt cost 12 of a temporary bootstrap password.
-- must_change_password = 1 forces a new password at first login, after which
-- this hash is worthless. The email is changeable in Settings.

-- ---------------------------------------------------------------------------
-- The owner login
-- ---------------------------------------------------------------------------

INSERT INTO users (name, email, password_hash, must_change_password, role) VALUES
  ('Winibex office', 'winibexoffice@gmail.com', '$2b$12$ZsvEWyEI1veztu57XyCeYe55/nhyWhO2JZEmyScH9Ku7QcNfJ76Tu', 1, 'owner');

-- Ahmad, Maryam and Fazal are added by the owner from Settings, users.
-- Doing it there means their passwords never pass through a SQL file.

-- ---------------------------------------------------------------------------
-- Company profile
--
-- Blank except the legal name. Filled in from Settings, company profile,
-- which is where it is maintained from then on. Nothing is printed on a
-- document until Phase 3, so there is no hurry.
-- ---------------------------------------------------------------------------

INSERT INTO company_profile (id, legal_name, trade_name) VALUES
  (1, 'Winibex (Private) Limited', 'Winibex');

-- ---------------------------------------------------------------------------
-- Company accounts
--
-- The five that belong to the company itself. Pass-through accounts, which are
-- Fazal's and Ahmad's personal accounts holding company money in transit, are
-- added from the Accounts screen once those users exist, because the database
-- refuses a pass-through account that names no owner.
--
-- opening_date is the earliest date an entry on the account may carry.
-- Decision 037. Balances are not set here. They come from the opening entry
-- on 2026-07-01, in Phase 1.
-- ---------------------------------------------------------------------------

INSERT INTO accounts (name, type, coa_id, opening_date)
SELECT seed.name, seed.type, coa.id, '2025-03-01'
FROM (
            SELECT 'Winibex bank'      AS name, 'bank'       AS type, '1113' AS code
  UNION ALL SELECT 'Office cash',            'cash',       '1111'
  UNION ALL SELECT 'Petty cash',             'petty_cash', '1112'
  UNION ALL SELECT 'Cheques in hand',        'cheque',     '1114'
  UNION ALL SELECT 'Platform balances',      'bank',       '1117'
) AS seed
JOIN chart_of_accounts coa ON coa.code = seed.code;

-- ---------------------------------------------------------------------------

INSERT INTO schema_migrations (filename)
VALUES ('003_bootstrap.sql')
ON DUPLICATE KEY UPDATE filename = filename;
