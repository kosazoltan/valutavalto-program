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

-- Copilot P2 #697 #5 fix: GET DIAGNOSTICS ROW_COUNT pontosan a CURRENT
-- futasban deaktivalt sorok szamat adja meg (V160 mintajara). A regi
-- COUNT(*) az osszes inaktiv sort tartalmazta volna, ami felrevezeto volt
-- (pl. HRK mar V160-ban inaktivalva).
DO $$
DECLARE
    deactivated_count INT;
BEGIN
    UPDATE currency
       SET is_active = false,
           updated_at = NOW()
     WHERE code IN ('DKK', 'NOK', 'SEK', 'HRK', 'BGN', 'RCH')
       AND is_active = true;
    GET DIAGNOSTICS deactivated_count = ROW_COUNT;
    RAISE NOTICE 'V237: % valuta deaktivalva ebben a futasban (cel max 6 valuta — egyesek mar elozoleg inaktivak voltak)', deactivated_count;
END $$;
