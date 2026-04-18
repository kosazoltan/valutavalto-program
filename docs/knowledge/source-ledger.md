---
type: ledger
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Source Ledger for Anti and Felmeres Ingestion"
load: on-demand
---

# Source Ledger

> Adatforras: `docs/valuta-knowledge.sqlite`
> Ingest script: `docs/valuta-kb-ingest-filesystem.py`
> Schema: `docs/knowledge/knowledge-base-architecture.md`

---

## S1 CEL

Ez a ledger nem tematikus elemzes, hanem bizonyitek arra, hogy:

1. milyen forrasfakat lattunk
2. mennyi artefaktot vettunk leltarba
3. milyen formatumcsaládokban
4. milyen ingest-allapottal
5. mi lett deduplikalva
6. mi maradt tovabbi feldolgozasra

---

## S2 GLOBALIS_OSSZESITO

Az aktualis ingest eredmenye:

- `source_artifacts`: `39 635`
- `artifact_dedup_groups`: `13 486`
- `artifact_ingest_runs`: `59 702`
- `artifact_text_extracts`: `20 076`
- `knowledge_coverage`: `38`
- `knowledge_gaps`: `4 082`

Forrasgyokerek szerint:

| Source root | Artefakt darab |
|-------------|---------------:|
| `Anti` | `39 159` |
| `Felmeres` | `459` |
| `RepoDocs` | `17` |

---

## S3 ANTI_FORRASLELTAR

Az `Anti` fa jelenlegi inventoryja:

| Format family | Darab | Megjegyzes |
|---------------|------:|------------|
| `other` | `14 804` | vegyes legacy artefaktok, ismeretlen vagy altalanos formatumok |
| `directory` | `6 200` | teljes mappastruktura is nyilvantartva |
| `delphi-project` | `5 003` | `.dpr`, `.dpk`, `.dfm`, `.dproj`, `.inc` |
| `java` | `3 304` | legacy Java/camera es sidecar projektek |
| `pascal` | `3 301` | `.pas` forrasok |
| `binary-pe` | `2 157` | `.exe`, `.dll` |
| `text` | `1 610` | `.txt`, `.ini`, `.cfg`, stb. |
| `image` | `1 254` | kepek, screenshotok, grafikai bizonyitekok |
| `word` | `556` | `doc/docx/docm/rtf/odt` |
| `structured-text` | `524` | `json/xml/yaml` |
| `spreadsheet` | `147` | `xls/xlsx/ods` |
| `archive` | `113` | `zip/7z/rar/cab/arj/tar/gz` |
| `html` | `91` | html dokumentaciok/exportok |
| `firebird-db` | `55` | `fdb/gdb/db/sqlite` |
| `pdf` | `24` | pdf dokumentumok |
| `markdown` | `8` | markdown anyagok |
| `csv` | `8` | csv mintak/exportok |

Lathato top-level bizonyitekok:

- `ARFOLYAM.zip`
- `camera-20260306T145042Z-1-001.zip`
- `camera.zip`
- `forrasok.7z`
- `KESZLEX.zip`
- `korlevel.zip`
- `old.zip`

Ez megerositi, hogy az inventory nem csak a mar kibontott tukroket, hanem a forrasarchivumokat is latja.

---

## S4 FELMERES_FORRASLELTAR

A `Felmérés` fa jelenlegi inventoryja:

| Format family | Darab | Megjegyzes |
|---------------|------:|------------|
| `image` | `178` | screenshotok, scanszeru es vizualis bizonyitekok |
| `word` | `92` | survey/interju/kovetelmeny dokumentumok |
| `markdown` | `45` | `v2.0` export vagy konvertalt folyamatleirasok |
| `html` | `45` | `v2.0` figdoc/HTML exportok |
| `directory` | `43` | teljes survey struktura |
| `spreadsheet` | `32` | XLS/XLSX/ODS |
| `audio` | `8` | hangfajlok, ASR-celpontok |
| `text` | `7` | TXT riportok es mintak |
| `csv` | `4` | operativ exportok |
| `pdf` | `2` | PDF dokumentumok |
| `archive` | `2` | archiv anyag |
| `other` | `1` | egyeb formatum |

Kulonosen ertekes csoportok:

