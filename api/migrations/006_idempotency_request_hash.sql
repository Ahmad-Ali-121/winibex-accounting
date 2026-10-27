-- 006_idempotency_request_hash
--
-- Each idempotency key remembers a fingerprint of the request it was first
-- used with. Defect F7, decision 059.
--
-- Until now a repeated key was checked only for the same person and the same
-- address. The content was never compared, so a changed request under an old
-- key was answered with the old result. In the Phase 1 test an entry changed
-- from 6,000 to 6,500 after a refused posting was "saved and posted" as 6,000.
--
-- From here the middleware stores a SHA-256 of the request body with the key,
-- and refuses the same key with a different body. Rows written before this
-- migration have no fingerprint and are replayed as before; they expire
-- within 24 hours, so the gap closes by itself.
--
-- A new migration, not an edit of 001, because 001 is on production.
-- Decision 052.

ALTER TABLE idempotency_keys
  ADD COLUMN request_hash CHAR(64) NULL COMMENT 'SHA-256 of the request body the key was first used with' AFTER endpoint;

INSERT INTO schema_migrations (filename)
VALUES ('006_idempotency_request_hash.sql')
ON DUPLICATE KEY UPDATE filename = filename;
