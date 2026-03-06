-- V48: Körlevél típusok, célcsoport, prioritás, csatolmány
-- Legacy: KORLEV DLL — 17+ variáns (FZS, BT, KI, KZ, DA, NEWYEAR, SERVER, VIP, ZALOG)

ALTER TABLE circular ADD COLUMN IF NOT EXISTS circular_type VARCHAR(30) NOT NULL DEFAULT 'GENERAL';
ALTER TABLE circular ADD COLUMN IF NOT EXISTS target VARCHAR(30) NOT NULL DEFAULT 'ALL_BRANCHES';
ALTER TABLE circular ADD COLUMN IF NOT EXISTS priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL';
ALTER TABLE circular ADD COLUMN IF NOT EXISTS target_branch_id UUID;
ALTER TABLE circular ADD COLUMN IF NOT EXISTS target_company_id INTEGER;
ALTER TABLE circular ADD COLUMN IF NOT EXISTS attachment_filename VARCHAR(255);
ALTER TABLE circular ADD COLUMN IF NOT EXISTS attachment_mime_type VARCHAR(100);
ALTER TABLE circular ADD COLUMN IF NOT EXISTS attachment_path VARCHAR(500);
ALTER TABLE circular ADD COLUMN IF NOT EXISTS valid_from DATE;
ALTER TABLE circular ADD COLUMN IF NOT EXISTS valid_to DATE;
ALTER TABLE circular ADD COLUMN IF NOT EXISTS registration_number VARCHAR(50);

CREATE INDEX IF NOT EXISTS idx_circular_type ON circular(circular_type);
CREATE INDEX IF NOT EXISTS idx_circular_target ON circular(target);
CREATE INDEX IF NOT EXISTS idx_circular_priority ON circular(priority);
CREATE INDEX IF NOT EXISTS idx_circular_reg_number ON circular(registration_number);