- `Valuta/v2.0/Markdown/`
- `Valuta/v2.0/HTML/`
- `Valuta/Cégcsoport felmérése/.../Dokumentumok/`

---

## S5 INGEST_STATUSZOK

Az `artifact_ingest_runs` jelenlegi allapota:

| Ingest status | Darab | Jelentes |
|---------------|------:|----------|
| `completed` | `54 648` | inventory, text extract, metadata extract vagy clue-pass sikeresen rogzitve |
| `blocked` | `2 212` | kezdeti inventory allapot, legacy binary/DB jelleggel |
| `ocr-required` | `1 432` | korabbi inventory-jelzes kep/PDF oldalon |
| `partial` | `1 281` | metadata-only vagy OCR-tooling-hiany miatti reszleges ingest |
| `archive-expand-required` | `115` | archivum, kulon kibontas vagy verifikacio kell |
| `asr-required` | `8` | hang/video transcript pipeline kell |
| `failed` | `6` | torteneti, mar javitott futasok az ingest historyban |

Megjegyzes:

- a ledger-szintu `completed` nem azt jelenti, hogy mar teljesen megfejtettuk a legacy logikat
- csak azt, hogy a forrasleltarban es a keresheto ingest-ledgerben rogzitve van

---

## S6 EXTRACT_RETEG

Az `artifact_text_extracts` mar nem csak survey bootstrapot tartalmaz, hanem valodi `Anti` ingestet is.

Legnagyobb extract-tipusok az `Anti` fán:

| Extract type | Darab |
|--------------|------:|
| `fulltext` | `13 756` |
| `binary-metadata` | `2 157` |
| `import-config-clues` | `1 613` |
| `image-metadata` | `1 254` |
| `office-xml` | `464` |
| `dat-metadata` | `305` |
| `firebird-metadata` | `55` |
| `pdf-text` | `16` |
| `pdf-metadata` | `8` |

Ez azt jelenti, hogy az `Anti` oldal mar nem csak inventory-szinten van bent, hanem:

- text-heavy forrasokkal
- binary import/symbol clue-kkal
- Firebird schema clue-kkal
- DAT/import/config clue-kkal
- image/PDF metadata vagy text extractekkel

---

## S7 DEDUP_BIZONYITEK

Jelenlegi dedup-csoportszam:

- `13 486`

Hasznalt logikak:

- `same-hash`
- `canonical_path` normalizalas
- `_extracted`, `_extracted_auto`, `*_unpacked` csaladok

Ez azt jelenti, hogy a `39 635` inventory-rekord mar egy deduplikalt logikai retegre ul ra, es nem tekinti kulon vilagnak az archive-derived tukroket.

---

## S8 GAP_RETEG

A jelenlegi gap-eloszlas mar az uj ingest-fokozatokat koveti:

| Gap type | Darab | Jelentes |
|----------|------:|----------|
| `metadata-only-binary` | `2 157` | PE binaryknel mar van keresheto import/symbol clue, de nincs dekompilacios vagy import-table parser szint |
| `ocr-tooling-missing` | `1 442` | kep/PDF artefaktokhoz a metadata mar bent van, de nincs telepitett OCR motor |
| `format-clue-only` | `305` | DAT csaladnal van formatum- es import clue, de nincs teljes rekordszintu parser |
| `not-ingested` | `115` | archivum vagy tovabbi kibontasi ellenorzes kell |
| `schema-clue-only` | `55` | Firebird fajloknal schema clue mar van, de nincs adatbazis-szintu strukturalt parser |
| `asr-needed` | `8` | audio/video transcript pipeline tovabbra is hianyzik |

---

## S9 MIT_NEM_ALLITHATUNK_MEG

Ez a ledger **nem** allitja:

- hogy az `Anti` es `Felmeres` teljes szemantikai tartalma mar ertelmezve van
- hogy a binary/PDF/image/audio anyagok mar teljesen es veglegesen szovegge lettek alakitva
- hogy a parity vagy a programterv mar teljes

Ez csak azt allitja bizonyithatoan, hogy:

- a forrasok nagy reszet mar leltarba vettuk
- az ingest-ledger tobbelepcsos, bizonyithato allapotra jutott
- a tovabbi feldolgozas pontos gap-listaval folytathato
