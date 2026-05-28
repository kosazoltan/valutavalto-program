-- V274: RSD (Szerb dinár) hiány javítása a központi valutanem-törzsben.
--
-- Beküldő: Kasza Helga (Főértéktár) — v2.27.35 telepítés-utáni visszajelzés.
-- Tünet: az RSD MINDHÁROM törzs-vezérelt felületről (Készlet-snapshot,
-- Országos készlet kártyák, Aktuális árfolyamok) HIÁNYZIK, miközben a kért
-- aktív sorrend tartalmazza (display_order=16, V271 spec).
--
-- A V271 az aktív halmazt UPDATE-tel állítja be (WHERE c.code = v.code) —
-- ez csak a LÉTEZŐ sorokon hat. Ha az RSD valamilyen okból hiányzott vagy
-- egy korábbi admin-művelet inaktiválta, a V271 step-3 UPDATE nem hozta
-- vissza aktívra. Ez a migráció defenzíven minden esetet kezel:
--
--   - ha az RSD nincs a táblában     → INSERT (új sor aktívan, display_order=16)
--   - ha az RSD inaktív              → UPDATE is_active=true, display_order=16
--   - ha az RSD már aktív és helyes  → no-op (a SET idempotens)
--
-- Idempotens: ismételt futtatáskor is a kívánt végállapotot eredményezi.
-- A V272 (TST) mintáját követi: törlés helyett, audit-megőrzéssel.

INSERT INTO currency (code, name, symbol, decimal_places, display_order, is_active, created_at)
VALUES ('RSD', 'Szerb dinár', 'дин', 2, 16, true, NOW())
ON CONFLICT (code) DO UPDATE
    SET is_active = true,
        display_order = 16,
        name = COALESCE(currency.name, EXCLUDED.name),
        symbol = COALESCE(currency.symbol, EXCLUDED.symbol),
        decimal_places = EXCLUDED.decimal_places,
        updated_at = NOW();
