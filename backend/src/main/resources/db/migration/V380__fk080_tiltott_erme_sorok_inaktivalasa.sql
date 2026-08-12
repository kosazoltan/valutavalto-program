-- FK-080 (FR-6): egyszeri korrekcio — a tiltott, mar letezo COIN denomination-sorok
-- inaktivalasa.
--
-- GYOKER: a V320/V328 backfill a teljes jegybanki katalogust szurta be minden aktiv
-- fiokra, a ClosingWizardService auto-create aga pedig a `faceValue >= 200 -> BANKNOTE,
-- egyebkent COIN` szabalyt alkalmazta devizatol fuggetlenul. Igy a fiokokon uzletileg
-- tiltott erme-sorok keletkeztek (pl. CAD 1/2, CZK ermek, ILS ermek, TRY 1, RSD 5/2/1,
-- valamint HUF 1/2 forint). Az uzleti szabaly szerint erme KIZAROLAG HUF 200/100/50/20/10/5
-- es EUR 2/1 lehet — minden mas erme-sor hibas.
--
-- MIT CSINAL: minden AKTIV, COIN tipusu `denomination` sort inaktival, amelynek
-- (company, deviza, nevertek) harmasa NEM szerepel UGYANANNAK a cegnek az AKTIV COIN
-- katalogus-sorakent a `denomination_allowed` tablaban.
--
-- MIT NEM CSINAL:
--   * NINCS DELETE — egyetlen sor sem torlodik (a sorok es az FK-n fuggo
--     `denomination_balance` egyenlegek megmaradnak, visszakereshetok maradnak);
--   * a `denomination_balance` tablahoz NEM nyul (NFR-4);
--   * BANKNOTE sorokat nem erint (a WHERE denomination_type = 'COIN' szuri);
--   * semasemodositas nincs (se DDL, se index).
--
-- MIERT BIZTONSAGOS AZ ENGEDELYEZETT ERMEKRE: a predikatum pozitiv-lista alapu, es a
-- V379 (HUF-seed) a verzioszam-sorrend miatt EZ ELOTT fut le ugyanabban a Flyway-futasban.
-- Ezert a HUF 200/100/50/20/10/5 es az EUR 2/1 sorok mar benne vannak a katalogusban,
-- amikor ez az UPDATE ertekeli oket — nem inaktivalodnak. A fajlok atszamozasa
-- (V379/V380 sorrend megforditasa) ezt a garanciat megtorne: TILOS.
--
-- MULTI-TENANT: a NOT EXISTS predikatum `da.company_id = d.company_id` szurest tartalmaz —
-- egy ceg katalogusa soha nem legitimal masik ceg sorat (spec 6.b, dedikalt cross-tenant
-- teszt bizonyitja).
--
-- MINDKET AKTIV-OSZLOP (ticket C3) — OSZLOP-AGNOSZTIKUS (2026-08-12 eles hotfix):
-- a `denomination` tablan a V3 DDL `active` oszlopot hozott letre, a V3_7/V109 guard
-- pedig `is_active`-ot ad hozza ott, ahol csak `active` van. A ket oszlop MEGLETE
-- KORNYEZETFUGGO: az eles Hetzner DB-n (2026-08-12) a `denomination` tablan CSAK
-- `is_active` van, a friss Testcontainers-sema viszont mindkettot tartalmazza.
--
-- Az eredeti, statikus `SET active = false, is_active = false ... WHERE d.active = true`
-- ezert elesben `ERROR: column d.active does not exist` (SQLSTATE 42703) hibaval elbukott
-- es a backend nem indult el (502). A javitas dinamikus SQL-t hasznal: futasidoben nezi
-- meg az information_schema-bol, melyik aktiv-oszlop letezik, es CSAK azokat irja.
-- Igy ugyanaz a fajl helyes a teljes (dev/teszt) es a csonka (eles) semaval is.
--
-- NFR-1 (idempotencia): a masodik futas 0 sort erint, mert a mar inaktivalt sorokra a
-- letezo aktiv-oszlop `= true` feltetele nem all fenn.
-- NFR-3 (nincs allasido): egyetlen, indexelt UPDATE egyetlen tranzakcioban; a varhato
-- eles hatokor ~90 fiok x nehany tucat sor — futasideje jol egy masodperc alatt,
-- karbantartasi ablak nem szukseges.

DO $$
DECLARE
    affected     integer;
    has_active   boolean;
    has_isactive boolean;
    set_clause   text;
    where_clause text;
BEGIN
    SELECT EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'denomination'
                      AND column_name = 'active')
      INTO has_active;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'denomination'
                      AND column_name = 'is_active')
      INTO has_isactive;

    IF NOT has_active AND NOT has_isactive THEN
        RAISE EXCEPTION 'FK-080 V380: a denomination tablan sem `active`, sem `is_active` oszlop nincs';
    END IF;

    -- MINDEN letezo aktiv-oszlopot explicit false-ra allitunk, igy az eredmeny nem fugg
    -- a trg_sync_active_columns trigger tuzelesetol.
    set_clause := concat_ws(', ',
        CASE WHEN has_active   THEN 'active = false'    END,
        CASE WHEN has_isactive THEN 'is_active = false' END,
        'updated_at = NOW()');

    -- A szurest a lehetoleg ELSODLEGES (`active`) oszlopra tesszuk, ha van; kulonben
    -- az `is_active`-ra. A ketto a trigger miatt szinkronban van, ahol mindketto letezik.
    where_clause := CASE WHEN has_active THEN 'd.active = true' ELSE 'd.is_active = true' END;

    EXECUTE format($fmt$
        UPDATE denomination d
           SET %s
         WHERE %s
           AND d.denomination_type = 'COIN'
           AND NOT EXISTS (
               SELECT 1
                 FROM denomination_allowed da
                WHERE da.company_id = d.company_id
                  AND da.currency_id = d.currency_id
                  AND da.face_value = d.face_value
                  AND da.denomination_type = 'COIN'
                  AND da.is_active = true
           )
    $fmt$, set_clause, where_clause);

    GET DIAGNOSTICS affected = ROW_COUNT;
    RAISE NOTICE 'FK-080 V380: % tiltott COIN denomination sor inaktivalva (active=%, is_active=%)',
                 affected, has_active, has_isactive;
END $$;
