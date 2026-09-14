-- V393 (FK13 / FR-11): valutánkénti ÉS irányonkénti "0 árfolyam engedélyezett" jelölő.
--
-- Kontextus: a rate-maker FK10 (PR #1454) óta a 0 forrásérték = "nincs érték" (véletlen
-- elgépelés elleni védelem). Egyes valutáknál (pl. UAH) a 0 vételi árfolyam SZÁNDÉKOS
-- (csak eladjuk). Ez a két oszlop az explicit, auditált kivétel-bejelentés: a Főértéktáros
-- irányonként engedélyezheti a 0-t. NULL/false = a mai szigorú viselkedés változatlan.
--
-- Hatókör (eldöntött): GLOBÁLIS, flotta-szintű — a currency tábla törzs, nincs company_id
-- oszlopa (lásd V318 fejléc), ezért nincs company-szintű felülbírálat.
--
-- Nullable oszlopok (nem NOT NULL): a flyway-content-audit ADD-NOT-NULL szabálya és a
-- "nem beállított = szigorú default" szemantika miatt. IF NOT EXISTS: a currency tábla
-- ddl-auto-örökségű (V3 `active` vs. élő `is_active`), ezért defenzív, idempotens DDL.

ALTER TABLE currency ADD COLUMN IF NOT EXISTS buy_zero_allowed BOOLEAN;
ALTER TABLE currency ADD COLUMN IF NOT EXISTS sell_zero_allowed BOOLEAN;

COMMENT ON COLUMN currency.buy_zero_allowed IS
    'FK13 (V393): a vételi (E/L) oldalon a 0 árfolyam szándékos, engedélyezett érték. NULL/false = 0 tiltott (FK10).';
COMMENT ON COLUMN currency.sell_zero_allowed IS
    'FK13 (V393): az eladási (F/M) oldalon a 0 árfolyam szándékos, engedélyezett érték. NULL/false = 0 tiltott (FK10).';

-- currency_audit_log.action CHECK bővítése egy generikus ZERO_RATE_POLICY actionnel
-- (1 action + JSON-diff az old_value/new_value-ban; a VARCHAR(20) miatt NEM 4 külön név).
-- A V238 inline (névtelen) CHECK-et definiálta, a Postgres által generált neve a repóból nem
-- ismert → pg_constraint alapján oldjuk fel (a V318 idempotens mintája), majd nevesítve
-- vesszük fel újra. Idempotens: ismételt futásnál ugyanazt a végállapotot adja.
DO $$
DECLARE
    v_conname text;
BEGIN
    FOR v_conname IN
        SELECT conname
          FROM pg_constraint
         WHERE conrelid = 'currency_audit_log'::regclass
           AND contype = 'c'
           AND pg_get_constraintdef(oid) ILIKE '%action%'
    LOOP
        EXECUTE format('ALTER TABLE currency_audit_log DROP CONSTRAINT %I', v_conname);
    END LOOP;

    ALTER TABLE currency_audit_log
        ADD CONSTRAINT currency_audit_log_action_check
        CHECK (action IN ('CREATE', 'ACTIVATE', 'DEACTIVATE', 'UPDATE', 'ZERO_RATE_POLICY'));
END $$;

COMMENT ON COLUMN currency_audit_log.action IS
    'CREATE | ACTIVATE | DEACTIVATE | UPDATE | ZERO_RATE_POLICY (V393, FK13: buy/sell_zero_allowed váltás, JSON-diff az old/new_value-ban)';
