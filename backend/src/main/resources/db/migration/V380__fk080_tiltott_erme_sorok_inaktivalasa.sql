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
-- MINDKET AKTIV-OSZLOP (ticket C3): a `denomination` tablan a V3 DDL `active`, a V3_7/V109
-- pedig `is_active` oszlopot hozott letre, es egy `trg_sync_active_columns` trigger tartja
-- oket szinkronban. Az UPDATE MINDKETTOT explicit false-ra allitja, igy az eredmeny nem
-- fugg a trigger tuzelesetol.
--
-- NFR-1 (idempotencia): a masodik futas 0 sort erint, mert a mar inaktivalt sorokra az
-- `active = true` feltetel nem all fenn.
-- NFR-3 (nincs allasido): egyetlen, indexelt UPDATE egyetlen tranzakcioban; a varhato
-- eles hatokor ~90 fiok x nehany tucat sor — futasideje jol egy masodperc alatt,
-- karbantartasi ablak nem szukseges.

DO $$
DECLARE affected integer;
BEGIN
    UPDATE denomination d
       SET active = false,
           is_active = false,
           updated_at = NOW()
     WHERE d.active = true
       AND d.denomination_type = 'COIN'
       AND NOT EXISTS (
           SELECT 1
             FROM denomination_allowed da
            WHERE da.company_id = d.company_id
              AND da.currency_id = d.currency_id
              AND da.face_value = d.face_value
              AND da.denomination_type = 'COIN'
              AND da.is_active = true
       );
    GET DIAGNOSTICS affected = ROW_COUNT;
    RAISE NOTICE 'FK-080 V380: % tiltott COIN denomination sor inaktivalva', affected;
END $$;
