-- V328: RUB cimlet-katalogus backfill minden aktiv branch-re.
--
-- GYOKER: a V319 a RUB-ot a V320 (teljes cimlet-katalogus backfill) ELOTT
-- inaktivalta, a V320 pedig CSAK aktiv valutakra seedel — ezert a RUB-nak
-- egyetlen branch-en sincs denomination sora. A V327 visszaaktivalta a RUB-ot,
-- igy enelkul a Cimletezes menu RUB-ra ures tablat mutatna (ugyanaz a bug,
-- amit a V320 az EUR-ra javitott, 2026-06-12 Fabulya-teszt).
--
-- KATALOGUS-FORRAS: a kodbeli kanonikus RUB-spec (DenominationConfigService),
-- a tobbi valutaval azonos jegybanki (Bank of Russia) cimlet-keszlet:
--   bankjegy: 5000, 2000, 1000, 500, 200, 100, 50
--   erme:     10, 5, 2, 1, 0.50, 0.10
-- A Java-oldali tukor (DenominationService.FOREIGN_DENOMINATIONS) ezzel
-- azonosan kap RUB-bejegyzest — az UJ branch-inicializalast az vezerli.
--
-- A V320 mintaja: company_id+branch_id+currency_id, idempotens (branch,
-- currency, face_value) NOT EXISTS guard-dal. Csak aktiv branch-ekre.
DO $$
DECLARE
    v_inserted INT;
BEGIN
    WITH catalog(face_value, denom_type) AS (VALUES
        (5000::numeric,'BANKNOTE'),(2000,'BANKNOTE'),(1000,'BANKNOTE'),
        (500,'BANKNOTE'),(200,'BANKNOTE'),(100,'BANKNOTE'),(50,'BANKNOTE'),
        (10,'COIN'),(5,'COIN'),(2,'COIN'),(1,'COIN'),(0.50,'COIN'),(0.10,'COIN')
    ),
    ins AS (
        INSERT INTO denomination (
            company_id, branch_id, currency_id, face_value,
            denomination_type, quantity, min_quantity, is_active,
            created_at, updated_at
        )
        SELECT
            b.company_id, b.id, c.id, cat.face_value,
            cat.denom_type, 0, 0, true,
            NOW(), NOW()
        FROM branch b
        CROSS JOIN catalog cat
        JOIN currency c ON c.code = 'RUB' AND c.is_active = true
        WHERE b.is_active = true
          AND NOT EXISTS (
              SELECT 1 FROM denomination d
              WHERE d.branch_id = b.id
                AND d.currency_id = c.id
                AND d.face_value = cat.face_value
          )
        RETURNING 1
    )
    SELECT COUNT(*) INTO v_inserted FROM ins;

    RAISE NOTICE 'V328 RUB cimlet-katalogus backfill: % uj denomination sor.', v_inserted;
END $$;
