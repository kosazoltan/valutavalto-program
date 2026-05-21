-- V251: Séma-drift rendezése — employee.active -> employee.is_active.
--
-- DIAGNÓZIS (2026-05-21): a V53 migráció `active BOOLEAN NOT NULL DEFAULT TRUE` oszlopot
-- definiál, a live production-séma viszont `is_active`-ot használ (a JPA Employee entity
-- `@Column(name = "is_active") private Boolean active` mapping miatt — Hibernate/ddl-auto
-- történeti hatás). Egy friss, csak-migrációkból épített DB `active`-ot kapna, a prod
-- `is_active`-ot → drift. Ez okozta a 2026-05-21-i employee-import első hibáját
-- ("column active does not exist").
--
-- FIX: idempotens, guarded RENAME. Csak akkor nevez át, ha `active` létezik ÉS `is_active`
-- még nem. A RENAME COLUMN a függő indexet (idx_employee_active) automatikusan átvezeti.
--   - Friss DB (V53 lefutott): active létezik, is_active nem → átnevezés → egyezik a prod-dal.
--   - Production: is_active már létezik, active nincs → no-op.
-- A V53-at NEM módosítjuk (Flyway checksum / F15 lint tiltja a mergelt migráció-változtatást).

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_name = 'employee' AND column_name = 'active')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_name = 'employee' AND column_name = 'is_active') THEN
        ALTER TABLE employee RENAME COLUMN active TO is_active;
        RAISE NOTICE 'V251: employee.active -> is_active átnevezve (drift rendezve).';
    ELSE
        RAISE NOTICE 'V251: employee.is_active már a kanonikus oszlop (vagy nincs active) — no-op (idempotens).';
    END IF;
END $$;
