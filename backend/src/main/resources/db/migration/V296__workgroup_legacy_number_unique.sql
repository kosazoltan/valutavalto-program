-- FK02-D (FR-15/16): a munkacsoport-sorszám (legacy_group_number) egyedi cégen belül.
-- A duplikált sorszámot eddig csak alkalmazás-szinten (semmi) tiltottuk; DB-szintű parciális
-- UNIQUE index kényszeríti ki, NULL-megengedő (a NULL sorszámú régi sorok nem ütköznek,
-- a Postgres NULL-jai egyediek a UNIQUE index szempontjából — a WHERE feltétel ezt explicitté teszi).
--
-- Megjegyzés: ha a meglévő adatban már van duplikált (company_id, legacy_group_number),
-- az index létrehozása elbukik — ez szándékos: a duplikációt előbb kézzel kell feloldani.

CREATE UNIQUE INDEX IF NOT EXISTS uq_workgroup_legacynum_per_company
    ON rate_workgroup (company_id, legacy_group_number)
    WHERE legacy_group_number IS NOT NULL;
