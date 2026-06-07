-- V299 (Értéktári átadás-átvétel bizonylat — sztornó + címletezés):
-- A `transfer` tábla bővítése sztornó-mezőkkel és egy opcionális címletezés gyermek-tábla.
--
-- Sorszám: NEM vezetünk be külön DB-szekvenciát/RLS-t. A cégszintű folyamatos AT/AV/FF/UF-NNNNNN
-- sorszámot a service a meglévő, bizonyított MAX(+1) + `transfer_number` UNIQUE constraint mintával
-- állítja elő (company-scope-ra szűkítve) — race esetén a UNIQUE constraint visszagördít (gap-mentes).
-- A tenant-izoláció application-szintű company_id-szűréssel történik (a kódbázis NEM használ Postgres
-- RLS-t / `app.current_company_id` settinget — a spec ezt tévesen feltételezte).
--
-- Zero-downtime: minden új oszlop nullable / default-os, a címletezés külön tábla. Idempotens.

-- 1) Sztornó-mezők a meglévő transfer rekordon (az eredeti megmarad, csak megjelölődik).
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS is_cancelled BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS cancellation_reason VARCHAR(500);
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS cancelled_by BIGINT REFERENCES worker(id);

-- 2) Opcionális címletezés (darab × névleges érték). Nincs előre rögzített címletlista — szabad bevitel.
--    Csak akkor van sor, ha a felhasználó megadta; a bizonylaton csak ekkor jelenik meg.
CREATE TABLE IF NOT EXISTS transfer_denomination (
    id            BIGSERIAL PRIMARY KEY,
    company_id    UUID NOT NULL REFERENCES company(id),
    transfer_id   BIGINT NOT NULL REFERENCES transfer(id) ON DELETE CASCADE,
    quantity      INT NOT NULL,
    face_value    NUMERIC(18,4) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    line_total    NUMERIC(18,4) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_transfer_denomination_transfer ON transfer_denomination (transfer_id);
CREATE INDEX IF NOT EXISTS idx_transfer_denomination_company ON transfer_denomination (company_id);

-- 3) CÉGSZINTŰ sorszám-egyediség. A cégszintű folyamatos AT/AV/FF/UF-NNNNNN sorszám miatt KÉT cég
--    azonos sorszámot kaphat (pl. mindkettő AT-000001) — ez a tenant-szintű szekvencia szándékos
--    következménye. A `transfer` táblán azonban a `transfer_number` eddig GLOBÁLIS UNIQUE volt (V63),
--    ami a második cég azonos sorszámán bukna. Ezért: company_id oszlop (backfill a from_branch cégéből),
--    a globális UNIQUE eldobása, és egy (company_id, transfer_number) COMPOSITE UNIQUE.
--    A régi sorszámok (F020…) globálisan egyediek voltak, így a composite egyediség rájuk is teljesül.
ALTER TABLE transfer ADD COLUMN IF NOT EXISTS company_id UUID;
UPDATE transfer t SET company_id = b.company_id
  FROM branch b WHERE t.from_branch_id = b.id AND t.company_id IS NULL;
ALTER TABLE transfer DROP CONSTRAINT IF EXISTS transfer_transfer_number_key;
ALTER TABLE transfer ADD CONSTRAINT uq_transfer_company_number UNIQUE (company_id, transfer_number);
