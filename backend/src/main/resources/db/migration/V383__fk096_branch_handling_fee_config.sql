-- ============================================================================
-- V383: FK-096 — iroda-szintu kezelesi dij konfiguracio (branch_handling_fee_config)
--
-- FR-1: DRAFT/LIVE tabla irodankent; partialis egyedi indexekkel max 1 LIVE
--       + 1 DRAFT aktiv sor irodankent.
-- FR-2: SEED — a bevezetes pillanataban minden AKTIV iroda a korabbi cegszintu
--       system_parameter (HANDLING_FEE_TYPE / HANDLING_FEE_PER_MILLE /
--       HANDLING_FEE_PER_MILLE_MAX) szerint szamol tovabb, bit-azonosan.
--       D6 precedencia: ceg-scope sor > global (company_id IS NULL) > kod-default.
--       D5: a per_mille_cap VERBATIM kerul a seedbe (nincs 5 Ft kerekites).
-- FR-3: handling_fee_bracket.status (DRAFT/LIVE) oszlop, DEFAULT 'LIVE'.
-- D4:   fee_mode elfogadja a NONE-t is (orokolt cegszintu ertek lehet NONE),
--       de a CHECK a whitelist-map miatt CSAK kanonikus erteket enged.
-- D7:   a seed VAULT_COUNTERPARTY tipusu irodakra is fut (nincs fail-closed lyuk).
--
-- Teljesen idempotens (IF NOT EXISTS / IF EXISTS / NOT EXISTS guard a seedben).
-- ============================================================================

-- ============================================================================
-- 1. Tabla
-- ============================================================================
CREATE TABLE IF NOT EXISTS branch_handling_fee_config (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id     UUID          NOT NULL REFERENCES company(id),
    branch_id      UUID          NOT NULL REFERENCES branch(id),
    fee_mode       VARCHAR(20)   NOT NULL,
    per_mille_rate NUMERIC(6,3),
    per_mille_cap  NUMERIC(15,2),
    status         VARCHAR(10)   NOT NULL,
    is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
    valid_from     DATE          NOT NULL DEFAULT CURRENT_DATE,
    version        BIGINT        NOT NULL DEFAULT 0,
    created_by     VARCHAR(100),
    created_at     TIMESTAMP     NOT NULL DEFAULT NOW(),
    published_by   VARCHAR(100),
    published_at   TIMESTAMP,
    CONSTRAINT ck_bhfc_fee_mode CHECK (fee_mode IN ('NONE','BRACKET','PER_MILLE')),
    CONSTRAINT ck_bhfc_status   CHECK (status   IN ('DRAFT','LIVE')),
    CONSTRAINT ck_bhfc_per_mille CHECK (
        fee_mode <> 'PER_MILLE' OR (per_mille_rate IS NOT NULL AND per_mille_rate >= 0))
);

-- Irodankent max 1 aktiv LIVE, ill. max 1 aktiv DRAFT sor.
CREATE UNIQUE INDEX IF NOT EXISTS uk_bhfc_branch_live
    ON branch_handling_fee_config(branch_id) WHERE status = 'LIVE'  AND is_active;
CREATE UNIQUE INDEX IF NOT EXISTS uk_bhfc_branch_draft
    ON branch_handling_fee_config(branch_id) WHERE status = 'DRAFT' AND is_active;

CREATE INDEX IF NOT EXISTS idx_bhfc_company ON branch_handling_fee_config(company_id);

-- ============================================================================
-- 2. handling_fee_bracket.status (FR-3) — a status ORTOGONALIS az active-re
--    (a V227 trg_sync_active_columns trigger az active/is_active parosert felel).
-- ============================================================================
ALTER TABLE handling_fee_bracket
    ADD COLUMN IF NOT EXISTS status VARCHAR(10) NOT NULL DEFAULT 'LIVE';
ALTER TABLE handling_fee_bracket DROP CONSTRAINT IF EXISTS ck_hfb_status;
ALTER TABLE handling_fee_bracket
    ADD CONSTRAINT ck_hfb_status CHECK (status IN ('DRAFT','LIVE'));
UPDATE handling_fee_bracket SET status = 'LIVE' WHERE status IS NULL;

