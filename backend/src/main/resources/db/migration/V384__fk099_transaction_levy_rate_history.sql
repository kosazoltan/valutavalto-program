-- ============================================================================
-- V384: FK-099 — penzugyi tranzakcios illetek rata-history
--        (transaction_levy_rate_history, append-only, datumozott)
--
-- A 2012. evi CXVI. tv. szerinti penzugyi tranzakcios illetek (alap +
-- kiegeszito konverzios illetek) merteke vallalatonkent, hatejbalpesi
-- datummal verziozott, APPEND-ONLY sorokban. A riport a ratat
-- lekerdezes-idoben szamitja (a transaction tabla erintetlen, illetek-ertek
-- NEM perzisztalodik).
--
-- FR-1: UPDATE/DELETE a tablan triggerrel tiltott (V238
--       currency_audit_log_immutable_guard minta); a rate-eroforrasnak
--       nincs PUT/PATCH/DELETE vegpontja, csak INSERT.
-- C12 seed: minden company kap egy kiindulo sort. Az effective_from =
--       2013-01-01 TECHNIKAI DEFAULT: úgy valasztottuk, hogy az adatbazisban
--       levo MINDEN tranzakcio-datumra pontosan egy rata-sor oldodjon fel;
--       ez NEM jogi allitas arrol, hogy az illetek mikortol fizetendo —
--       a jogilag helyes sorokat az uzemelteto az append-only kepernyon
--       rogziti. (Ticket C12: tilos kitalalt torveny-datumot jogi tenykent
--       feltuntetni.)
-- Teljesen idempotens (IF NOT EXISTS / IF EXISTS / WHERE NOT EXISTS a seedben).
-- ============================================================================

-- ============================================================================
-- 1. Tabla
-- ============================================================================
CREATE TABLE IF NOT EXISTS transaction_levy_rate_history (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id                  UUID          NOT NULL REFERENCES company(id),
    effective_from              DATE          NOT NULL,
    base_rate_percent           NUMERIC(6,3)  NOT NULL,
    base_rate_cap_huf           NUMERIC(15,2) NOT NULL,
    supplement_rate_percent     NUMERIC(6,3)  NOT NULL,
    supplement_rate_cap_huf     NUMERIC(15,2) NOT NULL,
    conversion_single_side_flag BOOLEAN       NOT NULL DEFAULT TRUE,
    created_by                  VARCHAR(100),
    created_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_tlrh_company_effective UNIQUE (company_id, effective_from),
    CONSTRAINT ck_tlrh_rates CHECK (base_rate_percent >= 0 AND supplement_rate_percent >= 0),
    CONSTRAINT ck_tlrh_caps  CHECK (base_rate_cap_huf >= 0 AND supplement_rate_cap_huf >= 0)
);

-- NFR-5: a hatejbalpes szerinti feloldas indexe (company_id, effective_from DESC).
CREATE INDEX IF NOT EXISTS idx_tlrh_company_effective
    ON transaction_levy_rate_history(company_id, effective_from DESC);

-- ============================================================================
-- 2. Immutable guard (V238 minta): UPDATE/DELETE tiltott — a rata-history
--    append-only, az adojogi elozmenyeket nem szabad utolag atirni.
--    Megj.: ez az egyetlen hely, ahol a DELETE kulcsszo a tablara nezve
--    megjelenik (a trigger definicioja es a hibaüzenet).
-- ============================================================================
CREATE OR REPLACE FUNCTION transaction_levy_rate_history_immutable_guard()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'transaction_levy_rate_history: UPDATE tiltott (append-only FK-099)';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'transaction_levy_rate_history: DELETE tiltott (append-only FK-099)';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS transaction_levy_rate_history_immutable ON transaction_levy_rate_history;
CREATE TRIGGER transaction_levy_rate_history_immutable
    BEFORE UPDATE OR DELETE ON transaction_levy_rate_history
    FOR EACH ROW EXECUTE FUNCTION transaction_levy_rate_history_immutable_guard();

-- ============================================================================
-- 3. C12 SEED — minden company-nek egy kiindulo rata-sor (insert-if-missing,
--    V383 minta). Ertekek: 0.45% / 20 000 Ft mindket komponensre;
--    conversion_single_side_flag = TRUE (a konverzio egy illetek-parban
--    szerepel, Konverzio oszlopcsoport — ticket C2/FR-5).
-- ============================================================================
INSERT INTO transaction_levy_rate_history
        (company_id, effective_from, base_rate_percent,
         base_rate_cap_huf, supplement_rate_percent, supplement_rate_cap_huf,
         conversion_single_side_flag, created_by)
SELECT c.id, DATE '2013-01-01', 0.450, 20000.00, 0.450, 20000.00, TRUE, 'V384'
  FROM company c
 WHERE NOT EXISTS (SELECT 1 FROM transaction_levy_rate_history x
                    WHERE x.company_id = c.id);

COMMENT ON TABLE transaction_levy_rate_history IS
    'V384 (FK-099): penzugyi tranzakcios illetek rata-history (append-only). '
    'A 2013-01-01 seed-datum technikai default (minden tranzakcio-datumra '
    'oldodjon fel rata), NEM jogi teny az illetek fizetendosegenek kezdetérol.';
