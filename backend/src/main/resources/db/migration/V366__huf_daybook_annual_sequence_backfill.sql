-- FKH-022 kiegészítés FR-K2: HUF naplókönyv éves sorszám BACKFILL — shipment_request + transfer
-- KÖZÖS, created_at szerinti időrendben, cégenként és évenként.
--
-- Szabályok (fagyasztott tesztek: HufDaybookAnnualSequenceBackfillFrK2PostgresTest):
--   1. Meglévő (élő úton kapott) sorszám NEM íródik át; a NULL-os bizonylatok a meglévő
--      maximum UTÁN folytatva kapnak sorszámot.
--   2. A két tábla eseményei EGY közös sorban számozódnak (nem táblánként külön).
--      Tie-break azonos időbélyegnél: event_time, majd forrás-tábla ('shipment' < 'transfer'),
--      majd id (Kósa-direktíva, 2026-07-29).
--   3. A sztornó-sor SAJÁT sorszámot kap (storno_journal_sequence), időrendi kulcsa a
--      cancelled_at. Shipment-sztornó: cancelled_at IS NOT NULL; transfer-sztornó:
--      is_cancelled = true ÉS cancelled_at IS NOT NULL.
--   4. A sorszám-blokk a huf_daybook_sequence számlálón keresztül, atomikusan foglalódik
--      (ON CONFLICT DO UPDATE), így az egyidejű élő kiosztással nem ütközhet.
--
-- Megjegyzés: szándékosan NINCS DO $$ blokk — a migrációt a tesztek statement-enként
-- splittelő ResourceDatabasePopulator-ral is futtatják. A tmp_hd_* táblák TEMP táblák:
-- a kapcsolat (Flyway-migrációs session / teszt-populator) végén automatikusan
-- megszűnnek, ezért explicit DROP nem szükséges (és nem is szerepel itt).

-- 1. Esemény-halmaz: minden még számozatlan eredeti bizonylat (created_at kulccsal)
--    és minden még számozatlan sztornó-esemény (cancelled_at kulccsal), mindkét táblából.
--    A legacy '...-SZ' sorszámú transfer-sorok kizárva (megjelenítési műtermékek).
CREATE TEMP TABLE tmp_hd_events AS
SELECT sr.company_id,
       EXTRACT(YEAR FROM sr.created_at)::int AS event_year,
       'shipment' AS source,
       sr.id::text AS id_text,
       sr.created_at AS event_time,
       false AS is_storno
FROM shipment_request sr
WHERE sr.company_id IS NOT NULL
  AND sr.serial_prefix IN ('FF', 'UF')
  AND sr.annual_journal_sequence IS NULL
UNION ALL
SELECT sr.company_id,
       EXTRACT(YEAR FROM sr.cancelled_at)::int,
       'shipment',
       sr.id::text,
       sr.cancelled_at,
       true
FROM shipment_request sr
WHERE sr.company_id IS NOT NULL
  AND sr.serial_prefix IN ('FF', 'UF')
  AND sr.cancelled_at IS NOT NULL
  AND sr.storno_journal_sequence IS NULL
UNION ALL
SELECT t.company_id,
       EXTRACT(YEAR FROM t.created_at)::int,
       'transfer',
       t.id::text,
       t.created_at,
       false
FROM transfer t
WHERE t.company_id IS NOT NULL
  AND (t.transfer_number LIKE 'FF-%' OR t.transfer_number LIKE 'UF-%')
  AND t.transfer_number NOT LIKE '%-SZ'
  AND t.annual_journal_sequence IS NULL
UNION ALL
SELECT t.company_id,
       EXTRACT(YEAR FROM t.cancelled_at)::int,
       'transfer',
       t.id::text,
       t.cancelled_at,
       true
FROM transfer t
WHERE t.company_id IS NOT NULL
  AND (t.transfer_number LIKE 'FF-%' OR t.transfer_number LIKE 'UF-%')
  AND t.transfer_number NOT LIKE '%-SZ'
  AND t.is_cancelled = true
  AND t.cancelled_at IS NOT NULL
  AND t.storno_journal_sequence IS NULL;

