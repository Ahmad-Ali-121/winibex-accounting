-- 004_phase1_tables
--
-- Phase 1: money in and out. Thirteen tables, four triggers.
--
-- Order matters. A table that points at another must be created after it.
-- Columns that point at Phase 2 and Phase 3 tables (clients, projects,
-- invoices, withholding_statements) exist here but carry no foreign key yet,
-- because the key cannot reference a table that does not exist. The key is
-- added by the migration of the phase that creates the target table.
-- Decision 051.
--
-- Three rules this file deliberately does NOT enforce, with reasons, so that
-- nobody later reads the gap as an oversight:
--
--   1. "An entry cannot reverse itself" would be CHECK (reversal_of_id <> id).
--      MariaDB refuses any CHECK that mentions an AUTO_INCREMENT column.
--      Decision 045 hit the same limit on accounts.parent_id. It lives in the
--      service layer. In practice the foreign key on reversal_of_id already
--      makes it impossible, since the target id must exist before the
--      reversing row is inserted.
--
--   2. "Debits equal credits" spans every journal line of one transaction.
--      A CHECK only ever sees a single row. It lives in the posting engine,
--      proved by the trial balance test.
--
--   3. "Historical entries are dated before books_live_from, the opening entry
--      is dated exactly on it" depends on a value in the settings table.
--      A CHECK cannot read another table, and hardcoding 2026-07-01 here would
--      put policy in code, which AGENTS.md forbids. Service layer.

-- ===========================================================================
-- taxes
--
-- One row per tax that can appear on an entry. Created empty on purpose.
-- Rates are data with effective dates, never constants in code, and the
-- accountant signs off docs/TAXES.md before a single row is seeded.
-- Decisions 018 and 046.
-- ===========================================================================

