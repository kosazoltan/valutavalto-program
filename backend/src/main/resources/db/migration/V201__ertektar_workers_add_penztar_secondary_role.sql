-- V201: Ertektaros dolgozoknak 'penztar' secondary role hozzaadasa.
--
-- Bug: a Penztar-Setup telepites a W-S011 (Bali Henrietta) dolgozonal
-- "Nincs ebben a programban hasznalhato szerepkore" hibat dob, mert
-- V149 kizarolag 'ertektar' role-t adott, es az ertektar role
-- NEM selectable penztar appMode-ban (AppModeRoleConstants).
--
-- Fix: minden EBC ertektaros (code='ertektar') kap 'penztar'
-- secondary role-t is, igy mindket Electron modban (Penztar + Ertektar)
-- be tudnak lepni. Ez a valos uzleti igeny: kis irodakban az ertektaros
-- penztari munkakat is vegez.

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT wra.worker_id, penztar_role.id, false
FROM worker_role_assignment wra
JOIN worker_role_def ertektar_role ON wra.role_def_id = ertektar_role.id AND ertektar_role.code = 'ertektar'
CROSS JOIN worker_role_def penztar_role
WHERE penztar_role.code = 'penztar'
  AND NOT EXISTS (
    SELECT 1 FROM worker_role_assignment existing
    WHERE existing.worker_id = wra.worker_id
      AND existing.role_def_id = penztar_role.id
  );
