# OCR + MD korrekcio + YAML (Jammo) fejlec - Portolhato playbook

## Cel
Ez a dokumentum egy teljes, ujrafuttathato modszertan arra, hogyan vigyel vegig egy legacy + media (kep/hang) feldolgozasi csomagot egy masik repositoryban.

A kimenet celja:
- forrasallomany-index es coverage
- OCR/ASR tartalomkivonat
- EXCMD-szeru modulspec MD-k
- YAML (Jammo) fejlec konzisztencia
- hivatkozas-audit javitas
- AI-ugynokoknek futtathato ticket/spec/teszt/kod batch

## Mi tortent ebben a repoban (osszefoglalo)
1. Felmeresre kerult a teljes EXCMD allomany es a source-of-truth forrasok.
2. OCR/ASR passz keszult a media allomanyokra.
3. Letrejottek a media module extract fajlok (modulonkenti kivonatok).
4. YAML fejlecek (frontmatter) lettek hozzaadva az erintett spec fajlokhoz.
5. Uj spec fajlok keszultek a hianyzo modulokra.
6. A hivatkozas-auditban talalt elteresek javitva lettek.
7. Generalva lett teljes AI munkacsomag az osszes EXCMD modulra.
8. Generalva lett priorizalt szelet (Magas kockazat + explicit FR).

## Elokeszites egy masik repohoz

### 1) Konyvtarstruktura minimum
Hozz letre hasonlo strukturat:
- EXCMD/
- EXCMD/_inventory/
- EXCMD/_compare/
- EXCMD/media-module-extracts/
- EXCMD/_ai-protokoll/
- scripts/media/

### 2) Source-of-truth teruletek kijelolese
Definiald a teljes forrashalmaz gyokerkonyvtarait (pl. legacy, media, dokumentumok).

### 3) Eszkozok
- Python 3.x
- Tesseract OCR (Windowson tipikusan: C:/Program Files/Tesseract-OCR/tesseract.exe)
- (opcionalis) Whisper/faster-whisper ASR

## Vegrehajtasi folyamat

### Faza A - Forrasindex es coverage
1. Keszits teljes file-indexet a source-of-truth allomanyokrol.
2. Keszits extension bontast.
3. Keszits source-to-doc coverage mapet (mely forras van emlitve EXCMD-ben).
4. Ments audit summary-t JSON-be.

Javasolt kimenetek:
- EXCMD/_inventory/source-truth-file-index-YYYY-MM-DD.csv
- EXCMD/_inventory/source-truth-extension-breakdown-YYYY-MM-DD.csv
- EXCMD/_inventory/source-to-excmd-name-coverage-YYYY-MM-DD.csv
- EXCMD/_inventory/source-truth-audit-summary-YYYY-MM-DD.json

### Faza B - Media manifest + deduplikacio
1. Generalj media-manifestet (kep/hang/video + meret/hash).
2. Csoportosits hash alapjan duplikatumokat.
3. Valaszd ki a non-duplicate reprezentans elemeket.

Javasolt kimenetek:
- EXCMD/_inventory/media-manifest-YYYY-MM-DD.csv
- EXCMD/_inventory/media-duplicates-YYYY-MM-DD.json
- EXCMD/_inventory/media-selected-non-duplicate-YYYY-MM-DD.csv
- EXCMD/_inventory/media-summary-YYYY-MM-DD.json

### Faza C - OCR/ASR passz
1. Futtasd az OCR-t a kivalasztott kepallomanyokra.
2. Futtasd az ASR-t a kivalasztott hangallomanyokra.
3. Keszits retry reportot az OCR hibakra.
4. Ments eredmenyeket inventory fajlokba.

Javasolt kimenetek:
- EXCMD/_inventory/media-ocr-results-YYYY-MM-DD.jsonl
- EXCMD/_inventory/media-asr-results-YYYY-MM-DD.json
- EXCMD/_inventory/media-ocr-retry-report-YYYY-MM-DD.json
- EXCMD/_inventory/media-content-summary-YYYY-MM-DD.json

### Faza D - Modulonkenti media-kivonatok
1. Keszits modulonkenti MD kivonatot (business/legacy bontasban).
2. Keszits egy osszesito index fajlt.

Javasolt kimenetek:
- EXCMD/media-module-extracts/YYYY-MM-DD-<modul>-media-kivonat.md
- EXCMD/_compare/YYYY-MM-DD-media-module-content-extracts.md

### Faza E - Spec fajlok es YAML (Jammo) fejlec
1. Minden erintett spec fajl ele keruljon egyseges YAML fejlec.
2. Minden hianyzo modult hozz letre uj spec MD-kent.
3. A tartalom kovesse az EXCMD sablont (system_context + functional_spec + FR kodok).

## YAML (Jammo) fejlec minta

