-- Add code column to company table (idempotent)
ALTER TABLE company ADD COLUMN IF NOT EXISTS code VARCHAR(20);

-- Update existing companies with default codes (if any exist)
-- User should update these to actual codes
UPDATE company SET code = 'DEFAULT' WHERE code IS NULL;

-- Make it NOT NULL (only if not already NOT NULL)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'company' AND column_name = 'code' AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE company ALTER COLUMN code SET NOT NULL;
    END IF;
END $$;

-- Create unique index if not exists
CREATE UNIQUE INDEX IF NOT EXISTS uk_company_code ON company(code);
