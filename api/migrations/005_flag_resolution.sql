-- 005_flag_resolution
--
-- How a flag in "To review" gets cleared. Decision 056, defect D2.
--
-- Until now nothing could clear a flag, so the review list only ever grew.
-- From here a flag is resolved in one of two ways, and the row says which:
--
--   automatically   the cause went away, for example a receipt was attached.
--                   resolved_by stays NULL, because no person did it.
--   by a person     the owner or an admin marked it reviewed, with a note
--                   saying why. resolved_by names them.
--
-- A resolved flag is never deleted. It stays as the record of what was
-- noticed and how it was dealt with.
--
-- This is a new migration, not an edit of 004, because 004 is on production.
-- Decision 052: after the first deploy a correction is always a new file.

ALTER TABLE entry_flags
  ADD COLUMN resolved_by     BIGINT UNSIGNED NULL COMMENT 'Who marked it reviewed. NULL when it resolved itself' AFTER resolved,
  ADD COLUMN resolved_at     DATETIME        NULL COMMENT 'UTC' AFTER resolved_by,
  ADD COLUMN resolution_note VARCHAR(255)    NULL COMMENT 'Why it needs nothing more, or what resolved it' AFTER resolved_at,
  ADD CONSTRAINT fk_entry_flags_resolved_by
    FOREIGN KEY (resolved_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- ===========================================================================
-- Bring existing flags into line before the rule below is switched on.
-- ===========================================================================

-- No flag could be resolved before this migration, so this should touch
-- nothing. It is here so the CHECK below can never fail on old data.
UPDATE entry_flags
   SET resolved_at = created_at,
       resolution_note = 'Resolved before migration 005'
 WHERE resolved = 1 AND resolved_at IS NULL;

-- Defect D1: every entry was given a "No receipt" flag, including entries
-- that never need one. Decision 056 and UI-GUIDE: money in, transfers between
-- the company's own accounts, reimbursements, the opening entry and manual
-- journals do not. Those flags resolve themselves here.
UPDATE entry_flags f
  JOIN transactions t ON t.id = f.transaction_id
  JOIN categories c ON c.id = t.category_id
  JOIN chart_of_accounts a ON a.id = c.coa_id
   SET f.resolved = 1,
       f.resolved_at = UTC_TIMESTAMP(),
       f.resolution_note = 'No receipt is needed for this kind of entry. Decision 056'
 WHERE f.code = 'NO_RECEIPT'
   AND f.resolved = 0
   AND (t.direction = 'in'
        OR t.transfer_group_id IS NOT NULL
        OR t.entry_type <> 'normal'
        OR a.code IN ('2114', '1118'));

-- A receipt attached after the flag was raised resolves it.
UPDATE entry_flags f
   SET f.resolved = 1,
       f.resolved_at = UTC_TIMESTAMP(),
       f.resolution_note = 'Receipt attached'
 WHERE f.code = 'NO_RECEIPT'
   AND f.resolved = 0
   AND EXISTS (SELECT 1 FROM attachments x
                WHERE x.transaction_id = f.transaction_id
                  AND x.document_type = 'receipt');

-- ===========================================================================
-- An open flag carries no resolution. A resolved one always says when and
-- why, so the review list can show it.
-- ===========================================================================

ALTER TABLE entry_flags
  ADD CONSTRAINT chk_entry_flags_resolved
    CHECK (
      (resolved = 0 AND resolved_by IS NULL AND resolved_at IS NULL AND resolution_note IS NULL)
      OR
      (resolved = 1 AND resolved_at IS NOT NULL AND resolution_note IS NOT NULL)
    );

-- ===========================================================================

INSERT INTO schema_migrations (filename)
VALUES ('005_flag_resolution.sql')
ON DUPLICATE KEY UPDATE filename = filename;