-- ============================================================================
-- 3. FR-2 SEED — minden aktiv iroda kap egy LIVE sort a korabbi cegszintu
--    system_parameter szerint.
--
--    B1 whitelist-map: a fee_mode kifejezes TRIM+UPPER kanonizacio utan CSAK
--    a ('NONE','BRACKET','PER_MILLE') ertekeket enged at; minden mas ertek
--    ('EZRELÉK', 'Foo', 'BRACKET ', ures, ...) -> 'BRACKET' (a mai runtime
--    fallbackje, HandlingFeeService.resolveFeeType:126-134). A nyers ertek
--    beirasa a CHECK-be utkozne es az EGESZ V383-at megbuktatna mind a 4 cegnel.
--
--    D6 precedencia: LEFT JOIN LATERAL, ORDER BY (company_id IS NULL) LIMIT 1 —
--    a ceg-scope sor (IS NULL = false) nyer a globalis sorral szemben, es CSAK
--    az aktiv (COALESCE(is_active, TRUE)) sorok lathatok (SystemParameterService
--    .findEffective paritas).
--
--    D5: a cap VERBATIM kerul at; a 0 cap "nincs sapka" jelentese NULL-kent
--    oroklodik (NULLIF, HandlingFeeService:149 `maxAmount > 0` paritas).
--
--    Nem szam parameter-ertekek nem buktathatjak a migraciot: a ::NUMERIC
--    castok csak regex-guardolt ('^[0-9]+(\.[0-9]+)?$') ertekre futnak,
--    egyebkent a LATERAL ures -> a default (rate 0 / cap NULL) eletbe lep.
-- ============================================================================
INSERT INTO branch_handling_fee_config
    (company_id, branch_id, fee_mode, per_mille_rate, per_mille_cap, status, is_active,
     valid_from, created_by, created_at, published_by, published_at)
SELECT b.company_id, b.id,
       -- B1: whitelist-map — TRIM+UPPER kanonizalas, minden mas ertek -> 'BRACKET'
       CASE WHEN UPPER(TRIM(COALESCE(t.v,''))) IN ('NONE','BRACKET','PER_MILLE')
            THEN UPPER(TRIM(t.v)) ELSE 'BRACKET' END,
       -- per_mille_rate: csak PER_MILLE modban; nem szam/hiányzo ertek -> 0 (kod-default)
       CASE WHEN UPPER(TRIM(COALESCE(t.v,''))) = 'PER_MILLE'
            THEN COALESCE(NULLIF(r.v,'')::NUMERIC, 0) END,
       -- per_mille_cap: VERBATIM (D5); NULL es 0 egyarant "nincs sapka" -> NULL
       CASE WHEN UPPER(TRIM(COALESCE(t.v,''))) = 'PER_MILLE'
            THEN NULLIF(NULLIF(m.v,'')::NUMERIC, 0) END,
       'LIVE', TRUE, CURRENT_DATE, 'V383', NOW(), 'V383', NOW()
  FROM branch b
  LEFT JOIN LATERAL (SELECT sp.parameter_value AS v FROM system_parameter sp
                      WHERE sp.parameter_key = 'HANDLING_FEE_TYPE'
                        AND COALESCE(sp.is_active, TRUE)
                        AND (sp.company_id = b.company_id OR sp.company_id IS NULL)
                      ORDER BY (sp.company_id IS NULL) LIMIT 1) t ON TRUE
  LEFT JOIN LATERAL (SELECT sp.parameter_value AS v FROM system_parameter sp
                      WHERE sp.parameter_key = 'HANDLING_FEE_PER_MILLE'
                        AND COALESCE(sp.is_active, TRUE)
                        AND (sp.company_id = b.company_id OR sp.company_id IS NULL)
                        AND sp.parameter_value ~ '^[0-9]+(\.[0-9]+)?$'
                      ORDER BY (sp.company_id IS NULL) LIMIT 1) r ON TRUE
  LEFT JOIN LATERAL (SELECT sp.parameter_value AS v FROM system_parameter sp
                      WHERE sp.parameter_key = 'HANDLING_FEE_PER_MILLE_MAX'
                        AND COALESCE(sp.is_active, TRUE)
                        AND (sp.company_id = b.company_id OR sp.company_id IS NULL)
                        AND sp.parameter_value ~ '^[0-9]+(\.[0-9]+)?$'
                      ORDER BY (sp.company_id IS NULL) LIMIT 1) m ON TRUE
 WHERE COALESCE(b.is_active, TRUE)
   AND NOT EXISTS (SELECT 1 FROM branch_handling_fee_config x
                    WHERE x.branch_id = b.id AND x.status = 'LIVE' AND x.is_active);

COMMENT ON TABLE branch_handling_fee_config IS
    'FK-096: iroda-szintu kezelesi dij konfiguracio (DRAFT/LIVE). V383 seed = a bevezetes '
    'pillanataban minden aktiv iroda a korabbi cegszintu system_parameter szerint szamol.';
