-- =====================================================================
-- FKH-050 / V387 — denomination_balance: datumnapi egyedi kulcs (D5)
-- =====================================================================
-- ELOZMENY: a V378 a denomination_balance egyedi kulcsat a
-- (cash_desk_id, denomination_id, denomination_category) harom oszlopra
-- feszitette. Ez a kulcs DATUM-VAK: egy utolagos (retroaktiv) napzaras
-- FKH-050 folyaman egy MULT-BELI estekre bevitt cimletezesi sor ugyanazt
-- a (penztar, cimlet, kategoria) kulcsot hasznalna, mint a MAI folyamatban
-- levo sor — a masodik mentes UPDATE-kent a MAI sort irna felul.
-- Penzugyi adatvesztes.
--
-- MEGOLDAS: a kulcs kiterjesztese a submission_date oszlopra:
--   (cash_desk_id, denomination_id, denomination_category, submission_date)
-- Az uj kulcs SZIGORUBB-helyu: a regi 3-oszlopu kulcs garantalja, hogy a
-- backfill/exisztalo adatok nem serulnek — minden letezo sor egyedi marad
-- az uj kulcson is (egy kulcson max 1 sor van ma). Nincs backfill,
-- nincs torles.
--
-- A regi 3-oszlopu kulcs eltavolitasa SZUKSEGES: ha megmaradna, az uj
-- datumnapi sorok beszurasa a regi kulcsba utkozne (same desk+denom+
-- category, mas datum).
--
-- IDEMPOTENS: nevre es szerkezetre egyarant vedett DROP + letezes-
-- ellenorzott ADD.
-- =====================================================================

-- 1) Fail-closed ellenorzes (V378 mintaja): ha barmi okbol lenne olyan
--    sorhalmaz, amit az uj 4-oszlopu kulcs nem tudna felvenni, inkabb
--    ne fusson le a migracio, mint hogy csendben elhasaljon az ADD
--    CONSTRAINT egy felig atallitott semaban. A regi 3-oszlopu kulcs
--    miatt ez elvileg 0 — de a penzugyi rendszerben a fail-closed nem
--    opcio.
DO $$
DECLARE
    duplicate_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO duplicate_count
      FROM (
            SELECT 1
              FROM denomination_balance
             GROUP BY cash_desk_id, denomination_id, denomination_category,
                      submission_date
            HAVING COUNT(*) > 1
           ) AS duplicates;

    IF duplicate_count > 0 THEN
        RAISE EXCEPTION
            '[FKH-050 V387] VISSZAGORGETVE: % duplikalt (cash_desk_id, denomination_id, '
            'denomination_category, submission_date) csoport van a denomination_balance '
            'tablaban — a datumnapi egyedi kulcs nem hozhato letre adatvesztes kockazata nelkul.',
            duplicate_count;
    END IF;
END
$$;

-- 2) A submission_date nem lehet NULL, ha kulcsresz: PostgreSQL-ben a NULL
--    ertekek egyedi kulcsban kulonbozonek szamitanak, ami kilyukasztana a
--    vedelmet. A V361 NOT NULL-t allitott rajta — de a defenziv ellenorzes
--    marad (ha valamilyen uton megis NULL lenne, a migracio fail-closed megall).
DO $$
DECLARE
    null_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO null_count
      FROM denomination_balance
     WHERE submission_date IS NULL;

    IF null_count > 0 THEN
        RAISE EXCEPTION
            '[FKH-050 V387] VISSZAGORGETVE: % sor submission_date erteke NULL — '
            'a datumnapi egyedi kulcs nem hozhato letre.',
            null_count;
    END IF;
END
$$;

-- 3) A regi 3-oszlopu kulcs eltavolitasa — NEV-AGNOSZTIKUSAN (V378 mintaja).
--    A V75 `uk_denom_balance_desk_denom`-kent hozta letre, a V378 atnevezte
--    `uk_denom_balance_desk_denom_category`-ra — de az ELES adatbazisban a
--    Hibernate altal generalt nev is allhat rajta. Ezert a DROP a kulcs
--    SZERKEZETET keresi (pontosan a 3 oszlop), nem a nevet.
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN
        SELECT con.conname
          FROM pg_constraint con
          JOIN pg_class rel ON rel.oid = con.conrelid
         WHERE rel.relname = 'denomination_balance'
           AND con.contype = 'u'
           AND (
                SELECT array_agg(a.attname::text ORDER BY a.attname::text)
                  FROM unnest(con.conkey) AS k(attnum)
                  JOIN pg_attribute a
                    ON a.attrelid = con.conrelid AND a.attnum = k.attnum
               ) = ARRAY['cash_desk_id', 'denomination_category', 'denomination_id']::text[]
    LOOP
        EXECUTE format('ALTER TABLE denomination_balance DROP CONSTRAINT %I',
                       constraint_record.conname);
        RAISE NOTICE '[FKH-050 V387] regi 3-oszlopu egyedi kulcs eltavolitva: %',
                     constraint_record.conname;
    END LOOP;
END
$$;

-- 4) Az uj 4-oszlopu, datumnapi egyedi kulcs letrehozasa.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint con
          JOIN pg_class rel ON rel.oid = con.conrelid
         WHERE rel.relname = 'denomination_balance'
           AND con.conname = 'uk_denom_balance_desk_denom_category_date'
    ) THEN
        ALTER TABLE denomination_balance
            ADD CONSTRAINT uk_denom_balance_desk_denom_category_date
            UNIQUE (cash_desk_id, denomination_id, denomination_category, submission_date);
        RAISE NOTICE '[FKH-050 V387] datumnapi egyedi kulcs letrehozva';
    ELSE
        RAISE NOTICE '[FKH-050 V387] MAR alkalmazva — a datumnapi kulcs all';
    END IF;
END
$$;
