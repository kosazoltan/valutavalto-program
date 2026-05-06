-- F2 cross-tenant fix (backend audit 2026-05-06):
-- A `fee_discount` tábla NEM volt company_id-vel scope-olt → egy cég kedvezménye
-- minden tenant-ban élt. Pénzügyi hatás: helytelen díjszámítás multi-tenant
-- üzemeltetés esetén.
--
-- A jelenlegi production csak EGY cég van (EBC), így a backfill egyszerű:
-- minden meglévő fee_discount rekord az EBC company-hoz kerül.

-- 1. Új oszlop hozzáadása
ALTER TABLE fee_discount
    ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES company(id);

-- 2. Backfill: meglévő rekordok → EBC cég
DO $$
DECLARE
    ebc_company_id UUID;
BEGIN
    SELECT id INTO ebc_company_id FROM company WHERE code = 'EBC' LIMIT 1;
    IF ebc_company_id IS NOT NULL THEN
        UPDATE fee_discount SET company_id = ebc_company_id WHERE company_id IS NULL;
        RAISE NOTICE 'V189: % fee_discount record assigned to EBC company',
            (SELECT COUNT(*) FROM fee_discount WHERE company_id = ebc_company_id);
    ELSE
        RAISE NOTICE 'V189: EBC company not found — fee_discount.company_id stays NULL (no records?)';
    END IF;
END $$;

-- 3. NOT NULL constraint (csak ha minden record-nak van company_id-je)
DO $$
DECLARE
    null_count INT;
BEGIN
    SELECT COUNT(*) INTO null_count FROM fee_discount WHERE company_id IS NULL;
    IF null_count = 0 THEN
        ALTER TABLE fee_discount ALTER COLUMN company_id SET NOT NULL;
        RAISE NOTICE 'V189: fee_discount.company_id is now NOT NULL';
    ELSE
        RAISE WARNING 'V189: % fee_discount records still have NULL company_id — manual intervention needed', null_count;
    END IF;
END $$;

-- 4. Régi unique index csere a company-scoped változatra
DROP INDEX IF EXISTS uk_fee_discount_code;
CREATE UNIQUE INDEX IF NOT EXISTS uk_fee_discount_company_code
    ON fee_discount(company_id, code);

-- 5. Index a per-company aktív lekérdezéshez
CREATE INDEX IF NOT EXISTS idx_fee_discount_company_active
    ON fee_discount(company_id, is_active);

COMMENT ON COLUMN fee_discount.company_id IS
    'F2 cross-tenant fix (V189, 2026-05-06): a kedvezmények cég-szinten elkülönítve. '
    'Egy cég VIP10 diszkontja NEM működik másik cégnél. A DiscountThresholdService '
    'a SecurityUtils.getCurrentCompanyId() alapján szűr.';
