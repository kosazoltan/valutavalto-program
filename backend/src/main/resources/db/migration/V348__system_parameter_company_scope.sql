-- V348: TD7 SYSPARAM-NO-COMPANYID — opcionális company_id, NULL = globális default.
-- A tenant-izoláció eddig kulcs-névkonvención múlt; mostantól DB-oszlop hordozza.
-- Forrásból verifikált tény: a kulcs-egyediséget a V3_5/V74 az
-- uk_system_parameter_key UNIQUE INDEX-szel adta (nem tábla-constrainttel).

-- 1) Additív, nullable oszlop — meglévő sorok NULL = globális (viselkedés változatlan)
ALTER TABLE system_parameter ADD COLUMN IF NOT EXISTS company_id UUID;

-- 2) Régi 1-oszlopos kulcs-unique eltávolítása (kötelező: a globál+cég azonos kulcsú
--    sorok ütköznének vele). Verifikált név:
DROP INDEX IF EXISTS uk_system_parameter_key;

-- 2b) Defenzív, név-független sweep: ha egy környezeten (pl. Hibernate ddl-auto által
--     inicializált séma) más néven él csak-(parameter_key) unique constraint/index,
--     azt is eldobjuk. Parciális indexet (indpred IS NOT NULL) NEM bánt.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT con.conname
          FROM pg_constraint con
          JOIN pg_attribute att
            ON att.attrelid = con.conrelid AND att.attnum = con.conkey[1]
         WHERE con.conrelid = 'system_parameter'::regclass
           AND con.contype = 'u'
           AND array_length(con.conkey, 1) = 1
           AND att.attname = 'parameter_key'
    LOOP
        EXECUTE format('ALTER TABLE system_parameter DROP CONSTRAINT %I', r.conname);
    END LOOP;

    FOR r IN
        SELECT c.relname AS idxname
          FROM pg_index i
          JOIN pg_class c ON c.oid = i.indexrelid
         WHERE i.indrelid = 'system_parameter'::regclass
           AND i.indisunique
           AND i.indnkeyatts = 1
           AND i.indpred IS NULL
           AND pg_get_indexdef(i.indexrelid) LIKE '%(parameter_key)%'
           AND NOT EXISTS (SELECT 1 FROM pg_constraint pc WHERE pc.conindid = i.indexrelid)
    LOOP
        EXECUTE format('DROP INDEX %I', r.idxname);
    END LOOP;
END $$;

-- 3) Összetett egyediség KÉT parciális unique indexszel (V347 precedens: NULL != NULL
--    miatt sima UNIQUE nem véd a NULL-os oszlopon):
CREATE UNIQUE INDEX IF NOT EXISTS ux_sysparam_key_company
    ON system_parameter (parameter_key, company_id)
    WHERE company_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_sysparam_key_global
    ON system_parameter (parameter_key)
    WHERE company_id IS NULL;

-- 4) Assertion (V242 precedens): az új indexek léteznek, régi 1-oszlopos nem maradt
DO $$
DECLARE
    v_company_idx BOOLEAN;
    v_global_idx  BOOLEAN;
    v_old_unique  INTEGER;
BEGIN
    SELECT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'ux_sysparam_key_company')
      INTO v_company_idx;
    SELECT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'ux_sysparam_key_global')
      INTO v_global_idx;
    SELECT COUNT(*)
      INTO v_old_unique
      FROM pg_index i
      JOIN pg_class c ON c.oid = i.indexrelid
     WHERE i.indrelid = 'system_parameter'::regclass
       AND i.indisunique
       AND i.indnkeyatts = 1
       AND i.indpred IS NULL
       AND pg_get_indexdef(i.indexrelid) LIKE '%(parameter_key)%';

    IF NOT v_company_idx OR NOT v_global_idx THEN
        RAISE EXCEPTION 'V348: parciális unique indexek nem jöttek létre!';
    END IF;
    IF v_old_unique > 0 THEN
        RAISE EXCEPTION 'V348: régi 1-oszlopos parameter_key unique még él!';
    END IF;
END $$;

-- MEGJEGYZÉS jövőbeli seedeknek: az ON CONFLICT (parameter_key) többé nem illeszkedik
-- egyértelmű unique-ra; V348 után a globális seedek formája:
--   ON CONFLICT (parameter_key) WHERE company_id IS NULL DO NOTHING
-- Régi (már lefutott) migrációkat NEM írunk át.
