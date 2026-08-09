-- V377: FKH-031 — AT-000010 reteg-ellentmondas rendezese (B valtozat, adatkorrekcio)
--
-- ============================================================================
-- GYOKEROK
-- ============================================================================
-- A BR035 penztarbol 2026-07-31-en TENYLEGESEN elment 1000 USD a BR020 fele
-- (AT-000010), amit BR020 2026-08-05-en at is vett. A kuldo oldali tranzakcio
-- (AA035100003) viszont REVERSED statuszban all, mert a duplikacio-elharitaskor
-- app-szintu sztornot kapott — mikozben maga a Transfer bizonylat COMPLETED es
-- NEM visszavont.
--
-- A forgalmi lekerdezesek status = 'COMPLETED' + financial_effective = TRUE
-- szuresre epulnek (TransactionRepository, 36 JPQL query), ezert ez az 1000 USD
-- HIANYZIK a BR035 forgalmi kimutatasaibol — jelen migracio ezt teszi helyre.
--
-- ELO PROD ALLAPOT (VERIFIED, psql, 2026-08-07) — BR035 USD, count(*)=4, szures nelkul:
--
--   AA035100002  TRANSFER_OUT  COMPLETED  1000  (AT-000009)       07-31 12:21:43.37
--   AA035100003  TRANSFER_OUT  REVERSED   1000  (AT-000010)       07-31 12:21:43.78  <-- ellentmondas
--   AA035100004  REVERSAL      COMPLETED  1000  (AA035100003-ra)  07-31 12:25:01
--   AV035100005  TRANSFER_IN   COMPLETED  1000  (AT-000009-SZ)    08-02 18:50:52
--
--   transfer:
--     AT-000009  CANCELLED  is_cancelled=true   cancelled 08-02 18:50:52
--     AT-000010  COMPLETED  is_cancelled=false  received  08-05 17:15:49  <-- elo, atvett
--
--   BR020 USD: AV020100003 TRANSFER_IN COMPLETED 1000 (AT-000010), egyenleg 1000
--
-- ============================================================================
-- VALASZTOTT MEGOLDAS: B VALTOZAT (spec 6. szekcio javaslata, TBD-1 lezarva)
-- ============================================================================
--   1. AA035100003:  REVERSED  -> COMPLETED   (a kimeno mozgas valoban megtortent)
--   2. AA035100004:  COMPLETED -> CANCELLED   (a sztorno a valosagban nem valosult meg,
--                                              a bizonylatot atvettek)
--
-- Ezzel a transfer- es a tranzakcio-reteg konzisztens lesz (FR-3), es a forgalmi
-- lekerdezesek MODOSITASA NELKUL teljesul az FR-1: a COMPLETED+financial_effective
-- szuresbe pontosan egy 1000 USD kimeno mozgas kerul be, a REVERSAL sor pedig kiesik.
--
-- Miert NEM a C valtozat (uj magyarazo korrekcios sor): a ket regi sor tovabbra is
-- felrevezeto maradna, es a "financial_effective=false, de forgalomban latszo" sor a
-- jelenlegi 36 JPQL query egyikebe sem illeszkedik termeszetesen.
--
-- ALLAPOTGEP-MEGJEGYZES: a TransactionStatus futasidoi atmenet-terkepe (COMPLETED ->
-- REVERSED | ARCHIVED) szerint sem a REVERSED -> COMPLETED, sem a COMPLETED ->
-- CANCELLED lepes nem jarhato ut az alkalmazasbol. Ez SZANDEKOS: ez egy egyszeri,
-- adatbazis-szintu tortenelmi korrekcio a spec (FKH-031, 2026-08-07 megrendeloi dontes:
-- "igen latni kell!") alapjan, NEM uj uzleti atmenet. A TransactionStatus enum NEM valtozik.
--
-- ============================================================================
-- SCOPE / BIZTONSAG
-- ============================================================================
--   - NFR-1 (egyenleg-semlegesseg): a migracio a `cash_balance` tablat EGYALTALAN
--     NEM irja. A helyes USD-egyenleget a V375 (FKH-028/B) mar beallitotta 3797-re.
--   - NFR-2 (idempotencia): a mar rendezett allapot felismerese + RETURN.
--   - NFR-3 (fail-closed): kizarolag akkor ir, ha a kiindulo allapot PONTOSAN a
--     vizsgalatban rogzitett (AA035100003=REVERSED, AA035100004=COMPLETED, AT-000010
--     COMPLETED es nem visszavont). Barmely elteres eseten NEM NYUL HOZZA, csak
--     RAISE NOTICE (data-correction-migrations konvencio, V375/TBD-4 tanulsag).
--   - NFR-4 (hash-lanc vedelme): SZANDEKOSAN NINCS `audit_log` INSERT
--     (V234 hash-lanc, V368/V370/V375 precedens). Az auditalhatosagot az FR-4 szerint
--     a `notes` mezobe irt magyarazat biztositja.
--   - Fiok-feloldas kizarolag kodos lookuppal (BR035 + EBC + is_active) — hardkodolt
--     UUID nelkul, a V368/V370/V375 mintajara.
--   - Sorrendi fuggoseg: a V375 UTAN futhat csak (spec 7. szekcio) — a verziosorrend
--     ezt biztositja.
--
-- ELLENORZO SELECT (elotte/utana):
--   SELECT tr.receipt_number, tr.transaction_type, tr.status, tr.currency_amount,
--          tr.reference_number, tr.created_at, LEFT(tr.notes, 80) AS notes
--     FROM transaction tr
--     JOIN branch b   ON b.id = tr.branch_id
--     JOIN currency c ON c.id = tr.currency_id
--    WHERE b.code = 'BR035' AND c.code = 'USD'
--    ORDER BY tr.created_at;

