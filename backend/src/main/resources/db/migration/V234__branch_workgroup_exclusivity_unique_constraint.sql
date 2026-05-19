-- V234: Branch ↔ Workgroup exclusivitás enforce - Anti legacy parity
--
-- Audit forrás: arfolyamkeszito-anti-legacy-parity-audit-2026-05-18.md
-- (P1 #1 GAP)
--
-- Legacy Arfolyam.exe szigorúan kényszerítette hogy egy iroda CSAK 1
-- munkacsoportban lehet (`AZ IRODA MAR BENN VAN EGY MUNKACSOPORTBAN!`
-- hibaüzenet a string-extraction-ban).
--
-- A rate_workgroup_branch tábla PRIMARY KEY (workgroup_id, branch_id) - de
-- ez NEM tiltja meg hogy egy branch_id MÁS workgroup_id-val több sorban
-- szerepeljen. A modern updateWorkgroupBranches service-szintű
-- ellenőrzés nélkül engedi ugyanazt a branch-et több workgroupba.
--
-- Ez a migration:
--   1. Detektálja a meglévő duplikációkat (RAISE NOTICE - audit célra)
--   2. Tisztítja a duplikációkat: az ELSŐ workgroup-asszociációt tartja
--      meg (created_at szerint, vagy ha hiányzik az oszlop akkor a
--      legalacsonyabb workgroup_id), a többit törli
--   3. UNIQUE constraint hozzáadása a branch_id-re a tábla szintjén,
--      így DB-szinten biztosítva hogy soha többé ne fordulhasson elő

DO $$
DECLARE
    v_duplicate_count INT;
    v_duplicate_record RECORD;
    v_cleaned_count INT := 0;
BEGIN
    -- 1. DETEKCIÓ: hány duplikáció van?
    SELECT COUNT(*) INTO v_duplicate_count
    FROM (
        SELECT branch_id
          FROM rate_workgroup_branch
         GROUP BY branch_id
        HAVING COUNT(*) > 1
    ) AS dups;

    IF v_duplicate_count = 0 THEN
        RAISE NOTICE 'V234: Nincs duplikacio - a rate_workgroup_branch tabla mar tiszta.';
    ELSE
        RAISE NOTICE 'V234: Talalt % branch_id ami tobb workgroupban van. Cleanup folyamatban.', v_duplicate_count;

        -- 2. CLEANUP: minden duplikalt branch_id-re tartsa meg az ELSŐ workgroup-
        --    asszociaciot (workgroup_id lexikografikus rendezesre alapozva,
        --    determinisztikus), a tobbit DELETE
        --
        --    PostgreSQL: ctid alapján deduplikalva, vagy ROW_NUMBER + DELETE
        FOR v_duplicate_record IN
            SELECT branch_id
              FROM rate_workgroup_branch
             GROUP BY branch_id
            HAVING COUNT(*) > 1
        LOOP
            -- Lokic: a min(workgroup_id)-t tartjuk meg, a tobbit toroljuk
            DELETE FROM rate_workgroup_branch
             WHERE branch_id = v_duplicate_record.branch_id
               AND workgroup_id <> (
                   SELECT MIN(workgroup_id)
                     FROM rate_workgroup_branch
                    WHERE branch_id = v_duplicate_record.branch_id
               );
            v_cleaned_count := v_cleaned_count + 1;
            RAISE NOTICE 'V234: Cleanup - branch_id=% duplikacio megszuntetve (csak a min(workgroup_id) maradt).', v_duplicate_record.branch_id;
        END LOOP;

        RAISE NOTICE 'V234: Cleanup kesz - % duplikacio megszuntetve.', v_cleaned_count;
    END IF;
END
$$;

-- 3. UNIQUE constraint: DB-szintu garancia hogy egy branch_id CSAK
--    1 workgroup_id-val tarsithato.
--
-- Megjegyzes: a PRIMARY KEY (workgroup_id, branch_id) marad - mert
-- ket sor azonos (workgroup_id, branch_id)-vel sem szabad. A UNIQUE
-- (branch_id) onmagaban hozzaadva enforce-olja a 1:N kapcsolatot
-- (workgroup:branches) ahelyett a M:N-t.
ALTER TABLE rate_workgroup_branch
  ADD CONSTRAINT uk_branch_workgroup_exclusive
  UNIQUE (branch_id);

-- Assertion: a constraint mukodik
DO $$
DECLARE
    v_constraint_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conname = 'uk_branch_workgroup_exclusive'
           AND conrelid = 'rate_workgroup_branch'::regclass
    ) INTO v_constraint_exists;

    IF NOT v_constraint_exists THEN
        RAISE EXCEPTION 'V234: uk_branch_workgroup_exclusive constraint NEM letrejott!';
    END IF;

    RAISE NOTICE 'V234: Verifikalva - uk_branch_workgroup_exclusive constraint aktiv. Branch-Workgroup 1:N exclusivity DB-szinten enforce-olva.';
END
$$;
