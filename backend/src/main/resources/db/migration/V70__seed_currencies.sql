-- V70: Currency seed data
-- Schema verified: id=BIGSERIAL(auto), NOT NULL: is_active, code, created_at, decimal_places, name
-- decimal_places: HUF=0, JPY=0, others=2

INSERT INTO currency (code, name, decimal_places, is_active, created_at) VALUES
('HUF', 'Magyar Forint', 0, true, NOW()),
('EUR', 'Euro', 2, true, NOW()),
('USD', 'US Dollar', 2, true, NOW()),
('GBP', 'Brit Font', 2, true, NOW()),
('CHF', 'Svajci Frank', 2, true, NOW()),
('CZK', 'Cseh Korona', 2, true, NOW()),
('PLN', 'Lengyel Zloty', 2, true, NOW()),
('RON', 'Roman Lej', 2, true, NOW()),
('SEK', 'Sved Korona', 2, true, NOW()),
('NOK', 'Norweg Korona', 2, true, NOW()),
('DKK', 'Dan Korona', 2, true, NOW()),
('JPY', 'Japan Jen', 0, true, NOW()),
('CAD', 'Kanadai Dollar', 2, true, NOW()),
('AUD', 'Ausztal Dollar', 2, true, NOW()),
('CNY', 'Kinai Juan', 2, true, NOW()),
('RUB', 'Orosz Rubel', 2, true, NOW()),
('UAH', 'Ukran Hrivnya', 2, true, NOW()),
('TRY', 'Torok Lira', 2, true, NOW()),
('SKK', 'Szlovak Korona', 2, false, NOW())
ON CONFLICT (code) DO NOTHING;
