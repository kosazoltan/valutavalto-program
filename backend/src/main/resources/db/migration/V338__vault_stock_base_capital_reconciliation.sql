-- V338: vault currency_stock anomalia-korrekcio a mozgas-alapu levezetett ertekre.
--
-- GYOKEROK / KONTEXTUS (elo Neon diagnozis, 2026-07-03, run 28643631686 + D7-levezetes):
--   A Fo Ertektar HUF/EUR currency_stock sorai V332 elotti, konyveletlen kezi allitasok
--   maradvanyai voltak, es eltertek a vault_territory.base_capital + lezart mozgasok nettojan
--   alapulo levezetett ertektol.
--
-- FELHATALMAZAS: Kosa Zoltan 2026-07-03 — B) a stock a DB-bol levezetett VALOS ertekre igazitando.
--
-- ELO BIZONYITEK:
--   - Fo Ertektar HUF: stock 99 582 500, levezetett 100 000 000 -> delta +417 500.
--   - Fo Ertektar EUR: stock 950, levezetett 0 -> delta -950; WAC valtozatlan marad.
--   - Szeged EUR: stock 0, levezetett -5 000 -> fizikailag lehetetlen negativ trezorkeszlet,
--     ezert a perzisztalt stock 0 marad; az elterest ez a migration dokumentalja, de nem ir
--     negativ keszletet.
--
-- BIZTONSAG / SCOPE:
--   - Nincs UUID hardcode: vault_territory nev + currency kod + aktualis currency_stock sorokbol
--     szarmazo company_id alapjan dolgozik.
--   - Tenant-scope: a cel company-t az anomalias currency_stock sorokbol vezetjuk le; ha ez nem
--     pontosan egy company, fail-closed EXCEPTION.
--   - Idempotens: minden UPDATE a JELENLEGI ertekre guardolt, masodik futas 0 sort erint es nem
--     hoz letre uj inventory_movement sort.
--   - Negativ stockot nem ir: a csokkento UPDATE csak akkor futhat, ha az eredmeny >= 0; a vegen
--     VAULT-szintu negativ-stock invarians ved.
--   - Audit trail: minden tenyleges korrekciorol CORRECTION/RECEIVED inventory_movement sor keszul
--     V338-as reference_numberrel es a diagnosztikai note-tal.
DO $$
DECLARE
    v_note CONSTANT TEXT := 'V338 base_capital reconciliation — mozgás-alapú levezetett értékre igazítás, diag run 28643631686';
    v_company_id UUID;
    v_candidate_count INT;
    v_main_territory_id INT;
    v_szeged_territory_id INT;
    v_huf_currency_id BIGINT;
    v_eur_currency_id BIGINT;
    v_worker_id BIGINT;
    v_huf_rows INT := 0;
    v_eur_rows INT := 0;
    v_huf_movement_rows INT := 0;
    v_eur_movement_rows INT := 0;
    v_eur_wac NUMERIC(12, 4);
    v_eur_huf_value NUMERIC(18, 2);
    v_szeged_eur_quantity NUMERIC(15, 2);
    v_negative_vault_rows INT := 0;
