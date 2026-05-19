-- V237: 6 alacsony forgalmu / elavult valuta deaktivalasa (2026-05-19 user-direktiva)
--
-- Kosa Zoltan / foertektaros: a Fooldal arfolyam-tabla zsufolt, az alabbi
-- 6 valutara alig vagy egyaltalan nincs forgalom, ezert el akarjak rejteni.
--
-- A is_active=false beallitassal:
-- - Az Arfolyamkeszito Foliap nem mutatja oket
-- - A penztaros UI dropdownok kihagyjak
-- - A historikus tranzakciok (exchange_rate_master + transaction) erintetlenek
--   maradnak, igy a regi adatok visszanezhetok
-- - Ha kesobb visszahozzak (pl. SEK turizmus mehet feljebb), egy egyszeru
--   UPDATE currency SET is_active=true WHERE code='SEK' elegendo
--
-- TERMESZETESEN reverzibilis. A "RCH" valuta ha letezett egyaltalan a
-- production-on (V70 alapseed-ben NEM szerepelt), is_active=false-re kerul.

UPDATE currency SET is_active = false, updated_at = NOW()
WHERE code IN ('DKK', 'NOK', 'SEK', 'HRK', 'BGN', 'RCH')
  AND is_active = true;

-- Audit log: rogzitjuk hogy melyik valutat deaktivaltuk
DO $$
DECLARE
    deactivated_count INT;
BEGIN
    SELECT COUNT(*) INTO deactivated_count
    FROM currency
    WHERE code IN ('DKK', 'NOK', 'SEK', 'HRK', 'BGN', 'RCH')
      AND is_active = false;
    RAISE NOTICE 'V237: % valuta deaktivalva (cel: 6 valuta)', deactivated_count;
END $$;
