-- V275 (FK-04/E): árfolyamvédelem flag a munkacsoport csempén.
--
-- Beküldő: Kasza Helga (Főértéktár) — Árfolyamkészítő fejlesztési kérés #04, E pont.
--
-- Cél: minden munkacsoport árfolyamlapon külön kapcsolható legyen az
-- árfolyamvédelem (vételi oszlopok ≤ J ≤ eladási oszlopok). A flag a csempe
-- jobb felső sarkában elhelyezett checkbox-szal vezérelhető (FK-04 A.3).
-- A tényleges validáció külön PR (E.2) — ez a migráció csak az állapotot
-- tárolja, hogy a UI rögtön perzisztálhassa a kollégák beállításait.
--
-- Default: TRUE (a védelem mindig engedélyezett alapból — elgépelés-védelem
-- biztonsági alapelv; az inaktiváláshoz tudatos felhasználói gesztus kell).
-- Idempotens: ha az oszlop már létezik, a hozzáadás kihagyva.

ALTER TABLE rate_workgroup
    ADD COLUMN IF NOT EXISTS protection_enabled BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN rate_workgroup.protection_enabled IS
    'FK-04/E árfolyamvédelem: ha TRUE, a csoport-lap mentése elutasít olyan rátákat, '
    'ahol vételi (L,N,P,R) > J vagy eladási (M,O,Q,S) < J. A csempe jobb felső checkbox vezérli.';
