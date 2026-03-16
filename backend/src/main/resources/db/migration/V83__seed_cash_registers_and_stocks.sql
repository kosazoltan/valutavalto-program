-- V83: Seed additional cash register branches + currency stock test data
-- Scope (INS-070): pénztárak, valutakészletek, árfolyamok

-- 1) Ensure required dictionary values exist
INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_STATUS', 'ACTIVE', 'Active', 'Aktiv', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'BRANCH_TYPE', 'PENZTAR', 'Cash Office', 'Penztar', 4, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

INSERT INTO dictionary (id, category, code, name, name_hu, sort_order, is_active, created_at)
VALUES (gen_random_uuid(), 'COUNTRY', 'HU', 'Hungary', 'Magyarorszag', 1, true, NOW())
ON CONFLICT (category, code) DO NOTHING;

-- 2) Ensure EBC company exists
INSERT INTO company (id, name, code, is_active, created_at)
VALUES (gen_random_uuid(), 'Exclusive Best Change Zrt.', 'EBC', true, NOW())
ON CONFLICT (code) DO NOTHING;

-- 3) Seed an additional cash office (pénztár)
INSERT INTO branch (
  id, company_id, name, code, bank_code, city, address, zip_code,
  opening_date, is_active, branch_type_did, country_did, branch_status_did, created_at
)
SELECT
  gen_random_uuid(), c.id,
  'Korut', 'KORUT', 'KORUT', 'Szeged', 'Korut 22, Szeged', '6722',
  CURRENT_DATE, true,
  (SELECT id FROM dictionary WHERE category = 'BRANCH_TYPE'   AND code = 'PENZTAR'),
  (SELECT id FROM dictionary WHERE category = 'COUNTRY'       AND code = 'HU'),
  (SELECT id FROM dictionary WHERE category = 'BRANCH_STATUS' AND code = 'ACTIVE'),
  NOW()
FROM company c
WHERE c.code = 'EBC'
ON CONFLICT (code) DO NOTHING;

-- 4) Seed cash balances for both cash offices
INSERT INTO cash_balance (
  company_id, branch_id, currency_id, current_balance, opening_balance,
  min_balance, max_balance, last_transaction_at, created_at, updated_at
)
SELECT
  c.id,
  b.id,
  cur.id,
  seed.current_balance,
  seed.opening_balance,
  seed.min_balance,
  seed.max_balance,
  NOW(),
  NOW(),
  NOW()
FROM company c
JOIN branch b ON b.company_id = c.id
JOIN (
  VALUES
    ('TISZA', 'HUF', 2500000::DECIMAL(15,2), 2000000::DECIMAL(15,2), 1500000::DECIMAL(15,2), 6000000::DECIMAL(15,2)),
    ('TISZA', 'EUR',    8500::DECIMAL(15,2),    7000::DECIMAL(15,2),    3000::DECIMAL(15,2),   15000::DECIMAL(15,2)),
    ('TISZA', 'USD',    6000::DECIMAL(15,2),    5000::DECIMAL(15,2),    2000::DECIMAL(15,2),   12000::DECIMAL(15,2)),
    ('KORUT', 'HUF', 1800000::DECIMAL(15,2), 1500000::DECIMAL(15,2), 1000000::DECIMAL(15,2), 4500000::DECIMAL(15,2)),
    ('KORUT', 'EUR',    5200::DECIMAL(15,2),    4500::DECIMAL(15,2),    1800::DECIMAL(15,2),   10000::DECIMAL(15,2)),
    ('KORUT', 'USD',    4100::DECIMAL(15,2),    3600::DECIMAL(15,2),    1500::DECIMAL(15,2),    9000::DECIMAL(15,2))
) AS seed(branch_code, currency_code, current_balance, opening_balance, min_balance, max_balance)
  ON seed.branch_code = b.code
JOIN currency cur ON cur.code = seed.currency_code AND cur.is_active = true
WHERE c.code = 'EBC'
ON CONFLICT (branch_id, currency_id) DO UPDATE SET
  current_balance = EXCLUDED.current_balance,
  opening_balance = EXCLUDED.opening_balance,
  min_balance = EXCLUDED.min_balance,
  max_balance = EXCLUDED.max_balance,
  last_transaction_at = EXCLUDED.last_transaction_at,
  updated_at = NOW();

-- 5) Seed WAC stock for profit tracking
INSERT INTO currency_stock (
  company_id, entity_type, entity_id, currency_code, quantity, weighted_avg_cost, last_updated
)
SELECT
  c.id,
  'CASHIER',
  b.id::VARCHAR(36),
  seed.currency_code,
  seed.quantity,
  seed.weighted_avg_cost,
  NOW()
FROM company c
JOIN branch b ON b.company_id = c.id
JOIN (
  VALUES
    ('TISZA', 'EUR', 8500::DECIMAL(15,2), 388.70::DECIMAL(12,4)),
    ('TISZA', 'USD', 6000::DECIMAL(15,2), 338.20::DECIMAL(12,4)),
    ('KORUT', 'EUR', 5200::DECIMAL(15,2), 389.10::DECIMAL(12,4)),
    ('KORUT', 'USD', 4100::DECIMAL(15,2), 338.80::DECIMAL(12,4))
) AS seed(branch_code, currency_code, quantity, weighted_avg_cost)
  ON seed.branch_code = b.code
WHERE c.code = 'EBC'
ON CONFLICT (company_id, entity_type, entity_id, currency_code) DO UPDATE SET
  quantity = EXCLUDED.quantity,
  weighted_avg_cost = EXCLUDED.weighted_avg_cost,
  last_updated = NOW();

-- 6) Seed branch-level exchange rates for current day if missing
INSERT INTO exchange_rate (
  company_id, branch_id, currency_id, valid_date, valid_time,
  base_buy_rate, base_sell_rate,
  limit1_amount, limit1_buy_rate, limit1_sell_rate,
  limit2_amount, limit2_buy_rate, limit2_sell_rate,
  official_rate, is_active, created_by, created_at
)
SELECT
  c.id,
  b.id,
  cur.id,
  CURRENT_DATE,
  CURRENT_TIME,
  seed.buy_rate,
  seed.sell_rate,
  seed.limit1_amount,
  seed.limit1_buy,
  seed.limit1_sell,
  seed.limit2_amount,
  seed.limit2_buy,
  seed.limit2_sell,
  seed.middle_rate,
  true,
  'SYSTEM',
  NOW()
FROM company c
JOIN branch b ON b.company_id = c.id
JOIN (
  VALUES
    ('EUR', 392.16, 386.28, 398.04, 1000, 387.50, 396.80, 5000, 388.70, 395.60),
    ('USD', 342.47, 335.62, 349.31, 1000, 336.90, 347.95, 5000, 338.20, 346.60),
    ('GBP', 454.55, 443.18, 465.91,  500, 445.00, 464.00, 2000, 447.00, 462.00)
) AS seed(currency_code, middle_rate, buy_rate, sell_rate, limit1_amount, limit1_buy, limit1_sell, limit2_amount, limit2_buy, limit2_sell)
  ON true
JOIN currency cur ON cur.code = seed.currency_code AND cur.is_active = true
WHERE c.code = 'EBC'
  AND b.code IN ('TISZA', 'KORUT')
  AND NOT EXISTS (
    SELECT 1
    FROM exchange_rate er
    WHERE er.company_id = c.id
      AND er.branch_id = b.id
      AND er.currency_id = cur.id
      AND er.valid_date = CURRENT_DATE
  );
