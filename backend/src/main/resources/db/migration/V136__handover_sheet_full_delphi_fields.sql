-- V136: HandoverSheet kibővítés — Delphi ATADOLAP 93 mezős struktúra
-- Legacy: _etData[] tömb [1-93] → relációs + JSONB mezők

-- Átadó/Átvevő (legacy [3-4])
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS handed_over_by VARCHAR(100);
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS received_by VARCHAR(100);

-- Pénzkészlet egyezés (legacy [5-7])
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS cash_balance_matches BOOLEAN;
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS cash_balance_deviation NUMERIC(15,0);

-- Tartozások (legacy [8-16]) — max 3 tétel JSONB
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS debts JSONB DEFAULT '[]'::jsonb;

-- Követelések (legacy [17-25]) — max 3 tétel JSONB
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS claims JSONB DEFAULT '[]'::jsonb;

-- WU/ÁFA rendelések (legacy [26-31]) — max 2 tétel JSONB
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS wu_vat_orders JSONB DEFAULT '[]'::jsonb;

-- Banki beszállítás (legacy [32-47]) — max 4 tétel JSONB
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS bank_inbound_shipments JSONB DEFAULT '[]'::jsonb;

-- Banki kiszállítás (legacy [48-59]) — max 4 tétel JSONB
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS bank_outbound_shipments JSONB DEFAULT '[]'::jsonb;

-- Pénztári rendelések (legacy [60-79]) — max 4 tétel JSONB
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS cash_desk_orders JSONB DEFAULT '[]'::jsonb;

-- Körlevelek (legacy [80-91]) — max 4 tétel JSONB
ALTER TABLE handover_sheet ADD COLUMN IF NOT EXISTS circulars JSONB DEFAULT '[]'::jsonb;
