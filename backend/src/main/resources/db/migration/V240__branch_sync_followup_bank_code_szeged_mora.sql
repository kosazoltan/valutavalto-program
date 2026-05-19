-- V240: V239 follow-up — Codex + Copilot P2 review fix (PR #699)
--
-- Két javítás:
--
-- 1. CODEX P2 (BR026 Szeged Móra szinkronizálás):
--    A V239 `ON CONFLICT (code) DO NOTHING` kihagyta a BR026 rekord
--    frissítését, mert már létezett a V145__real_branches_and_workers_seed.sql
--    seed-ben "Szeged Shell Site-Móra" név + régi címmel. A Google Sheet a
--    "Szeged Móra" név + "6729, Szabadkai út 7." címet adja. A V239 érintetlenül
--    hagyta — most UPDATE-tel szinkronizáljuk.
--
-- 2. COPILOT P2 (8 értéktár bank_code helyes self-code):
--    A V239 a BR009 (Dombóvár Tesco) template-ből CLONE-olta a `bank_code`-ot,
--    így a 8 új értéktár mind `bank_code='BR009'`-t kapott. A V145 seed
--    konvenciója: `bank_code = self.code` (BR026 → 'BR026'). A 8 új értéktár
--    bank_code-ját self.code-ra frissítjük.

-- 1. BR026 Szeged Móra adatok szinkronizálása a Google Sheets értékekkel
UPDATE branch SET
    name = 'Szeged Móra',
    address = 'Szabadkai út 7.',
    city = 'Szeged',
    zip_code = '6729',
    region_code = '20',
    is_vault = FALSE,
    updated_at = NOW()
WHERE code = 'BR026'
  AND (name != 'Szeged Móra' OR address != 'Szabadkai út 7.' OR zip_code != '6729');

-- 2. 8 értéktár bank_code = self.code beállítás (a V145 konvenció szerint).
-- Csak akkor frissít, ha a bank_code NEM egyezik a code-dal (idempotens).
UPDATE branch SET
    bank_code = code,
    updated_at = NOW()
WHERE code IN ('BR010', 'BR020', 'BR040', 'BR050', 'BR063', 'BR075', 'BR120', 'BR145')
  AND bank_code != code;

-- Audit log a NOTICE-ban
DO $$
DECLARE
    br026_fixed INT;
    vault_bank_codes_fixed INT;
BEGIN
    SELECT COUNT(*) INTO br026_fixed FROM branch WHERE code = 'BR026' AND name = 'Szeged Móra';
    SELECT COUNT(*) INTO vault_bank_codes_fixed FROM branch
     WHERE code IN ('BR010','BR020','BR040','BR050','BR063','BR075','BR120','BR145')
       AND bank_code = code;
    RAISE NOTICE 'V240: BR026 Szeged Móra szinkron OK (% sor), 8 értéktár bank_code=self_code (% sor)',
        br026_fixed, vault_bank_codes_fixed;
END $$;
