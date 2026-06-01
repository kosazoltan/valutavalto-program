-- V282 — FK (2026-06-01): a Google-login értéktár-account-ok HAZAI fiókjának javítása.
--
-- GYÖKÉROK: a V179__google_login_employee_seed.sql MINDEN account-ot a `default_branch_id`-hez
-- (= a TISZA fiók) kötött. Emiatt a 8 értéktár-operátor account (G_SZEGED_ET stb.) branch_id-je
-- a TISZA, nem a saját értéktára → a JWT branchId rossz → az AccessScopeService régió-scope-ja
-- üres/rossz → az átadás-átvétel "Cél iroda" listából HIÁNYZIK a "Helyi Pénztárak" csoport, ÉS a
-- saját értéktár tévesen megjelenik a "Társ értéktárak" között (a peerVaults nem zárja ki).
-- (A screenshoton: "Szeged Ertektar / Telephely: Tisza Sarok".)
--
-- A 8 értéktár + account-mapping a hivatalos értéktár-törzs (Kósa Zoltán táblázata, 2026-06-01) és a
-- V145/V254 region-seed alapján egyértelmű. A két cashier-jellegű account (G_PECS_RAKOCZI =
-- Pécs Rákóczi, NEM értéktár; a Pécs értéktár a BR120 Megyeri/Plaza; valamint G_KOSZTYU_CSABA)
-- SZÁNDÉKOSAN NEM kerül átkötésre — azok nem értéktár-operátorok.
--
-- Multi-tenant: minden UPDATE company_id='EBC'-re szűr. Idempotens (a már helyes rekordot nem írja).

DO $$
DECLARE
    ebc_company_id UUID;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NULL THEN
        RAISE NOTICE 'V282: EBC company nem található — skip.';
        RETURN;
    END IF;

    -- worker.code -> értéktár branch.code páros
    UPDATE worker w
       SET branch_id = b.id, updated_at = NOW()
      FROM branch b
     WHERE w.company_id = ebc_company_id
       AND b.company_id = ebc_company_id
       AND (
            (w.code = 'G_SZEGED_ET'      AND b.code = 'BR020') OR
            (w.code = 'G_ET_DEBRECEN'    AND b.code = 'BR050') OR
            (w.code = 'G_ET_KECSKEMET'   AND b.code = 'BR040') OR
            (w.code = 'G_ET_NYIREGYHAZA' AND b.code = 'BR063') OR
            (w.code = 'G_ET_BEKESCSABA'  AND b.code = 'BR075') OR
            (w.code = 'G_ET_SZEKSZARD'   AND b.code = 'BR010') OR
            (w.code = 'G_KAPOSVAR_ET'    AND b.code = 'BR145') OR
            (w.code = 'G_LACIKA_PECS'    AND b.code = 'BR120')
       )
       AND w.branch_id IS DISTINCT FROM b.id;
END $$;
