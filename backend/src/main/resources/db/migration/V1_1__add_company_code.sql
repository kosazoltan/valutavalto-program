-- Add code column to company table
ALTER TABLE company ADD COLUMN code VARCHAR(20);

-- Update existing companies with default codes (if any exist)
-- User should update these to actual codes
UPDATE company SET code = 'DEFAULT' WHERE code IS NULL;

-- Make it NOT NULL and UNIQUE after data update
ALTER TABLE company ALTER COLUMN code SET NOT NULL;
CREATE UNIQUE INDEX uk_company_code ON company(code);
