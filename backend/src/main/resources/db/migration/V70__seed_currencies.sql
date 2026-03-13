INSERT INTO currency (id, code, name, is_active, created_at) VALUES
(gen_random_uuid(), 'HUF', 'Magyar Forint', true, NOW()),
(gen_random_uuid(), 'EUR', 'Euro', true, NOW()),
(gen_random_uuid(), 'USD', 'US Dollár', true, NOW()),
(gen_random_uuid(), 'GBP', 'Brit Font', true, NOW()),
(gen_random_uuid(), 'CHF', 'Svájci Frank', true, NOW()),
(gen_random_uuid(), 'CZK', 'Cseh Korona', true, NOW()),
(gen_random_uuid(), 'PLN', 'Lengyel Zloty', true, NOW()),
(gen_random_uuid(), 'RON', 'Román Lej', true, NOW()),
(gen_random_uuid(), 'RSD', 'Szerb Dinár', true, NOW()),
(gen_random_uuid(), 'UAH', 'Ukrán Hrivnya', true, NOW())
ON CONFLICT DO NOTHING;
