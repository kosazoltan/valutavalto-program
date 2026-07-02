-- V337: TISZA arva-adatok rendezese (worker-atkotes + HUF egyenleg-konszolidacio + fuggo szallitmany).
--
-- GYOKEROK / KONTEXTUS (elo Neon diagnozis, 2026-07-02, run 28596040523):
--   A V244/V246 a TISZA branch-et inaktiv duplikatumkent kezelte a BR035 "Szeged Tisza Sarok"
--   mellett, de elo adatban 7 AKTIV worker, egy 4 985 000 HUF cash_balance sor es egy SUBMITTED
--   shipment_request (SHR-20260529-0001) a TISZA-n ragadt.
--
-- FELHATALMAZAS: Kosa Zoltan 2026-07-02 — "Javitsd az adatokat, javaslat szerint!"
--
-- MAPPING-BIZONYITEKOK:
--   - BALI, BORSI, KASZA, KOSA -> BR035: TISZA = BR035 duplikatum, szegedi dolgozok.
--   - FABULYA -> BR076: W-S036 Fabulya Zsuzsanna duplikatum BR076-on.
--   - G_KISS_KORNEL -> BR150: W-S094 Kiss Kornel duplikatum BR150-en.
--   - G_KOSZTYU_CSABA -> BR057: W-S104 Kosztyu Csaba duplikatum BR057-en.
--
-- BIZTONSAG / SCOPE:
--   - Minden lookup a TISZA branch company_id-jan belul tortenik (multi-tenant invarians).
--   - Nincs UUID hardcode; branch/worker/currency/request kodos lookupot hasznalunk.
--   - A TISZA cash_balance sorok megmaradnak audit-nyomkent, csak a HUF current_balance nullazodik.
--   - A 6 elo BR035 -> Szeged Ertektar SUBMITTED keres NEM erintett: a shipment update csak a
--     TISZA from_branch + SHR-20260529-0001 + SUBMITTED harmasra szur.
--   - A shipmenthez NEM hivunk keszlet-visszapolto logikat SQL-bol: a diagnosztika szerint a keres
--     2026-05-29-i, a keszletkonyveles (d499a650) 2026-06-30-i, tehat ehhez a kereshez nincs OUT
--     konyveles, nincs mit visszapótolni.
DO $$
DECLARE
    v_company_id UUID;
    v_tisza_id UUID;
    v_br035_id UUID;
    v_br057_id UUID;
    v_br076_id UUID;
    v_br150_id UUID;
    v_huf_id BIGINT;
    v_tisza_huf NUMERIC(15, 2);
    v_rows INT;
    v_total_workers INT := 0;
    v_cash_rows INT := 0;
    v_cash_zeroed_rows INT := 0;
    v_shipment_rows INT := 0;
