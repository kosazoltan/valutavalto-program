-- V264: archive_task tábla multi-tenant izoláció
-- Audit finding F3.1: ArchiveTask entity nem tartalmazott company_id-t → cross-tenant IDOR lehetséges volt.
-- Fix: company_id FK hozzáadása, backfill első meglévő company-val (ha van adat),
--      majd NOT NULL constraint + index.

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

    -- 2. Backfill: ha vannak sorok company_id nélkül, az első céggel töltjük (rendszer-szintű feladat)
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
