-- V246: FK-003 4. pont — Zárás beérkezés felügyelet adatkorrekciók (Kasza Helga, Főértéktár).
--
-- KÉRT VÁLTOZTATÁSOK (FK-003):
--   + Hozzáadandó: BR105 – Békéscsaba Belváros (jelenleg hiányzik az aktív listából)
--   - Törlendő:   KORUT – Korut, Szeged
--   - Törlendő:   TISZA – Tisza Sarok, Szeged
--
-- BIZTONSÁGI ELVEK (Kósa Zoltán):
--   1. NEM hard DELETE — SOFT-DELETE (is_active = false): a tranzakció-/audit-történet
--      megőrzendő, a fiók csak eltűnik az aktív Országos-készlet / Zárás-beérkezés nézetből.
--      Ez CSAK az is_active flaget változtatja → a "készlet = SUM(tranzakciók)" invariánst
--      NEM sérti (cash_balance és transaction táblákat NEM érinti).
--   2. Az egyenleg tényleges KONSZOLIDÁLÁSA (KORUT/TISZA → cél-pénztár) KÖNYVELÉSI művelet
--      (átadás-átvétel a programban) — NEM nyers SQL-merge, mert az tranzakció-rekord nélkül
--      megsértené az invariánst. Ha a deaktivált fiókon marad nem-nulla egyenleg, NOTICE jelzi.
--   3. Idempotens: ismételt futáskor nincs változás (a count/NOTICE jelzi a tényt).

DO $$
DECLARE
    v_count   INT;
    v_nonzero INT;
BEGIN
    -- ============ BR105 – Békéscsaba Belváros: AKTIVÁLÁS ============
    UPDATE branch SET is_active = true
     WHERE code = 'BR105' AND (is_active = false OR is_active IS NULL);
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count > 0 THEN
        RAISE NOTICE 'FK-003: BR105 (Békéscsaba Belváros) AKTIVÁLVA (% sor) — megjelenik a záráslistában.', v_count;
    ELSE
        SELECT COUNT(*) INTO v_count FROM branch WHERE code = 'BR105';
        IF v_count = 0 THEN
            RAISE NOTICE 'FK-003: BR105 kódú fiók NEM létezik — kézi ellenőrzés szükséges (lehet, más a kód).';
        ELSE
            RAISE NOTICE 'FK-003: BR105 már aktív — nincs teendő (idempotens).';
        END IF;
    END IF;

    -- ============ KORUT – Korut, Szeged: DEAKTIVÁLÁS ============
    SELECT COUNT(*) INTO v_nonzero
      FROM cash_balance cb
      JOIN branch b ON b.id = cb.branch_id
     WHERE b.code = 'KORUT' AND b.is_active = true AND cb.current_balance <> 0;
    UPDATE branch SET is_active = false WHERE code = 'KORUT' AND is_active = true;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count > 0 THEN
        RAISE NOTICE 'FK-003: KORUT (Korut, Szeged) DEAKTIVÁLVA (% sor).', v_count;
        IF v_nonzero > 0 THEN
            RAISE NOTICE 'FK-003 FIGYELEM: a KORUT még % nem-nulla valuta-egyenleget tartott a deaktiváláskor — '
                         'a tényleges KONSZOLIDÁLÁST átadás-átvétellel kell könyvelni (nem SQL).', v_nonzero;
        END IF;
    ELSE
        RAISE NOTICE 'FK-003: nincs aktív KORUT fiók — nincs teendő (idempotens).';
    END IF;

    -- ============ TISZA – Tisza Sarok, Szeged: DEAKTIVÁLÁS ============
    SELECT COUNT(*) INTO v_nonzero
      FROM cash_balance cb
      JOIN branch b ON b.id = cb.branch_id
     WHERE b.code = 'TISZA' AND b.is_active = true AND cb.current_balance <> 0;
    UPDATE branch SET is_active = false WHERE code = 'TISZA' AND is_active = true;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count > 0 THEN
        RAISE NOTICE 'FK-003: TISZA (Tisza Sarok, Szeged) DEAKTIVÁLVA (% sor).', v_count;
        IF v_nonzero > 0 THEN
            RAISE NOTICE 'FK-003 FIGYELEM: a TISZA még % nem-nulla valuta-egyenleget tartott a deaktiváláskor — '
                         'a tényleges KONSZOLIDÁLÁST a "Szeged Tisza Sarok"-ra átadás-átvétellel kell könyvelni (nem SQL).', v_nonzero;
        END IF;
    ELSE
        RAISE NOTICE 'FK-003: nincs aktív TISZA fiók — nincs teendő (idempotens).';
    END IF;
END $$;
