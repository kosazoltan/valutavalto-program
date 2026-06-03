# Automatikus Média-Feldolgozó Passz (2026-06-02)

## Cél

Az `Anti/`, `Felmérés/`, `forrasok/` source-of-truth mappák médiafájljainak automatikus, gépi feldolgozása:

- teljes média-leltár (kép/hang/videó),
- technikai metadata (méret, felbontás, időtartam),
- duplikátum-analízis (SHA-256),
- eredmények visszavezetése az EXCMD dokumentációba.

## Futtatott automatikus passz

- Fájlbejárás: `Anti/`, `Felmérés/`, `forrasok/`
- Media kiterjesztés-készlet: kép + hang + videó
- Metadata-forrás: `ffprobe`
- Duplikátum-képzés: SHA-256 hash

## Eredmény összegzés

- Összes médiafájl: **1519**
- Képfájl: **1511**
- Hangfájl: **8**
- Videófájl: **0**
- Duplikátum-csoportok: **381**
- `ffprobe` feldolgozási hiba: **0**

Kiterjesztés szerinti bontás:

- `.png`: 910
- `.jpg`: 488
- `.jpeg`: 90
- `.gif`: 16
- `.m4a`: 8
- `.bmp`: 7

## Generált artefaktok

- `EXCMD/_inventory/media-manifest-2026-06-02.csv`
- `EXCMD/_inventory/media-summary-2026-06-02.json`
- `EXCMD/_inventory/media-duplicates-2026-06-02.json`
- `EXCMD/_inventory/media-selected-non-duplicate-2026-06-02.csv`
- `EXCMD/_inventory/media-ocr-results-2026-06-02.jsonl`
- `EXCMD/_inventory/media-asr-results-2026-06-02.json`
- `EXCMD/_inventory/media-content-summary-2026-06-02.json`
- `EXCMD/_inventory/media-asr-transcripts-2026-06-02/`
- `EXCMD/_compare/2026-06-02-media-module-content-extracts.md`
- `EXCMD/media-module-extracts/2026-06-02-*-media-kivonat.md`

## Hangfájlok (forrásfaktum)

Az automatikus passz 8 darab `.m4a` állományt talált, amelyek 4 egyedi felvétel duplikációi a Felmérés mappastruktúrában.

- `Hang 002_sd.m4a`: 10553.051 s
- `Hang 003_sd.m4a`: 625.197 s
- `Hang 004_sd.m4a`: 5171.270 s
- `Hang 005_sd.m4a`: 2634.675 s

## Duplikátum-finding

A forrásfában jelentős számú azonos médiafájl van (elsősorban `Anti/`, `_extracted`, `_extracted_auto`, `forrasok/` és kamera/old snapshot ágak között). Ez alátámasztja, hogy a korábbi duplikációs megállapítások a médiahalmazon is fennállnak.

## OCR/ASR kimenet (2026-06-02)

- Nem-duplikált kiválasztott média: **403**
- Kiválasztott kép: **399**
- Kiválasztott hang: **4**
- OCR feldolgozott: **399**
- OCR szöveges találat: **204**
- OCR hiba/üres: **101**
- ASR feldolgozott: **4**
- ASR hiba: **0**

## Korlátok (tényalapú)

- A gépen a GPU ASR futtatás CUDA runtime DLL hiány miatt (`cublas64_12.dll`) nem volt stabilan végrehajtható.
- Emiatt a véglegesített ASR kivonat CPU (`int8`) futásból készült.
- Az ASR feldolgozás célzottan az első **300 másodpercre** (5 perc) korlátozott minden egyedi hangfájlon.