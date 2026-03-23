-- V109: Compatibilitas javitas active <-> is_active oszlopok kozott
-- Cél: ahol csak 'active' létezik, de JPA 'is_active'-ot vár, ott biztosítsuk mindkettőt
-- és tartsuk szinkronban INSERT/UPDATE során.

CREATE OR REPLACE FUNCTION sync_active_columns()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.active := COALESCE(NEW.active, NEW.is_active, TRUE);
    NEW.is_active := COALESCE(NEW.is_active, NEW.active, TRUE);
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    t RECORD;
BEGIN
    -- 1) Ahol van boolean 'active', de nincs 'is_active', ott hozzuk letre
    FOR t IN
        SELECT c.table_schema, c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.column_name = 'active'
          AND c.data_type = 'boolean'
          AND NOT EXISTS (
              SELECT 1
              FROM information_schema.columns c2
              WHERE c2.table_schema = c.table_schema
                AND c2.table_name = c.table_name
                AND c2.column_name = 'is_active'
          )
    LOOP
        EXECUTE format('ALTER TABLE %I.%I ADD COLUMN is_active BOOLEAN', t.table_schema, t.table_name);
    END LOOP;

    -- 2) Ahol mindkettő létezik, ott backfill + trigger szinkron
    FOR t IN
        SELECT c.table_schema, c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.column_name = 'active'
          AND c.data_type = 'boolean'
          AND EXISTS (
              SELECT 1
              FROM information_schema.columns c2
              WHERE c2.table_schema = c.table_schema
                AND c2.table_name = c.table_name
                AND c2.column_name = 'is_active'
                AND c2.data_type = 'boolean'
          )
    LOOP
        EXECUTE format(
            'UPDATE %I.%I
             SET active = COALESCE(active, is_active, TRUE),
                 is_active = COALESCE(is_active, active, TRUE)
             WHERE active IS NULL OR is_active IS NULL',
            t.table_schema, t.table_name
        );

        EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN is_active SET DEFAULT TRUE', t.table_schema, t.table_name);

        EXECUTE format('DROP TRIGGER IF EXISTS trg_sync_active_columns ON %I.%I', t.table_schema, t.table_name);
        EXECUTE format(
            'CREATE TRIGGER trg_sync_active_columns
             BEFORE INSERT OR UPDATE ON %I.%I
             FOR EACH ROW
             EXECUTE FUNCTION sync_active_columns()',
            t.table_schema, t.table_name
        );
    END LOOP;
END;
$$;
