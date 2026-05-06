-- V185: AML teljes azonositas mezoinek bovitese (2017. evi LIII. tv. 7.ss)
-- Uj mezok: tartózkodási hely (residence), lakcimkartya szama (address_card_number)
ALTER TABLE customer ADD COLUMN IF NOT EXISTS residence VARCHAR(500);
ALTER TABLE customer ADD COLUMN IF NOT EXISTS address_card_number VARCHAR(30);