-- 2. Számláló-szinkron: minden érintett (cég, év) csoportra legyen számláló-sor, és a
--    last_value legalább a már kiosztott sorszámok maximuma legyen (GREATEST — a számláló
--    sosem csökken, az élő kiosztással konzisztens marad).
INSERT INTO huf_daybook_sequence (company_id, sequence_year, last_value)
SELECT g.company_id, g.event_year, COALESCE(x.max_existing, 0)
FROM (SELECT DISTINCT company_id, event_year FROM tmp_hd_events) g
LEFT JOIN (
    SELECT company_id, seq_year, MAX(v) AS max_existing
    FROM (
        SELECT company_id, EXTRACT(YEAR FROM created_at)::int AS seq_year,
               annual_journal_sequence AS v
        FROM shipment_request
        WHERE company_id IS NOT NULL AND annual_journal_sequence IS NOT NULL
        UNION ALL
        SELECT company_id, EXTRACT(YEAR FROM cancelled_at)::int,
               storno_journal_sequence
        FROM shipment_request
        WHERE company_id IS NOT NULL AND storno_journal_sequence IS NOT NULL
        UNION ALL
        SELECT company_id, EXTRACT(YEAR FROM created_at)::int,
               annual_journal_sequence
        FROM transfer
        WHERE company_id IS NOT NULL AND annual_journal_sequence IS NOT NULL
        UNION ALL
        SELECT company_id, EXTRACT(YEAR FROM cancelled_at)::int,
               storno_journal_sequence
        FROM transfer
        WHERE company_id IS NOT NULL AND storno_journal_sequence IS NOT NULL
    ) all_assigned
    GROUP BY company_id, seq_year
) x ON x.company_id = g.company_id AND x.seq_year = g.event_year
ON CONFLICT (company_id, sequence_year)
DO UPDATE SET last_value = GREATEST(huf_daybook_sequence.last_value, EXCLUDED.last_value);

CREATE TEMP TABLE tmp_hd_bases (company_id UUID, event_year INT, base_value INT);

-- 3. Blokk-foglalás az élő allokátorral közös számlálón: a last_value atomikusan lép
--    az esemény-darabszámmal; a foglalt blokk kezdete (base) = új last_value - darabszám.
--    Így az egyidejű élő next() hívások sosem kaphatnak a backfill-blokkba eső értéket.
WITH cnt AS (
    SELECT company_id, event_year, count(*)::int AS cnt
    FROM tmp_hd_events
    GROUP BY company_id, event_year
), upd AS (
    UPDATE huf_daybook_sequence h
    SET last_value = h.last_value + c.cnt
    FROM cnt c
    WHERE h.company_id = c.company_id AND h.sequence_year = c.event_year
    RETURNING h.company_id, h.sequence_year, h.last_value, c.cnt
)
INSERT INTO tmp_hd_bases (company_id, event_year, base_value)
SELECT company_id, sequence_year, last_value - cnt FROM upd;

-- 4. Közös időrendi számozás a foglalt blokkon belül (tie-break: event_time, source, id).
CREATE TEMP TABLE tmp_hd_assigned AS
SELECT e.source,
       e.id_text,
       e.is_storno,
       (b.base_value + ROW_NUMBER() OVER (
           PARTITION BY e.company_id, e.event_year
           ORDER BY e.event_time, e.source, e.id_text
       ))::int AS assigned
FROM tmp_hd_events e
JOIN tmp_hd_bases b
  ON b.company_id = e.company_id AND b.event_year = e.event_year;

-- 5. Visszaírás a bizonylat-táblákba.
UPDATE shipment_request sr
SET annual_journal_sequence = a.assigned
FROM tmp_hd_assigned a
WHERE a.source = 'shipment' AND a.is_storno = false AND sr.id::text = a.id_text;

UPDATE shipment_request sr
SET storno_journal_sequence = a.assigned
FROM tmp_hd_assigned a
WHERE a.source = 'shipment' AND a.is_storno = true AND sr.id::text = a.id_text;

UPDATE transfer t
SET annual_journal_sequence = a.assigned
FROM tmp_hd_assigned a
WHERE a.source = 'transfer' AND a.is_storno = false AND t.id::text = a.id_text;

UPDATE transfer t
SET storno_journal_sequence = a.assigned
FROM tmp_hd_assigned a
WHERE a.source = 'transfer' AND a.is_storno = true AND t.id::text = a.id_text;
