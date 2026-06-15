-- V327: RUB (orosz rubel) visszaaktivalasa — MEGIS forgalmazott valuta.
--
-- Kosa Zoltan user-direktiva (2026-06-15): a 2026-06-12-i "RUB-ot nem forgalmazunk"
-- direktiva TEVES informacion alapult; a RUB-ot forgalmazzuk, vissza kell allitani.
-- Ez a migracio a V319__deactivate_rub_currency.sql szandekos megforditasa.
--
-- A display_order=14 (V317 kanonikus sorrend: UAH=13, RUB=14, EUA=15, TRY=16)
-- valtozatlan marad — a V319 csak az is_active-et allitotta, a sorrendet nem.
--
-- Idempotens: csak inaktiv RUB-sort aktival; tobbszori futtatas (es a Hetzner
-- prod-on korabban kezzel deaktivalt allapot) eseten is biztonsagos.
-- A koveto V328 (cimlet-katalogus) es V329 (currency_stock) erre az aktiv
-- allapotra epul — ezert KELL ennek elobb futnia.
DO $$
DECLARE
    activated_count INT;
BEGIN
    UPDATE currency
       SET is_active = true,
           updated_at = NOW()
     WHERE code = 'RUB'
       AND is_active = false;
    GET DIAGNOSTICS activated_count = ROW_COUNT;
    RAISE NOTICE 'V327: % RUB sor visszaaktivalva ebben a futasban (0 = mar aktiv volt)', activated_count;
END $$;
