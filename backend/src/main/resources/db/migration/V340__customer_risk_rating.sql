-- FS-2 (MNB ajánlás): ügyfél kockázati besorolás — 3 fokozat, default LOW.
ALTER TABLE customer ADD COLUMN IF NOT EXISTS risk_rating VARCHAR(10) NOT NULL DEFAULT 'LOW';
