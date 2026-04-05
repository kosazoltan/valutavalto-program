-- V139: AML bejelentési határidő mező + OVERDUE státusz támogatás
-- 2017. évi LIII. tv. 33.§ — 2 munkanapon belüli bejelentési kötelezettség

ALTER TABLE aml_report ADD COLUMN IF NOT EXISTS deadline_at TIMESTAMP;

-- Meglévő DRAFT rekordokhoz: deadline = created_at + 2 nap (közelítés, munkanap logika kódban)
UPDATE aml_report
SET deadline_at = created_at + INTERVAL '2 days'
WHERE deadline_at IS NULL AND status = 'DRAFT';

CREATE INDEX IF NOT EXISTS idx_aml_report_deadline ON aml_report(deadline_at);
