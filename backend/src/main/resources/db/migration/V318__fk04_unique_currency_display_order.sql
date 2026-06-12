-- V318 (FK04 / FR-6): UNIQUE constraint a currency.display_order oszlopra.
--
-- Csak a V317 (duplikáció-felszámolás) UTÁN futtatható — a Flyway verziósorrend ezt garantálja.
--
-- TBD-2 eldöntve (repo-tény): a currency tábla GLOBÁLIS törzs, nincs company_id oszlopa
-- (V3__create_transaction_tables.sql:10–25), ezért a UNIQUE csak a display_order-re vonatkozik
-- (nem (company_id, display_order) párra, ahogy a kontextus-dokumentum feltételesen javasolta).
--
-- Megjegyzés: a PostgreSQL UNIQUE constraint a NULL értékeket nem tekinti ütközőnek; a
-- display_order oszlopnak DEFAULT 100 értéke van (V3), a V317 pedig minden meglévő sornak
-- explicit értéket ad.

DO $$
BEGIN
    -- Self-review P1: schema-kvalifikált ellenőrzés (conrelid), hogy egy másik sémában
    -- azonos nevű constraint ne adjon fals pozitívot megosztott instance-en.
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'uq_currency_display_order'
           AND conrelid = 'currency'::regclass
    ) THEN
        ALTER TABLE currency
            ADD CONSTRAINT uq_currency_display_order UNIQUE (display_order);
    END IF;
END $$;
