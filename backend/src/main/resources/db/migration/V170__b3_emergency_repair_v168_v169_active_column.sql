-- 2026-04-29 v2.3.31 V170 EMERGENCY REPAIR (production-side incident):
--
-- Incident: a v2.3.27 (V168) és v2.3.29 (V169) Flyway migration-ok `INSERT INTO
-- denomination (..., active, ...)` syntax-ot használtak, DE a Hetzner production
-- DB schema-ban a denomination tábla CSAK `is_active` columnával rendelkezik
-- (V3_7 dynamic-add migration-ban). Eredmény: production HTTP 502 4 deploy-on
-- keresztül (v2.3.27, v2.3.28, v2.3.29, v2.3.30 mind-en V168 fail-elt a Flyway
-- migrate során).
--
-- Fix:
-- 1) V168 + V169 fájlok már javítva (`active` → `is_active`)
-- 2) Ez a V170 migration biztonsági backfill — ha a V168/V169 valami okból még
--    nem futott le újra (pl. checksum mismatch), itt explicit végrehajtjuk a
--    HUF címlet seed-et + threshold align-t.
-- 3) Idempotens — `WHERE NOT EXISTS` minden INSERT-en.
--
-- Production flyway_schema_history cleanup szükséges manuálisan, ha a v168/v169
-- "FAILED" státusszal van benn (admin-side: DELETE FROM flyway_schema_history
-- WHERE version IN ('168', '169') AND success = false; majd `mvn flyway:repair`
-- vagy a Spring Boot config `spring.flyway.out-of-order=true` + redeploy).
--
-- Forrás: Hetzner deploy log 25131348997 (PR #292 v2.3.27 first failed deploy)

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

    -- 1) HUF denomination seed minden branch-en (active VAGY inactive)
    FOR v_branch IN
        SELECT b.id, b.company_id, b.name FROM branch b
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
