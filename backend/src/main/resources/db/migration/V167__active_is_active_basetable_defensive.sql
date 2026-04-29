-- V167: V166 defensive hardening — base-table filter + simplified predicate.
--
-- Sourcery PR #255 review feedback (2026-04-29):
-- 1) BASE TABLE filter: a V166 dynamic UPDATE az information_schema.columns-ból
--    keresett tablakat, beleértve a view-ket is (ha hipotetikusan letezne egy
--    public view active+is_active oszlopokkal). Az UPDATE view-n undefined
--    behavior — defensive: information_schema.tables WHERE table_type='BASE TABLE'.
-- 2) Egyszerusiteni a WHERE predicate-et: `active=false` mar implyiti hogy
--    `active IS NOT NULL`, igy a kulon NULL-check redundans.
-- 3) is_active is legyen boolean — a V166-ban csak az `active` boolean check-et
--    csinaltuk, az `is_active` data_type-jat nem ellenoriztuk.
--
-- Eredmeny: ugyanaz a UPDATE-ek a public.* base-tablakra, csak szigorubb scope.
-- A V166 mar lefutott a productionon (Hetzner deploy SUCCESS), ez egy idempotens
-- defensive re-apply, ami biztositja a base-table-only scope-ot.
--
-- Forras: Sourcery PR #255 inline-feedback (Reviewer's Guide), 2026-04-29.

DO $$
DECLARE
    t RECORD;
    rows_updated INTEGER := 0;
    total_updated INTEGER := 0;
BEGIN
    FOR t IN
        SELECT c.table_schema, c.table_name
        FROM information_schema.columns c
        INNER JOIN information_schema.tables tab
            ON tab.table_schema = c.table_schema
           AND tab.table_name   = c.table_name
        WHERE c.table_schema = 'public'
          AND c.column_name   = 'active'
          AND c.data_type     = 'boolean'
          AND tab.table_type  = 'BASE TABLE'                 -- Sourcery: csak base-table
          AND EXISTS (
              SELECT 1
              FROM information_schema.columns c2
              WHERE c2.table_schema = c.table_schema
                AND c2.table_name  = c.table_name
                AND c2.column_name = 'is_active'
                AND c2.data_type   = 'boolean'              -- Sourcery: is_active is boolean
          )
    LOOP
        EXECUTE format(
            'UPDATE %I.%I SET is_active = active
             WHERE active = false                           -- Sourcery: active=false implyiti NOT NULL-t
               AND is_active = true',
            t.table_schema, t.table_name
        );
        GET DIAGNOSTICS rows_updated = ROW_COUNT;
        IF rows_updated > 0 THEN
            RAISE NOTICE 'V167: Helyrehozva %.%: % silent-reactivated row (defensive re-apply)',
                t.table_schema, t.table_name, rows_updated;
            total_updated := total_updated + rows_updated;
        END IF;
    END LOOP;

    IF total_updated = 0 THEN
        RAISE NOTICE 'V167: Defensive re-apply lefutott - 0 inkonzisztens sor (V166 mar helyrehozta).';
    ELSE
        RAISE NOTICE 'V167: Osszesen % sor javitva (defensive re-apply utan).', total_updated;
    END IF;
END;
$$;
