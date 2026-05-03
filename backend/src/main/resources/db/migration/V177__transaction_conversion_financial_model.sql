-- Audit P0.8 (2026-05-03): konverzio penzugyi modell rewrite.
--
-- A `TransactionConversionService` egy konverzio-bol HAROM transaction sort
-- hoz letre, mind COMPLETED-status-szal:
--   1. parent CONVERSION (osszesito, dupla bizonylat-szam)
--   2. convBuy (ugyanazon HUF-ot mozgato BUY)
--   3. convSell (ugyanazon HUF-ot mozgato SELL)
--
-- A riportok / AML / NGM export — barhol, ahol `transactionType` szures
-- nelkul SUM(hufAmount) megy — DUPLA vagy TRIPLA szamolast eredmenyez.
--
-- Megoldas (audit doc szerint):
--   - `conversion_group_id`: ket child + parent osszekapcsolasa.
--   - `financial_effective`: a parent CONVERSION sora NEM penzugyi mozgas
--     (csak metadata/grouping); a riportok alapertelmezetten szurnek
--     `financial_effective = TRUE`-ra.

ALTER TABLE transaction ADD COLUMN IF NOT EXISTS conversion_group_id UUID;
ALTER TABLE transaction ADD COLUMN IF NOT EXISTS financial_effective BOOLEAN NOT NULL DEFAULT TRUE;

-- Retrofit: a meglevo parent CONVERSION sorok NEM penzugyileg effective.
-- (A child convBuy/convSell sorok megmarado financial_effective = TRUE — ezek a tenyleges
-- penzmozgas, ezeken alapulnak a riportok.)
UPDATE transaction
   SET financial_effective = FALSE
 WHERE transaction_type = 'CONVERSION'
   AND financial_effective IS DISTINCT FROM FALSE;

-- Index a riport queries-hez (branch_id + transaction_date).
-- Sourcery PR #362: a `financial_effective` a partial WHERE-ben van, NEM key column —
-- index size csokken, scan efficiency valtozatlan (constant column nem ad selectivity-t).
CREATE INDEX IF NOT EXISTS transaction_financial_effective_date_idx
    ON transaction (branch_id, transaction_date)
    WHERE financial_effective = TRUE;

-- Index a conversion_group_id-re (a child sorok parenttel-link-elesehez).
CREATE INDEX IF NOT EXISTS transaction_conversion_group_idx
    ON transaction (conversion_group_id)
    WHERE conversion_group_id IS NOT NULL;
