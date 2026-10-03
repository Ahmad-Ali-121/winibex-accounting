-- 000_schema_migrations
--
-- The ledger of which migrations have been applied. Every other migration
-- file records itself here as its last statement, so the record is the same
-- whether the file was applied by the local runner or pasted into phpMyAdmin
-- on Hostinger.
--
-- Safe to run twice.

CREATE TABLE IF NOT EXISTS schema_migrations (
  filename    VARCHAR(190) NOT NULL,
  applied_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  checksum    CHAR(64)     NULL COMMENT 'SHA-256 of the file. Set by the local runner, null when applied through phpMyAdmin',
  PRIMARY KEY (filename)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

INSERT INTO schema_migrations (filename)
VALUES ('000_schema_migrations.sql')
ON DUPLICATE KEY UPDATE filename = filename;
