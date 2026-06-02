-- V285 — FK-ÉRTÉKTÁR (2026-06-02): intézményi (közös) Google-fiók jelölés a kétlépcsős belépéshez.
--
-- A 8 értéktár-operátor Google-fiók (G_SZEGED_ET stb.) NEM személyt azonosít, hanem az intézményi
-- értéktárat (közös szeged.ebc@gmail.com típusú email). A kétlépcsős login ezeket a fiókokat
-- ismeri fel: Google OAuth siker után a dolgozó kiválasztja a SAJÁT nevét + személyes jelszó.
--
-- A `shared_account` flag jelöli az intézményi fiókokat. A személyes workerek (pl. Bali Henriett)
-- shared_account = false maradnak, és NEM kapnak googleLoginEnabled-et (a 2. lépcső jelszavas).
--
-- A 8 kód a V282__vault_workers_branch_assignment.sql-lel egyező hivatalos értéktár-account lista.
-- Multi-tenant: EBC company-re szűrve. Idempotens (IF NOT EXISTS + WHERE).

ALTER TABLE worker ADD COLUMN IF NOT EXISTS shared_account BOOLEAN NOT NULL DEFAULT FALSE;

DO $$
DECLARE
    ebc_company_id UUID;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V285: EBC company nem található — skip.';
        RETURN;
    END IF;

    UPDATE worker
       SET shared_account = TRUE
     WHERE company_id = ebc_company_id
       AND code IN (
            'G_SZEGED_ET', 'G_ET_DEBRECEN', 'G_ET_KECSKEMET', 'G_ET_NYIREGYHAZA',
            'G_ET_BEKESCSABA', 'G_ET_SZEKSZARD', 'G_KAPOSVAR_ET', 'G_LACIKA_PECS'
       )
       AND shared_account IS DISTINCT FROM TRUE;
END $$;
