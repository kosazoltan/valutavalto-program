-- KESZLEX legacy körzet kód hozzáadása a branch táblához
-- Legacy körzetek: Szekszárd=10, Szeged=20, Kecskemét=40, Debrecen=50,
-- Nyíregyháza=63, Békéscsaba=75, Pécs=120, Kaposvár=145
ALTER TABLE branch ADD COLUMN region_code VARCHAR(10);

CREATE INDEX idx_branch_region_code ON branch(region_code);

COMMENT ON COLUMN branch.region_code IS 'Legacy körzet kód (KESZLEX): 10,20,40,50,63,75,120,145';
