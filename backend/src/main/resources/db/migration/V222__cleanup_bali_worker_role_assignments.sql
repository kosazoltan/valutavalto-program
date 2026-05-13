-- V222: Hotfix — Bali Henriett (W-S011) over-permissive role-assignment cleanup
-- A test/migration során a W-S011 worker MIND a 15 különböző role-assignment-tel rendelkezett
-- (penztar, ertektar, foertektar, ugyvezeto, ...), ami a production-ben security incident:
-- a pénztáros kóddal minden modulba (RFM, Központi) be tudott lépni.
--
-- A user 2026-05-13 18:30 CEST jelentett incidens alapján:
-- - bali.henriett.ebc@gmail.com (W-S011, SUPERVISOR legacy role) → CSAK `penztar` + `foertektar` role
-- - szeged.ebc@gmail.com (G_SZEGED_ET, CASHIER) → CSAK `ertektar` role (jelenleg `penztar` is meg van neki)

-- 1. W-S011 worker: töröljük az ÖSSZES extra role-assignment-et, kivéve `penztar` + `foertektar`-t
DELETE FROM worker_role_assignment wra
USING worker w, worker_role_def rd
WHERE wra.worker_id = w.id
  AND wra.role_def_id = rd.id
  AND w.code = 'W-S011'
  AND rd.code NOT IN ('penztar', 'foertektar');

-- 2. G_SZEGED_ET worker: töröljük a felesleges `penztar` role-assignment-et (csak `ertektar` marad)
DELETE FROM worker_role_assignment wra
USING worker w, worker_role_def rd
WHERE wra.worker_id = w.id
  AND wra.role_def_id = rd.id
  AND w.code = 'G_SZEGED_ET'
  AND rd.code = 'penztar';

-- 3. BALI (id=2) régi inaktív worker — törölhetjük a role_assignment-eket
-- (already is_active=false a worker táblán, de a role-assignment-eknek nincs is_active mezőjük)
DELETE FROM worker_role_assignment wra
USING worker w
WHERE wra.worker_id = w.id
  AND w.code = 'BALI'
  AND w.is_active = false;
