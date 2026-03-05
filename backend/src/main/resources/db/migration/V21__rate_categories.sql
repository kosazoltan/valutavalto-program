-- V21: Kis/Nagy váltós árfolyam kategóriák
CREATE TABLE rate_category (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id       UUID NOT NULL REFERENCES branch(id),
    currency_code   VARCHAR(3) NOT NULL,
    category        VARCHAR(20) NOT NULL DEFAULT 'STANDARD' CHECK (category IN ('STANDARD', 'SMALL', 'LARGE')),
    buy_rate        NUMERIC(18,6) NOT NULL,
    sell_rate       NUMERIC(18,6) NOT NULL,
    min_amount      NUMERIC(18,2),
    max_amount      NUMERIC(18,2),
    valid_from      TIMESTAMP NOT NULL DEFAULT now(),
    valid_to        TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP,
    UNIQUE (branch_id, currency_code, category)
);

CREATE INDEX idx_rate_category_branch ON rate_category(branch_id);
CREATE INDEX idx_rate_category_currency ON rate_category(currency_code);