BEGIN
    SELECT id, company_id
      INTO v_tisza_id, v_company_id
      FROM branch
     WHERE code = 'TISZA'
       AND is_active = FALSE
     LIMIT 1;

    IF v_tisza_id IS NULL OR v_company_id IS NULL THEN
        RAISE NOTICE 'V337: inaktiv TISZA branch nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    SELECT id INTO v_br035_id FROM branch WHERE company_id = v_company_id AND code = 'BR035' AND is_active = TRUE LIMIT 1;
    SELECT id INTO v_br057_id FROM branch WHERE company_id = v_company_id AND code = 'BR057' AND is_active = TRUE LIMIT 1;
    SELECT id INTO v_br076_id FROM branch WHERE company_id = v_company_id AND code = 'BR076' AND is_active = TRUE LIMIT 1;
    SELECT id INTO v_br150_id FROM branch WHERE company_id = v_company_id AND code = 'BR150' AND is_active = TRUE LIMIT 1;
    SELECT id INTO v_huf_id FROM currency WHERE code = 'HUF' LIMIT 1;

    -- A) Worker-atkotes: idempotens, csak a TISZA-n levo aktiv worker sorokra hat.
    IF v_br035_id IS NOT NULL THEN
        UPDATE worker
           SET branch_id = v_br035_id,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND code = 'BALI'
           AND branch_id = v_tisza_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_total_workers := v_total_workers + v_rows;
        RAISE NOTICE 'V337/A: BALI -> BR035, % worker sor atkotve.', v_rows;

        UPDATE worker
           SET branch_id = v_br035_id,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND code = 'BORSI'
           AND branch_id = v_tisza_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_total_workers := v_total_workers + v_rows;
        RAISE NOTICE 'V337/A: BORSI -> BR035, % worker sor atkotve.', v_rows;

        UPDATE worker
           SET branch_id = v_br035_id,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND code = 'KASZA'
           AND branch_id = v_tisza_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_total_workers := v_total_workers + v_rows;
        RAISE NOTICE 'V337/A: KASZA -> BR035, % worker sor atkotve.', v_rows;

        UPDATE worker
           SET branch_id = v_br035_id,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND code = 'KOSA'
           AND branch_id = v_tisza_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_total_workers := v_total_workers + v_rows;
        RAISE NOTICE 'V337/A: KOSA -> BR035, % worker sor atkotve.', v_rows;
    ELSE
        RAISE NOTICE 'V337/A: BR035 aktiv celbranch nem talalhato TISZA company scope-ban — 4 szegedi worker kihagyva.';
    END IF;

    IF v_br076_id IS NOT NULL THEN
        UPDATE worker
           SET branch_id = v_br076_id,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND code = 'FABULYA'
           AND branch_id = v_tisza_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_total_workers := v_total_workers + v_rows;
        RAISE NOTICE 'V337/A: FABULYA -> BR076, % worker sor atkotve.', v_rows;
    ELSE
        RAISE NOTICE 'V337/A: BR076 aktiv celbranch nem talalhato TISZA company scope-ban — FABULYA kihagyva.';
    END IF;

    IF v_br150_id IS NOT NULL THEN
        UPDATE worker
           SET branch_id = v_br150_id,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND code = 'G_KISS_KORNEL'
           AND branch_id = v_tisza_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_total_workers := v_total_workers + v_rows;
        RAISE NOTICE 'V337/A: G_KISS_KORNEL -> BR150, % worker sor atkotve.', v_rows;
    ELSE
        RAISE NOTICE 'V337/A: BR150 aktiv celbranch nem talalhato TISZA company scope-ban — G_KISS_KORNEL kihagyva.';
    END IF;

    IF v_br057_id IS NOT NULL THEN
        UPDATE worker
           SET branch_id = v_br057_id,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND code = 'G_KOSZTYU_CSABA'
           AND branch_id = v_tisza_id;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        v_total_workers := v_total_workers + v_rows;
        RAISE NOTICE 'V337/A: G_KOSZTYU_CSABA -> BR057, % worker sor atkotve.', v_rows;
    ELSE
        RAISE NOTICE 'V337/A: BR057 aktiv celbranch nem talalhato TISZA company scope-ban — G_KOSZTYU_CSABA kihagyva.';
    END IF;

    -- B) TISZA HUF cash_balance konszolidacio BR035-re; csak nem-nulla forrasnal fut, igy idempotens.
    SELECT cb.current_balance
      INTO v_tisza_huf
      FROM cash_balance cb
     WHERE cb.company_id = v_company_id
       AND cb.branch_id = v_tisza_id
       AND cb.currency_id = v_huf_id
     LIMIT 1;

    IF v_br035_id IS NOT NULL AND v_huf_id IS NOT NULL AND COALESCE(v_tisza_huf, 0) <> 0 THEN
        INSERT INTO cash_balance (company_id, branch_id, currency_id, current_balance, opening_balance, created_at, updated_at, version)
        VALUES (v_company_id, v_br035_id, v_huf_id, v_tisza_huf, 0, NOW(), NOW(), 0)
        ON CONFLICT (branch_id, currency_id) DO UPDATE
            SET current_balance = cash_balance.current_balance + EXCLUDED.current_balance,
                updated_at = NOW();
        GET DIAGNOSTICS v_cash_rows = ROW_COUNT;

        UPDATE cash_balance
           SET current_balance = 0,
               updated_at = NOW()
         WHERE company_id = v_company_id
           AND branch_id = v_tisza_id
           AND currency_id = v_huf_id
           AND current_balance <> 0;
        GET DIAGNOSTICS v_cash_zeroed_rows = ROW_COUNT;

        RAISE NOTICE 'V337/B: TISZA HUF egyenleg (% HUF) BR035-re konszolidalva, % cel cash_balance sor erintve, % TISZA forras sor nullazva.', v_tisza_huf, v_cash_rows, v_cash_zeroed_rows;
    ELSE
        RAISE NOTICE 'V337/B: TISZA HUF konszolidacio kihagyva (BR035/HUF hiany vagy nulla forras-egyenleg).';
    END IF;

    -- C) Arva, TISZA-forrasu SUBMITTED shipment adminisztrativ lezarasa.
    UPDATE shipment_request
       SET status = 'CANCELLED',
           notes = COALESCE(NULLIF(notes, '') || E'\n', '') || 'V337: inaktív TISZA branch árva függő kérése — adminisztratív lezárás'
     WHERE company_id = v_company_id
       AND request_number = 'SHR-20260529-0001'
       AND from_branch_id = v_tisza_id
       AND status = 'SUBMITTED';
    GET DIAGNOSTICS v_shipment_rows = ROW_COUNT;
    RAISE NOTICE 'V337/C: SHR-20260529-0001 TISZA arva shipment CANCELLED, % sor erintve.', v_shipment_rows;

    RAISE NOTICE 'V337 osszesito: % worker sor atkotve, % cash_balance cel sor erintve, % TISZA cash_balance forras sor nullazva, % shipment_request lezarva.',
        v_total_workers, v_cash_rows, v_cash_zeroed_rows, v_shipment_rows;
END $$;
