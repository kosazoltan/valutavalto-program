---
type: implementation-plan
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Windows OCR toolchain installation and integration plan for Anti and Felmeres ingestion"
load: on-demand
---

# OCR Toolchain Installation And Integration Plan

## O1 CEL

A jelenlegi Python kornyezetben a `pytesseract`, `PIL` es `fitz` mar elerheto, de a futtathato `tesseract` motor nincs telepitve.

Ezert a cel:

1. reprodukalhato Windows OCR telepitesi lepesek meghatarozasa
2. a jelenlegi `docs/valuta-kb-extract-media-metadata.py` pipeline-hoz valo illesztes leirasa
3. az `ocr-tooling-missing` gap-ek lezarasahoz szukseges allapotgep rogzitese

---

## O2 AKTUALIS_HELYZET

Jelenlegi allapot:

- Python package: `pytesseract` elerheto
- image/PDF metadata pipeline: elerheto
- PDF text extraction: elerheto, ha van beagyazott szoveg
- raster OCR: nincs, mert a `tesseract` binaris nincs a PATH-on

Aktualis gap kovetkezmeny:

- `ocr-tooling-missing`: `1 442`

---

## O3 JAVASOLT_WINDOWS_TELEPITES

Javasolt alaptelepites:

1. `Tesseract OCR` Windows binary telepitese
2. nyelvi csomagok telepitese:
   - `hun.traineddata`
   - `eng.traineddata`
3. PATH vagy explicit konfiguracio beallitasa

Javasolt elvart mappaszerkezet:

- `C:\\Program Files\\Tesseract-OCR\\tesseract.exe`
- `C:\\Program Files\\Tesseract-OCR\\tessdata\\hun.traineddata`
- `C:\\Program Files\\Tesseract-OCR\\tessdata\\eng.traineddata`

Elfogadhato alternativa:

- ha a PATH nem modositott, akkor a script egy konfiguracios valtozobol is olvashatja a binaris helyet

---

## O4 VALIDACIOS_LEPESEK

Telepites utan a minimum ellenorzes:

```powershell
tesseract --version
tesseract --list-langs
```

Elvart eredmeny:

- a `tesseract` parancs fut
- a `hun` es `eng` nyelvek listazva vannak

Python oldali ellenorzes:

```python
import pytesseract
print(pytesseract.get_tesseract_version())
```

---

## O5 INTEGRACIOS_PONTOK

Erintett fo fajl:

- `docs/valuta-kb-extract-media-metadata.py`

Mar meglevo integracios pontok:

- `tesseract_available()`
- `try_image_ocr()`
- `extract_pdf_text_or_metadata()`
- `rebuild_gaps()`

Szukseges kovetkezo modositasok:

1. explicit Tesseract path tamogatasa
   - pl. kornyezeti valtozo vagy script-szintu konstans
2. oldalankenti OCR tamogatas image-only PDF-ekhez
3. `image-metadata` -> `ocr` upgrade logika
4. `pdf-metadata` -> `ocr` vagy `pdf-text` upgrade logika

---

## O6 JAVASOLT_STATUSZ_ATMENETEK

Az ingest statusz logika javasolt frissitese:

- telepites elott:
  - `image-metadata` + `ocr-tooling-missing`
  - `pdf-metadata` + `ocr-tooling-missing`
- telepites utan, de OCR nelkul:
  - `ocr-needed`
- sikeres OCR utan:
  - `completed`

Javasolt gap-lezaras:

- ha `extract_type='ocr'` letrejott, az adott artefakt `ocr-tooling-missing` gapje lezarhato

---

## O7 PDF_OCR_TERV

PDF-eknel ket ag kell:

1. ha a PDF mar tartalmaz beagyazott szoveget:
   - marad `pdf-text`
2. ha csak kepoldalak vannak:
   - oldal render -> kep -> OCR -> osszefuzott transcript

Javasolt `extract_type` ertekek:

- `pdf-text`
- `pdf-ocr`
- `ocr`

---

## O8 KOCKAZATOK

- Windows PATH geprol gepre elterhet
- magyar nyelvi csomag hianya eros minosegromlast okoz
- gyenge minosegu scaneknel az OCR text csak reszleges lesz
- kepes PDF oldalaknal a render felbontas befolyasolja az eredmenyt

---

## O9 SIKERFELTETELEK

Az OCR integracio akkor tekintheto sikeresnek, ha:

- a `tesseract_available()` mar `True`
- az `ocr-tooling-missing` gap-ek csokkennek
- az `image-metadata` extractek egy resze `ocr` extractre bovul
- a `pdf-metadata` extractek egy resze `pdf-ocr` vagy `ocr` extractre valtozik