```yaml
---
title: "Modul emberi neve"
modul: bX-pelda-modul
kategoria: pelda-kategoria
alkalmazas: penztar-client
szerepokor:
  - ROLE_CASHIER
  - ROLE_TREASURER
forrasok:
  - "Felmérés/.../kep1.jpg"
prio: Kozepes
utolso_frissites: "2026-06-02"
media_eredetu: true
---
```

## Spec tartalom minta

```md
<system_context>
# Modul: ...
## Kontextus
...
## Technologiai stack
...
## Scope
- IN: ...
- OUT: ...
</system_context>

<functional_spec>
### [FR-XXX-01] [Cim]
- Leiras: ...
- Forras: ...
- Prio: Must/Should/Could
- Validaciok: ...
</functional_spec>
```

## Faza F - Hivatkozas-audit es korrekcio
1. Ellenorizd, hogy minden EXCMD forrashivatkozas letezo utvonalra mutat.
2. A wildcard/ambivalens utvonalakat csereld explicit, letezo utvonalra.
3. Frissitsd az audit summary artefaktokat, hogy konzisztens legyen a kep.

Javasolt kimenetek:
- EXCMD/_inventory/excmd-source-reference-validation-YYYY-MM-DD-v2.csv
- EXCMD/_inventory/excmd-source-reference-missing-YYYY-MM-DD-v2.csv
- EXCMD/_compare/YYYY-MM-DD-source-truth-revalidation.md

## Faza G - AI ugynok futtatasi csomag generalasa
1. Keszits modul-regisztert minden EXCMD md-rol.
2. Generalj AI workitemeket (MIC + ticket/spec/teszt/kod prompt).
3. Generalj priorizalt szeletet (pl. Magas + explicit FR).

Javasolt kimenetek:
- EXCMD/_ai-protokoll/all-modules-registry.csv
- EXCMD/_ai-protokoll/ai-workitems.jsonl
- EXCMD/_ai-protokoll/ai-ticket-spec-test-kod-batch.md
- EXCMD/_ai-protokoll/high-priority-explicit-fr.csv
- EXCMD/_ai-protokoll/high-priority-explicit-fr.md

## Repofuggetlen minosegbiztositasi checklist

### A) Teljesseg
- [ ] Source index generalva
- [ ] Coverage map generalva
- [ ] Media manifest generalva
- [ ] OCR/ASR eredmenyek mentve
- [ ] Modul-kivonatok generalva

### B) Konzisztencia
- [ ] Hivatkozas-audit missing = 0
- [ ] Nincs ellentmondo osszegzo JSON/CSV
- [ ] YAML fejlec szabvanyos a spec fajlokban

### C) AI futtathatosag
- [ ] Minden modul benne van a registryben
- [ ] Workitem JSONL ervenyes
- [ ] Priorizalt szelet eloallitva

## Atviteli sablon masik repohoz

1. Masold at a kovetkezo elemeket:
- scripts/media/ OCR/ASR script
- scripts/generate-excmd-ai-pack.py (vagy repo-specifikus valtozata)
- EXCMD sablonfajlok

2. Alakitsd a kovetkezo parametereket:
- source gyokerkonyvtarak
- Tesseract eleresi ut
- modul-detekcios szabalyok
- kockazat-besorolasi szabalyok

3. Futtatasi sorrend:
- source index
- media manifest
- OCR/ASR
- modul extract
- spec + YAML fejlec korrekcio
- hivatkozas-audit fix
- AI pack generalas
- priorizalt szelet

## Tipikus hibak es javitasuk
- OCR null output: nem ASCII fajlutvonal / rossz PSM / timeout tul alacsony.
- ASR lassu vagy hiba: GPU DLL hiany, fallback CPU int8.
- Tulszamlalt modulok: kimeneti mappa onmaga is bekerul a bemenetbe.
- Hamis missing reference: wildcard vagy szoveges utalas explicit path helyett.

## Ebben a repoban hasznalt kulcsfajlok
- EXCMD/AI-fejlesztesi-protokoll.md
- scripts/generate-excmd-ai-pack.py
- EXCMD/_ai-protokoll/all-modules-registry.csv
- EXCMD/_ai-protokoll/ai-workitems.jsonl
- EXCMD/_ai-protokoll/ai-ticket-spec-test-kod-batch.md
- EXCMD/_ai-protokoll/high-priority-explicit-fr.csv
- EXCMD/_ai-protokoll/high-priority-explicit-fr.md

## Zaro megjegyzes
Ez a playbook ugy lett osszerakva, hogy ugyanaz a feladatcsomag egy masik repoban is vegrehajthato legyen minimalis atallitas mellett. A kulcs az, hogy a source-of-truth inventory + audit + frontmatter szabvany + AI workitem generalas egyetlen, reprodukalhato pipeline-kent fusson.