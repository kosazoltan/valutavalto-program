---
type: audit
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Missing-knowledge audit after full filesystem inventory ingest"
load: on-demand
---

# Knowledge Gap Audit

> Adatforras: `docs/valuta-knowledge.sqlite`
> Ledger reference: `docs/knowledge/source-ledger.md`

---

## G1 FO_MEGALLAPITAS

A teljes filesystem inventory bent van, es az `Anti` ingest azota ket nagy lepest tett:

- a text-heavy legacy allomanyok searchable extractet kaptak
- a `binary-pe`, `firebird-db`, `image`, `pdf` es `.dat` csaladok metadata/clue extractet kaptak
- kulon `import-config-clues` reteget kaptak a relevans import-konfigok

Ez azt jelenti, hogy az `Anti` oldal mar **nem 0%-os** a legtobb kritikus temaban, de a maradek gap-ek jellege most mar sokkal pontosabban ismert.

---

## G2 GLOBALIS_GAP_SZAMOK

Jelenlegi gap-mennyisegek:

| Gap type | Darab | Jelentes |
|----------|------:|----------|
| `metadata-only-binary` | `2 157` | PE binaryknel mar van keresheto clue, de nincs mely import-table vagy dekompilacios rekonstrukcio |
| `ocr-tooling-missing` | `1 442` | kep/PDF metadata bent van, de a gepen nincs telepitett OCR motor |
| `format-clue-only` | `305` | DAT fajloknal mar van formatum- es import clue, de nincs teljes parser |
| `not-ingested` | `115` | archivum vagy tovabbi pipeline-lepest igenylo forras |
| `schema-clue-only` | `55` | Firebird fajloknal schema clue mar van, de nincs strukturalt tabela/field parser |
| `asr-needed` | `8` | audio/video atirat szukseges |

---

## G3 ANTI_LEGMELYEBB_RESEK

Jelenleg legalacsonyabb fedettsegu `Anti` temak:

| Topic | Seen | Indexed | Blocked | Coverage |
|-------|-----:|--------:|--------:|---------:|
| `firebird-schema-and-db-artifacts` | `2 093` | `546` | `184` | `26.09%` |
| `server-import-receptor` | `4 812` | `1 894` | `146` | `39.36%` |
| `dat-file-formats` | `3 609` | `1 425` | `238` | `39.48%` |
| `camera-core` | `9 639` | `3 880` | `1 212` | `40.25%` |
| `western-union` | `959` | `437` | `75` | `45.57%` |
| `customers-aml-kyc` | `1 239` | `582` | `111` | `46.97%` |

Kovetkeztetes:

- a legnagyobb vakfolt mar nem a teljes indexhiany, hanem a melyebb szemantikai rekonstrukcio hianya
- a kovetkezo nagy nyereseg a `Firebird`, `binary imports/symbols`, illetve a valodi `OCR/ASR` iranyokbol jon

---

## G4 FELMERES_MEGMARADT_HIANYOK

A `Felmérés` fa tovabbra is jobb allapotban van, de maradnak konkret hianyok:

| Topic | Seen | Indexed | Blocked | Coverage |
|-------|-----:|--------:|--------:|---------:|
| `audio-video-transcripts` | `8` | `6` | `8` | `75.0%` |
| `survey-requirements` | `459` | `414` | `188` | `90.2%` |
| `reservations-booking` | `219` | `205` | `170` | `93.61%` |
| `receipts-printing` | `39` | `37` | `35` | `94.87%` |

Maradek fo hianyok:

- kepek/PDF-ek valodi OCR-je
- hanganyagok ASR-e
- nehany archive/pdfs tovabbi feldolgozasa

---

## G5 MIT_KELL_KOVETKEZONEK_FELDOLGOZNI

Prioritas szerint:

1. `Firebird` parser-melyites
   - schema clue -> tabla/field/generator/trigger strukturalt rekonstrukcio
2. `PE binary` import/symbol parser-melyites
   - metadata clue -> import table / domain string / modulkapcsolat bontas
3. `OCR` toolchain telepites
   - a `1 442` darab `ocr-tooling-missing` gap csokkentesehez
4. `ASR` transcript pipeline
   - a `8` darab `asr-needed` gap bezarasahoz
5. archive verification pass
   - a `115` darab `not-ingested` gap lezarasahoz

---

## G6 DEPLOY_ES_IMPLEMENTACIO_STOP

Jelen audit alapjan tovabbra sem korrekt:

- implementaciot veglegesnek nevezni
- parity-t teljesnek nevezni
- ujraepitesi tervet 100%-osnak allitani

Mert bar az `Anti` mar nem `0%` a kritikus teruleteken, a melyebb schema/import/OCR/ASR retegek meg hianyoznak.

---

## G7 SIKERKRITERIUM_A_KOVETKEZO_FAZISHOZ

A kovetkezo ingest fazis akkor tekintheto sikeresnek, ha legalabb:

- a `schema-clue-only` Firebird gap-ek egy resze strukturalt schema extractte valik
- a `metadata-only-binary` PE gap-ek egy resze import/symbol rekonstrukcios szintre lep
- az `ocr-tooling-missing` gap-ek telepites utan tenyleges OCR gappe alakulnak vagy csokkennek
- a `dat-file-formats` es `server-import-receptor` tovabb emelkedik a jelenlegi ~`39%` savbol
