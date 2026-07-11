-- V356: darius_report_line tenant defense-in-depth (FS-15 utótakarítás).
-- Minta: darius_fixing_request_line (V355) — a sor maga is hordozza a company_id-t.
-- Backfill a szülő darius_daily_report-ból; az fk_darius_line_report
-- (ON DELETE CASCADE, V107) garantálja, hogy minden sornak van szülője,
-- ezért a backfill totális és a NOT NULL azonnal kimondható.
-- FK a company-ra szándékosan NINCS (V350–V355 precedens).
ALTER TABLE darius_report_line ADD COLUMN IF NOT EXISTS company_id UUID;

UPDATE darius_report_line l
   SET company_id = r.company_id
  FROM darius_daily_report r
 WHERE l.report_id = r.id
   AND l.company_id IS NULL;

ALTER TABLE darius_report_line ALTER COLUMN company_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS ix_darius_line_company_report
    ON darius_report_line (company_id, report_id);