BEGIN
    -- A target company kizarolag az anomalias Fo Ertektar stock-sorokbol szarmazhat.
    WITH main_territories AS (
        SELECT vt.id, vt.company_id
          FROM vault_territory vt
         WHERE vt.is_active = TRUE
           AND vt.name IN ('Fo Ertektar', 'Fő Értéktár')
    ), candidate_companies AS (
        SELECT DISTINCT cs.company_id
          FROM currency_stock cs
          JOIN main_territories vt
            ON vt.company_id = cs.company_id
           AND vt.id::TEXT = cs.entity_id
         WHERE cs.entity_type = 'VAULT'
           AND (
                (cs.currency_code = 'HUF' AND cs.quantity = 99582500.00)
             OR (cs.currency_code = 'EUR' AND cs.quantity = 950.00)
           )
    )
    SELECT COUNT(*), MIN(company_id::TEXT)::UUID
      INTO v_candidate_count, v_company_id
      FROM candidate_companies;

    IF v_candidate_count = 0 THEN
        RAISE NOTICE 'V338: nincs aktualis Fo Ertektar HUF/EUR anomalias stock-sor — nincs teendo (idempotens no-op).';
        RETURN;
    END IF;

    IF v_candidate_count > 1 THEN
        RAISE EXCEPTION 'V338 fail-closed: az anomalias Fo Ertektar stock-sorok % kulonbozo company-ban vannak; tenant-scope nem egyertelmu.', v_candidate_count;
    END IF;

    SELECT vt.id
      INTO v_main_territory_id
      FROM vault_territory vt
     WHERE vt.company_id = v_company_id
       AND vt.is_active = TRUE
       AND vt.name IN ('Fo Ertektar', 'Fő Értéktár')
     ORDER BY CASE WHEN vt.name = 'Fo Ertektar' THEN 0 ELSE 1 END, vt.id
     LIMIT 1;

    SELECT vt.id
      INTO v_szeged_territory_id
      FROM vault_territory vt
     WHERE vt.company_id = v_company_id
       AND vt.is_active = TRUE
       AND vt.name = 'Szeged'
     LIMIT 1;

    SELECT id INTO v_huf_currency_id FROM currency WHERE code = 'HUF' LIMIT 1;
    SELECT id INTO v_eur_currency_id FROM currency WHERE code = 'EUR' LIMIT 1;

    IF v_main_territory_id IS NULL THEN
        RAISE EXCEPTION 'V338 fail-closed: Fo Ertektar vault_territory nem talalhato a cel company-ban (%).', v_company_id;
    END IF;
    IF v_huf_currency_id IS NULL OR v_eur_currency_id IS NULL THEN
        RAISE EXCEPTION 'V338 fail-closed: HUF vagy EUR currency kod nem talalhato.';
    END IF;

    SELECT w.id
      INTO v_worker_id
      FROM worker w
     WHERE w.company_id = v_company_id
       AND w.is_active = TRUE
       AND (
            w.role IN ('ADMIN', 'MANAGER')
         OR EXISTS (
                SELECT 1
                  FROM worker_role_assignment wra
                  JOIN worker_role_def wrd ON wrd.id = wra.role_def_id
                 WHERE wra.worker_id = w.id
                   AND wrd.code IN ('ugyvezeto', 'foertektar', 'DIRECTOR', 'CHIEF_VAULT')
            )
       )
     ORDER BY CASE WHEN w.role = 'ADMIN' THEN 0 WHEN w.role = 'MANAGER' THEN 1 ELSE 2 END,
              w.created_at NULLS LAST,
              w.id
     LIMIT 1;

    IF v_worker_id IS NULL THEN
        RAISE EXCEPTION 'V338 fail-closed: nincs aktiv admin/ugyvezeto worker a cel company-ban (%) az inventory_movement audit sorhoz.', v_company_id;
    END IF;

    -- A) Fo Ertektar HUF: 99 582 500 -> 100 000 000 (delta +417 500).
    UPDATE currency_stock cs
       SET quantity = cs.quantity + 417500.00,
           last_updated = NOW()
     WHERE cs.company_id = v_company_id
       AND cs.entity_type = 'VAULT'
       AND cs.entity_id = v_main_territory_id::TEXT
       AND cs.currency_code = 'HUF'
       AND cs.quantity = 99582500.00
       AND cs.quantity + 417500.00 >= 0;
    GET DIAGNOSTICS v_huf_rows = ROW_COUNT;

    IF v_huf_rows = 1 THEN
        INSERT INTO inventory_movement (
            from_branch_id, to_branch_id, currency_id, amount, huf_value,
            movement_type, status, initiated_by_id, approved_by_id, received_by_id,
            reference_number, notes, movement_date, movement_time,
            approved_at, received_at, created_at, received_amount, difference
        )
        VALUES (
            NULL, NULL, v_huf_currency_id, 417500.0000, 417500.00,
            'CORRECTION', 'RECEIVED', v_worker_id, v_worker_id, v_worker_id,
            'V338-FO-HUF', v_note, CURRENT_DATE, LOCALTIME,
            NOW(), NOW(), NOW(), 417500.0000, 0.0000
        )
        ON CONFLICT (reference_number) DO NOTHING;
        GET DIAGNOSTICS v_huf_movement_rows = ROW_COUNT;
        RAISE NOTICE 'V338/A: Fo Ertektar HUF stock +417500 korrigalva; % inventory_movement audit sor beszurva.', v_huf_movement_rows;
    ELSE
        RAISE NOTICE 'V338/A: Fo Ertektar HUF guard nem talalt 99 582 500-as aktualis sort — kihagyva.';
    END IF;

    -- B) Fo Ertektar EUR: 950 -> 0 (delta -950), WAC valtozatlan.
    UPDATE currency_stock cs
       SET quantity = cs.quantity - 950.00,
           last_updated = NOW()
     WHERE cs.company_id = v_company_id
       AND cs.entity_type = 'VAULT'
       AND cs.entity_id = v_main_territory_id::TEXT
       AND cs.currency_code = 'EUR'
       AND cs.quantity = 950.00
       AND cs.quantity - 950.00 >= 0
     RETURNING cs.weighted_avg_cost INTO v_eur_wac;
    GET DIAGNOSTICS v_eur_rows = ROW_COUNT;

    IF v_eur_rows = 1 THEN
        v_eur_huf_value := ROUND((950.00 * COALESCE(v_eur_wac, 0))::NUMERIC, 2);
        INSERT INTO inventory_movement (
            from_branch_id, to_branch_id, currency_id, amount, huf_value,
            movement_type, status, initiated_by_id, approved_by_id, received_by_id,
            reference_number, notes, movement_date, movement_time,
            approved_at, received_at, created_at, received_amount, difference
        )
        VALUES (
            NULL, NULL, v_eur_currency_id, 950.0000, v_eur_huf_value,
            'CORRECTION', 'RECEIVED', v_worker_id, v_worker_id, v_worker_id,
            'V338-FO-EUR', v_note, CURRENT_DATE, LOCALTIME,
            NOW(), NOW(), NOW(), 950.0000, 0.0000
        )
        ON CONFLICT (reference_number) DO NOTHING;
        GET DIAGNOSTICS v_eur_movement_rows = ROW_COUNT;
        RAISE NOTICE 'V338/B: Fo Ertektar EUR stock -950 korrigalva 0-ra, WAC valtozatlan (%); % inventory_movement audit sor beszurva.', v_eur_wac, v_eur_movement_rows;
    ELSE
        RAISE NOTICE 'V338/B: Fo Ertektar EUR guard nem talalt 950-es aktualis sort — kihagyva.';
    END IF;

    -- C) Szeged EUR: a levezetett -5000 dokumentalt, de negativ stockot nem irunk.
    IF v_szeged_territory_id IS NOT NULL THEN
        SELECT cs.quantity
          INTO v_szeged_eur_quantity
          FROM currency_stock cs
         WHERE cs.company_id = v_company_id
           AND cs.entity_type = 'VAULT'
           AND cs.entity_id = v_szeged_territory_id::TEXT
           AND cs.currency_code = 'EUR'
         LIMIT 1;
        RAISE NOTICE 'V338/C: Szeged EUR fizikai stock % marad; a -5000 levezetett elteres dokumentalt, negativ keszlet irasa tilos.', COALESCE(v_szeged_eur_quantity, 0);
    ELSE
        RAISE NOTICE 'V338/C: Szeged vault_territory nem talalhato a cel company-ban — negativra javitas tovabbra sem tortenik.';
    END IF;

    SELECT COUNT(*)
      INTO v_negative_vault_rows
      FROM currency_stock
     WHERE entity_type = 'VAULT'
       AND quantity < 0;

    IF v_negative_vault_rows <> 0 THEN
        RAISE EXCEPTION 'V338 fail-closed: % negativ VAULT currency_stock sor maradt/keletkezett.', v_negative_vault_rows;
    END IF;

    RAISE NOTICE 'V338 osszesito: % HUF stock sor, % EUR stock sor korrigalva; % CORRECTION inventory_movement audit sor beszurva.',
        v_huf_rows, v_eur_rows, v_huf_movement_rows + v_eur_movement_rows;
END $$;
