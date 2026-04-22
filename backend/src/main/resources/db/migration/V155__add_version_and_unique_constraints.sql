-- V155: Optimistic locking (@Version) es hianyzo unique constraint-ek
-- (eredeti V104 a cherry-pick-bol; V104 mar foglalt V104__daily_checklist.sql-ben)
--
-- AI REVIEW FIX (PR #98 Codex P1): a Hetzner production DB tartalmazhat
-- mar duplikalt (company_id, branch_id, session_date) vagy
-- (branch_id, transaction_date, receipt_number) rekordokat.
-- A unique index letrehozas ELSZALL duplikatum eseten -> migration failure.
-- Pre-cleanup lepes: duplikatumok detektalasa + legitim/illegitim donteshez
-- leallitas (Hetzner production nem fog duplikatumot maganaban tartani, de
-- a migration defensive-legyen kell).

-- 1. @Version oszlopok hozzaadása pénzügyi entitásokhoz
ALTER TABLE daily_session ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE aml_report    ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE daily_balance ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE customer      ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

-- 2. DUPLICATE PRE-CHECK: daily_session (company_id, branch_id, session_date)
-- Ha talalunk duplikatumot, DOBUNK hibat explicit uzenettel -> admin donti el.
-- Ez MEGELOZI hogy a CREATE UNIQUE INDEX siman elszaljon titkos hibaval.
DO $$
DECLARE
    duplicate_count INT;
    duplicate_info TEXT;
BEGIN
    -- Sourcery AI P2 fix: COUNT(*) csak a duplicate KEY-eket szamolta, nem az ERINTETT ROW-okat.
    -- SUM(dup.cnt) = duplikatum-csoportok osszes sor-szama, igazan informativ.
    SELECT COALESCE(SUM(dup.cnt), 0), STRING_AGG(DISTINCT CONCAT(dup.company_id::text, '/', dup.branch_id::text, '/', dup.session_date::text, ' (', dup.cnt, ' sor)'), ', ')
        INTO duplicate_count, duplicate_info
    FROM (
        SELECT company_id, branch_id, session_date, COUNT(*) AS cnt
        FROM daily_session
        GROUP BY company_id, branch_id, session_date
        HAVING COUNT(*) > 1
    ) dup;

    IF duplicate_count > 0 THEN
        RAISE EXCEPTION 'V155 migration ABORT: % duplikalt daily_session tobb session ugyanazon napon/irodaban/cegben. Rendezd elobb: %',
            duplicate_count, duplicate_info;
    END IF;
END $$;

-- 3. DUPLICATE PRE-CHECK: transaction (branch_id, transaction_date, receipt_number)
DO $$
DECLARE
    duplicate_count INT;
    duplicate_info TEXT;
BEGIN
    -- Sourcery AI P2 fix: SUM(dup.cnt) = osszes erintett sor szama + cnt megjelenitese
    SELECT COALESCE(SUM(dup.cnt), 0), STRING_AGG(DISTINCT CONCAT(dup.branch_id::text, '/', dup.transaction_date::text, '/', dup.receipt_number, ' (', dup.cnt, ' sor)'), ', ')
        INTO duplicate_count, duplicate_info
    FROM (
        SELECT branch_id, transaction_date, receipt_number, COUNT(*) AS cnt
        FROM transaction
        WHERE receipt_number IS NOT NULL
        GROUP BY branch_id, transaction_date, receipt_number
        HAVING COUNT(*) > 1
    ) dup;

    IF duplicate_count > 0 THEN
        RAISE EXCEPTION 'V155 migration ABORT: % duplikalt receipt_number ugyanazon branch+datumban. NGM 23/2014 sertes! Rendezd elobb: %',
            duplicate_count, duplicate_info;
    END IF;
END $$;

-- 4. Unique constraint: egy nap, egy iroda, egy session
CREATE UNIQUE INDEX IF NOT EXISTS uq_daily_session_branch_date
    ON daily_session (company_id, branch_id, session_date);

-- 5. Unique constraint: bizonylat szam egyediseg branch+datum scope-ban
-- (WHERE clause: csak nem-null receipt_number-t indexel, hogy a draft tranzakciokat ne erintse)
CREATE UNIQUE INDEX IF NOT EXISTS uq_transaction_receipt_branch_date
    ON transaction (branch_id, transaction_date, receipt_number)
    WHERE receipt_number IS NOT NULL;
