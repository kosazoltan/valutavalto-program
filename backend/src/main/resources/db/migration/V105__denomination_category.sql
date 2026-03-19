-- V104: Denomination category support
-- A napi zárás különböző kasszatípusokra (EVENING, HANDLING_FEE, WU, stb.)
-- külön-külön címletezést igényel. Eddig ez nem volt nyilvántartva oszlop szinten.

-- 1. denomination_count táblába denomination_category oszlop
ALTER TABLE denomination_count ADD COLUMN IF NOT EXISTS denomination_category VARCHAR(30) DEFAULT 'EVENING';

-- 2. denomination_balance táblába is (a DailyClosingService ezt a táblát kérdezi)
ALTER TABLE denomination_balance ADD COLUMN IF NOT EXISTS denomination_category VARCHAR(30) DEFAULT 'EVENING';

-- 3. Index a napi zárási lekérdezésekhez (denomination_count)
CREATE INDEX IF NOT EXISTS idx_denom_count_category
    ON denomination_count(branch_id, created_at, denomination_category);

-- 4. Index a napi zárási lekérdezésekhez (denomination_balance)
CREATE INDEX IF NOT EXISTS idx_denom_balance_category
    ON denomination_balance(cash_desk_id, updated_at, denomination_category);
