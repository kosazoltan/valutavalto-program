-- V170 EMERGENCY REPAIR — V168/V169 'active' → 'is_active' column fix utáni
-- biztonsági HUF címlet backfill + 500 HUF threshold align (COIN, NEM BANKNOTE).
--
-- Migration sorrend felteveny (Sourcery #297 P3):
--   V168 = active branch HUF backfill (eredeti, 'active' col bug)
--   V169 = (1) 500 HUF threshold align + (2) INACTIVE branch backfill (out-of-order V168 utan)
--   V170 = V168 ujra-kovetes ESKUVEL aktív branch-eken + threshold safety net
--
-- Scope: CSAK aktív branch-ek (mirror V168 scope). Az inaktív branch-eket V169
-- part 2 kezeli külön (Sourcery #296+#297 P2/P3, v2.3.32+v2.3.34 align).
-- Felteveny: V169 part 2 mar lefutott a V170 elott (hibrid out-of-order ok).
--
-- Idempotens: WHERE NOT EXISTS minden INSERT-en, threshold align UPDATE WHERE

DO $$
DECLARE
    v_branch RECORD;
    v_huf_currency_id BIGINT;
    v_face_value NUMERIC(15,2);
    v_face_values NUMERIC(15,2)[] := ARRAY[20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    v_denom_type VARCHAR(20);
    v_inserted INT := 0;
    v_aligned INT := 0;
BEGIN
    SELECT id INTO v_huf_currency_id FROM currency WHERE code = 'HUF' LIMIT 1;
    IF v_huf_currency_id IS NULL THEN
        RAISE NOTICE 'V170 SKIP: HUF currency NEM létezik a currency táblában.';
        RETURN;
    END IF;

    -- 1) HUF denomination seed CSAK aktív branch-en (mirror V168 scope).
    -- Inaktív branch-ek backfill-jét V169 part 2 kezeli (Sourcery #296 P2).
    FOR v_branch IN
        SELECT b.id, b.company_id, b.name FROM branch b WHERE b.is_active = true
    LOOP
        FOREACH v_face_value IN ARRAY v_face_values
        LOOP
            -- Threshold-align (DenominationService.classifyHufDenomination): >= 1000 = BANKNOTE
            IF v_face_value >= 1000 THEN
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
            END IF;
        END LOOP;
    END LOOP;

    -- 2) Threshold align: 500 HUF = COIN (V168 hibás 'BANKNOTE' javítása)
    UPDATE denomination
    SET denomination_type = 'COIN', updated_at = NOW()
    WHERE currency_id = v_huf_currency_id
      AND face_value = 500
      AND denomination_type = 'BANKNOTE';
    GET DIAGNOSTICS v_aligned = ROW_COUNT;

    RAISE NOTICE 'V170 EMERGENCY REPAIR: % új HUF denomination beillesztve, % rekord COIN-ra javítva.',
                 v_inserted, v_aligned;
END $$;
