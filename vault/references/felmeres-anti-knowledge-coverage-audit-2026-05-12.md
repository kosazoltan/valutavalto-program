---
title: Felmeres es Anti legacy tudaslefedettsegi audit
date: 2026-05-12
type: reference
priority: P0
source_detail: docs/architecture/felmeres-anti-knowledge-coverage-audit-2026-05-12.md
status: active
---

# Felmeres es Anti legacy tudaslefedettsegi audit

Ez a referencia a 2026-05-12-i mely audit memoriaba emelt rovid, de donteshozatalra alkalmas valtozata. Teljes reszletes bizonyitek:

- `docs/architecture/felmeres-anti-knowledge-coverage-audit-2026-05-12.md`

## Fo kovetkeztetes

A repo memoriaja mukodik es jelentos tudas van benne, de a legacy program nincs minden reszeben teljes binaris/kod/adatformat melysegben feldolgozva.

Hasznalhato memoria alap van:

- QMD memoria: OK
- YAML memoria: OK
- Cognee/SQLite memoria: OK
- vault es Obsidian mirror fajlok: OK
- Cognee service: healthy, `status: ready`, `version: 0.5.6-local`

Nyitott problema:

- Live Obsidian REST plugin nem elerheto a 27123/27124 portokon, `fetch failed`.

## SQLite tudasbazis meretek

Forras:

- `docs/valuta-knowledge.sqlite`
- `docs/valuta-kb-ingest-filesystem.py`

Tabla meretek:

| Tabla | Sor |
| --- | ---: |
| `source_artifacts` | 39648 |
| `artifact_ingest_runs` | 61167 |
| `artifact_text_extracts` | 20473 |
| `felmeres_docs` | 431 |
| `legacy_binary_inventory` | 2157 |
| `legacy_dll_parity_matrix` | 41 |
| `firebird_db_artifacts` | 92 |
| `knowledge_gaps` | 3719 |

Source root osszesito:

| Source root | Artefaktum | Meret |
| --- | ---: | ---: |
| `Anti` | 39159 | 6233706295 byte |
| `Felmeres` | 459 | 1034839093 byte |
| `RepoDocs` | 30 | 204221 byte |

Fontos: az ingest script sajat megjegyzese szerint nem teljes OCR/ASR/deep content extraction, hanem inventory es ingest ledger. Ezert a magas coverage szamok nem jelentik automatikusan, hogy minden kep, audio, EXE/DLL, DAT es Firebird DB teljesen meg van ertve.

## Felmeres\Valuta audit

Vizsgalt mappa:

- `D:\repo\valutavalto-program\Felmérés\Valuta`

Leltar:

- 416 fajl
- kb. 986.90 MB

Top-level:

| Mappa | Fajl | Meret |
| --- | ---: | ---: |
| `Cégcsoport felmérése` | 102 | 377.56 MB |
| `Hálózati és számítógép felmérés` | 37 | 11.33 MB |
| `Kósa Szervezés` | 131 | 397.90 MB |
| `Kósa Tervezés és fejlesztés` | 46 | 194.74 MB |
| `Szervezés` | 6 | 3.36 MB |
| `v2.0` | 90 | 1.42 MB |

Fobb tartalom:

- arfolyamkeszito kovetelmenyek es hibak,
- igenyfelmeresi interjuk,
- `c.docm.docx`, `sztorno.docx`, `zaras_ablak.docx`,
- `v2.0\Markdown\valuta_folyamatok` folyamatmodell,
- halozati es szamitogep felmeres,
- forgalom/keszlet/atlagarfolyam/kezelesi koltseg spreadsheet-ek,
- kepernyokepek, bizonylatkepek, 8 hangfelvetel.

Nyitott Felmeres gap-ek:

| Gap | Darab |
| --- | ---: |
| `asr-needed` | 8 |
| `ocr-needed` | 10 |
| `not-ingested` archive | 2 |

Kovetkeztetes: a Felmeres memoriaja nem ures es nem felszines, de az audio/kep/archive bizonyitekokat P0 uzleti dontes elott gap-zarni kell.

## Anti audit

Vizsgalt mappa:

- `D:\repo\valutavalto-program\Anti`

Leltar:

- 32960 fajl
- kb. 5944.94 MB

Top-level:

