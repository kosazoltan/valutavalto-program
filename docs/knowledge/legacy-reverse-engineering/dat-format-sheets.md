---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Byte-Level Format Sheets for ARFDATA.DAT and FOGLALO.DAT"
load: on-demand
---

# Byte-Level Format Sheets for `ARFDATA.DAT` and `FOGLALO.DAT`

> Fontos: ez a lap **bizonyitek-alapu formatumlap**, nem teljesen visszaellenorzott binaris parser-spec. Ahol nincs valos minta/hex dump, ott a sor `inferred` vagy `unknown`.

---

## S1 ARFDATA_DAT

### Szerep

- kozponti arfolyam-kikuldési artefakt
- legacy eloallito: `MNBArfKikuldo` / `ArfdataIras`
- legacy szallitas: FTP
- modern megfelelo: rate publish pipeline

### Bizonyitekallapot

| Allitas | Status | Forras |
|---------|--------|--------|
| binaris fajl | confirmed | `RateCreationService` legacy javadoc |
| rates publish artefakt | confirmed | `RateCreationService`, legacy docs |
| FTP terites | confirmed | `RateCreationService`, import knowledge base |
| XOR 255 hasznalat | inferred | rates/camera implementation plans, nincs parser-bizonyitek |
| 28 valuta x 9 oszlop x 4 property | inferred | `IMPLEMENTATION_PLAN_CAMERA_AND_RATES.md` |
| header verziok 15/16 | inferred | `IMPLEMENTATION_PLAN_CAMERA_AND_RATES.md` |
| konkret byte offsetok | unknown | nincs binaris minta a workspace-ben |

### Fajlszintu lap

| Mezo | Ertek |
|------|-------|
| canonical name | `ARFDATA.DAT` / `arfdata.dat` |
| rokon fajlok | `old_arfdata.dat`, `ujdata.dat`, `ARFDATA.TMP` |
| tipikus hely | `Anti/ARFOLYAM/` |
| eloallito | `ArfdataIras`, `MNBArfKikuldo` |
| fogyaszto | penztarak, rate-import/update path |

### Byte-level format sheet

| Offset | Size | Type | Status | Jelentes |
|--------|------|------|--------|----------|
| `0x00..?` | unknown | header | inferred | verzio vagy csomagmeta lehet |
| header utan | unknown | repeated rate block | inferred | 28 valuta blokk |
| per valuta | unknown | repeated fields | inferred | 9 rate column / valuta |
| per mező | unknown | scalar | inferred | egyes leirasok 4 property-rendszert emlitenek |
| tail | unknown | checksum/footer? | unknown | nincs bizonyitek |

### Ami biztosan nem keverendo ide

- a `GETARF` formatum **szoveges**, pontosvesszovel tagolt
- a `RateFileParserService` ezt a text formatumot kezeli
- ez **nem** bizonyitja az `ARFDATA.DAT` byte layoutjat

### Mintafajl helyek

- `Anti/ARFOLYAM/arfdata.dat`
- `Anti/ARFOLYAM/old_arfdata.dat`
- `Anti/ARFOLYAM/ujdata.dat`

### Nyitott kerdesek

1. A teljes file XOR-olt vagy csak egyes szakaszok?
2. Van-e fix fejlec `version`, `count`, `groupCount` mezokkel?
3. A 28/9/4 allitas hogyan fordul byte szintre: int16, int32 vagy packed decimal?
4. Ugyanaz a formatum-e az `ARFDATA.DAT`, `arfdata.dat` es az `ARFDATA.TMP`?

---

## S2 FOGLALO_DAT

### Szerep

- foglalo/reservation allapot export a KESZLEX vilagban
- keszlet exporthoz kapcsolt kiegeszito adat
- modern megfelelo: `Reservation` domain + snapshot/export logic

### Bizonyitekallapot

| Allitas | Status | Forras |
|---------|--------|--------|
| binaris fajl | confirmed | KESZLEX spec, inventory prompt |
| stringek XOR 255-tel kodoltak | confirmed | `2026-03-16-keszlex-stock-export-design.md` |
| nested structure: penztar -> foglalok | confirmed | ugyanott |
| foglalo osszeg `int32` | confirmed | ugyanott |
| devizanem string | confirmed | ugyanott |
| int32 little-endian | inferred | Delphi/Windows konvencio, nincs explicit parser |
| string framing | unknown | nincs Pascal parser snippet |

### Logikai struktura

| Sorrend | Elem | Status |
|---------|------|--------|
| 1 | penztardarab | confirmed |
| 2 | penztar szam | confirmed |
| 3 | penztar nev | confirmed |
| 4 | korzet | confirmed |
| 5 | foglalodarab | confirmed |
| 6 | foglalonkent osszeg `int32` | confirmed |
| 7 | foglalonkent devizanem string | confirmed |

### Byte-level format sheet

| Offset | Size | Type | Status | Jelentes |
|--------|------|------|--------|----------|
| `0x00..?` | unknown | count | inferred | penztardarab mező |
| after count | unknown | branch record | confirmed logical / unknown binary | egy penztar blokk kezdete |
| branch field 1 | unknown | numeric | inferred | `ptszam` |
| branch field 2 | unknown | XOR string | confirmed | `ptnev` |
| branch field 3 | unknown | XOR string or numeric | inferred | `korzet` |
| branch field 4 | unknown | count | inferred | `foglalodarab` |
| reservation field 1 | 4 | `int32` | confirmed | osszeg |
| reservation field 2 | unknown | XOR string | confirmed logical / unknown binary | devizanem |

### Mintafajl hely

- `Anti/SZERVER/_extracted_auto/SZERVER/_extracted/SZERVER/fejleszt/makeszlt/keszlex_unpacked/FOGLALO.DAT`

### Nyitott kerdesek

1. A count mezok 1, 2 vagy 4 byte-on vannak?
2. A stringek Pascal shortstring, length-prefixed vagy null-terminated formatumuak?
3. A `korzet` byte-szinten numeric kod vagy XOR-olt text?
4. Van-e record padding vagy alignment?

---

## S3 MINIMUM_REVERSE_ENGINEERING_WORKPLAN

1. valodi mintafajlok SHA-256 rogzítese
2. elso 256 byte hex dump es XOR-elotti/XOR-utani nezet
3. valutanem-stringek es ismert branch-nevek alapjan anchor keresese
4. Delphi/Pascal forrasban `BlockRead`, `AssignFile`, `rewrite`, `reset`, `XOR 255`, `foglalo`, `arfdatairas` mintak keresese
5. formatumlap frissitese `confirmed` offsetekkel
