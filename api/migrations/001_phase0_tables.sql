-- 001_phase0_tables
--
-- Everything Phase 0 needs and nothing more. Transactions, taxes, invoices and
-- payroll arrive in their own phase's migration, so the accountant's review can
-- still change those tables before they exist. Decision 035.
--
-- Conventions used throughout:
--   Surrogate keys are BIGINT UNSIGNED AUTO_INCREMENT.
--   Money is BIGINT in paisa. Never DECIMAL, never FLOAT.
--   Times are DATETIME holding UTC, not TIMESTAMP. TIMESTAMP stops working in
--     2038 and silently converts by session time zone; books are kept ten years
--     and some dates are in the future, so neither is acceptable.
--   Booleans are TINYINT(1).
--   Foreign keys are RESTRICT because nothing in this system is ever deleted.

-- ---------------------------------------------------------------------------
-- Currencies
-- ---------------------------------------------------------------------------

CREATE TABLE currencies (
  code         CHAR(3)          NOT NULL,
  name         VARCHAR(50)      NOT NULL,
  symbol       VARCHAR(8)       NOT NULL,
  minor_units  TINYINT UNSIGNED NOT NULL DEFAULT 2 COMMENT 'Decimal places. 2 for every currency used today',
  is_active    TINYINT(1)       NOT NULL DEFAULT 1,
  PRIMARY KEY (code),
  CONSTRAINT chk_currencies_minor_units CHECK (minor_units BETWEEN 0 AND 4)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------

CREATE TABLE users (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name                  VARCHAR(100)    NOT NULL,
  email                 VARCHAR(190)    NOT NULL,
  password_hash         VARCHAR(255)    NOT NULL COMMENT 'The algorithm is readable from the value itself, so it can change without locking anyone out',
  must_change_password  TINYINT(1)      NOT NULL DEFAULT 0,
  role                  ENUM('owner', 'admin', 'staff') NOT NULL,
  approval_limit        BIGINT UNSIGNED NULL COMMENT 'Paisa. Admins only. Null means unlimited',
  auto_approve_own      TINYINT(1)      NOT NULL DEFAULT 0,
  shares_owner_login    TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Set for people who also use the winibexoffice login',
  is_active             TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'A user is deactivated, never deleted',
  created_at            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- There is exactly one owner account. A unique index on a column that is 1
  -- for the owner and NULL for everyone else enforces that, because NULLs do
  -- not collide in a unique index.
  owner_singleton       TINYINT UNSIGNED GENERATED ALWAYS AS (CASE WHEN role = 'owner' THEN 1 END) STORED,

  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  UNIQUE KEY uq_users_single_owner (owner_singleton),
  CONSTRAINT chk_users_limit_is_admin_only
    CHECK (approval_limit IS NULL OR role = 'admin'),
  CONSTRAINT chk_users_auto_approve_not_staff
    CHECK (auto_approve_own = 0 OR role IN ('owner', 'admin'))
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Sessions
-- ---------------------------------------------------------------------------

CREATE TABLE refresh_tokens (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id         BIGINT UNSIGNED NOT NULL,
  token_hash      CHAR(64)        NOT NULL COMMENT 'SHA-256 of the token. The token itself is never stored',
  family_id       CHAR(36)        NOT NULL COMMENT 'One login session. Reuse of a rotated token revokes the whole family',
  expires_at      DATETIME        NOT NULL,
  revoked_at      DATETIME        NULL,
  replaced_by_id  BIGINT UNSIGNED NULL COMMENT 'Set on rotation',
  ip              VARCHAR(45)     NULL,
  user_agent      VARCHAR(255)    NULL,
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_refresh_tokens_hash (token_hash),
  KEY idx_refresh_tokens_family (family_id, revoked_at),
  KEY idx_refresh_tokens_user (user_id, expires_at),
  CONSTRAINT fk_refresh_tokens_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_refresh_tokens_replaced_by
    FOREIGN KEY (replaced_by_id) REFERENCES refresh_tokens (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

CREATE TABLE settings (
  setting_key  VARCHAR(100) NOT NULL COMMENT 'Not named key, which is a reserved word',
  value        TEXT         NULL,
  value_type   ENUM('string', 'int', 'bool', 'date', 'json') NOT NULL DEFAULT 'string',
  description  VARCHAR(255) NOT NULL DEFAULT '',
  updated_by   BIGINT UNSIGNED NULL,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (setting_key),
  CONSTRAINT fk_settings_updated_by
    FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Company profile, one row only
-- ---------------------------------------------------------------------------

CREATE TABLE company_profile (
  id                  TINYINT UNSIGNED NOT NULL DEFAULT 1,
  legal_name          VARCHAR(150) NOT NULL,
  trade_name          VARCHAR(150) NOT NULL DEFAULT '',
  ntn                 VARCHAR(20)  NOT NULL DEFAULT '',
  strn_pra            VARCHAR(20)  NOT NULL DEFAULT '' COMMENT 'Blank until PRA registration, if it ever happens',
  pseb_reg_no         VARCHAR(40)  NOT NULL DEFAULT '',
  pseb_valid_until    DATE         NULL COMMENT 'Drives the certificate expiry warning',
  secp_reg_no         VARCHAR(40)  NOT NULL DEFAULT '',
  paid_up_capital     BIGINT       NOT NULL DEFAULT 0 COMMENT 'Paisa. Drives the audit exemption note on the statements',
  address             VARCHAR(255) NOT NULL DEFAULT '',
  phone               VARCHAR(40)  NOT NULL DEFAULT '',
  email               VARCHAR(190) NOT NULL DEFAULT '',
  website             VARCHAR(190) NOT NULL DEFAULT '',
  logo_path           VARCHAR(255) NULL,
  bank_details_text   TEXT         NULL,
  default_terms_text  TEXT         NULL,
  updated_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT chk_company_profile_single_row CHECK (id = 1)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- FBR return heads, seeded empty until the accountant supplies the mapping
-- ---------------------------------------------------------------------------

CREATE TABLE fbr_return_heads (
  code           VARCHAR(20)  NOT NULL COMMENT 'Return line code',
  name           VARCHAR(200) NOT NULL,
  schedule       VARCHAR(100) NOT NULL DEFAULT '',
  tax_year_from  SMALLINT UNSIGNED NULL COMMENT 'Return formats change between years',
  tax_year_to    SMALLINT UNSIGNED NULL,
  PRIMARY KEY (code),
  CONSTRAINT chk_fbr_return_heads_years
    CHECK (tax_year_to IS NULL OR tax_year_from IS NULL OR tax_year_to >= tax_year_from)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Chart of accounts
-- ---------------------------------------------------------------------------

CREATE TABLE chart_of_accounts (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code                  VARCHAR(10)     NOT NULL COMMENT 'Four digits. First digit is the class',
  name                  VARCHAR(100)    NOT NULL,
  type                  ENUM('asset', 'liability', 'equity', 'income', 'expense') NOT NULL,
  parent_id             BIGINT UNSIGNED NULL,
  fbr_return_head_code  VARCHAR(20)     NULL COMMENT 'Null until the accountant supplies the mapping',
  normal_balance        ENUM('debit', 'credit') NOT NULL COMMENT 'Contra accounts such as 1219 are credit despite being assets',
  is_header             TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Grouping only, never posted to by any path',
  is_system             TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Cannot be renamed or deactivated',
  allow_manual_posting  TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'False for control accounts, written only by their own module',
  is_active             TINYINT(1)      NOT NULL DEFAULT 1,
  created_at            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_chart_of_accounts_code (code),
  KEY idx_chart_of_accounts_type (type, code),
  CONSTRAINT fk_chart_of_accounts_parent
    FOREIGN KEY (parent_id) REFERENCES chart_of_accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_chart_of_accounts_return_head
    FOREIGN KEY (fbr_return_head_code) REFERENCES fbr_return_heads (code) ON DELETE RESTRICT ON UPDATE RESTRICT,
  -- An account being its own parent is checked in the service layer, not here.
  -- MariaDB refuses a CHECK clause that mentions an AUTO_INCREMENT column, and
  -- the case cannot arise on insert anyway because the id does not exist yet.
  CONSTRAINT chk_chart_of_accounts_header_not_postable
    CHECK (is_header = 0 OR allow_manual_posting = 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Categories, what the user picks on the entry form
-- ---------------------------------------------------------------------------

CREATE TABLE categories (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(100)    NOT NULL,
  main_head  ENUM('revenue', 'cgs', 'admin', 'selling', 'financial', 'taxation', 'balance_sheet') NOT NULL,
  direction  ENUM('in', 'out') NOT NULL,
  coa_id     BIGINT UNSIGNED NOT NULL COMMENT 'Which ledger account this posts to',
  is_active  TINYINT(1)      NOT NULL DEFAULT 1,
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_name (name),
  KEY idx_categories_head (main_head, direction, is_active),
  CONSTRAINT fk_categories_coa
    FOREIGN KEY (coa_id) REFERENCES chart_of_accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Accounts, the real places money sits
-- ---------------------------------------------------------------------------

CREATE TABLE accounts (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name           VARCHAR(100)    NOT NULL COMMENT 'Winibex bank, Office cash, Petty cash',
  type           ENUM('bank', 'cash', 'petty_cash', 'cheque', 'pass_through') NOT NULL,
  coa_id         BIGINT UNSIGNED NOT NULL COMMENT 'The ledger code whose posted lines make up this balance',
  owner_user_id  BIGINT UNSIGNED NULL COMMENT 'Set for pass-through accounts, which are a person own account holding company money in transit',
  opening_date   DATE            NOT NULL COMMENT 'Earliest date any entry on this account may carry',
  is_active      TINYINT(1)      NOT NULL DEFAULT 1,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_accounts_name (name),
  UNIQUE KEY uq_accounts_coa (coa_id) COMMENT 'One ledger code per account, or a balance belongs to two places at once',
  CONSTRAINT fk_accounts_coa
    FOREIGN KEY (coa_id) REFERENCES chart_of_accounts (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_accounts_owner
    FOREIGN KEY (owner_user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_accounts_pass_through_has_owner
    CHECK (type <> 'pass_through' OR owner_user_id IS NOT NULL)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Sequences, gapless numbering
-- ---------------------------------------------------------------------------

CREATE TABLE sequences (
  name        VARCHAR(50)     NOT NULL COMMENT 'journal, invoice, quotation, receipt, voucher',
  prefix      VARCHAR(10)     NOT NULL DEFAULT '',
  next_value  BIGINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Allocated with SELECT ... FOR UPDATE inside the caller transaction, so a rollback leaves no gap',
  PRIMARY KEY (name),
  CONSTRAINT chk_sequences_next_value CHECK (next_value >= 1)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Audit log, append only
-- ---------------------------------------------------------------------------

CREATE TABLE audit_log (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NULL COMMENT 'Null for actions by a job rather than a person',
  table_name   VARCHAR(64)     NOT NULL,
  record_id    BIGINT UNSIGNED NULL,
  action       VARCHAR(30)     NOT NULL COMMENT 'insert, update, status change, login, and so on',
  before_json  JSON            NULL COMMENT 'Text on MariaDB. Stringify on write, parse on read',
  after_json   JSON            NULL,
  ip           VARCHAR(45)     NULL,
  created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_log_record (table_name, record_id, created_at),
  KEY idx_audit_log_user (user_id, created_at),
  CONSTRAINT fk_audit_log_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Idempotency keys, the only table anything ever deletes from
-- ---------------------------------------------------------------------------

CREATE TABLE idempotency_keys (
  idempotency_key  CHAR(36)        NOT NULL COMMENT 'Not named key, which is a reserved word',
  user_id          BIGINT UNSIGNED NOT NULL,
  endpoint         VARCHAR(120)    NOT NULL,
  response_json    JSON            NULL COMMENT 'Returned as-is on a repeat request',
  created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (idempotency_key),
  KEY idx_idempotency_keys_expiry (created_at),
  CONSTRAINT fk_idempotency_keys_user
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------

INSERT INTO schema_migrations (filename)
VALUES ('001_phase0_tables.sql')
ON DUPLICATE KEY UPDATE filename = filename;