| Mappa | Fajl | Meret | EXE | DLL | PAS | DFM | DPR |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `SZERVER` | 25985 | 4204.88 MB | 1135 | 700 | 2881 | 2875 | 1430 |
| `camera3` | 3124 | 421.74 MB | 20 | 2 | 0 | 0 | 0 |
| `VALUTA` | 3049 | 328.23 MB | 155 | 129 | 420 | 419 | 279 |
| `camera2` | 461 | 211.46 MB | 2 | 0 | 0 | 0 | 0 |
| `ARFOLYAM` | 10 | 3.48 MB | 2 | 0 | 0 | 0 | 0 |

Top kiterjesztesek:

- `.pas`: 3301
- `.dfm`: 3294
- `.java`: 3228
- `.dpr`: 1709
- `.exe`: 1326
- `.dll`: 831
- `.dat`: 305

Legacy binary inventory:

- 2157 EXE/DLL elofordulas.
- Fontos klaszterek: `rates`, `rates-sync`, `server-core`, `server-receptor`, `vault-transfer`, `closing`, `customer-aml`, `denomination`, `western-union`, `camera`, `firebird-runtime`.

Anti coverage kritikus szamok:

| Tema | Coverage |
| --- | ---: |
| `firebird-schema-and-db-artifacts` | 26.09% |
| `server-import-receptor` | 39.36% |
| `dat-file-formats` | 39.48% |
| `camera-core` | 40.25% |
| `treasury-vault-transfer` | 46.96% |
| `rates-rate-publication` | 48.67% |
| `closing-daily-monthly-yearly` | 49.45% |

Anti gap-ek:

| Gap | Darab |
| --- | ---: |
| `metadata-only-binary` | 2157 |
| `ocr-needed` | 1069 |
| `format-clue-only` | 305 |
| `not-ingested` | 113 |
| `schema-clue-only` | 55 |

Kovetkeztetes: az Anti jol leltarozott es sok source-level elemzes van, de nem teljes binaris/deep adatformat reverse engineering. Ahol forras van, ott source-level olvasas a fo igazsag; ahol csak EXE/DLL van, ott PE strings/import/resource/decompiler elemzes kell.

## Kozponti helyi munkaallomas dontes

Az arfolyamkeszito irany helyes:

- kulon helyi Electron alkalmazas,
- foertektaros kesziti az arfolyamot,
- szerver csak hitelesitett atvevo, validalo, auditáló, publikalo es terito,
- penztarak automatikusan olvassak az aktualis arfolyamot.

Kozponti helyi munkaallomasba valo modulok:

- arfolyamkeszito,
- zaras beerkezes dashboard,
- beerkezett adatok attekintese,
- MNB/Raiffeisen/Darius/compliance riportok,
- atlagarfolyam es arfolyameltérés,
- WU/AFA/TRB/storno audit,
- dolgozok, jutalek, tranzakcios dijak,
- iroda/korzet/ertektar torzs,
- bank import/export,
- ugyfel/jogi szemely/okmany/belso ellenori toolok,
- bizalmas/nevtelen bejelentes,
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

- valuta vetel/eladas/konverzio,
- helyi napnyitas/napzaras,
- helyi keszlet es cimlet,
- bizonylat/nyomtatas,
- ugyfelazonositas/scanner,
- arfolyam csak olvasas/beolvasas.

Nem portolando kozvetlenul:

- `userin.dll` legacy login,
- direkt Firebird credential Electronban,
- direkt `C:\receptor` fajlmutacio operator UI-bol,
- FTP mint fo modern publish path,
- hardcoded `SYSDBA`/jelszavak.

## Kotelezo P0 gap-zaras

1. Felmeres OCR: 10 kep.
2. Felmeres ASR: Hang 002-005 eredeti/duplikalt statusz osszevezetes.
3. Felmeres archivum: 2 not-ingested archive kibontas.
4. Anti P0 binary/source drilldown: rates, receptor, closing, vault-transfer, AML, denomination, Firebird.
5. Firebird sema extraction: 55 schema-clue-only gap.
6. DAT/ARF format deep spec: `arfdata.dat`, `ujdata.dat`, `NR*.DAT`, `RM*.ARF`, `AF100.*`, zaro csomagok.
7. Central workstation module manifest: Google OAuth role -> allowed module matrix.
8. Legacy parity tests: minden P0 modulhoz modern acceptance/parity teszt.

## Fejlesztesi szabaly

Minden P0 funkcio csak akkor mondhato legacy-parity complete-nek, ha van:

1. Felmeres kovetelmeny vagy legacy forras.
2. Legacy modul/fajl hivatkozas.
3. Modern service/controller/UI megfeleltetes.
4. Teszt vagy manualis verifikacio.
5. Memoriafrissites.

