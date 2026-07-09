-- FK-028: MNB elszámolási árfolyam (havi rögzítés) + append-only history.
-- FK constraint szándékosan NINCS (V346/V347/V350 precedens, típus-drift
-- tanulság): UNIQUE index véd.
CREATE TABLE IF NOT EXISTS mnb_settlement_rate (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    official_rate NUMERIC(15,4) NOT NULL,
    available_to_offices_at TIMESTAMPTZ,
    updated_by VARCHAR(50),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_mnb_settlement_rate_company_currency
    ON mnb_settlement_rate (company_id, currency_code);

CREATE TABLE IF NOT EXISTS mnb_settlement_rate_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    official_rate NUMERIC(15,4) NOT NULL,
    available_to_offices_at TIMESTAMPTZ,
    recorded_by VARCHAR(50),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_msr_history_company_recorded
    ON mnb_settlement_rate_history (company_id, recorded_at);

-- Seed: minden cég × aktív nem-HUF valuta, 0 = "első rögzítés" jelző (FR-8)
INSERT INTO mnb_settlement_rate (company_id, currency_code, official_rate)
SELECT co.id, cu.code, 0
FROM company co CROSS JOIN currency cu
WHERE cu.is_active = TRUE AND cu.code <> 'HUF'
ON CONFLICT DO NOTHING;

-- HUF sor: fix 1.0000 (FR-2)
INSERT INTO mnb_settlement_rate (company_id, currency_code, official_rate)
SELECT co.id, 'HUF', 1.0000 FROM company co
ON CONFLICT DO NOTHING;
