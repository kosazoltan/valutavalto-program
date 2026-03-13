INSERT INTO currency (code, name, is_active, created_at) VALUES
('HUF', 'Magyar Forint', true, NOW()),
('EUR', 'Euro', true, NOW()),
('USD', 'US Dollar', true, NOW()),
('GBP', 'Brit Font', true, NOW()),
('CHF', 'Svajci Frank', true, NOW()),
('CZK', 'Cseh Korona', true, NOW()),
('PLN', 'Lengyel Zloty', true, NOW()),
('RON', 'Roman Lej', true, NOW()),
('RSD', 'Szerb Dinar', true, NOW()),
('UAH', 'Ukran Hrivnya', true, NOW())
ON CONFLICT (code) DO NOTHING;