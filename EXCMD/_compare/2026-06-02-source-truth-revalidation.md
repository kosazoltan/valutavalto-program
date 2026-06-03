# Source-of-Truth Revalidáció (2026-06-02)

## Cél

Az `Anti/`, `Felmérés/`, `forrasok/` könyvtárak teljes fájlállományának újrainventarizálása és az `EXCMD/` utasításdokumentumok forráshivatkozásainak tényszerű ellenőrzése, majd a hibás hivatkozások javítása.

## Gépi audit artefaktok

- `EXCMD/_inventory/source-truth-file-index-2026-06-02.csv`
- `EXCMD/_inventory/source-truth-extension-breakdown-2026-06-02.csv`
- `EXCMD/_inventory/source-truth-audit-summary-2026-06-02.json`
- `EXCMD/_inventory/excmd-source-reference-validation-2026-06-02-v2.csv`
- `EXCMD/_inventory/excmd-source-reference-missing-2026-06-02-v2.csv`

## Tények (újramérés)

- Összes source-of-truth fájl: **41 437**
- `Anti/`: **32 960** fájl
- `Felmérés/`: **416** fájl
- `forrasok/`: **8 061** fájl

## EXCMD hivatkozás-audit eredmény

- Ellenőrzött EXCMD dokumentumok: `*.md`, `*.txt`
- Kinyert forráshivatkozások száma: **661**
- Nem létező forráshivatkozás: **0**

## Javított fájlok (konkrét korrekciók)

1. `EXCMD/legacy/00-VALUTA-modul-terkep.md`
	- `Anti/VALUTA/DLL/*` -> `Anti/VALUTA/DLL/`
2. `EXCMD/legacy/04-ERTEKTAR-SZERVER-modul-terkep.md`
	- `Anti/SZERVER/_extracted/*` -> `Anti/SZERVER/_extracted/`
3. `EXCMD/legacy/modules/ADATLAP.md`
	- Ambivalens szöveg helyett explicit mappaút: `Anti/VALUTA/DLL/` és `Anti/SZERVER/_extracted/VALUTA/DLL/`
4. `EXCMD/legacy/modules/AFATABLA.md`
	- Ambivalens szöveg helyett explicit mappaút: `Anti/VALUTA/DLL/` és `Anti/SZERVER/_extracted/VALUTA/DLL/`
5. `EXCMD/legacy/modules/ARFDISP.md`
	- Ambivalens szöveg helyett explicit mappaút: `Anti/VALUTA/DLL/` és `Anti/SZERVER/_extracted/VALUTA/DLL/`
6. `EXCMD/legacy/modules/ARFREG.md`
	- Ambivalens szöveg helyett explicit mappaút: `Anti/VALUTA/DLL/` és `Anti/SZERVER/_extracted/VALUTA/DLL/`
7. `EXCMD/legacy/modules/ARFTMK.md`
	- Ambivalens szöveg helyett explicit mappaút: `Anti/VALUTA/DLL/` és `Anti/SZERVER/_extracted/VALUTA/DLL/`

## Megjegyzés

Ez a kör a forrásfájlok teljes leltárát és az EXCMD-forráshivatkozások konzisztenciáját zárta le. A media-típusú (kép/hang/video) tartalmak tényszerű jelenléte a teljes indexben szerepel, és az EXCMD oldalon a hivatkozási integritás jelen állapotban hibamentes.

## Média-feldolgozó passz (automatikus)

A source-of-truth körre lefutott külön automatikus média-passz is, amely a teljes médiakészletre technikai metadata és duplikátum-analízist készített.

- Forrás: `Anti/`, `Felmérés/`, `forrasok/`
- Feldolgozott médiafájl: **1519**
- Képfájl: **1511**
- Hangfájl: **8**
- Videófájl: **0**
- Duplikátum-csoport: **381**
- `ffprobe` hiba: **0**

Média artefaktok:

- `EXCMD/_inventory/media-manifest-2026-06-02.csv`
- `EXCMD/_inventory/media-summary-2026-06-02.json`
- `EXCMD/_inventory/media-duplicates-2026-06-02.json`

Részletes riport:

- `EXCMD/_compare/2026-06-02-media-processing-pass.md`

## OCR/ASR visszavezetés státusz

A nem-duplikált médiakészletre a tartalmi passz elkészült, és az eredmények modulonként vissza lettek vezetve EXCMD artefaktokba.

- Nem-duplikált kiválasztás: **403** elem
- OCR: **399** kép feldolgozva
- ASR: **4** hangfeldolgozás, **0** ASR hiba
- Modul-index: `EXCMD/_compare/2026-06-02-media-module-content-extracts.md`
- Modul-kivonatok: `EXCMD/media-module-extracts/2026-06-02-*-media-kivonat.md`

Kapcsolódó inventory artefaktok:

- `EXCMD/_inventory/media-selected-non-duplicate-2026-06-02.csv`
- `EXCMD/_inventory/media-ocr-results-2026-06-02.jsonl`
- `EXCMD/_inventory/media-asr-results-2026-06-02.json`
- `EXCMD/_inventory/media-content-summary-2026-06-02.json`

Megjegyzés:

- A GPU ASR útvonal CUDA runtime DLL hiány (`cublas64_12.dll`) miatt ezen a környezeten nem volt stabil; a végső ASR eredmények CPU (`int8`) futásból származnak.
