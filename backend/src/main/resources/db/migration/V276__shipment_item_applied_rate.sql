-- V276 (Bali Henriett kérés D.): alkalmazott elszámoló árfolyam + forintosított érték
-- a szállítmány-tételeken.
--
-- Beküldő: Bali Henriett (Szeged Ertektar) 2026-05-27 Átadás-átvétel kérés D pont:
-- "A tranzakció rögzítésekor a deviza kiválasztása után a rendszernek tartalmaznia
-- kell az alkalmazott árfolyamot is. Ezt az árfolyamot a programnak kötelezően és
-- automatikusan a rendszerben lévő aktuális elszámoló árból kell beemelnie. A
-- rögzített bizonylaton és a háttérben történő forintosított kiszámításnál is ezzel
-- a hivatalos elszámoló árral kell dolgoznia a programnak, ezt nekem ne kelljen
-- kézzel beírnom."
--
-- Új oszlopok a shipment_request_item táblán:
--   applied_rate  NUMERIC(18,6)  — az elszámoló árfolyam, amit a tétel rögzítésekor
--                                   beemeltünk (audit-megőrzés: utólagos rate-változás
--                                   nem írja felül).
--   huf_value     NUMERIC(18,2)  — forintosított érték = requested_amount × applied_rate
--                                   (auto-számolt, HUF kerekítés alkalmazva).
--
-- Mindkét oszlop nullable a backward-compat miatt — meglévő szállítmányok érték nélkül
-- maradnak; új tételek a service-ben kötelezően kitöltik (vagy explicit hibát adnak).
-- Idempotens: ADD COLUMN IF NOT EXISTS.

ALTER TABLE shipment_request_item
    ADD COLUMN IF NOT EXISTS applied_rate NUMERIC(18, 6),
    ADD COLUMN IF NOT EXISTS huf_value    NUMERIC(18, 2);

COMMENT ON COLUMN shipment_request_item.applied_rate IS
    'D követelmény: a tétel rögzítésekor beemelt elszámoló árfolyam (officialRate). '
    'Audit-megőrzés — utólagos árfolyam-változás nem írja felül.';

COMMENT ON COLUMN shipment_request_item.huf_value IS
    'D követelmény: forintosított érték = requested_amount × applied_rate, HUF kerekítve.';
