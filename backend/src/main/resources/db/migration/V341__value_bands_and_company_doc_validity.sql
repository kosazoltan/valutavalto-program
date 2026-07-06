-- FS-8: konfigurálható AML értéksávok (effective_from-verziózott, cég-független — terv T2)
CREATE TABLE IF NOT EXISTS value_band_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    simplified_identification_limit_huf NUMERIC(18, 2) NOT NULL,
    identification_limit_huf NUMERIC(18, 2) NOT NULL,
    income_proof_limit_huf NUMERIC(18, 2) NOT NULL,
    rolling_window_days INTEGER NOT NULL DEFAULT 8,
    effective_from DATE NOT NULL,
    created_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP,
    CONSTRAINT uq_value_band_effective_from UNIQUE (effective_from)
);

-- Baseline sor: a mai törvényi értékek (a lookup ezt találja, a UI ezt mutatja hatályosként).
INSERT INTO value_band_config
    (simplified_identification_limit_huf, identification_limit_huf,
     income_proof_limit_huf, rolling_window_days, effective_from, created_by)
SELECT 100000, 300000, 10000000, 8, DATE '2020-01-01', 'V341_SEED'
WHERE NOT EXISTS (SELECT 1 FROM value_band_config);

-- FS-6: cégjegyzék-dokumentum lejárat
ALTER TABLE scanned_document ADD COLUMN IF NOT EXISTS valid_until DATE;

-- FS-6: konfigurálható érvényességi napok (Center FS: 30 nap, compliance-ben állítható)
INSERT INTO system_parameter (id, parameter_key, parameter_value, parameter_type, category, description, is_active)
SELECT gen_random_uuid(), 'COMPANY_DOC_VALIDITY_DAYS', '30', 'INTEGER', 'COMPLIANCE',
       'Cégjegyzék-okirat (COMPANY_REGISTRY scan) érvényessége a feltöltéstől számított napokban (Center FS-6, default 30)',
       true
WHERE NOT EXISTS (SELECT 1 FROM system_parameter WHERE parameter_key = 'COMPANY_DOC_VALIDITY_DAYS');
