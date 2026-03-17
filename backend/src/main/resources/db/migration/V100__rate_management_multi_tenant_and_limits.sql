-- V100: Rate management multi-tenant support + template limit fields
-- Background: A rate_workgroup, rate_template, rate_publication és rate_discount
-- táblákról hiányzik a company_id → bármelyik cég látja bármelyik munkacsoportot.
-- Továbbá a rate_template-ből hiányoznak a limit szintek és az official_rate,
-- ezért a publikáláskor elvesznek a keretértékek.

-- ============ 1. rate_workgroup: company_id ============

ALTER TABLE rate_workgroup ADD COLUMN IF NOT EXISTS company_id UUID;

DO $$
BEGIN
    -- Backfill: ha van létező company, az elsőt használjuk
    UPDATE rate_workgroup
       SET company_id = (SELECT id FROM company ORDER BY created_at LIMIT 1)
     WHERE company_id IS NULL
       AND EXISTS (SELECT 1 FROM company);
END $$;

-- Csak akkor tesszük NOT NULL-ra, ha minden sor ki van töltve
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM rate_workgroup WHERE company_id IS NULL) THEN
        ALTER TABLE rate_workgroup ALTER COLUMN company_id SET NOT NULL;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_rate_workgroup_company'
    ) THEN
        ALTER TABLE rate_workgroup
            ADD CONSTRAINT fk_rate_workgroup_company
            FOREIGN KEY (company_id) REFERENCES company(id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rate_workgroup_company ON rate_workgroup(company_id);

-- Globális UNIQUE(code) → compound UNIQUE(company_id, code) a multi-tenant támogatáshoz
DO $$
BEGIN
    -- Drop the old global unique constraint on code (if it exists)
    IF EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'rate_workgroup' AND indexname = 'rate_workgroup_code_key'
    ) THEN
        ALTER TABLE rate_workgroup DROP CONSTRAINT rate_workgroup_code_key;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'uq_rate_workgroup_company_code'
          AND table_name = 'rate_workgroup'
    ) THEN
        ALTER TABLE rate_workgroup
            ADD CONSTRAINT uq_rate_workgroup_company_code UNIQUE (company_id, code);
    END IF;
END $$;

-- ============ 2. rate_template: company_id + limit mezők + official_rate ============

ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS company_id UUID;

DO $$
BEGIN
    -- Backfill: workgroup-ból kapja a company_id-t
    UPDATE rate_template rt
       SET company_id = rw.company_id
      FROM rate_workgroup rw
     WHERE rw.id = rt.workgroup_id
       AND rt.company_id IS NULL;

    -- Fallback: ha nincs workgroup match
    UPDATE rate_template
       SET company_id = (SELECT id FROM company ORDER BY created_at LIMIT 1)
     WHERE company_id IS NULL
       AND EXISTS (SELECT 1 FROM company);
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM rate_template WHERE company_id IS NULL) THEN
        ALTER TABLE rate_template ALTER COLUMN company_id SET NOT NULL;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_rate_template_company'
    ) THEN
        ALTER TABLE rate_template
            ADD CONSTRAINT fk_rate_template_company
            FOREIGN KEY (company_id) REFERENCES company(id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rate_template_company ON rate_template(company_id);

-- Limit és official_rate mezők
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS official_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit1_amount NUMERIC(15,2);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit1_buy_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit1_sell_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit2_amount NUMERIC(15,2);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit2_buy_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit2_sell_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit3_amount NUMERIC(15,2);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit3_buy_rate NUMERIC(18,6);
ALTER TABLE rate_template ADD COLUMN IF NOT EXISTS limit3_sell_rate NUMERIC(18,6);

-- ============ 3. rate_publication: company_id ============

ALTER TABLE rate_publication ADD COLUMN IF NOT EXISTS company_id UUID;

DO $$
BEGIN
    UPDATE rate_publication rp
       SET company_id = rw.company_id
      FROM rate_workgroup rw
     WHERE rw.id = rp.workgroup_id
       AND rp.company_id IS NULL;

    UPDATE rate_publication
       SET company_id = (SELECT id FROM company ORDER BY created_at LIMIT 1)
     WHERE company_id IS NULL
       AND EXISTS (SELECT 1 FROM company);
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM rate_publication WHERE company_id IS NULL) THEN
        ALTER TABLE rate_publication ALTER COLUMN company_id SET NOT NULL;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_rate_publication_company'
    ) THEN
        ALTER TABLE rate_publication
            ADD CONSTRAINT fk_rate_publication_company
            FOREIGN KEY (company_id) REFERENCES company(id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rate_publication_company ON rate_publication(company_id);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_rate_publication_workgroup'
          AND table_name = 'rate_publication'
    ) THEN
        ALTER TABLE rate_publication
            ADD CONSTRAINT fk_rate_publication_workgroup
            FOREIGN KEY (workgroup_id) REFERENCES rate_workgroup(id);
    END IF;
END $$;

-- ============ 4. rate_discount: company_id ============

ALTER TABLE rate_discount ADD COLUMN IF NOT EXISTS company_id UUID;

DO $$
BEGIN
    UPDATE rate_discount rd
       SET company_id = rw.company_id
      FROM rate_workgroup rw
     WHERE rw.id = rd.workgroup_id
       AND rd.company_id IS NULL;

    UPDATE rate_discount
       SET company_id = (SELECT id FROM company ORDER BY created_at LIMIT 1)
     WHERE company_id IS NULL
       AND EXISTS (SELECT 1 FROM company);
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM rate_discount WHERE company_id IS NULL) THEN
        ALTER TABLE rate_discount ALTER COLUMN company_id SET NOT NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_rate_discount_company_id ON rate_discount(company_id);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_rate_discount_company'
          AND table_name = 'rate_discount'
    ) THEN
        ALTER TABLE rate_discount
            ADD CONSTRAINT fk_rate_discount_company
            FOREIGN KEY (company_id) REFERENCES company(id);
    END IF;
END $$;

-- ============ 5. audit_log: company_id (multi-tenant audit trail isolation) ============

ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS company_id UUID;

CREATE INDEX IF NOT EXISTS idx_audit_log_company_id ON audit_log(company_id);
