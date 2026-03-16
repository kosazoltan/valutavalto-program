-- V76: Seed exchange rates with realistic HUF rates (2026-03-15)
-- Source: exchangerate-api.com + frankfurter.app cross-validated
-- Rates expressed as: 1 foreign currency unit = X HUF

-- Ensure we have a default workgroup for rate management
INSERT INTO rate_workgroup (id, name, code, legacy_group_number, active, created_at)
VALUES (gen_random_uuid(), 'Alapertelmezett', 'DEFAULT', 0, true, NOW())
ON CONFLICT (code) DO NOTHING;

-- Seed exchange rates for the EBC company (Tisza Sarok branch)
-- exchange_rate schema: company_id, currency_id, valid_date, valid_time,
--   base_buy_rate, base_sell_rate, official_rate, active
INSERT INTO exchange_rate (
    company_id, currency_id, valid_date, valid_time,
    base_buy_rate, base_sell_rate,
    limit1_amount, limit1_buy_rate, limit1_sell_rate,
    limit2_amount, limit2_buy_rate, limit2_sell_rate,
    official_rate, is_active, created_by, created_at
)
SELECT
    c.id,
    cur.id,
    CURRENT_DATE,
    CURRENT_TIME,
    v.buy_rate,
    v.sell_rate,
    v.limit1_amount, v.limit1_buy, v.limit1_sell,
    v.limit2_amount, v.limit2_buy, v.limit2_sell,
    v.middle_rate,
    true,
    'SYSTEM',
    NOW()
FROM company c
CROSS JOIN (VALUES
    -- code, middle_rate, buy_rate,  sell_rate,  limit1_amt, limit1_buy, limit1_sell, limit2_amt, limit2_buy, limit2_sell
    ('EUR',  392.16,      386.28,    398.04,     1000,       387.50,     396.80,      5000,       388.70,     395.60),
    ('USD',  342.47,      335.62,    349.31,     1000,       336.90,     347.95,      5000,       338.20,     346.60),
    ('GBP',  454.55,      443.18,    465.91,      500,       445.00,     464.00,      2000,       447.00,     462.00),
    ('CHF',  432.90,      422.08,    443.73,      500,       423.50,     442.20,      2000,       425.00,     440.60),
    ('CZK',   16.05,       15.41,     16.69,    10000,        15.55,      16.55,     50000,        15.65,      16.45),
    ('PLN',   91.74,       88.07,     95.41,     1000,        88.90,      94.55,      5000,        89.70,      93.70),
    ('RON',   76.92,       73.85,     80.00,     1000,        74.50,      79.35,      5000,        75.15,      78.70),
    ('SEK',   36.40,       34.94,     37.86,     5000,        35.20,      37.60,     20000,        35.45,      37.35),
    ('NOK',   35.09,       33.68,     36.49,     5000,        33.95,      36.20,     20000,        34.20,      35.95),
    ('DKK',   52.38,       51.33,     53.43,     5000,        51.55,      53.20,     20000,        51.80,      52.95),
    ('JPY',    2.1414,      2.0557,    2.2271,  100000,        2.0700,     2.2130,   500000,        2.0850,     2.1980),
    ('CAD',  250.00,      243.75,    256.25,      500,       244.80,     255.20,      2000,       245.90,     254.10),
    ('AUD',  240.38,      234.37,    246.39,      500,       235.30,     245.45,      2000,       236.25,     244.50),
    ('CNY',   49.26,       46.80,     51.72,     5000,        47.20,      51.30,     20000,        47.60,      50.90),
    ('RUB',    4.2735,      4.0598,    4.4872,  50000,         4.0900,     4.4570,  200000,         4.1200,     4.4270),
    ('UAH',    7.7519,      7.3643,    8.1395,  10000,         7.4200,     8.0840,   50000,         7.4750,     8.0280),
    ('TRY',    7.7190,      7.3331,    8.1050,  10000,         7.3880,     8.0500,   50000,         7.4430,     7.9950)
) AS v(code, middle_rate, buy_rate, sell_rate, limit1_amount, limit1_buy, limit1_sell, limit2_amount, limit2_buy, limit2_sell)
JOIN currency cur ON cur.code = v.code AND cur.is_active = true
WHERE c.code = 'EBC';

-- Seed MNB official rates into cache for monthly closing revaluation
INSERT INTO mnb_exchange_rate_cache (
    currency_code, rate_date, official_rate, unit, fetched_at
)
VALUES
    ('EUR', CURRENT_DATE, 392.16, 1, NOW()),
    ('USD', CURRENT_DATE, 342.47, 1, NOW()),
    ('GBP', CURRENT_DATE, 454.55, 1, NOW()),
    ('CHF', CURRENT_DATE, 432.90, 1, NOW()),
    ('CZK', CURRENT_DATE,  16.05, 1, NOW()),
    ('PLN', CURRENT_DATE,  91.74, 1, NOW()),
    ('RON', CURRENT_DATE,  76.92, 1, NOW()),
    ('SEK', CURRENT_DATE,  36.40, 1, NOW()),
    ('NOK', CURRENT_DATE,  35.09, 1, NOW()),
    ('DKK', CURRENT_DATE,  52.38, 1, NOW()),
    ('JPY', CURRENT_DATE,   2.1414, 1, NOW()),
    ('CAD', CURRENT_DATE, 250.00, 1, NOW()),
    ('AUD', CURRENT_DATE, 240.38, 1, NOW()),
    ('CNY', CURRENT_DATE,  49.26, 1, NOW()),
    ('RUB', CURRENT_DATE,   4.2735, 1, NOW()),
    ('UAH', CURRENT_DATE,   7.7519, 1, NOW()),
    ('TRY', CURRENT_DATE,   7.7190, 1, NOW())
ON CONFLICT (currency_code, rate_date) DO NOTHING;
