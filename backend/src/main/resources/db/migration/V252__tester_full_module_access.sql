-- V252: Tesztelők teljes modul-hozzáférése (Kósa Zoltán user-direktíva, 2026-05-21).
--
-- ELV: "A Főértéktáros, Bali Heni, Kasza Helga, Fabulya Zsuzsa, Borsi Tamás mindenhez
-- hozzáfér, mert ők tesztelik; az összes többi marad a szerepkör szerinti hozzáférés."
--
-- A tesztelők (BALI, KASZA, BORSI, W-S036=Fabulya Zsuzsanna) megkapják azt a kanonikus
-- szerepkör-készletet, amely mind az 5 appMode-ot lefedi:
--   - full (központi)        : foertektar / ugyvezeto (szerver-szerepkör)
--   - rate-maker (árfolyam)  : foertektar / ugyvezeto
--   - penztar / ertektar / ertekszallito : a megfelelő lokális szerepkör (+ szerver-szerepkör)
-- Így a teljes készlet: foertektar, ugyvezeto, penztar, ertektar, ertekszallito.
--
-- DIAGNÓZIS (2026-05-21, prod): BORSI + KASZA már teljes (14 role); BALI-nak hiányzott az
-- ertekszallito; FABULYA-nak (W-S036) csak belso_ellenor + teruleti_vezeto volt → a
-- rate-maker BLOKKOLT volt (nincs foertektar/ugyvezeto). Ez a migráció pótolja a hiányt.
--
-- FONTOS: a tényleges MUNKAKÖR (employee.job_title) változatlan (Bali=Értéktáros stb.) —
-- ez KIZÁRÓLAG a teszteléshez adott bővített belépési hozzáférés, NEM munkakör-módosítás.
-- A többi dolgozó szerepköreit NEM érintjük. Idempotens (ON CONFLICT DO NOTHING).
-- is_primary = false: az elsődleges szerepkört nem írjuk felül.

INSERT INTO worker_role_assignment (worker_id, role_def_id, is_primary)
SELECT w.id, rd.id, FALSE
  FROM worker w
  CROSS JOIN worker_role_def rd
 WHERE w.company_id = (SELECT id FROM company WHERE code = 'EBC')
   AND w.code IN ('BALI', 'KASZA', 'BORSI', 'W-S036')
   AND rd.code IN ('foertektar', 'ugyvezeto', 'penztar', 'ertektar', 'ertekszallito')
ON CONFLICT (worker_id, role_def_id) DO NOTHING;
