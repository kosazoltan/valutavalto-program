-- V319: RUB (orosz rubel) deaktivalasa — nem forgalmazott valuta
--
-- Kosa Zoltan user-direktiva (2026-06-12): "Rubelt, RUB nem forgalmazunk."
-- Repo-teny: a V70 alapseed ota a RUB aktiv volt; a 2026-05-19-i valuta-
-- eltavolitasi kor (V237: DKK/NOK/SEK/HRK/BGN/RCH) NEM erintette.
--
-- A V237 mintajat koveti (is_active=false, NEM DELETE — Pmt./NAV 8 eves
-- megorzes, historikus tranzakciok visszanezhetok maradnak):
-- - FK04 ota minden valutalista katalogus-vezerelt aktiv-szuressel
--   (useCurrencyCatalog), igy a RUB automatikusan eltunik a Folaprol,
--   a munkacsoportokbol es a penztari valasztokbol.
-- - A V317-es kanonikus display_order=14 erteke megmarad (a UNIQUE
--   constraintet nem serti, inaktiv sorkent nem renderelodik).
-- - FONTOS: a V320-as cimlet-katalogus seed AKTIV valutakra szur, ezert
--   ennek a migracionak ELOTTE kell futnia — a RUB cimleteket nem seedeljuk.
--
-- Visszahozatal ha megis kellene: UPDATE currency SET is_active=true WHERE code='RUB';
DO $$
DECLARE
    deactivated_count INT;
BEGIN
    UPDATE currency
       SET is_active = false,
           updated_at = NOW()
     WHERE code = 'RUB'
       AND is_active = true;
    GET DIAGNOSTICS deactivated_count = ROW_COUNT;
    RAISE NOTICE 'V319: % RUB sor deaktivalva ebben a futasban (0 = mar inaktiv volt)', deactivated_count;
END $$;
