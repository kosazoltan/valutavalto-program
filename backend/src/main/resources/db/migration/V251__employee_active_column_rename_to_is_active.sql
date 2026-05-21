-- V251: Séma-drift rendezése — employee.active -> employee.is_active.
--
-- DIAGNÓZIS (2026-05-21): a V53 migráció `active BOOLEAN NOT NULL DEFAULT TRUE` oszlopot
-- definiál, a live production-séma viszont `is_active`-ot használ (a JPA Employee entity
-- `@Column(name = "is_active") private Boolean active` mapping miatt — Hibernate/ddl-auto
-- történeti hatás). Egy friss, csak-migrációkból épített DB `active`-ot kapna, a prod
-- `is_active`-ot → drift. Ez okozta a 2026-05-21-i employee-import első hibáját
-- ("column active does not exist").
--
-- FIX: idempotens, teljesen konvergáló, public-sémára szűkített (Sourcery/Codex #760):
--   1. Csak `active` van  (tiszta Flyway, ddl-auto off)        -> RENAME active -> is_active.
--   2. MINDKETTŐ létezik  (ddl-auto a `active` mellé is_active-ot is csinált — Codex P2)
--                                                              -> a redundáns `active` DROP
--                                                                 (a kanonikus az is_active).
--   3. Csak `is_active`   (production jelenleg)                -> no-op.
-- A RENAME COLUMN a függő indexet (idx_employee_active) automatikusan átvezeti.
-- A V53-at NEM módosítjuk (Flyway checksum / F15 lint tiltja a mergelt migráció-változtatást).

DO $$
DECLARE
    v_has_active    BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns
                                        WHERE table_schema = 'public'
                                          AND table_name = 'employee' AND column_name = 'active');
    v_has_is_active BOOLEAN := EXISTS (SELECT 1 FROM information_schema.columns
                                        WHERE table_schema = 'public'
                                          AND table_name = 'employee' AND column_name = 'is_active');
BEGIN
    IF v_has_active AND NOT v_has_is_active THEN
        ALTER TABLE employee RENAME COLUMN active TO is_active;
        RAISE NOTICE 'V251: employee.active -> is_active átnevezve (drift rendezve).';
    ELSIF v_has_active AND v_has_is_active THEN
        ALTER TABLE employee DROP COLUMN active;
        RAISE NOTICE 'V251: redundáns employee.active oszlop eldobva (is_active a kanonikus).';
    ELSE
        RAISE NOTICE 'V251: employee.is_active már a kanonikus oszlop — no-op (idempotens).';
    END IF;
END $$;
