-- V322 (Batch3-B / currency_stock-doc FR-3): branch.vault_territory_id backfill
-- minden is_vault=TRUE branch-re.
--
-- GYOKEROK (2026-06-12 feltaras): az "Ertektari keszlet" nezet
-- (InventoryService.getVaultStockFlow) FAIL-CLOSED ures listat ad, ha a
-- bejelentkezett territory-scoped szerep (pl. ERTEKTAR) branch-enek
-- vault_territory_id mezoje NULL. A V60 bevezette az oszlopot, de tabla-szeles
-- kitoltes SOSEM tortent (csak a V288-as Bekescsaba-hotfix) — ezert a BR020
-- (Szeged Ertektar) ertektarosa ures nezetet kapott.
--
-- LEKEPEZES: a vault branch nevebol kepzett terulet-nev = vault_territory.name
-- (V60 seed: Bekescsaba, Nyiregyhaza, Szeged, Kaposvar, Debrecen, Kecskemet,
-- Pecs, Szekszard). Pl. 'Szeged Ertektar' -> 'Szeged'.
-- A doc V283-as szamozasa elavult (a repo V321-nel jart) — V322-tol szamozunk.
--
-- Edge-case (doc 9.2 Fazis 6): ha egy vault branch lekepezese nem talal
-- territory-t, EXPLICIT NOTICE-szintu jelzes keszul (nem csendes kihagyas);
-- a kesobbi keszlet-konyveles ValidationException-nel jelez (nem csendes 0).
DO $$
DECLARE
    v_updated INT;
    v_branch RECORD;
BEGIN
    UPDATE branch b
       SET vault_territory_id = vt.id,
           updated_at = NOW()
      FROM vault_territory vt
     WHERE b.is_vault = TRUE
       AND b.vault_territory_id IS NULL
       AND vt.company_id = b.company_id
       AND vt.active = TRUE
       AND vt.name = TRIM(REPLACE(b.name, 'Értéktár', ''));
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RAISE NOTICE 'V322: % vault branch vault_territory_id kitoltve.', v_updated;

    -- Explicit jelzes a tovabbra is kitoltetlen vault branch-ekre.
    FOR v_branch IN
        SELECT code, name FROM branch WHERE is_vault = TRUE AND vault_territory_id IS NULL
    LOOP
        RAISE NOTICE 'V322 FIGYELEM: a(z) % (%) vault branch-hez nem talalhato vault_territory — kezi rendezes szukseges!',
            v_branch.code, v_branch.name;
    END LOOP;
END $$;
