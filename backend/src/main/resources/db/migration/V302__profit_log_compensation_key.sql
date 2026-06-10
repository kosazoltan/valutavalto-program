ALTER TABLE profit_log
    ADD COLUMN IF NOT EXISTS compensation_key VARCHAR(120);

CREATE UNIQUE INDEX IF NOT EXISTS ux_profit_log_compensation_key
    ON profit_log(compensation_key)
    WHERE compensation_key IS NOT NULL;
