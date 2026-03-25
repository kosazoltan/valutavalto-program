-- V119: Fix Hungarian accents in currency names
-- Fixes: V70 seed data had missing accents (Svajci->Svájci, Dan->Dán, etc.)

UPDATE currency SET name = 'Svájci Frank' WHERE code = 'CHF' AND (name = 'Svajci Frank' OR name LIKE 'Sv_jci%');
UPDATE currency SET name = 'Román Lej' WHERE code = 'RON' AND (name = 'Roman Lej' OR name LIKE 'Rom_n%');
UPDATE currency SET name = 'Svéd Korona' WHERE code = 'SEK' AND (name = 'Sved Korona' OR name LIKE 'Sv_d%');
UPDATE currency SET name = 'Norvég Korona' WHERE code = 'NOK' AND (name = 'Norweg Korona' OR name LIKE 'Norv_g%');
UPDATE currency SET name = 'Dán Korona' WHERE code = 'DKK' AND (name = 'Dan Korona' OR name LIKE 'D_n Korona%');
UPDATE currency SET name = 'Japán Jen' WHERE code = 'JPY' AND (name = 'Japan Jen' OR name LIKE 'Jap_n%');
UPDATE currency SET name = 'Kanadai Dollár' WHERE code = 'CAD' AND (name = 'Kanadai Dollar' OR name LIKE 'Kanadai Doll_r%');
UPDATE currency SET name = 'Ausztrál Dollár' WHERE code = 'AUD' AND (name = 'Ausztal Dollar' OR name = 'Ausztral Dollar' OR name LIKE 'Ausztr_l%');
UPDATE currency SET name = 'Kínai Jüan' WHERE code = 'CNY' AND (name = 'Kinai Juan' OR name LIKE 'K_nai%');
UPDATE currency SET name = 'Orosz Rubel' WHERE code = 'RUB' AND name = 'Orosz Rubel';
UPDATE currency SET name = 'Ukrán Hrivnya' WHERE code = 'UAH' AND (name = 'Ukran Hrivnya' OR name LIKE 'Ukr_n%');
UPDATE currency SET name = 'Török Líra' WHERE code = 'TRY' AND (name = 'Torok Lira' OR name LIKE 'T_r_k%');
UPDATE currency SET name = 'Szlovák Korona' WHERE code = 'SKK' AND (name = 'Szlovak Korona' OR name LIKE 'Szlov_k%');
UPDATE currency SET name = 'Lengyel Zloty' WHERE code = 'PLN' AND name = 'Lengyel Zloty';
UPDATE currency SET name = 'US Dollár' WHERE code = 'USD' AND (name = 'US Dollar' OR name LIKE 'US Doll_r%');
UPDATE currency SET name = 'Brit Font' WHERE code = 'GBP' AND name = 'Brit Font';
UPDATE currency SET name = 'Euró' WHERE code = 'EUR' AND (name = 'Euro' OR name LIKE 'Eur_%');
