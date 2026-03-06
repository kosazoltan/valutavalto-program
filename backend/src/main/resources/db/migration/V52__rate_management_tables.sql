-- Rate management tables for exchange rate creation system

CREATE TABLE rate_workgroup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    legacy_group_number INTEGER,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE rate_workgroup_branch (
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    branch_id UUID NOT NULL REFERENCES branch(id),
    PRIMARY KEY (workgroup_id, branch_id)
);

CREATE TABLE rate_template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_id UUID NOT NULL REFERENCES currency(id),
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    base_buy_rate NUMERIC(18,6) NOT NULL,
    base_sell_rate NUMERIC(18,6) NOT NULL,
    buy_spread NUMERIC(18,6) DEFAULT 0,
    sell_spread NUMERIC(18,6) DEFAULT 0,
    rounding_rule INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'DRAFT',
    created_by BIGINT,
    approved_by BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    published_at TIMESTAMP
);

CREATE INDEX idx_rate_template_wg_status ON rate_template(workgroup_id, status);
CREATE INDEX idx_rate_template_currency ON rate_template(currency_id);

CREATE TABLE rate_discount (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workgroup_id UUID NOT NULL REFERENCES rate_workgroup(id),
    level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 3),
    name VARCHAR(50) NOT NULL,
    buy_discount_percent NUMERIC(8,4) DEFAULT 0,
    sell_discount_percent NUMERIC(8,4) DEFAULT 0,
    active BOOLEAN DEFAULT true,
    UNIQUE(workgroup_id, level)
);

CREATE TABLE rate_publication (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES rate_template(id),
    workgroup_id UUID NOT NULL,
    published_by BIGINT NOT NULL,
    published_at TIMESTAMP DEFAULT NOW(),
    affected_branches INTEGER DEFAULT 0,
    notes TEXT
);

CREATE INDEX idx_rate_publication_wg ON rate_publication(workgroup_id);
