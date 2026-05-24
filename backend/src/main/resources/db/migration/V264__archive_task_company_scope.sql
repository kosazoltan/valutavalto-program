-- V264: archive_task tábla multi-tenant izoláció
-- Audit finding F3.1: ArchiveTask entity nem tartalmazott company_id-t → cross-tenant IDOR lehetséges volt.
-- Fix: company_id FK hozzáadása, backfill branch-ownership alapján (criteria-ból),
--      csak utolsó fallback: az első meglévő company (Copilot P1 fix).

DO $$
DECLARE
    first_company_id UUID;
BEGIN
    -- 1. Oszlop hozzáadása (nullable először a backfill miatt)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'archive_task' AND column_name = 'company_id'
    ) THEN
        ALTER TABLE archive_task ADD COLUMN company_id UUID REFERENCES company(id);
    END IF;

    -- 2a. Backfill branch-ownership alapján: criteria-ban lévő branchId → branch.company_id
    --     Formátum: "branchId=<UUID>;yearMonth=YYYY-MM"
    UPDATE archive_task t
    SET company_id = b.company_id
    FROM branch b
    WHERE t.company_id IS NULL
      AND t.criteria IS NOT NULL
      AND t.criteria ~ 'branchId=[0-9a-f\-]{36}'
      AND b.id = (
          regexp_match(t.criteria, 'branchId=([0-9a-f\-]{36})')
      )[1]::UUID;

    -- 2b. Fallback: ha criteria-ból nem sikerült meghatározni, az első (legrégebbi) céget használjuk.
    --     Indoklás: archive_task a V264 előtt új feature volt (nincsenek éles multi-tenant sorok);
    --     ez a fallback idempotens és biztonsági szempontból elfogadható üres tábla esetén.
    SELECT id INTO first_company_id FROM company ORDER BY created_at ASC LIMIT 1;
    IF first_company_id IS NOT NULL THEN
        UPDATE archive_task SET company_id = first_company_id WHERE company_id IS NULL;
    END IF;

    -- 3. NOT NULL constraint (csak ha minden sor kitöltött)
    IF NOT EXISTS (
        SELECT 1 FROM archive_task WHERE company_id IS NULL
    ) THEN
        ALTER TABLE archive_task ALTER COLUMN company_id SET NOT NULL;
    END IF;
END $$;

-- 4. Index a company-scoped lekérdezésekhez
CREATE INDEX IF NOT EXISTS idx_archive_task_company_id ON archive_task (company_id);
