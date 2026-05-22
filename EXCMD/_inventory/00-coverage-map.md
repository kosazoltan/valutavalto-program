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
