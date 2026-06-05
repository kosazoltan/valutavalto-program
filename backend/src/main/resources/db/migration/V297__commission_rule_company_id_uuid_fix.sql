-- V297 (2026-06-05): commission_rule.company_id INTEGER -> UUID — a V108 potlasa.
--
-- A V108 ezen a production DB-n NEM hatott: a flyway_schema_history-ban success=t,
-- de a company_id MARADT integer (FK nelkul). A V108 DO-blockja a futasakor skip-pelt
-- (a 'data_type IN integer/smallint/bigint' feltetel akkor false volt), es Flyway
-- success-kent rogzitette -> applied migracio NEM futtathato ujra, ezert kell ez az uj
-- verzio.
--
-- Tunet: a CommissionRule entitas company_id-t UUID-kent mappeli
-- (@Column(name="company_id") private UUID companyId), igy Hibernate `ddl-auto=validate`
-- alatt (pl. failover/promote-olt node) a backend NEM indul:
--   "Schema validation: wrong column type ... column [company_id] ... found [int4],
--    but expecting [uuid]".
-- Production-ben nem tort, mert ott ddl-auto=none (default).
--
-- A production commission_rule URES (0 sor) -> a konverzio adatvesztes-mentes. A legacy
-- int->uuid mappinget (company rangsor szerint) megtartjuk arra az esetre, ha valamelyik
-- kornyezetben mar lenne adat. Idempotens: fresh DB-ken (ahol a V108 mar uuid-da tette)
-- a feltetel false -> no-op.

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

        -- legacy integer company_id -> company.id (letrehozasi sorrend szerinti rangsor)
        WITH ranked_company AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at, id) AS rn
            FROM company
        )
        UPDATE commission_rule cr
           SET company_id_uuid = rc.id
          FROM ranked_company rc
         WHERE cr.company_id_uuid IS NULL
           AND cr.company_id = rc.rn;

        -- maradek (nem-parosithato) sorok -> elso (legregibb) ceg
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
