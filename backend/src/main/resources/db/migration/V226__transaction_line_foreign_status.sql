-- V226: Devizastatusz per-line (TransactionLine) — kulonbozo a Transaction-szintu erteknel.
--
-- Hatter: A V210 + V214 a TRANZAKCIO-szintu foreign_status mezot vezette be (egy bizonylat
-- = egy DOMESTIC/FOREIGN ertek). User-direktiva (2026-05-14, Kosa Zoltan):
-- 'Vetel/eladas: lehetoseg legyen a devizastatuszt TETELENKENT kivalasztani es a bizonylaton
-- megjeleniteni.' — ezert minden tetelsorra kulonbozo lehet (pl. egy bizonylaton 2 EUR
-- KULFOLDI + 1 USD BELFOLDI).
--
-- Hatas: a Transaction.foreignStatus mezo tovabbra is megmarad (default: az elso tetel
-- erteke vagy 'FOREIGN'), de a bizonylat generator a TransactionLine.foreignStatus-bol
-- olvas tetelenkent.
--
-- Backfill: meglevo TransactionLine rekordoknak megegyezik a parent Transaction.foreignStatus
-- erteke (igy nincs viselkedes-valtozas a regi adatokon).

ALTER TABLE transaction_line
    ADD COLUMN IF NOT EXISTS foreign_status VARCHAR(10) DEFAULT NULL;

-- Backfill: parent transaction foreignStatus-bol masol minden meglevo sornak
UPDATE transaction_line tl
   SET foreign_status = t.foreign_status
  FROM transaction t
 WHERE tl.transaction_id = t.id
   AND tl.foreign_status IS NULL
   AND t.foreign_status IS NOT NULL;

-- CHECK constraint: csak DOMESTIC vagy FOREIGN ertek megengedett (mint V214 a Transaction-en)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'chk_transaction_line_foreign_status'
    ) THEN
        ALTER TABLE transaction_line
            ADD CONSTRAINT chk_transaction_line_foreign_status
            CHECK (foreign_status IS NULL OR foreign_status IN ('DOMESTIC', 'FOREIGN'));
    END IF;
END $$;

-- Index: bizonylat sablonok / lekerdezesek gyorsitja, ha foreign_status-szal szurnek
CREATE INDEX IF NOT EXISTS idx_txline_foreign_status
    ON transaction_line(foreign_status)
 WHERE foreign_status IS NOT NULL;

COMMENT ON COLUMN transaction_line.foreign_status IS
    'Devizastatusz tetel-szinten: DOMESTIC (belfoldi) / FOREIGN (kulfoldi). V226 (2026-05-14).
     A parent Transaction.foreign_status a default ertek (backfill alapja), de tetelenkent
     felulirhato. NULL = nincs megadva (regi adatok elott vagy migracion kivuli set).';