CREATE TABLE taxes (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name            VARCHAR(150)    NOT NULL COMMENT 'Section 154A IT export final tax',
  short_code      VARCHAR(20)     NOT NULL COMMENT 'Shown on documents',
  authority       ENUM('fbr', 'pra', 'srb', 'ict', 'bank', 'other') NOT NULL,
  law_reference   VARCHAR(50)     NULL COMMENT 'ITO 2001 s.154A',
  kind            ENUM('withholding', 'final', 'advance', 'sales_tax', 'fed', 'other') NOT NULL,
  applies_to      ENUM('sales', 'purchases', 'both') NOT NULL,
  computation     ENUM('percent', 'fixed') NOT NULL DEFAULT 'percent',
  rate_atl        DECIMAL(9,4)    NOT NULL COMMENT 'Rate when the party the tax is about is on the Active Taxpayers List',
  rate_non_atl    DECIMAL(9,4)    NOT NULL,
  status_basis    ENUM('company', 'counterparty') NOT NULL COMMENT 'company when tax is deducted from Winibex, counterparty when Winibex deducts. Decision 030',
  return_section  VARCHAR(20)     NULL COMMENT 'Section code used in the s.165 statement',
  is_inclusive    TINYINT(1)      NOT NULL DEFAULT 0,
  is_adjustable   TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Creditable later, as opposed to a final cost',
  coa_id          BIGINT UNSIGNED NOT NULL COMMENT 'Ledger account this tax posts to',
  effective_from  DATE            NOT NULL,
  effective_to    DATE            NULL,
  is_active       TINYINT(1)      NOT NULL DEFAULT 1,
  notes           TEXT            NULL COMMENT 'Conditions such as PSEB registration or ATL',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_taxes_code_from (short_code, effective_from),
  CONSTRAINT fk_taxes_coa
    FOREIGN KEY (coa_id) REFERENCES chart_of_accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_taxes_rates CHECK (rate_atl >= 0 AND rate_non_atl >= 0),
  CONSTRAINT chk_taxes_period CHECK (effective_to IS NULL OR effective_to >= effective_from)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- tax_rules
--
-- Which tax the entry form suggests in which situation. The form suggests,
-- the user confirms, and what the bank actually deducted wins. Decision 018.
-- A NULL in a matching column means "this rule does not care about that".
-- ===========================================================================

CREATE TABLE tax_rules (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name                VARCHAR(150)    NOT NULL,
  tax_id              BIGINT UNSIGNED NOT NULL,
  direction           ENUM('in', 'out') NOT NULL,
  currency_is_foreign TINYINT(1)      NULL COMMENT 'NULL means the rule applies either way',
  account_type        ENUM('bank', 'cash', 'petty_cash', 'cheque', 'pass_through') NULL,
  category_id         BIGINT UNSIGNED NULL,
  client_country      VARCHAR(60)     NULL,
  priority            INT             NOT NULL DEFAULT 100 COMMENT 'Lower number is matched first',
  is_active           TINYINT(1)      NOT NULL DEFAULT 1,
  created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_tax_rules_tax
    FOREIGN KEY (tax_id) REFERENCES taxes (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_tax_rules_category
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- vendors
--
-- Anyone Winibex pays other than employees. Needed before a withholding rate
-- can be chosen, because the rate depends on the payee's ATL status, not on
-- Winibex's. Decisions 030 and 031.
-- ===========================================================================

CREATE TABLE vendors (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name           VARCHAR(150)    NOT NULL,
  kind           ENUM('company', 'aop', 'individual', 'foreign') NOT NULL,
  ntn            VARCHAR(20)     NULL,
  cnic           VARCHAR(20)     NULL,
  strn           VARCHAR(20)     NULL,
  atl_status     ENUM('atl', 'non_atl', 'unknown') NOT NULL DEFAULT 'unknown',
  atl_checked_on DATE            NULL COMMENT 'Warned about when older than 30 days at payment time',
  default_tax_id BIGINT UNSIGNED NULL,
  country        VARCHAR(60)     NULL,
  email          VARCHAR(190)    NULL,
  phone          VARCHAR(40)     NULL,
  notes          TEXT            NULL,
  is_active      TINYINT(1)      NOT NULL DEFAULT 1,
  created_by     BIGINT UNSIGNED NOT NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vendors_name (name),
  CONSTRAINT fk_vendors_tax
    FOREIGN KEY (default_tax_id) REFERENCES taxes (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_vendors_created_by
    FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_vendors_atl_checked
    CHECK (atl_status = 'unknown' OR atl_checked_on IS NOT NULL)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- cheques
--
-- The cheque register. transaction_id is added as a foreign key at the end of
-- this file, once transactions exists, because the two point at each other.
-- ===========================================================================

CREATE TABLE cheques (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  account_id     BIGINT UNSIGNED NOT NULL,
  cheque_number  VARCHAR(30)     NOT NULL,
  payee          VARCHAR(150)    NOT NULL,
  amount         BIGINT          NOT NULL COMMENT 'PKR paisa',
  issue_date     DATE            NOT NULL,
  status         ENUM('issued', 'presented', 'cleared', 'bounced', 'cancelled') NOT NULL DEFAULT 'issued',
  cleared_on     DATE            NULL,
  transaction_id BIGINT UNSIGNED NULL,
  note           VARCHAR(255)    NULL,
  created_by     BIGINT UNSIGNED NOT NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cheques_account_number (account_id, cheque_number),
  CONSTRAINT fk_cheques_account
    FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_cheques_created_by
    FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_cheques_amount CHECK (amount > 0),
  CONSTRAINT chk_cheques_cleared
    CHECK (status <> 'cleared' OR cleared_on IS NOT NULL)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- transactions
--
-- One row per movement of money. A transfer is two rows sharing
-- transfer_group_id, never one row.
--
-- journal_number is the entry's number in the book. It is allocated from the
-- sequences table at the moment of posting, not when the draft is created, so
-- an abandoned draft can never leave a hole in the series. Decision 051.
--
-- client_id, project_id and rebilled_invoice_id carry no foreign key yet.
-- Clients and projects arrive in Phase 2, invoices in Phase 3.
-- ===========================================================================

CREATE TABLE transactions (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  journal_number         VARCHAR(20)     NULL COMMENT 'From sequences, at posting. Null while draft or pending',
  date                   DATE            NOT NULL COMMENT 'Date of payment, not the date it was entered',
  account_id             BIGINT UNSIGNED NOT NULL,
  direction              ENUM('in', 'out') NOT NULL COMMENT 'Direction carries the sign. Amounts are never negative',
  amount                 BIGINT          NOT NULL COMMENT 'PKR paisa. Net effect on the account, the figure balances use',
  currency               CHAR(3)         NOT NULL DEFAULT 'PKR',
  foreign_amount         BIGINT          NULL COMMENT 'Minor units of the foreign currency. Null for PKR',
  fx_rate                DECIMAL(18,6)   NULL COMMENT 'PKR per one unit of the foreign currency',
  fx_rate_source         ENUM('manual', 'bank_advice', 'derived') NULL,
  method                 ENUM('cash', 'account', 'cheque', 'online') NOT NULL,
  description            VARCHAR(255)    NOT NULL,
  category_id            BIGINT UNSIGNED NOT NULL,
  client_id              BIGINT UNSIGNED NULL COMMENT 'No FK until Phase 2 creates clients',
  project_id             BIGINT UNSIGNED NULL COMMENT 'No FK until Phase 2 creates projects',
  is_rebillable          TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Recovered from the client, so it posts to an asset not an expense',
  rebilled_invoice_id    BIGINT UNSIGNED NULL COMMENT 'No FK until Phase 3 creates invoices',
  fund_source            ENUM('operations', 'investor') NOT NULL DEFAULT 'operations',
  paid_by_type           ENUM('company', 'person') NOT NULL DEFAULT 'company',
  paid_by_user_id        BIGINT UNSIGNED NULL COMMENT 'Set when a person paid personally. The company then owes them',
  received_by_user_id    BIGINT UNSIGNED NULL COMMENT 'Set when money landed with a person',
  vendor_id              BIGINT UNSIGNED NULL,
  cheque_id              BIGINT UNSIGNED NULL,
  gross_amount           BIGINT          NOT NULL COMMENT 'PKR paisa before taxes and charges',
  tax_total              BIGINT          NOT NULL DEFAULT 0,
  charges_total          BIGINT          NOT NULL DEFAULT 0,
  reference              VARCHAR(50)     NULL COMMENT 'Cheque or voucher number',
  transfer_group_id      CHAR(36)        NULL COMMENT 'Links the two legs of a transfer',
  status                 ENUM('draft', 'pending', 'posted', 'rejected', 'reversed') NOT NULL DEFAULT 'draft',
  entry_type             ENUM('normal', 'opening', 'historical') NOT NULL DEFAULT 'normal',
  rejection_reason       VARCHAR(255)    NULL,
  reversal_of_id         BIGINT UNSIGNED NULL COMMENT 'This entry reverses that one',
  reversed_by_id         BIGINT UNSIGNED NULL COMMENT 'That entry reverses this one',
  reversal_reason        VARCHAR(255)    NULL,
  created_by             BIGINT UNSIGNED NOT NULL,
  approved_by            BIGINT UNSIGNED NULL,
  posted_at              DATETIME        NULL,
  approval_method        ENUM('owner', 'admin', 'auto') NULL,
  possible_self_approval TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Owner login approved an entry made by someone who shares it. Silent marker',
  created_at             DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at             DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_transactions_journal_number (journal_number),
  UNIQUE KEY uq_transactions_reversal_of (reversal_of_id) COMMENT 'An entry can be reversed once',
  UNIQUE KEY uq_transactions_reversed_by (reversed_by_id),
  KEY idx_transactions_account_status_date (account_id, status, date),
  KEY idx_transactions_client_date (client_id, date),
  KEY idx_transactions_status_created (status, created_at) COMMENT 'The approval inbox',
  KEY idx_transactions_date (date),
  KEY idx_transactions_transfer_group (transfer_group_id),
  CONSTRAINT fk_transactions_account
    FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_currency
    FOREIGN KEY (currency) REFERENCES currencies (code) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_category
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_paid_by
    FOREIGN KEY (paid_by_user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_received_by
    FOREIGN KEY (received_by_user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_vendor
    FOREIGN KEY (vendor_id) REFERENCES vendors (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_cheque
    FOREIGN KEY (cheque_id) REFERENCES cheques (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_reversal_of
    FOREIGN KEY (reversal_of_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_reversed_by
    FOREIGN KEY (reversed_by_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_created_by
    FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transactions_approved_by
    FOREIGN KEY (approved_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,

  -- Money is never zero or negative. Direction carries the sign.
  CONSTRAINT chk_transactions_amounts
    CHECK (amount > 0 AND gross_amount > 0 AND tax_total >= 0 AND charges_total >= 0),

  -- The four money columns must reconcile. SCHEMA.md, Money and currency.
  CONSTRAINT chk_transactions_reconcile
    CHECK (
      (direction = 'out' AND amount = gross_amount + tax_total + charges_total)
      OR
      (direction = 'in'  AND amount = gross_amount - tax_total - charges_total)
    ),

  -- A PKR entry carries no conversion. A foreign entry carries all of it.
  CONSTRAINT chk_transactions_currency
    CHECK (
      (currency = 'PKR' AND foreign_amount IS NULL AND fx_rate IS NULL AND fx_rate_source IS NULL)
      OR
      (currency <> 'PKR' AND foreign_amount > 0 AND fx_rate > 0 AND fx_rate_source IS NOT NULL)
    ),

  -- Paid by a person means naming the person. Decision 020.
  CONSTRAINT chk_transactions_paid_by
    CHECK (
      (paid_by_type = 'company' AND paid_by_user_id IS NULL)
      OR
      (paid_by_type = 'person' AND paid_by_user_id IS NOT NULL)
    ),

  -- An entry in the book has a number and a posting time. One not yet in the
  -- book has neither. This is what makes gapless numbering physically true.
  CONSTRAINT chk_transactions_posted_fields
    CHECK (
      (status IN ('posted', 'reversed')
        AND journal_number IS NOT NULL
        AND posted_at IS NOT NULL
        AND approved_by IS NOT NULL
        AND approval_method IS NOT NULL)
      OR
      (status IN ('draft', 'pending', 'rejected')
        AND journal_number IS NULL
        AND posted_at IS NULL)
    ),

  CONSTRAINT chk_transactions_rejected
    CHECK (status <> 'rejected' OR rejection_reason IS NOT NULL),

  CONSTRAINT chk_transactions_reversed
    CHECK (status <> 'reversed' OR reversed_by_id IS NOT NULL),

  -- A reversing entry always carries its reason. Decision 012.
  CONSTRAINT chk_transactions_reversal_reason
    CHECK (reversal_of_id IS NULL OR reversal_reason IS NOT NULL)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- journal_lines
--
-- The double entry itself. Written by the posting engine, never by the UI.
-- A line is a debit or a credit, never both, never neither.
-- ===========================================================================

CREATE TABLE journal_lines (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id BIGINT UNSIGNED NOT NULL,
  coa_id         BIGINT UNSIGNED NOT NULL,
  debit          BIGINT          NOT NULL DEFAULT 0 COMMENT 'PKR paisa',
  credit         BIGINT          NOT NULL DEFAULT 0 COMMENT 'PKR paisa',
  line_no        INT             NOT NULL COMMENT 'Display order within the entry',
  memo           VARCHAR(255)    NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_journal_lines_order (transaction_id, line_no),
  KEY idx_journal_lines_coa (coa_id, transaction_id),
  CONSTRAINT fk_journal_lines_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_journal_lines_coa
    FOREIGN KEY (coa_id) REFERENCES chart_of_accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_journal_lines_sides
    CHECK (debit >= 0 AND credit >= 0 AND (debit = 0 OR credit = 0) AND (debit > 0 OR credit > 0))
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- transaction_taxes
--
-- The tax lines on one entry. rate_applied and atl_status_used are snapshots,
-- so changing a rate in the taxes table never alters a posted entry.
-- Decision 018.
-- ===========================================================================

CREATE TABLE transaction_taxes (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id  BIGINT UNSIGNED NOT NULL,
  tax_id          BIGINT UNSIGNED NOT NULL,
  base_amount     BIGINT          NOT NULL COMMENT 'PKR paisa the rate was applied to',
  rate_applied    DECIMAL(9,4)    NOT NULL COMMENT 'Snapshot of the rate used',
  atl_status_used ENUM('atl', 'non_atl') NOT NULL,
  atl_party       ENUM('company', 'vendor', 'client', 'employee', 'cardholder') NOT NULL COMMENT 'Whose status decided the rate. Decision 030',
  tax_amount      BIGINT          NOT NULL COMMENT 'PKR paisa',
  is_override     TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'User changed it from the configured rate',
  deducted_by     ENUM('bank', 'customer', 'us', 'platform') NOT NULL,
  statement_id    BIGINT UNSIGNED NULL COMMENT 'No FK until Phase 6 creates withholding_statements',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_transaction_taxes_statement (tax_id, statement_id),
  CONSTRAINT fk_transaction_taxes_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transaction_taxes_tax
    FOREIGN KEY (tax_id) REFERENCES taxes (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_transaction_taxes_amounts
    CHECK (tax_amount >= 0 AND base_amount > 0 AND rate_applied >= 0),
  CONSTRAINT chk_transaction_taxes_not_larger
    CHECK (tax_amount <= base_amount)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- transaction_charges
--
-- Everything deducted that is not a tax: bank charges, forex fees, platform
-- fees, card fees.
-- ===========================================================================

CREATE TABLE transaction_charges (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id BIGINT UNSIGNED NOT NULL,
  type           ENUM('bank_charge', 'forex_fee', 'platform_fee', 'card_fee', 'other') NOT NULL,
  amount         BIGINT          NOT NULL COMMENT 'PKR paisa',
  coa_id         BIGINT UNSIGNED NOT NULL,
  note           VARCHAR(255)    NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_transaction_charges_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_transaction_charges_coa
    FOREIGN KEY (coa_id) REFERENCES chart_of_accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_transaction_charges_amount CHECK (amount > 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- entry_flags
--
-- Warnings the user acknowledged and flags raised for later review. Blocking
-- rules never reach this table, because they stop the insert entirely.
-- Decision 013.
-- ===========================================================================

CREATE TABLE entry_flags (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id  BIGINT UNSIGNED NOT NULL,
  severity        ENUM('warning', 'flag') NOT NULL,
  code            VARCHAR(50)     NOT NULL COMMENT 'possible_duplicate, no_receipt, unusual_amount, closed_client, backdated, thin_description',
  detail          VARCHAR(255)    NOT NULL COMMENT 'Names the record it matched against. A warning the user cannot investigate is one they dismiss by reflex',
  acknowledged_by BIGINT UNSIGNED NULL,
  acknowledged_at DATETIME        NULL,
  resolved        TINYINT(1)      NOT NULL DEFAULT 0,
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_entry_flags_review (resolved, severity),
  CONSTRAINT fk_entry_flags_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_entry_flags_acknowledged_by
    FOREIGN KEY (acknowledged_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_entry_flags_acknowledged
    CHECK ((acknowledged_by IS NULL) = (acknowledged_at IS NULL))
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- attachments
--
-- Receipts and bank advices. Files live on disk outside the web root. Only
-- the record lives here. retain_until is at least ten financial years after
-- the entry date. Decision 033.
-- ===========================================================================

CREATE TABLE attachments (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id BIGINT UNSIGNED NULL COMMENT 'Null while the upload is not yet attached to an entry',
  document_type  ENUM('receipt', 'bank_advice', 'bank_statement', 'tax_certificate',
                      'invoice_received', 'contract', 'other') NOT NULL,
  file_path      VARCHAR(255)    NOT NULL,
  mime           VARCHAR(100)    NOT NULL,
  size_bytes     BIGINT UNSIGNED NOT NULL,
  sha256         CHAR(64)        NOT NULL,
  uploaded_by    BIGINT UNSIGNED NOT NULL,
  retain_until   DATE            NOT NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_attachments_transaction (transaction_id, document_type),
  CONSTRAINT fk_attachments_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_attachments_uploaded_by
    FOREIGN KEY (uploaded_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_attachments_size CHECK (size_bytes > 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- reimbursements
--
-- Paying a person back for company costs they paid personally. The payment
-- itself is an ordinary transaction. This row says which costs it cleared.
-- Decision 020. The amount owed to a person is always computed, never stored.
-- ===========================================================================

CREATE TABLE reimbursements (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  person_user_id BIGINT UNSIGNED NOT NULL,
  transaction_id BIGINT UNSIGNED NOT NULL COMMENT 'The payment back to the person',
  amount         BIGINT          NOT NULL COMMENT 'PKR paisa',
  note           VARCHAR(255)    NULL,
  created_by     BIGINT UNSIGNED NOT NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_reimbursements_transaction (transaction_id),
  CONSTRAINT fk_reimbursements_person
    FOREIGN KEY (person_user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_reimbursements_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_reimbursements_created_by
    FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_reimbursements_amount CHECK (amount > 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- reimbursement_items
--
-- Which personally paid costs one reimbursement covered. A cost can appear
-- once per reimbursement.
-- ===========================================================================

CREATE TABLE reimbursement_items (
  id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reimbursement_id        BIGINT UNSIGNED NOT NULL,
  covered_transaction_id  BIGINT UNSIGNED NOT NULL,
  amount                  BIGINT          NOT NULL COMMENT 'PKR paisa. May be part of the covered cost',
  PRIMARY KEY (id),
  UNIQUE KEY uq_reimbursement_items (reimbursement_id, covered_transaction_id),
  CONSTRAINT fk_reimbursement_items_reimbursement
    FOREIGN KEY (reimbursement_id) REFERENCES reimbursements (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_reimbursement_items_transaction
    FOREIGN KEY (covered_transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_reimbursement_items_amount CHECK (amount > 0)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- period_locks
--
-- Built now, unused. Locking is off by default so months stay open, which is
-- safe only because posted entries are already immutable. Decision 014.
-- Enabling it later is a settings change, not a migration.
-- ===========================================================================

CREATE TABLE period_locks (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  period_month TINYINT UNSIGNED NOT NULL,
  period_year  SMALLINT UNSIGNED NOT NULL,
  locked_by    BIGINT UNSIGNED NOT NULL,
  locked_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note         VARCHAR(255)    NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_period_locks (period_year, period_month),
  CONSTRAINT fk_period_locks_user
    FOREIGN KEY (locked_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_period_locks_month CHECK (period_month BETWEEN 1 AND 12)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_uca1400_ai_ci;

-- ===========================================================================
-- The link that had to wait
--
-- cheques.transaction_id points at transactions, and transactions.cheque_id
-- points back at cheques. One of the two keys has to be added after both
-- tables exist.
-- ===========================================================================

ALTER TABLE cheques
  ADD CONSTRAINT fk_cheques_transaction
  FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ===========================================================================
-- Triggers
--
-- Decision 012 wants posted entries immutable in the service layer AND in the
-- database, because an application rule is one bad script away from being
-- bypassed. These run inside the database on every change, including a change
-- made by hand in phpMyAdmin.
--
-- <=> is the NULL-safe equality operator. a <=> b is true when both are NULL,
-- which plain = is not. Without it every comparison involving a NULL column
-- would be unknown and the check would silently pass.
--
-- SIGNAL raises an error and abandons the statement. MESSAGE_TEXT is limited
-- to 128 characters, which is why these read tersely.
-- ===========================================================================

DELIMITER $$

-- A posted or reversed entry is frozen, except for the four fields a reversal
-- and a later rebilling have to write.
CREATE TRIGGER trg_transactions_immutable
BEFORE UPDATE ON transactions
FOR EACH ROW
BEGIN
  IF OLD.status IN ('posted', 'reversed') THEN

    IF NOT (
         NEW.journal_number         <=> OLD.journal_number
     AND NEW.date                   <=> OLD.date
     AND NEW.account_id             <=> OLD.account_id
     AND NEW.direction              <=> OLD.direction
     AND NEW.amount                 <=> OLD.amount
     AND NEW.currency               <=> OLD.currency
     AND NEW.foreign_amount         <=> OLD.foreign_amount
     AND NEW.fx_rate                <=> OLD.fx_rate
     AND NEW.fx_rate_source         <=> OLD.fx_rate_source
     AND NEW.method                 <=> OLD.method
     AND NEW.description            <=> OLD.description
     AND NEW.category_id            <=> OLD.category_id
     AND NEW.client_id              <=> OLD.client_id
     AND NEW.project_id             <=> OLD.project_id
     AND NEW.is_rebillable          <=> OLD.is_rebillable
     AND NEW.fund_source            <=> OLD.fund_source
     AND NEW.paid_by_type           <=> OLD.paid_by_type
     AND NEW.paid_by_user_id        <=> OLD.paid_by_user_id
     AND NEW.received_by_user_id    <=> OLD.received_by_user_id
     AND NEW.vendor_id              <=> OLD.vendor_id
     AND NEW.cheque_id              <=> OLD.cheque_id
     AND NEW.gross_amount           <=> OLD.gross_amount
     AND NEW.tax_total              <=> OLD.tax_total
     AND NEW.charges_total          <=> OLD.charges_total
     AND NEW.reference              <=> OLD.reference
     AND NEW.transfer_group_id      <=> OLD.transfer_group_id
     AND NEW.entry_type             <=> OLD.entry_type
     AND NEW.rejection_reason       <=> OLD.rejection_reason
     AND NEW.reversal_of_id         <=> OLD.reversal_of_id
     AND NEW.reversal_reason        <=> OLD.reversal_reason
     AND NEW.created_by             <=> OLD.created_by
     AND NEW.approved_by            <=> OLD.approved_by
     AND NEW.posted_at              <=> OLD.posted_at
     AND NEW.approval_method        <=> OLD.approval_method
     AND NEW.possible_self_approval <=> OLD.possible_self_approval
     AND NEW.created_at             <=> OLD.created_at
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Posted entries are immutable. Reverse and re-enter instead.';
    END IF;

    -- The only status move allowed after posting.
    IF NOT (NEW.status <=> OLD.status)
       AND NOT (OLD.status = 'posted' AND NEW.status = 'reversed') THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A posted entry may only move to reversed.';
    END IF;

    -- reversed_by_id is written once, by the reversal.
    IF NOT (NEW.reversed_by_id <=> OLD.reversed_by_id)
       AND OLD.reversed_by_id IS NOT NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An entry is reversed once. Its reversal cannot be changed.';
    END IF;

  END IF;
END$$

-- Nothing is ever hard deleted from the books. Decision 007.
CREATE TRIGGER trg_transactions_no_delete
BEFORE DELETE ON transactions
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Transactions are never deleted. Reverse the entry instead.';
END$$

-- Journal lines are written once, when an entry posts. A correction is new
-- lines on a new entry, never an edit of old ones.
CREATE TRIGGER trg_journal_lines_no_update
BEFORE UPDATE ON journal_lines
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Journal lines cannot be changed. Post a reversing entry.';
END$$

CREATE TRIGGER trg_journal_lines_no_delete
BEFORE DELETE ON journal_lines
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Journal lines are never deleted. Post a reversing entry.';
END$$

DELIMITER ;

-- ===========================================================================

INSERT INTO schema_migrations (filename)
VALUES ('004_phase1_tables.sql')
ON DUPLICATE KEY UPDATE filename = filename;
