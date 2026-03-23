-- Migrate commission_rule.company_id from legacy INTEGER to UUID (company.id)

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'commission_rule'
          AND column_name = 'company_id'
          AND data_type IN ('integer', 'smallint', 'bigint')
    ) THEN
        ALTER TABLE commission_rule ADD COLUMN IF NOT EXISTS company_id_uuid UUID;

        WITH ranked_company AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at, id) AS rn
            FROM company
        )
        UPDATE commission_rule cr
           SET company_id_uuid = rc.id
          FROM ranked_company rc
         WHERE cr.company_id_uuid IS NULL
           AND cr.company_id = rc.rn;

        UPDATE commission_rule cr
           SET company_id_uuid = (
               SELECT id FROM company ORDER BY created_at, id LIMIT 1
           )
         WHERE cr.company_id_uuid IS NULL;

        ALTER TABLE commission_rule DROP COLUMN company_id;
        ALTER TABLE commission_rule RENAME COLUMN company_id_uuid TO company_id;
        ALTER TABLE commission_rule ALTER COLUMN company_id SET NOT NULL;

        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.table_constraints
            WHERE table_schema = 'public'
              AND table_name = 'commission_rule'
              AND constraint_name = 'fk_comm_rule_company'
        ) THEN
            ALTER TABLE commission_rule
                ADD CONSTRAINT fk_comm_rule_company
                FOREIGN KEY (company_id) REFERENCES company(id);
        END IF;

        CREATE INDEX IF NOT EXISTS idx_comm_rule_company ON commission_rule(company_id);
    END IF;
END $$;
