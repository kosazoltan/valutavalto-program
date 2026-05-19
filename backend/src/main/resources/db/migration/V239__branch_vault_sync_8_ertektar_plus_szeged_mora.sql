-- V239: Branch t\xE1bla sync — 8 értéktár (vault) + 1 hiányzó pénztár beszúrása
--
-- Kósa Zoltán user-direktíva (2026-05-19 14:30 CEST, Google Sheets a 73 iroda
-- listájával): "Ennek kellene lenni a pénztár adatbázisban is, itt jól
-- azonosíthatóak az értéktárak, az értéktári program csak értéktárra
-- lehessen telepíteni, ne hozzon föl pénztárakat."
--
-- DIAGNÓZIS:
-- - Sheet: 73 iroda, ebből 8 értéktár (region_code = 10/20/40/50/63/75/120/145)
-- - Production: 66 iroda, **0 db `is_vault=TRUE`** — a Setup Wizard értéktáros
--   módja az összes 66 selectable iroda-t mutatja a graceful fallback miatt
-- - 9 hiány: 8 értéktár (BR010, BR020, BR040, BR050, BR063, BR075, BR120, BR145)
--   + 1 pénztár (BR026 Szeged Móra)
--
-- FIX: IDéazt INSERT-eli a 9 üj rekordot, idempotens (ON CONFLICT DO NOTHING).
-- Plus a 8 értéktárra `is_vault=TRUE` (akkor is ha már létezett és nem flag-elt).
-- Az FK mezőkön (bank_code, branch_type_did, country_did, branch_status_did,
-- company_id) a már létező EBC iroda (template = BR009 Dombóvár Tesco) értékeit
-- klon-oljuk. Így NEM kell hard-code-olt UUID-okat ismerni.

DO $$
DECLARE
    v_company_id UUID;
    v_branch_type_did UUID;
    v_country_did UUID;
    v_branch_status_did UUID;
    v_bank_code VARCHAR(20);
    inserted_count INT;
    updated_count INT;
BEGIN
    -- Template-FK értékek a már létező BR009-ből (Dombóvár Tesco — EBC cég, magyar
    -- pénztár, magyar cím). Ha BR009 nem létezne, fall-back: az első EBC iroda.
    SELECT b.company_id, b.bank_code, b.branch_type_did, b.country_did, b.branch_status_did
      INTO v_company_id, v_bank_code, v_branch_type_did, v_country_did, v_branch_status_did
      FROM branch b
      JOIN company c ON c.id = b.company_id
     WHERE c.code = 'EBC' AND b.code = 'BR009'
     LIMIT 1;

    IF v_company_id IS NULL THEN
        SELECT b.company_id, b.bank_code, b.branch_type_did, b.country_did, b.branch_status_did
          INTO v_company_id, v_bank_code, v_branch_type_did, v_country_did, v_branch_status_did
          FROM branch b
          JOIN company c ON c.id = b.company_id
         WHERE c.code = 'EBC'
         LIMIT 1;
    END IF;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'V239: EBC cég vagy más template-iroda nem található — még a v0_1 alap-adat sem fut le?';
    END IF;

    -- 8 értéktár + 1 pénztár INSERT (ON CONFLICT DO NOTHING).
    -- A name, address, city, zip_code, is_vault, region_code közvetlenül a
    -- Google Sheets-ből. A region_code a KESZLEX legacy körzet-kód.
    WITH new_branches(code, name, address, city, zip_code, is_vault, region_code) AS (VALUES
        ('BR010', 'Szekszárd Értéktár',     'Széchenyi u. 26.',  'Szekszárd',     '7100', TRUE,  '10'),
        ('BR020', 'Szeged Értéktár',        'Tisza L. krt 57',    'Szeged',         '6722', TRUE,  '20'),
        ('BR026', 'Szeged Móra',             'Szabadkai út 7.',     'Szeged',         '6729', FALSE, '20'),
        ('BR040', 'Kecskemét Értéktár',     'Deák F. tér 6.',     'Kecskemét',     '6000', TRUE,  '40'),
        ('BR050', 'Debrecen Értéktár',      'Péterfia u. 18.',    'Debrecen',       '4026', TRUE,  '50'),
        ('BR063', 'Nyíregyháza Értéktár',  'Országzászló tér 6.',   'Nyíregyháza',   '4400', TRUE,  '63'),
        ('BR075', 'Békéscsaba Értéktár',   'Andrássy út 24-28.',  'Békéscsaba',    '5600', TRUE,  '75'),
        ('BR120', 'Pécs Értéktár',          'Megyeri út 76.',     'Pécs',           '7632', TRUE,  '120'),
        ('BR145', 'Kaposvár Értéktár',     'Ady utca 12-14',     'Kaposvár',       '7400', TRUE,  '145')
    )
    INSERT INTO branch (
        id, code, company_id, bank_code, branch_type_did,
        name, address, city, zip_code,
        country_did, branch_status_did, opening_date,
        is_vault, region_code, created_at, updated_at
    )
    SELECT
        gen_random_uuid(), nb.code, v_company_id, v_bank_code, v_branch_type_did,
        nb.name, nb.address, nb.city, nb.zip_code,
        v_country_did, v_branch_status_did, '2020-01-01'::date,
        nb.is_vault, nb.region_code, NOW(), NOW()
    FROM new_branches nb
    ON CONFLICT (code) DO NOTHING;

    GET DIAGNOSTICS inserted_count = ROW_COUNT;

    -- Defenzív: a 8 értéktár-kódra `is_vault=TRUE` UPDATE (ha már létezett, de nem
    -- volt flag-elt). Plus region_code beillítése.
    UPDATE branch SET
        is_vault = TRUE,
        region_code = CASE code
            WHEN 'BR010' THEN '10'
            WHEN 'BR020' THEN '20'
            WHEN 'BR040' THEN '40'
            WHEN 'BR050' THEN '50'
            WHEN 'BR063' THEN '63'
            WHEN 'BR075' THEN '75'
            WHEN 'BR120' THEN '120'
            WHEN 'BR145' THEN '145'
            ELSE region_code
        END,
        updated_at = NOW()
    WHERE code IN ('BR010','BR020','BR040','BR050','BR063','BR075','BR120','BR145')
      AND (is_vault = FALSE OR region_code IS NULL OR region_code = '');

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    RAISE NOTICE 'V239: % üj branch INSERT, % már-létező értéktár is_vault=TRUE flag-elve',
        inserted_count, updated_count;
END $$;

COMMENT ON COLUMN branch.is_vault IS
    'V174 + V239 (2026-05-19): TRUE = értéktári fiók (Setup Wizard értéktár módjában választható), FALSE = pénztár.';
