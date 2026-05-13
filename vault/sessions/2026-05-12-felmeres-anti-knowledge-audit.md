---
date: 2026-05-12
type: knowledge-audit
scope:
  - D:\repo\valutavalto-program\Felmérés\Valuta
  - D:\repo\valutavalto-program\Anti
status: captured
priority: P0
related:
  - docs/architecture/felmeres-anti-knowledge-coverage-audit-2026-05-12.md
  - docs/architecture/central-workstation-legacy-module-inventory.md
  - docs/architecture/local-rate-maker-architecture.md
---

# 2026-05-12 Felmeres + Anti tudaslefedettsegi audit

Felhasznaloi kontextus:

- A felhasznalo kerte a `Felmérés\Valuta` es `Anti` teljes ellenorzeset.
- Gyanú: a legacy program nincs eleg melyen, binaris szinten feldolgozva.
- Keres: ne programozzunk, csak mely audit es memoriafrissites.
- Obsidian helyben elinditva, de a repo `memory:status` szerint a live REST plugin tovabbra sem elerheto a 27123/27124 portokon.

## Donto megallapitas

A repo memoriaja nem ures es nem rossz: van QMD, YAML, Cognee/SQLite, vault es Obsidian mirror tudasa. A Cognee service healthy. Viszont a legacy es felmeresi tudas nem teljesen lezart:

- `Felmeres` root: 459 KB artefaktum, `Felmérés\Valuta`: 416 fajl, kb. 986.90 MB.
- `Anti`: 32960 fajl, kb. 5944.94 MB.
- SQLite `source_artifacts`: 39648 sor.
- SQLite `legacy_binary_inventory`: 2157 EXE/DLL.
- Anti gap-ek: 2157 metadata-only-binary, 1069 OCR-needed, 305 format-clue-only, 113 not-ingested, 55 schema-clue-only.
- Felmeres gap-ek: 8 ASR-needed, 10 OCR-needed, 2 not-ingested archive.

## Kovetkeztetes

A keszrefejleszteshez a jelenlegi memoria eleg eros alap, de minden P0 funkciohoz kell legacy-parity bizonyiteklanc:

1. Felmeresi kovetelmeny vagy legacy forras.
2. Legacy modul/fajl.
3. Modern backend/frontend/Electron megfeleltetes.
4. Teszt vagy manualis verifikacio.
5. Memoriafrissites.

## Kozponti helyi munkaallomas dontes megerositve

A kulon helyi Electron munkaallomas iranya helyes:

- A foertektaros helyi arfolyamkeszito/workstation appban dolgozik.
- A szerver nem allandoan nyitott szerkeszto, hanem hitelesitett API, validalo, auditáló, publikalo es terito kozpont.
- A penztarak automatikusan beolvassak az aktualis arfolyamot.
- Google OAuth + backend RBAC/ABAC modul-manifeszt kell.

Central workstation modulok:

- arfolyamkeszito,
- zaras beerkezes dashboard,
- beerkezett adatok attekintese,
- MNB/Raiffeisen/Darius/compliance riportok,
- atlagarfolyam es arfolyameltérés,
- WU/AFA/TRB/storno audit,
- dolgozok, jutalek, tranzakcios dijak,
- iroda/korzet/ertektar torzs,
- bank import/export,
- ugyfel/jogi szemely/okmany/belso ellenori es bizalmas riport modulok,
- korlevel.

Szerveren marad:

- receptor ingest,
- unpacker/dekoder,
- adatbazis/migracio/evnyitas,
- rate publication authority,
- audit/idempotencia,
- outbox/WebSocket/polling terites,
- backup es report materialization.

Penztari kliensben marad:

- vetel/eladas/konverzio,
- helyi napnyitas/napzaras,
- helyi keszlet es cimlet,
- bizonylat/nyomtatas,
- ugyfelazonositas/scanner,
- arfolyam csak olvasas/beolvasas.

## Elsodleges uj memoriafajl

Teljes reszletes audit:

- `docs/architecture/felmeres-anti-knowledge-coverage-audit-2026-05-12.md`

