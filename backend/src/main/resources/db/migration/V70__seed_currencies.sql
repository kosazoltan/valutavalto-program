INSERT INTO currency (id, code, name, is_active, created_at) VALUES
(gen_random_uuid(), 'HUF', 'Magyar Forint', true, NOW()),
(gen_random_uuid(), 'EUR', 'Euro', true, NOW()),
(gen_random_uuid(), 'USD', 'US Dollar', true, NOW()),
(gen_random_uuid(), 'GBP', 'Brit Font', true, NOW()),
(gen_random_uuid(), 'CHF', 'Svajci Frank', true, NOW()),
(gen_random_uuid(), 'CZK', 'Cseh Korona', true, NOW()),
(gen_random_uuid(), 'PLN', 'Lengyel Zloty', true, NOW()),
(gen_random_uuid(), 'RON', 'Roman Lej', true, NOW()),
(gen_random_uuid(), 'RSD', 'Szerb Dinar', true, NOW()),
(gen_random_uuid(), 'UAH', 'Ukran Hrivnya', true, NOW())
ON CONFLICT DO NOTHING;