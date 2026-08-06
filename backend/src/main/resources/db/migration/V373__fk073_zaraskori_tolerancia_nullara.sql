-- V373: FK-073 — záráskori eltérés-tolerancia küszöbök 0-ra állítása (HUF/EUR/USD)
--
-- TUDATOS FELÜLÍRÁS (egyszeri üzleti döntés): a V364__closing_tolerance_per_currency_seed.sql
-- fejléce kifejezetten rögzíti, hogy „a V307-mintától szándékosan eltérve NINCS
-- update-if-different ág — az üzemeltető által testre szabott toleranciát redeploy nem
-- írhatja felül némán”. A jelen migráció ezt a korábbi technikai szerződést TUDATOSAN
-- FELÜLÍRJA: ez most egyszeri, üzleti döntésen alapuló értékfrissítés (a záráskori
-- tolerancia-küszöb HUF/EUR/USD-re egyaránt 0, pénztári és értéktári kontextusban is),
-- NEM visszatérő seed-viselkedés — a jövőbeni seed-felülírás tilalma továbbra is fennáll.
--
-- Cél (FK-073 FR-3): a három GLOBÁLIS (company_id IS NULL) tolerancia-sor
-- (CLOSING_TOLERANCE_HUF/EUR/USD, V364 seed: 5/1/1) értéke 0-ra változik ÉS
-- is_active = TRUE-ra állítódik (akkor is, ha korábban FALSE/NULL lenne). Az is_active
-- biztosítása kötelező: a SystemParameterService.findEffective() (4a0e39d0, FK-073 §7)
-- csak aktív sort tekint effektívnek — egy inaktivált sor a kód-fallbackre esne vissza
-- (HUF→1, > operátor), ami csendben kioltaná a 0-tolerancia célját.
--
-- Operátor-hatás: explicit 0 értékű sorral a ClosingTolerance.blocks() |diff| >= 0 szerint
-- dönt, de nulla eltérés soha nem blokkol — tehát bármilyen nem-nulla eltérés blokkol,
-- a nulla eltérés nem. Ez a finalizeClosing enforce-ágára és az eltérés-táblázat
-- státuszára (FK-073 FR-1) egyaránt igaz, mind pénztárban, mind értéktárban.
--
-- Cég-szintű override-ok: a ClosingToleranceService a céges sort részesíti előnyben a
-- globálissal szemben (ha aktív) — ezt a migráció NEM írja felül; az AKTÍV céges
-- override-sorokról RAISE NOTICE tájékoztat (inaktivált override nem effektív, ezért
-- azokról nem kell jelezni).
--
-- Idempotens: insert-if-missing (V364-minta) + update-if-different (V307-minta),
-- DO-blokkban, RAISE NOTICE jelzéssel a tényleges változásról.

DO $$
DECLARE
    param_key text;
    keys text[] := ARRAY['CLOSING_TOLERANCE_HUF', 'CLOSING_TOLERANCE_EUR', 'CLOSING_TOLERANCE_USD'];
    changed_keys text[] := ARRAY[]::text[];
    override_summary text;
BEGIN
    FOREACH param_key IN ARRAY keys LOOP
        -- 1) insert-if-missing (V364/V307 minta): ha a globális sor valamilyen okból
        --    hiányozna, a kívánt végállapot (explicit 0, aktív) így is előáll.
        INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
        SELECT gen_random_uuid(), param_key, '0', 'NUMBER', 'CLOSING',
               'FK-073: záráskori eltérés-tolerancia ' || substr(param_key, 17) || '-ra (0 = bármilyen nem-nulla '
               || 'eltérés blokkol). Egyszeri üzleti döntés: a V364 seed-értékek tudatos felülírása.',
               TRUE
        WHERE NOT EXISTS (
            SELECT 1 FROM system_parameter
             WHERE parameter_key = param_key AND company_id IS NULL
        );
        IF FOUND THEN
            changed_keys := changed_keys || param_key;
        END IF;

        -- 2) update-if-different (V307 minta): meglévő globális sor 0-ra + aktívra,
        --    ha még nem az (érték ÉS is_active egyaránt ellenőrizve).
        UPDATE system_parameter
           SET parameter_value = '0',
               is_active = TRUE,
               updated_at = now(),
               updated_by = 'V373_fk073_migration'
         WHERE parameter_key = param_key
           AND company_id IS NULL
           AND (parameter_value IS DISTINCT FROM '0' OR is_active IS NOT TRUE);
        IF FOUND THEN
            changed_keys := changed_keys || param_key;
        END IF;
    END LOOP;

    IF cardinality(changed_keys) > 0 THEN
        RAISE NOTICE 'FK-073: globális záráskori tolerancia-küszöbök 0-ra állítva (is_active=TRUE biztosítva): %',
            array_to_string(changed_keys, ', ');
    ELSE
        RAISE NOTICE 'FK-073: nincs változtatnivaló — a globális záráskori toleranciák már 0 értékűek és aktívak.';
    END IF;

    -- 3) Aktív cég-szintű override-ok jelzése (FK-073 §6): a globális 0-küszöb ezekben
    --    a cégekben NEM érvényesül, amíg az aktív céges sor létezik. Inaktivált
    --    override nem effektív találat (findEffective is_active-szűrése), ezért az
    --    nem jelenik meg itt.
    SELECT string_agg(
               'company_id=' || company_id::text || ' ' || parameter_key || '=' || parameter_value,
               '; ' ORDER BY parameter_key, company_id::text)
      INTO override_summary
      FROM system_parameter
     WHERE parameter_key = ANY(keys)
       AND company_id IS NOT NULL
       AND is_active = TRUE;

    IF override_summary IS NOT NULL THEN
        RAISE NOTICE 'FK-073: AKTÍV cég-szintű tolerancia-override sorok léteznek — a globális 0-küszöb náluk nem érvényesül: %',
            override_summary;
    END IF;
END $$;
