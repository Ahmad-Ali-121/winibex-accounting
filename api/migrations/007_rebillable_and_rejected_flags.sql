-- 007_rebillable_and_rejected_flags
--
-- Two of the open items Ahmad asked Claude to decide. Decision 062.
--
-- O1. Rebillable spend is recorded by picking what it really was and ticking
-- "Client will pay this back". The tick posts it to 1123 either way, but the
-- category keeps what kind of cost it was. The separate money-out category on
-- 1123 is switched off, never deleted, so any entry that used it keeps it.
-- "absorbed" leaves the advertising category's name: the tick says which.
--
-- N. A rejected entry is not in the books, so its flags describe nothing that
-- needs review. From now on rejecting resolves them; this resolves the ones
-- already sitting on rejected entries.
--
-- A new file, decision 052.

UPDATE categories c
  JOIN chart_of_accounts a ON a.id = c.coa_id
   SET c.is_active = 0
 WHERE a.code = '1123' AND c.direction = 'out';

UPDATE categories
   SET name = 'Client advertising spend'
 WHERE name = 'Client advertising spend, absorbed';

UPDATE entry_flags f
  JOIN transactions t ON t.id = f.transaction_id
   SET f.resolved = 1,
       f.resolved_at = UTC_TIMESTAMP(),
       f.resolution_note = 'Entry rejected'
 WHERE t.status = 'rejected' AND f.resolved = 0;

INSERT INTO schema_migrations (filename)
VALUES ('007_rebillable_and_rejected_flags.sql')
ON DUPLICATE KEY UPDATE filename = filename;
