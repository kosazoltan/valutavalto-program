-- V293 (Pénztár Törzs Adatbázis alapmodul, Kasza Helga FELTERKEPEZES 2026-06-03):
-- a branch (iroda-törzs) kiegészítése a Pénztár Törzs modul által kért, eddig hiányzó
-- alap-mezőkkel. Minden oszlop ADDITÍV, visszafelé kompatibilis (zero-downtime):
--   - a logikai szolgáltatás-flagek NOT NULL DEFAULT FALSE → a meglévő sorok azonnal FALSE-t
--     kapnak, a ~40 Branch-re hivatkozó modul (Transaction/CashBalance/Worker/ShipmentRequest/...)
--     változatlanul működik (egyik sem olvassa ezeket a mezőket);
--   - a short_name nullable VARCHAR → opcionális rövid név.
-- A phone, email, bank_code, is_vault MÁR LÉTEZIK (V0_1 / V174) — azokat NEM duplikáljuk.
--
-- PostgreSQL 11+ alatt a DEFAULT-os ADD COLUMN metaadat-művelet (nem ír újra teljes táblát),
-- így nagy branch-táblán is gyors és lock-barát. Idempotens: ADD COLUMN IF NOT EXISTS.

ALTER TABLE branch ADD COLUMN IF NOT EXISTS short_name      VARCHAR(100);
ALTER TABLE branch ADD COLUMN IF NOT EXISTS has_afa         BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE branch ADD COLUMN IF NOT EXISTS has_wu          BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE branch ADD COLUMN IF NOT EXISTS has_mg          BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE branch ADD COLUMN IF NOT EXISTS has_pos         BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE branch ADD COLUMN IF NOT EXISTS closed_saturday BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE branch ADD COLUMN IF NOT EXISTS closed_sunday   BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN branch.short_name      IS 'Pénztár Törzs: rövid név (opcionális, listákhoz/címkékhez).';
COMMENT ON COLUMN branch.has_afa         IS 'Pénztár Törzs: az iroda nyújt-e ÁFA-visszatérítést.';
COMMENT ON COLUMN branch.has_wu          IS 'Pénztár Törzs: Western Union szolgáltatás elérhető-e.';
COMMENT ON COLUMN branch.has_mg          IS 'Pénztár Törzs: MoneyGram szolgáltatás elérhető-e.';
COMMENT ON COLUMN branch.has_pos         IS 'Pénztár Törzs: bankkártya-elfogadás (POS) elérhető-e.';
COMMENT ON COLUMN branch.closed_saturday IS 'Pénztár Törzs: az iroda szombaton zárva van-e.';
COMMENT ON COLUMN branch.closed_sunday   IS 'Pénztár Törzs: az iroda vasárnap zárva van-e.';
