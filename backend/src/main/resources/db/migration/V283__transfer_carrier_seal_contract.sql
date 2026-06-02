-- V283: Átadás-átvétel szállító/plomba szerződés-igazítás (FR/NFR-1,2).
-- A V208 a carrier_name VARCHAR(200) / seal_number VARCHAR(100) mezőket hozta létre; a követelmény
-- 128/64. Védett szűkítés: ha bármely meglévő sor túl hosszú, a migráció HIBÁVAL leáll (nincs csendes
-- adatcsonkítás). A seal_number formátumát (alfanumerikus + kötőjel + perjel) CHECK védi, NULL-megengedő
-- (régi rekordok és a nem-átadás-átvétel rekordok null-ok lehetnek; az új-rekord-kötelezőséget a
-- CreateTransferDto @NotBlank/@Pattern adja).

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM transfer WHERE length(carrier_name) > 128 OR length(seal_number) > 64) THEN
        RAISE EXCEPTION 'V283: a transfer.carrier_name/seal_number mezőkben 128/64-nél hosszabb meglévő adat van — előbb tisztítani kell.';
    END IF;
END $$;

ALTER TABLE transfer ALTER COLUMN carrier_name TYPE VARCHAR(128);
ALTER TABLE transfer ALTER COLUMN seal_number  TYPE VARCHAR(64);

-- Plombaszám-formátum (NFR-2). NULL megengedett (régi/nem-átadás rekordok).
ALTER TABLE transfer DROP CONSTRAINT IF EXISTS chk_transfer_seal_number_format;
ALTER TABLE transfer
    ADD CONSTRAINT chk_transfer_seal_number_format
    CHECK (seal_number IS NULL OR seal_number ~ '^[A-Za-z0-9/-]+$');
