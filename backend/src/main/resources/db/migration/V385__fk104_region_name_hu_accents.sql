-- V385 (FK-104 FR-1): accent the REGION dictionary name_hu values.
--
-- The V145 seed wrote the 6 city names without Hungarian accents
-- (Bekescsaba, Nyiregyhaza, Kecskemet, Kaposvar, Pecs, Szekszard).
-- The Terület dropdown shows name_hu, so the report UI displayed the
-- unaccented forms.
--
-- Each UPDATE carries an OLD-VALUE predicate (ticket C8): a row whose
-- name_hu was hand-fixed in production to any third value does NOT
-- match and stays untouched. IRODA/DEBRECEN/SZEGED are already correct
-- and are deliberately absent. No row removal, no other category, no
-- code/name column is touched.
UPDATE dictionary SET name_hu = 'Békéscsaba'
 WHERE category = 'REGION' AND code = 'BEKESCSABA' AND name_hu = 'Bekescsaba';
UPDATE dictionary SET name_hu = 'Nyíregyháza'
 WHERE category = 'REGION' AND code = 'NYIREGYHAZA' AND name_hu = 'Nyiregyhaza';
UPDATE dictionary SET name_hu = 'Kecskemét'
 WHERE category = 'REGION' AND code = 'KECSKEMET' AND name_hu = 'Kecskemet';
UPDATE dictionary SET name_hu = 'Kaposvár'
 WHERE category = 'REGION' AND code = 'KAPOSVAR' AND name_hu = 'Kaposvar';
UPDATE dictionary SET name_hu = 'Pécs'
 WHERE category = 'REGION' AND code = 'PECS' AND name_hu = 'Pecs';
UPDATE dictionary SET name_hu = 'Szekszárd'
 WHERE category = 'REGION' AND code = 'SZEKSZARD' AND name_hu = 'Szekszard';
