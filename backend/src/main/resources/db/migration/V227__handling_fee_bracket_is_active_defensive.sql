-- V227: Defensive ensure-is-active a handling_fee_bracket táblán
--
-- ELŐZMÉNY: A V75 hozta létre a táblát 'active BOOLEAN' oszloppal. A V109 dinamikus
-- alias-trigger script elvileg minden 'active' boolean oszlopú tábláról hozzáad
-- egy is_active oszlopot és trigger-szinkronizálást. Production-on azonban a
-- handling_fee_bracket táblán a kollégák a Save gomb után PSQLException-szerű
-- hibát tapasztaltak ("Kezelési költség mértéke nem rögzíthető"), ami arra utal,
-- hogy a JPA `@Column(name = "is_active")` várakozással ellentétben az is_active
-- oszlop hiányzott vagy nem volt szinkronban.
--
-- EZ a migráció IDEMPOTENS és VÉDEKEZŐ: ha az is_active oszlop és a trigger már
-- létezik, no-op. Ha hiányzik, létrehozza + szinkronizálja.
--
-- HATÁS:
--   - admin UI "Kezelési költség beállítás" Save gombja működik
--   - HandlingFeeService.calculateBracket() vissza tudja olvasni az aktív sávokat
--
-- TESZT: BackendIntegrationTest HandlingFeeConfigControllerIT a V227-tel együtt
--   próbálja a save + get cikust végrehajtani.

DO $$
BEGIN
    -- 1. Ha az is_active oszlop hiányzik, hozzá adjuk + backfilljük
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'handling_fee_bracket'
          AND column_name = 'is_active'
    ) THEN
        EXECUTE 'ALTER TABLE handling_fee_bracket ADD COLUMN is_active BOOLEAN';
        EXECUTE 'UPDATE handling_fee_bracket SET is_active = COALESCE(active, TRUE) WHERE is_active IS NULL';
        EXECUTE 'ALTER TABLE handling_fee_bracket ALTER COLUMN is_active SET NOT NULL';
        EXECUTE 'ALTER TABLE handling_fee_bracket ALTER COLUMN is_active SET DEFAULT TRUE';
    END IF;

    -- 2. Ha az active oszlop hiányzik (régi V75 előtti env), hozzáadjuk (defenzív)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'handling_fee_bracket'
          AND column_name = 'active'
    ) THEN
        EXECUTE 'ALTER TABLE handling_fee_bracket ADD COLUMN active BOOLEAN DEFAULT TRUE';
        EXECUTE 'UPDATE handling_fee_bracket SET active = COALESCE(is_active, TRUE) WHERE active IS NULL';
        EXECUTE 'ALTER TABLE handling_fee_bracket ALTER COLUMN active SET NOT NULL';
    END IF;

    -- 3. Backfill: bármelyik NULL érték esetén a másikból töltjük, fallback TRUE
    EXECUTE 'UPDATE handling_fee_bracket
             SET active = COALESCE(active, is_active, TRUE),
                 is_active = COALESCE(is_active, active, TRUE)
             WHERE active IS NULL OR is_active IS NULL';

    -- 4. Trigger biztosítása: minden INSERT/UPDATE-nél szinkronizáljon
    EXECUTE 'DROP TRIGGER IF EXISTS trg_sync_active_columns ON handling_fee_bracket';
    EXECUTE 'CREATE TRIGGER trg_sync_active_columns
             BEFORE INSERT OR UPDATE ON handling_fee_bracket
             FOR EACH ROW
             EXECUTE FUNCTION sync_active_columns()';
END$$;

-- Sanity log a flyway_schema_history-be
COMMENT ON COLUMN handling_fee_bracket.is_active IS
    'Active flag (JPA @Column alias). V227 ensures column + sync trigger exist.';
