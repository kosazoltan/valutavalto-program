-- V93: MNB riport retry és státusz oszlopok
-- DRAFT → SUBMITTED → ACKNOWLEDGED/REJECTED státuszflow

ALTER TABLE mnb_report
    ADD COLUMN IF NOT EXISTS retry_count        INTEGER      NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_retry_at      TIMESTAMP,
    ADD COLUMN IF NOT EXISTS mnb_reference_number VARCHAR(100),
    ADD COLUMN IF NOT EXISTS submission_error   TEXT,
    ADD COLUMN IF NOT EXISTS acknowledged_at    TIMESTAMP,
    ADD COLUMN IF NOT EXISTS rejected_at        TIMESTAMP,
    ADD COLUMN IF NOT EXISTS rejection_reason_detail TEXT;

COMMENT ON COLUMN mnb_report.retry_count             IS 'Újraküldési kísérletek száma (max 3)';
COMMENT ON COLUMN mnb_report.last_retry_at           IS 'Utolsó újraküldési kísérlet időpontja';
COMMENT ON COLUMN mnb_report.mnb_reference_number    IS 'MNB által visszaadott hivatkozási szám';
COMMENT ON COLUMN mnb_report.submission_error        IS 'Utolsó beküldési hiba szövege';
COMMENT ON COLUMN mnb_report.acknowledged_at         IS 'MNB elfogadás időpontja';
COMMENT ON COLUMN mnb_report.rejected_at             IS 'MNB elutasítás időpontja';
COMMENT ON COLUMN mnb_report.rejection_reason_detail IS 'MNB elutasítási indoklás (részletes)';
