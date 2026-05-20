-- V245: RFM (Rate Flow Management) optimista zárolás - @Version oszlopok
--
-- Forrás: docs/CAPABILITIES.md RFM spread-kapu + VV-ELVI v2 7.3
-- (concurrent szerkesztés-védelem).
--
-- A JPA @Version mező optimista zárolást ad az árfolyam-szerkesztő (RFM)
-- entitásoknak, így ha két felhasználó egyszerre szerkeszti ugyanazt a
-- sablont/master-rate-et/publikációt, a második mentés
-- OptimisticLockException-t kap a néma felülírás (lost update) helyett.
--
-- Hibernate a NULL version mezőt nem kezeli megfelelően a már meglévő
-- soroknál, ezért NOT NULL DEFAULT 0 a helyes induló érték.
--
-- Érintett táblák:
--   - rate_template       (RateTemplate)
--   - exchange_rate_master(ExchangeRateMaster)
--   - rate_publication    (RatePublication)

ALTER TABLE rate_template
  ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

ALTER TABLE exchange_rate_master
  ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

ALTER TABLE rate_publication
  ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

-- Assertion: mindhárom version oszlop létrejött
DO $$
DECLARE
    v_missing TEXT := '';
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name = 'rate_template' AND column_name = 'version'
    ) THEN
        v_missing := v_missing || 'rate_template ';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name = 'exchange_rate_master' AND column_name = 'version'
    ) THEN
        v_missing := v_missing || 'exchange_rate_master ';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name = 'rate_publication' AND column_name = 'version'
    ) THEN
        v_missing := v_missing || 'rate_publication ';
    END IF;

    IF v_missing <> '' THEN
        RAISE EXCEPTION 'V245: hianyzo version oszlop(ok): %', v_missing;
    END IF;

    RAISE NOTICE 'V245: Verifikalva - optimista zarolas (version) oszlop aktiv: rate_template, exchange_rate_master, rate_publication.';
END
$$;
