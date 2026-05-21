-- V250: Branch tábla sync a Google Sheets igazságforrás szerint (Kósa Zoltán user-direktíva,
--       2026-05-21 — "olvasd be a linket és nézd meg az adatbázisban szereplő pénztárakat és
--       értéktárakat, egyeznek-e a táblázattal").
--
-- DIAGNÓZIS (sheet 73 pénztár vs production 72 aktív iroda):
--   A) 1 HIÁNYZÓ pénztár: BR105 — "Békéscsaba Belváros 2" (5600 Békéscsaba, Andrássy út 24-28.).
--      A V246 ezt már AKTIVÁLNI akarta (UPDATE is_active=true), de a sor nem létezett
--      → a NOTICE "BR105 nem létezik" lefutott, a pénztár NEM került be. A 76 (Békéscsaba
--      Belváros) és a 105 (Békéscsaba Belváros 2) KÉT KÜLÖN pénztár a sheet szerint — a
--      főértéktáros megerősítette: a Békéscsaba értéktár (BR075), a Belváros (BR076) és a
--      Belváros 2 (BR105) is UGYANAZON a címen (Andrássy út 24-28.) van, 3 egység 1 cím.
--   B) 5 NÉV-ELTÉRÉS (pénztárszám egyezik, név más) — a sheet az igazságforrás:
--        BR027 "Szeged Tesco-Rókusi" -> "Szeged Tesco"
--        BR036 "Szeged Tisza 1"      -> "Szeged Tisza"
--        BR039 "Szeged Árkád 1"      -> "Szeged Árkád"
--        BR066 "Hajdúszoboszló"      -> "Hajdúszoboszló Mátyás"
--        BR090 "Bajcsy II"           -> "Debrecen Új Bajcsy 2"
--
-- BIZTONSÁGI ELVEK + AI-review (Sourcery/Copilot #759) beépítve:
--   1. Idempotens: INSERT ... ON CONFLICT (code) DO UPDATE (valódi sheet-sync, a V145 saját
--      mintája) — ha létezne stale/inaktív/hibás-nevű BR105, a sheet-állapotra szinkronizál;
--      IS DISTINCT FROM guard → no-op ha már egyezik. (Copilot #759)
--   2. bank_code = self.code (= 'BR105') — NEM klónozzuk a template-ből (V240 tanulság).
--      Csak INSERT-kor; meglévő sor bank_code-ját NEM írjuk felül (identitás-mező).
--   3. `region` (FK-002 Országos készlet csoportosítás, length=40): a Békéscsaba sibling-ből
--      ('BEKESCSABA', V145 BR076/BR074) — így a BR105 a Békéscsaba terület alá csoportosul.
--   4. `region_code` (KESZLEX legacy körzet-kód, length=10): a Békéscsaba ÉRTÉKTÁRBÓL klónozva
--      (BR075='75', V239), mert a pénztárak region_code-ja a seedben NULL — különben a BR105
--      körzetkód nélkül maradna. (Copilot #759). Fallback NULL (konzisztens a sibling pénztárakkal).
--   5. Minden SELECT determinisztikus ORDER BY-jal (Sourcery #759 — nincs ORDER BY nélküli LIMIT 1).
--   6. A név/cím/pénztár-létrehozás nem érinti a cash_balance / transaction táblákat,
--      így a "készlet = SUM(tranzakciók)" invariáns nem sérül.

DO $$
DECLARE
    v_company_id        UUID;
    v_branch_type_did   UUID;
    v_country_did       UUID;
    v_branch_status_did UUID;
    v_region            VARCHAR(40);
    v_region_code       VARCHAR(10);
    affected_count      INT;
    renamed_count       INT;
BEGIN
    -- ===== Template-FK + region a Békéscsaba sibling-ből (BR076 -> BR074 -> BR075) =====
    SELECT b.company_id, b.branch_type_did, b.country_did, b.branch_status_did, b.region
      INTO v_company_id, v_branch_type_did, v_country_did, v_branch_status_did, v_region
      FROM branch b
      JOIN company c ON c.id = b.company_id
     WHERE c.code = 'EBC' AND b.code IN ('BR076','BR074','BR075')
     ORDER BY CASE b.code WHEN 'BR076' THEN 1 WHEN 'BR074' THEN 2 ELSE 3 END
     LIMIT 1;

    -- Fallback: bármely EBC iroda, DETERMINISZTIKUS ORDER BY-jal (Sourcery #759).
    IF v_company_id IS NULL THEN
        SELECT b.company_id, b.branch_type_did, b.country_did, b.branch_status_did, b.region
          INTO v_company_id, v_branch_type_did, v_country_did, v_branch_status_did, v_region
          FROM branch b
          JOIN company c ON c.id = b.company_id
         WHERE c.code = 'EBC'
         ORDER BY b.code
         LIMIT 1;
    END IF;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'V250: EBC cég vagy template-iroda nem található — még a v0_1 alap-adat sem fut le?';
    END IF;

    -- ===== region_code a Békéscsaba ÉRTÉKTÁRBÓL (Copilot #759) =====
    -- A pénztárak region_code-ja a seedben NULL; a vault BR075 region_code-ja '75' (V239).
    -- Így a BR105 a területéhez tartozó körzetkódot kapja. Determinisztikus ORDER BY.
    SELECT b.region_code INTO v_region_code
      FROM branch b
      JOIN company c ON c.id = b.company_id
     WHERE c.code = 'EBC' AND b.is_vault = TRUE AND b.region = v_region AND b.region_code IS NOT NULL
     ORDER BY b.code
     LIMIT 1;
    -- v_region_code maradhat NULL (ha nincs vault-körzetkód) — konzisztens a sibling pénztárakkal.

    -- ===== A) BR105 — Békéscsaba Belváros 2 INSERT/SYNC (pénztár, NEM értéktár) =====
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
    ON CONFLICT (code) DO UPDATE SET
        name        = EXCLUDED.name,
        address     = EXCLUDED.address,
        city        = EXCLUDED.city,
        zip_code    = EXCLUDED.zip_code,
        is_vault    = EXCLUDED.is_vault,
        is_active   = EXCLUDED.is_active,
        -- region/region_code: csak ha a meglévő hiányzik (ne írjuk felül a már meglévő helyeset).
        region      = COALESCE(branch.region, EXCLUDED.region),
        region_code = COALESCE(branch.region_code, EXCLUDED.region_code),
        updated_at  = NOW()
      WHERE branch.name      IS DISTINCT FROM EXCLUDED.name
         OR branch.address   IS DISTINCT FROM EXCLUDED.address
         OR branch.city      IS DISTINCT FROM EXCLUDED.city
         OR branch.zip_code  IS DISTINCT FROM EXCLUDED.zip_code
         OR branch.is_vault  IS DISTINCT FROM EXCLUDED.is_vault
         OR branch.is_active IS DISTINCT FROM EXCLUDED.is_active
         OR branch.region    IS NULL
         OR branch.region_code IS NULL;
    GET DIAGNOSTICS affected_count = ROW_COUNT;

    IF affected_count > 0 THEN
        RAISE NOTICE 'V250: BR105 (Békéscsaba Belváros 2) BESZÚRVA/SZINKRONIZÁLVA — pénztár, is_vault=FALSE, régió=%, körzetkód=%.',
            v_region, COALESCE(v_region_code, '(nincs)');
    ELSE
        RAISE NOTICE 'V250: BR105 már a sheet-állapotban van — nincs változás (idempotens).';
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
