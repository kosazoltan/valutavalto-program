# Felmérés/Valuta — fájl-leltár + lefedettség-térkép

> Generálva: 2026-05-22. Forrás: `EXCMD/_inventory/file-inventory.csv` (416 fájl).

## Összegzés

- **Összes forrásfájl:** 416
- **A 27 EXCMD spec által név szerint hivatkozott:** 41
- **Nem hivatkozott — derivált/duplikált (v2.0 md/html stb.):** 88
- **Nem hivatkozott — PRIMER, feldolgozandó:** 287

## Feldolgozandó primer források típus szerint

| Típus | Db | Megjegyzés |
|---|---|---|
| jpeg | 89 | képernyőkép (új vagy variáns) |
| docx | 77 | követelmény/interjú/spec dokumentumok |
| jpg | 63 | képernyőkép |
| png | 19 | képernyőkép |
| xlsx | 19 | táblázatok (árfolyam/címlet/adatszerk.) |
| m4a | 8 | **hangfelvétel — átirat kell** |
| csv | 4 | adatkivonat |
| ods | 3 | táblázat (ODF) |
| txt | 2 | szöveges |
| odt | 2 | dokumentum (ODF) |
| zip | 1 | archív |

## Megjegyzés a hatókörhöz

A korábbi 27 EXCMD spec (b1–b10) a **fő funkcionális modulokat** fedi (váltás, foglaló, zárás, AML/szankció, RFM, riportok, munkavállaló, beállítások). A fenti **primer feldolgozandó** halmaz a részletes/kiegészítő forrásanyag (interjúk, követelménylisták, táblázatok, további képernyők, hangfelvételek), amit a user-direktíva (2026-05-22: "mindent egyenként") szerint egyenként EXCMD-spekké alakítunk, összevetünk, és a talált gap-eket implementáljuk.

**Batch-terv:** (1) docx/txt/odt szöveges követelmények → specek; (2) xlsx/ods/csv táblázatok → adat/funkció-specek; (3) új képernyőképek → UI-specek; (4) m4a hangfelvételek → átirat majd spec.

## 2026-06-02 automatizált média-passz (kiterjesztett source-of-truth)

A teljes source-of-truth körre (`Anti/`, `Felmérés/`, `forrasok/`) külön médiafeldolgozó passz futott metadata + duplikátum analízissel.

- Összes médiafájl: 1519
- Artefaktok:
	- `EXCMD/_inventory/media-manifest-2026-06-02.csv`
	- `EXCMD/_inventory/media-summary-2026-06-02.json`
	- `EXCMD/_inventory/media-duplicates-2026-06-02.json`
- Részletes riport: `EXCMD/_compare/2026-06-02-media-processing-pass.md`

## 2026-06-02 OCR/ASR tartalmi kivonat státusz

A nem-duplikált médiahalmazra célzott OCR/ASR passz készült.

- Nem-duplikált kiválasztott elemszám: **403**
- OCR: **399** kép
- ASR: **4** hangfájl
- ASR ablak: első **300 mp** / hangfájl

Generált artefaktok:

- `EXCMD/_inventory/media-selected-non-duplicate-2026-06-02.csv`
- `EXCMD/_inventory/media-ocr-results-2026-06-02.jsonl`
- `EXCMD/_inventory/media-asr-results-2026-06-02.json`
- `EXCMD/_inventory/media-content-summary-2026-06-02.json`
- `EXCMD/_compare/2026-06-02-media-module-content-extracts.md`
- `EXCMD/media-module-extracts/2026-06-02-*-media-kivonat.md`
