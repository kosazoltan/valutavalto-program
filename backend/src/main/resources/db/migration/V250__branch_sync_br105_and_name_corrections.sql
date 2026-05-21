-- V250: Branch tábla sync a Google Sheets igazságforrás szerint (Kósa Zoltán user-direktíva,
--       2026-05-21 — "olvasd be a linket és nézd meg az adatbázisban szereplő pénztárakat és
--       értéktárakat, egyeznek-e a táblázattal").
--
-- DIAGNÓZIS (sheet 73 pénztár vs production 72 aktív iroda):
--   A) 1 HIÁNYZÓ pénztár: BR105 — "Békéscsaba Belváros 2" (5600 Békéscsaba, Andrássy út 24-28.).
--      A V246 ezt már AKTIVÁLNI akarta (UPDATE is_active=true), de a sor nem létezett
--      → a NOTICE "BR105 nem létezik" lefutott, a pénztár NEM került be. A 76 (Békéscsaba
--      Belváros) és a 105 (Békéscsaba Belváros 2) KÉT KÜLÖN pénztár a sheet szerint.
--   B) 5 NÉV-ELTÉRÉS (pénztárszám egyezik, név más) — a sheet az igazságforrás:
--        BR027 "Szeged Tesco-Rókusi" -> "Szeged Tesco"
--        BR036 "Szeged Tisza 1"      -> "Szeged Tisza"
--        BR039 "Szeged Árkád 1"      -> "Szeged Árkád"
--        BR066 "Hajdúszoboszló"      -> "Hajdúszoboszló Mátyás"
--        BR090 "Bajcsy II"           -> "Debrecen Új Bajcsy 2"
--
-- BIZTONSÁGI ELVEK:
--   1. Idempotens: INSERT ... ON CONFLICT (code) DO NOTHING; UPDATE ... IS DISTINCT FROM guard.
--   2. bank_code = self.code (= 'BR105') — NEM klónozzuk a template-ből (V240 tanulság:
--      a V239 a bank_code-ot is klónozta → 9 branch BR009-et kapott → V240 javította).
--      Csak company_id, branch_type_did, country_did, branch_status_did, region_code klónozott.
--   3. Template = BR076 (Békéscsaba Belváros, ugyanaz a város+régió), fallback BR074, BR075,
--      majd bármely EBC iroda. Ha nincs EBC iroda, EXCEPTION (alap-adat sem futott le).
--   4. A név/cím/pénztár-létrehozás nem érinti a cash_balance / transaction táblákat,
--      így a "készlet = SUM(tranzakciók)" invariáns nem sérül.

DO $$
DECLARE
    v_company_id        UUID;
    v_branch_type_did   UUID;
    v_country_did       UUID;
    v_branch_status_did UUID;
    v_region_code       VARCHAR(20);
    v_region            VARCHAR(40);
    inserted_count      INT;
    renamed_count       INT;
BEGIN
    -- ===== Template-FK értékek (BR076 -> BR074 -> BR075 -> bármely EBC) =====
    -- A `region` (login-prefill + FK-002 Országos készlet területi csoportosítás, length=40)
    -- ÉS a `region_code` (KESZLEX legacy körzet-kód, length=10) is a sibling Békéscsaba
    -- rekordból klónozott — így a BR105 ugyanúgy Békéscsaba alá csoportosul a területi nézetben.
    SELECT b.company_id, b.branch_type_did, b.country_did, b.branch_status_did, b.region_code, b.region
      INTO v_company_id, v_branch_type_did, v_country_did, v_branch_status_did, v_region_code, v_region
      FROM branch b
      JOIN company c ON c.id = b.company_id
     WHERE c.code = 'EBC' AND b.code IN ('BR076','BR074','BR075')
     ORDER BY CASE b.code WHEN 'BR076' THEN 1 WHEN 'BR074' THEN 2 ELSE 3 END
     LIMIT 1;

    IF v_company_id IS NULL THEN
        SELECT b.company_id, b.branch_type_did, b.country_did, b.branch_status_did, b.region_code, b.region
          INTO v_company_id, v_branch_type_did, v_country_did, v_branch_status_did, v_region_code, v_region
          FROM branch b
          JOIN company c ON c.id = b.company_id
         WHERE c.code = 'EBC'
         LIMIT 1;
    END IF;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'V250: EBC cég vagy template-iroda nem található — még a v0_1 alap-adat sem fut le?';
    END IF;

    -- ===== A) BR105 — Békéscsaba Belváros 2 INSERT (pénztár, NEM értéktár) =====
    INSERT INTO branch (
        id, code, company_id, bank_code, branch_type_did,
        name, address, city, zip_code,
        country_did, branch_status_did, opening_date,
        is_vault, region_code, region, is_active, created_at, updated_at
    )
    VALUES (
        gen_random_uuid(), 'BR105', v_company_id, 'BR105', v_branch_type_did,
        'Békéscsaba Belváros 2', 'Andrássy út 24-28.', 'Békéscsaba', '5600',
        v_country_did, v_branch_status_did, '2020-01-01'::date,
        FALSE, v_region_code, v_region, TRUE, NOW(), NOW()
    )
    ON CONFLICT (code) DO NOTHING;
    GET DIAGNOSTICS inserted_count = ROW_COUNT;

    IF inserted_count > 0 THEN
        RAISE NOTICE 'V250: BR105 (Békéscsaba Belváros 2) BESZÚRVA — pénztár, is_vault=FALSE, régió=%.', v_region_code;
    ELSE
        RAISE NOTICE 'V250: BR105 már létezett — nincs INSERT (idempotens).';
    END IF;

    -- ===== B) 5 név-korrekció a sheet szerint (idempotens, IS DISTINCT FROM guard) =====
    UPDATE branch SET name = CASE code
            WHEN 'BR027' THEN 'Szeged Tesco'
            WHEN 'BR036' THEN 'Szeged Tisza'
            WHEN 'BR039' THEN 'Szeged Árkád'
            WHEN 'BR066' THEN 'Hajdúszoboszló Mátyás'
            WHEN 'BR090' THEN 'Debrecen Új Bajcsy 2'
            ELSE name
        END,
        updated_at = NOW()
     WHERE code IN ('BR027','BR036','BR039','BR066','BR090')
       AND name IS DISTINCT FROM (CASE code
            WHEN 'BR027' THEN 'Szeged Tesco'
            WHEN 'BR036' THEN 'Szeged Tisza'
            WHEN 'BR039' THEN 'Szeged Árkád'
            WHEN 'BR066' THEN 'Hajdúszoboszló Mátyás'
            WHEN 'BR090' THEN 'Debrecen Új Bajcsy 2'
            ELSE name
        END);
    GET DIAGNOSTICS renamed_count = ROW_COUNT;

    RAISE NOTICE 'V250: % pénztár-név korrigálva a sheet szerint.', renamed_count;
END $$;
