-- 2026-04-29 v2.3.29 V169 (Codex P2 #292 follow-up): V168 align
--
-- Két javítás a V168 migráció után (Codex review):
--
-- 1. **Threshold align**: V168 `BANKNOTE` >= 500 HUF, DE
--    `DenominationService.classifyHufDenomination()` `>= 1000` használ.
--    Magyarországon az 500 Ft ÉRME (NEM bankjegy). A Service logika a helyes,
--    a V168 tévedett. Ez UPDATE javítja a V168-as backfilled records denomination_type-ját.
--
-- 2. **Inactive branch include**: V168 csak `is_active = true` branch-eket
--    iterál. Re-aktivált branch-ek (BranchService.update flips isActive)
--    hiányos denomination-nal kerülnének vissza forgalomba. Ez a migration
--    az ÖSSZES branch-en (active vagy inactive) végrehajtja a backfill-t.
--
-- Forrás: Codex P2 review PR #292 (2026-04-29)
-- Followup: BranchService.update() később külön ticketben kapja meg a
-- denomination init re-trigger-t (out of scope itt).

-- 1) Threshold align: 500 HUF = COIN (NEM BANKNOTE)
DO $$
DECLARE
    v_huf_currency_id BIGINT;
    v_updated INT;
BEGIN
    SELECT id INTO v_huf_currency_id FROM currency WHERE code = 'HUF' LIMIT 1;
    IF v_huf_currency_id IS NULL THEN
        RAISE NOTICE 'V169 skip: HUF currency NEM létezik.';
        RETURN;
    END IF;

    -- Update: 500 HUF rekordok = COIN (a Service classifyHufDenomination logika szerint)
    UPDATE denomination
    SET denomination_type = 'COIN', updated_at = NOW()
    WHERE currency_id = v_huf_currency_id
      AND face_value = 500
      AND denomination_type = 'BANKNOTE';

    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RAISE NOTICE 'V169 threshold align: % HUF 500 rekord COIN-ra javítva.', v_updated;
END $$;

-- 2) Inactive branch backfill: V168 csak active branch-eket kezelt, most az ÖSSZES branch-et
DO $$
DECLARE
    v_branch RECORD;
    v_huf_currency_id BIGINT;
    v_face_value NUMERIC(15,2);
    v_face_values NUMERIC(15,2)[] := ARRAY[20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    v_denom_type VARCHAR(20);
    v_inserted INT := 0;
BEGIN
    SELECT id INTO v_huf_currency_id FROM currency WHERE code = 'HUF' LIMIT 1;
    IF v_huf_currency_id IS NULL THEN
        RAISE NOTICE 'V169 skip part 2: HUF currency NEM létezik.';
        RETURN;
    END IF;

    -- INACTIVE branch-ek backfill (V168 kihagyta őket)
    FOR v_branch IN
        SELECT b.id, b.company_id, b.name FROM branch b WHERE b.is_active = false
    LOOP
        FOREACH v_face_value IN ARRAY v_face_values
        LOOP
            -- Threshold-align (DenominationService classifyHufDenomination): >= 1000 = BANKNOTE
            IF v_face_value >= 1000 THEN
                v_denom_type := 'BANKNOTE';
            ELSE
                v_denom_type := 'COIN';
            END IF;

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
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'V169 inactive branch backfill: % új HUF denomination beillesztve.', v_inserted;
END $$;