DO $$
DECLARE
    v_marker      CONSTANT TEXT := '[FKH-031 V377]';
    v_company_id  UUID;
    v_branch_id   UUID;
    v_usd_id      BIGINT;
    v_out_id      BIGINT;
    v_out_status  TEXT;
    v_rev_id      BIGINT;
    v_rev_status  TEXT;
    v_tr_status   TEXT;
    v_tr_cancel   BOOLEAN;
    v_rows        INT;
BEGIN
    -- 1. Entitas-feloldas kodok alapjan (nem UUID-vel).
    SELECT b.id, b.company_id
      INTO v_branch_id, v_company_id
      FROM branch b
      JOIN company co ON co.id = b.company_id
     WHERE b.code = 'BR035'
       AND co.code = 'EBC'
       AND b.is_active = TRUE
     LIMIT 1;

    IF v_branch_id IS NULL THEN
        RAISE NOTICE 'V377: aktiv BR035 branch (EBC ceg) nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    SELECT id INTO v_usd_id FROM currency WHERE code = 'USD' LIMIT 1;
    IF v_usd_id IS NULL THEN
        RAISE NOTICE 'V377: USD currency torzsadat nem talalhato — nincs teendo.';
        RETURN;
    END IF;

    -- 2. A ket erintett bizonylatsor.
    SELECT id, status INTO v_out_id, v_out_status
      FROM transaction
     WHERE company_id = v_company_id
       AND branch_id = v_branch_id
       AND currency_id = v_usd_id
       AND receipt_number = 'AA035100003'
       AND transaction_type = 'TRANSFER_OUT'
     LIMIT 1;

    SELECT id, status INTO v_rev_id, v_rev_status
      FROM transaction
     WHERE company_id = v_company_id
       AND branch_id = v_branch_id
       AND currency_id = v_usd_id
       AND receipt_number = 'AA035100004'
       AND transaction_type = 'REVERSAL'
     LIMIT 1;

    IF v_out_id IS NULL OR v_rev_id IS NULL THEN
        RAISE NOTICE 'V377: az AA035100003 / AA035100004 bizonylatpar nem talalhato a BR035 USD '
                     'forgalomban — a korrekcio NEM fut le (nincs mit rendezni).';
        RETURN;
    END IF;

    -- 3. IDEMPOTENCIA: a mar rendezett allapot felismerese.
    IF v_out_status = 'COMPLETED' AND v_rev_status = 'CANCELLED' THEN
        RAISE NOTICE 'V377: a korrekcio MAR alkalmazva (AA035100003=COMPLETED, '
                     'AA035100004=CANCELLED) — nincs teendo (idempotens).';
        RETURN;
    END IF;

    -- 4. FAIL-CLOSED ALLAPOT-ELLENORZES (NFR-3). A marker/idempotencia csak az ISMETELT
    --    futas ellen ved; a HIBAS KIINDULO ALLAPOT ellen ez a blokk. Ha az adat idokozben
    --    barhogy megvaltozott (pl. kezi rendezes, ujabb sztorno), NEM irunk.
    IF v_out_status <> 'REVERSED' OR v_rev_status <> 'COMPLETED' THEN
        RAISE NOTICE 'V377: a kiindulo allapot NEM a vizsgalatban rogzitett '
                     '(AA035100003=% [vart: REVERSED], AA035100004=% [vart: COMPLETED]) — '
                     'a korrekcio NEM fut le. Idokozben valtozott az adat; kezi vizsgalat szukseges.',
                     v_out_status, v_rev_status;
        RETURN;
    END IF;

    -- A transfer-reteg is igazolja, hogy az atadas VALOBAN megtortent (ez az egesz
    -- korrekcio uzleti alapja). Ha az AT-000010 megsem elo/atvett, NEM irunk.
    SELECT status, is_cancelled INTO v_tr_status, v_tr_cancel
      FROM transfer
     WHERE company_id = v_company_id
       AND transfer_number = 'AT-000010'
     LIMIT 1;

    IF v_tr_status IS NULL THEN
        RAISE NOTICE 'V377: az AT-000010 transfer bizonylat nem talalhato — a korrekcio NEM fut le.';
        RETURN;
    END IF;

    IF v_tr_cancel IS DISTINCT FROM FALSE OR v_tr_status = 'CANCELLED' THEN
        RAISE NOTICE 'V377: az AT-000010 transfer NEM elo (status=%, is_cancelled=%) — '
                     'a tranzakcio-reteg REVERSED allapota ilyenkor HELYES, a korrekcio NEM fut le.',
                     v_tr_status, v_tr_cancel;
        RETURN;
    END IF;

    -- 5. B valtozat, 1. lepes: a kimeno tranzakcio visszaallitasa COMPLETED-re, hogy a
    --    forgalmi lekerdezesekben (status='COMPLETED') megjelenjen az elment 1000 USD.
    UPDATE transaction
       SET status = 'COMPLETED',
           notes = COALESCE(notes || ' ', '') || v_marker ||
                   ' FKH-031: a bizonylat (AT-000010) COMPLETED es atvett (BR020, 2026-08-05),' ||
                   ' a kimeno 1000 USD tenylegesen elment, ezert a 2026-07-31-i app-szintu' ||
                   ' sztorno miatti REVERSED statusz COMPLETED-re allitva. cash_balance NEM' ||
                   ' erintett (a helyes egyenleget a V375 allitotta be).'
     WHERE id = v_out_id
       AND status = 'REVERSED';   -- optimista guard: parhuzamos iras ellen
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 1 THEN
        RAISE NOTICE 'V377: az AA035100003 UPDATE % sort erintett (parhuzamos valtozas?) — '
                     'kezi vizsgalat szukseges.', v_rows;
        RETURN;
    END IF;

    -- 6. B valtozat, 2. lepes: a valosagban meg nem tortent sztorno-sor ervenytelenitese.
    --    A CANCELLED statusz kiveszi a forgalmi (COMPLETED-szures) lekerdezesekbol, igy az
    --    1000 USD PONTOSAN EGYSZER szerepel a BR035 forgalmaban.
    UPDATE transaction
       SET status = 'CANCELLED',
           notes = COALESCE(notes || ' ', '') || v_marker ||
                   ' FKH-031: ez a sztorno-sor a valosagban NEM valosult meg — az AT-000010' ||
                   ' atadolapot BR020 2026-08-05-en atvette. A sor ervenytelenitve (CANCELLED),' ||
                   ' hogy a tranzakcio-reteg ne mondjon ellent a transfer-retegnek.' ||
                   ' cash_balance NEM erintett.'
     WHERE id = v_rev_id
       AND status = 'COMPLETED';   -- optimista guard
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows = 1 THEN
        RAISE NOTICE 'V377: AT-000010 reteg-ellentmondas rendezve — AA035100003 REVERSED->COMPLETED, '
                     'AA035100004 COMPLETED->CANCELLED (1000 USD megjelenik a BR035 forgalmaban).';
    ELSE
        -- FAIL-CLOSED (FKH-031/A NFR-3 kiterjesztese): ide csak ugy juthatunk, hogy az elso
        -- UPDATE MAR lefutott (AA035100003 COMPLETED), a masodik viszont nem talalt sort.
        -- RAISE NOTICE eseten ez a FEL-ALLAPOT COMMITALODNA, es a 1000 USD DUPLAN latszana
        -- a BR035 forgalmaban — pontosan az a penzugyi hiba, amit ez a migracio rendezni hivatott.
        -- EXCEPTION-nel a Flyway a TELJES migraciot visszagorgeti: inkabb ne fusson le, mint
        -- hogy felig fusson le.
        RAISE EXCEPTION 'V377: az AA035100004 ervenytelenitese % sort erintett (parhuzamos valtozas?) — '
                        'a migracio VISSZAGORGETVE, hogy az AA035100003 mar elvegzett '
                        'REVERSED->COMPLETED valtasa ne maradjon fel-allapotban (kulonben a '
                        'forgalom DUPLAN latszana). Kezi vizsgalat szukseges.', v_rows;
    END IF;
END $$;
