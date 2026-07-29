-- FKH-022 kiegészítés FR-K2: a HUF naplókönyv éves sorszáma a transfer táblára is kiterjed,
-- és a sztornó-sor SAJÁT, önálló sorszámot kap (nem az eredeti bizonylatét ismétli).
--
--   * transfer.annual_journal_sequence  — az FF-/UF- prefixű átadás-átvétel bizonylat
--     cég+év szerinti naplókönyv-sorszáma (a shipment_request V360-as oszlopának párja).
--   * transfer.storno_journal_sequence  — a transfer sztornó-sorának saját sorszáma
--     (a cancelled_at időrendi helyén kiosztva).
--   * shipment_request.storno_journal_sequence — a shipment sztornó-sorának saját sorszáma.
--
-- A visszamenőleges kitöltést a V366-os backfill-migráció végzi.

ALTER TABLE transfer
    ADD COLUMN IF NOT EXISTS annual_journal_sequence INTEGER;

ALTER TABLE transfer
    ADD COLUMN IF NOT EXISTS storno_journal_sequence INTEGER;

ALTER TABLE shipment_request
    ADD COLUMN IF NOT EXISTS storno_journal_sequence INTEGER;
