-- V3_7: Schema guard — active/is_active oszlop szinkronizálás (fresh install fix)
-- Probléma: V69, V70, V79 stb. seed migration-ök az `is_active` oszlopot használják
--           olyan táblákban (worker, currency, dictionary, company, branch), ahol
--           csak `active` oszlop létezik. V109 adja hozzá a valódi szinkronizálást.
-- Megoldás: V109 logikájának korai guard változata — CSAK oszlop hozzáadás + backfill.
--           Trigger wiring NEM itt van — azt V109 végzi el teljes körűen.
--           V109 biztonságosan újrafuthat (CREATE OR REPLACE + IF NOT EXISTS).

-- Funkcio: is_active szinkron trigger (V109-tel megegyező, OR REPLACE)
CREATE OR REPLACE FUNCTION sync_active_columns()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.active    := COALESCE(NEW.active,    NEW.is_active, TRUE);
    NEW.is_active := COALESCE(NEW.is_active, NEW.active,    TRUE);
    RETURN NEW;
END;
$$;

-- Dinamikus: minden public tábla ahol 'active' van de 'is_active' nincs → hozzáadjuk
DO $$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT c.table_schema, c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.column_name   = 'active'
          AND c.data_type     = 'boolean'
          AND NOT EXISTS (
              SELECT 1
              FROM information_schema.columns c2
              WHERE c2.table_schema = c.table_schema
                AND c2.table_name  = c.table_name
                AND c2.column_name = 'is_active'
          )
    LOOP
        EXECUTE format(
            'ALTER TABLE %I.%I ADD COLUMN is_active BOOLEAN DEFAULT TRUE',
            t.table_schema, t.table_name
        );
        -- Backfill: active → is_active
        EXECUTE format(
            'UPDATE %I.%I SET is_active = COALESCE(active, TRUE) WHERE is_active IS NULL',
            t.table_schema, t.table_name
        );
    END LOOP;
END;
$$;
