-- V90: Add highRiskFlag fields to customer table
-- AML: ha az ügyfél éves göngyölt összege eléri a limitet → high risk jelölés
ALTER TABLE customer ADD COLUMN IF NOT EXISTS high_risk_flag BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE customer ADD COLUMN IF NOT EXISTS high_risk_reason VARCHAR(500);
ALTER TABLE customer ADD COLUMN IF NOT EXISTS high_risk_set_at TIMESTAMP;
