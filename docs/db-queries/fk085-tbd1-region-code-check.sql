-- =============================================================================
-- FK-085 TBD-1 — region_code ellenőrző lekérdezések
-- =============================================================================
-- JELLEG: KIZÁRÓLAG OLVASÓ (read-only) lekérdezések.
-- A pipeline EZT NEM FUTTATJA. Éles futtatás kizárólag a prod-ops szabályok
-- szerint, kézzel, megfelelő jogosultsággal és körültekintéssel végezhető.
-- Forrás: commit d57532737ac052fbe2114620442c20a5f5b1be7c (FK-085 TBD-1).
-- =============================================================================

-- FK-085 TBD-1: aktív fiókok, amelyeket a dashboard a "Régió nincs beállítva"
-- csoportba sorolna (darabszám).
SELECT count(*) FROM branch
WHERE is_active = true AND (region IS NULL OR btrim(region) = '');

-- FK-085 TBD-1: ugyanaz a halmaz soronként, azonosítókkal és adatokkal.
SELECT id, code, name, city, region, region_code
FROM branch
WHERE is_active = true AND (region IS NULL OR btrim(region) = '')
ORDER BY code;

-- region_code a készlet-snapshot ismert térképen kívül
-- (10/20/40/50/63/75/120/145).
-- MEGJEGYZÉS: a pénztárak NULL region_code-ja TERVEZETT viselkedés (V250),
-- és NEM hibajelenség.
SELECT id, code, name, region_code FROM branch
WHERE is_active = true AND region_code IS NOT NULL
  AND region_code NOT IN ('10','20','40','50','63','75','120','145')
ORDER BY code;
