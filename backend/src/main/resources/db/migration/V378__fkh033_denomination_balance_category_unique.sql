-- =====================================================================
-- FKH-033 / V378 — denomination_balance: kategoria-tudatos egyedi kulcs
-- =====================================================================
-- ELOZMENY: a V75 a tablat a (cash_desk_id, denomination_id) egyedi kulccsal
-- hozta letre, a V105 viszont KESOBB vezette be a denomination_category
-- oszlopot (EVENING / HANDLING_FEE / WESTERN_UNION / ...). A ket lepes soha
-- nem lett osszehangolva, igy ugyanarra a (penztar, cimlet) parra a MASODIK
-- kategoria mentese unique-utkozest dobott.
--
-- ELES HATAS: a zarasi varazsloban az ELSO HANDLING_FEE cimlet-mentes
-- DataIntegrityViolationException / HTTP 500 lett, es a torvenyileg kotelezo
-- napi zaras megszakadt. Eddig csak a kikapcsolt
-- FEATURE_HANDLING_FEE_DENOMINATION flag fedte el a hibat.
--
-- MEGOLDAS: a kulcs kiterjesztese a kategoriara. A regi kulcs SZIGORUBB volt,
-- mint az uj, ezert a csere semmilyen letezo sort nem serthet — nincs
-- backfill, nincs adatveszteseg, nincs torles.
--
-- IDEMPOTENS: DROP ... IF EXISTS + letezes-ellenorzott ADD.
-- =====================================================================

-- 1) A kategoria-oszlop csak akkor lehet kulcsresz, ha NEM NULL: PostgreSQL-ben
--    a NULL ertekek egyedi kulcsban kulonbozonek szamitanak, ami kilyukasztana
--    a vedelmet. A V105 DEFAULT 'EVENING'-et adott, de a regi sorokban maradhatott
--    NULL. A regi (cash_desk_id, denomination_id) kulcs garantalja, hogy ez a
--    backfill NEM hozhat letre duplikatumot a harmas kulcson.
UPDATE denomination_balance
   SET denomination_category = 'EVENING'
 WHERE denomination_category IS NULL;

ALTER TABLE denomination_balance
    ALTER COLUMN denomination_category SET DEFAULT 'EVENING';

ALTER TABLE denomination_balance
    ALTER COLUMN denomination_category SET NOT NULL;

-- 2) Fail-closed ellenorzes: ha barmi okbol MEGIS lenne olyan sorhalmaz, amit az
--    uj kulcs nem tudna felvenni, inkabb ne fusson le a migracio, mint hogy
--    csendben elhasaljon az ADD CONSTRAINT egy felig atallitott semaban.
DO $$
DECLARE
    duplicate_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO duplicate_count
      FROM (
            SELECT 1
              FROM denomination_balance
             GROUP BY cash_desk_id, denomination_id, denomination_category
            HAVING COUNT(*) > 1
           ) AS duplicates;

    IF duplicate_count > 0 THEN
        RAISE EXCEPTION
            '[FKH-033 V378] VISSZAGORGETVE: % duplikalt (cash_desk_id, denomination_id, '
            'denomination_category) csoport van a denomination_balance tablaban — '
            'a kategoria-tudatos egyedi kulcs nem hozhato letre adatvesztes kockazata nelkul.',
            duplicate_count;
    END IF;
END
$$;

-- 3) A kategoria-mentes kulcs eltavolitasa es a kategoria-tudatos felvetele.
--
-- FIGYELEM — NEV-AGNOSZTIKUS DROP (2026-08-10, eles Gate A merés alapján):
-- a kulcs NEVE kornyezetenkent ELTER. A V75 `uk_denom_balance_desk_denom`-kent
-- hozza letre, az ELES adatbazisban viszont a Hibernate altal generalt
-- `uk4g8glqo7rah6ebhlltscwyvdx` nev all rajta. Egy nevre szolo
-- `DROP CONSTRAINT IF EXISTS` ezert prodban NEMA NO-OP lenne: a regi kulcs
-- maradna, es a javitas nem ervenyesulne — miközben minden teszt zold.
-- Ezert a DROP a kulcs SZERKEZETET keresi (pontosan a
-- (cash_desk_id, denomination_id) oszloppar), nem a nevet.
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
               ) = ARRAY['cash_desk_id', 'denomination_id']::text[]
    LOOP
        EXECUTE format('ALTER TABLE denomination_balance DROP CONSTRAINT %I',
                       constraint_record.conname);
        RAISE NOTICE '[FKH-033 V378] kategoria-mentes egyedi kulcs eltavolitva: %',
                     constraint_record.conname;
    END LOOP;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint con
          JOIN pg_class rel ON rel.oid = con.conrelid
         WHERE rel.relname = 'denomination_balance'
           AND con.conname = 'uk_denom_balance_desk_denom_category'
    ) THEN
        ALTER TABLE denomination_balance
            ADD CONSTRAINT uk_denom_balance_desk_denom_category
            UNIQUE (cash_desk_id, denomination_id, denomination_category);
        RAISE NOTICE '[FKH-033 V378] kategoria-tudatos egyedi kulcs letrehozva';
    ELSE
        RAISE NOTICE '[FKH-033 V378] MAR alkalmazva — a kategoria-tudatos kulcs all';
    END IF;
END
$$;
