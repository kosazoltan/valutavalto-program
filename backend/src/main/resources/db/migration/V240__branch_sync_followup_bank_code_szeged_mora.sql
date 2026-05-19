-- V240: V239 follow-up — Codex + Copilot P2 review fix (PR #699, #700)
--
-- Három javítás (PR #700 Codex+Copilot P2 review-vel kibővítve):
--
-- 1. CODEX P2 #699 (BR026 Szeged Móra szinkronizálás):
--    A V239 `ON CONFLICT (code) DO NOTHING` kihagyta a BR026 rekord
--    frissítését, mert már létezett a V145__real_branches_and_workers_seed.sql
--    seed-ben "Szeged Shell Site-Móra" név + régi címmel. A Google Sheet a
--    "Szeged Móra" név + "6729, Szabadkai út 7." címet adja.
--
-- 2. COPILOT P2 #699 + CODEX P2 #700 (9 branch bank_code helyes self-code):
--    A V239 a BR009 (Dombóvár Tesco) template-ből CLONE-olta a `bank_code`-ot,
--    így a 8 új értéktár + esetleg az új-install BR026 mind `bank_code='BR009'`-t
--    kapott. A V145 seed konvenciója: `bank_code = self.code`. Ezt javítjuk
--    mind a 9 érintett kódra (BR026 + 8 értéktár).
--
-- 3. COPILOT P2 #700 (WHERE feltétel + GET DIAGNOSTICS + BIGINT):
--    - BR026 WHERE feltétel `IS DISTINCT FROM` minden beállított mezőre
--      (null-safe, defenzív drift-detektálás).
--    - GET DIAGNOSTICS ROW_COUNT (NEM post-COUNT) a NOTICE-ban
--      a ténylegesen módosított sorszámhoz.
--    - BIGINT változó típus (COUNT/ROW_COUNT BIGINT-et ad).
--
-- Idempotens: ismételt futtatás no-op (UPDATE WHERE feltétel only-if-diff).

DO $$
DECLARE
    br026_updated  BIGINT := 0;
    bank_codes_fix BIGINT := 0;
BEGIN
    -- 1. BR026 Szeged Móra adatok szinkronizálása a Google Sheets értékekkel.
    --    Null-safe IS DISTINCT FROM check minden set-elt mezőre — ha bármelyik
    --    driftelt (vagy egy korábbi V239 új-install-ban másképp állt), javítjuk.
    UPDATE branch SET
        name = 'Szeged Móra',
        address = 'Szabadkai út 7.',
        city = 'Szeged',
        zip_code = '6729',
        region_code = '20',
        is_vault = FALSE,
        updated_at = NOW()
    WHERE code = 'BR026'
      AND (
            name        IS DISTINCT FROM 'Szeged Móra'
         OR address     IS DISTINCT FROM 'Szabadkai út 7.'
         OR city        IS DISTINCT FROM 'Szeged'
         OR zip_code    IS DISTINCT FROM '6729'
         OR region_code IS DISTINCT FROM '20'
         OR is_vault    IS DISTINCT FROM FALSE
      );
    GET DIAGNOSTICS br026_updated = ROW_COUNT;

    -- 2. 9 branch bank_code = self.code (V145 konvenció).
    --    BR026 is bekerül (Codex P2 #700): új-install path-on V239 INSERT-elte
    --    bank_code='BR009'-cel. A WHERE bank_code != code idempotenssé teszi.
    UPDATE branch SET
        bank_code = code,
        updated_at = NOW()
    WHERE code IN ('BR010', 'BR020', 'BR026', 'BR040', 'BR050', 'BR063', 'BR075', 'BR120', 'BR145')
      AND bank_code IS DISTINCT FROM code;
    GET DIAGNOSTICS bank_codes_fix = ROW_COUNT;

    RAISE NOTICE 'V240: BR026 Szeged Móra szinkron (% sor frissítve), 9 branch bank_code=self_code (% sor frissítve)',
        br026_updated, bank_codes_fix;
END $$;
