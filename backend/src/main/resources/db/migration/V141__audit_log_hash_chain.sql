-- H11 gap fix: tamper-evidence hash-lanc az audit logokhoz
-- SHA-256 hash az aktualis bejegyzes tartalmabol + elozo bejegyzes hash-e (lancolashoz)

ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS entry_hash VARCHAR(64);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS previous_hash VARCHAR(64);

CREATE UNIQUE INDEX IF NOT EXISTS idx_audit_log_entry_hash ON audit_log (entry_hash);
