-- Wipe the database after the Phase 1 test. DESTROYS EVERYTHING.
--
-- Posted entries cannot be deleted (the triggers from migration 004 refuse),
-- so the only clean reset is to drop every table and apply the migrations
-- again. Dropping a table drops its triggers with it.
--
-- Before running on production:
--   1. Check the database name at the top left of phpMyAdmin. It must be the
--      accounting database and nothing else.
--   2. Optional: Export it first (Export tab, Quick, SQL) in case you want to
--      look at the test data later.
--   3. UNTICK "Enable foreign key checks" below the SQL box before pressing
--      Go. phpMyAdmin's box overrides the SET line below, and with it ticked
--      the drops stop at `transactions`. Tick it again for the migrations.
--
-- After running, follow "Part 10. Reset" in docs/PHASE1-TEST.md:
-- re-apply migrations 000 to 006, set the owner password, delete the receipt
-- files from the upload folder.

SET FOREIGN_KEY_CHECKS = 0;

-- Phase 1, migration 004. Migration 005 adds columns to entry_flags, no tables.
DROP TABLE IF EXISTS period_locks;
DROP TABLE IF EXISTS reimbursement_items;
DROP TABLE IF EXISTS reimbursements;
DROP TABLE IF EXISTS attachments;
DROP TABLE IF EXISTS entry_flags;
DROP TABLE IF EXISTS transaction_charges;
DROP TABLE IF EXISTS transaction_taxes;
DROP TABLE IF EXISTS journal_lines;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS cheques;
DROP TABLE IF EXISTS vendors;
DROP TABLE IF EXISTS tax_rules;
DROP TABLE IF EXISTS taxes;

-- Phase 0, migration 001
DROP TABLE IF EXISTS idempotency_keys;
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS sequences;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS fbr_return_heads;
DROP TABLE IF EXISTS chart_of_accounts;
DROP TABLE IF EXISTS currencies;
DROP TABLE IF EXISTS company_profile;
DROP TABLE IF EXISTS settings;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS users;

-- Migration 000
DROP TABLE IF EXISTS schema_migrations;

SET FOREIGN_KEY_CHECKS = 1;

-- Expected: this returns no rows. If any table is listed, drop it by hand.
SHOW TABLES;
