-- V243: Átadás-átvétel több valuta egy átadólapon (Kósa Zoltán tesztelői kérés #6).
--
-- Eddig egy Transfer = egy valuta + egy összeg. A kérés: "Valuta átadás/átvétel
-- esetében több valutát is lehessen rögzíteni" — EGY átadólapon több valuta-sor.
--
-- Megoldás: transfer_lines gyermek-tábla (transfer header + N valuta-sor).
-- VISSZAFELÉ KOMPAT: a meglévő egy-valutás átadások NEM kapnak transfer_lines sort
-- (a transfer.currency_id + amount marad a forrás); csak a multi-line átadások
-- használják a transfer_lines-t. Így nincs adat-migráció és nincs regresszió.

CREATE TABLE IF NOT EXISTS transfer_lines (
    id               BIGSERIAL PRIMARY KEY,
    transfer_id      BIGINT  NOT NULL REFERENCES transfer(id) ON DELETE CASCADE,
    currency_id      BIGINT  NOT NULL REFERENCES currencies(id),
    amount           NUMERIC(18, 2) NOT NULL,
    received_amount  NUMERIC(18, 2),
    difference       NUMERIC(18, 2),
    line_no          INTEGER NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_transfer_lines_transfer ON transfer_lines (transfer_id);

-- Egy átadólapon egy valuta csak egyszer szerepeljen (adatbeviteli hiba ellen).
CREATE UNIQUE INDEX IF NOT EXISTS uq_transfer_lines_transfer_currency
    ON transfer_lines (transfer_id, currency_id);
