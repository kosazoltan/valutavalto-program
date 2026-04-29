-- 2026-04-29 v2.3.27 V168 (B3 P0 fix): HUF címletek backfill minden meglévő branch-en
--
-- Háttér: a `DenominationService.HUF_DENOMINATIONS` 14 hivatalos magyar címlet-et
-- tartalmaz (1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000),
-- de az `initializeBranchDenominations(branchId)` metódust EDDIG SOHA NEM hívta
-- senki. Ennek következtében a frontend `DenominationPage`-en csak részleges
-- címletlista látható (B3 audit-jegyzet: "csak 20000/1000/100/50 HUF").
--
-- Ez a migration backfill-eli a hiányzó HUF címleteket minden már létező branch-re,
-- idempotensen (NEM dob hibát ha már létezik a (branch, currency, face_value) hármas).
--
-- Forrás: D:\valutavalto-vault\sessions\2026-04-29-full-program-audit.md (B3)
-- Followup: új branch létrehozásakor a BranchService.create() most már automatikusan
-- hívja a `denominationService.initializeBranchDenominations(branchId)`-t.

DO $$
DECLARE
    v_branch RECORD;
    v_huf_currency_id BIGINT;
    v_face_value NUMERIC(15,2);
    v_face_values NUMERIC(15,2)[] := ARRAY[20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    v_denom_type VARCHAR(20);
    v_inserted INT := 0;
    v_skipped INT := 0;
BEGIN
    -- HUF currency_id lookup
    SELECT id INTO v_huf_currency_id FROM currency WHERE code = 'HUF' LIMIT 1;
    IF v_huf_currency_id IS NULL THEN
        RAISE NOTICE 'V168 SKIP: HUF currency NEM létezik a currency táblában — backfill kihagyva.';
        RETURN;
    END IF;

    -- Minden meglévő (aktív) branch-en
    FOR v_branch IN
        SELECT b.id, b.company_id, b.name FROM branch b WHERE b.is_active = true
    LOOP
        -- Minden HUF címlet-en
        FOREACH v_face_value IN ARRAY v_face_values
        LOOP
            -- Type classification: érme < 500 HUF, bankjegy >= 500 HUF
            -- (DenominationService.classifyHufDenomination logika)
            IF v_face_value >= 500 THEN
                v_denom_type := 'BANKNOTE';
            ELSE
                v_denom_type := 'COIN';
            END IF;

            -- Idempotens INSERT: csak ha még nincs a (branch, currency, face_value) hármas
            INSERT INTO denomination (
                company_id, branch_id, currency_id, face_value,
                denomination_type, quantity, min_quantity, is_active,
                created_at, updated_at
            )
            SELECT
                v_branch.company_id, v_branch.id, v_huf_currency_id, v_face_value,
                v_denom_type, 0, 0, true,
                NOW(), NOW()
            WHERE NOT EXISTS (
                SELECT 1 FROM denomination d
                WHERE d.branch_id = v_branch.id
                  AND d.currency_id = v_huf_currency_id
                  AND d.face_value = v_face_value
            );
            IF FOUND THEN
                v_inserted := v_inserted + 1;
            ELSE
                v_skipped := v_skipped + 1;
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'V168 B3 backfill: % új HUF denomination beillesztve, % már létezett.',
                 v_inserted, v_skipped;
END $$;
