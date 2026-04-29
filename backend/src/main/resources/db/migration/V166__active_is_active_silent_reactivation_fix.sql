-- V166: V3_7 silent reactivation fix (Codex P1 #252)
--
-- Problema: A V3_7__active_is_active_column_guard.sql migration
--   ALTER TABLE ... ADD COLUMN is_active BOOLEAN DEFAULT TRUE
--   utan UPDATE ... WHERE is_active IS NULL pattern-t hasznalt.
--
-- PostgreSQL 11+ "fast default" optimalizacio (vagy regebbi verzioban
-- physical re-write) miatt a `DEFAULT TRUE` AZONNAL ervenyes minden
-- meglevo sorra. Igy mire az UPDATE ... WHERE is_active IS NULL lefut,
-- mar nincsenek NULL-os sorok, es az `active=false` rekordok (workers,
-- currencies, dictionary, company, branch) silently TRUE-ra kerulnek
-- az `is_active` oszlopban.
--
-- Migracio celja: helyrehozni a `active=false` rekordokat ahol az
-- `is_active=true` (V3_7 silent-reactivation kovetkezmenye).
--
-- Hatas:
--   - Csak akkor frissit, ha active=false ES is_active=true (kovetkezetlenseg).
--   - Az active es is_active mar V109-ben szinkronban tartott trigger-rel,
--     uj rekordoknal nincs problema. Ez a migracio csak a tortenelmi
--     V3_7-induced inkonzisztenciat javitja.
--
-- Kockazat: minimum (defensive UPDATE, csak inkonzisztens sorokat erint).
--
-- Forras: Codex review PR #252 (commit 59c2d6959f), 2026-04-28.

DO $$
DECLARE
    t RECORD;
    rows_updated INTEGER := 0;
    total_updated INTEGER := 0;
BEGIN
    FOR t IN
        SELECT c.table_schema, c.table_name
        FROM information_schema.columns c
        WHERE c.table_schema = 'public'
          AND c.column_name   = 'active'
          AND c.data_type     = 'boolean'
          AND EXISTS (
              SELECT 1
              FROM information_schema.columns c2
              WHERE c2.table_schema = c.table_schema
                AND c2.table_name  = c.table_name
                AND c2.column_name = 'is_active'
          )
    LOOP
        EXECUTE format(
            'UPDATE %I.%I SET is_active = active
             WHERE active IS NOT NULL
               AND active = false
               AND is_active = true',
            t.table_schema, t.table_name
        );
        GET DIAGNOSTICS rows_updated = ROW_COUNT;
        IF rows_updated > 0 THEN
            RAISE NOTICE 'V166: Helyrehozva %.%: % silent-reactivated row',
                t.table_schema, t.table_name, rows_updated;
            total_updated := total_updated + rows_updated;
        END IF;
    END LOOP;

    RAISE NOTICE 'V166: Osszesen % sor javitva (active=false -> is_active=false szinkron).', total_updated;
END;
$$;
