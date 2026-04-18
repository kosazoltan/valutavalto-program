---
type: architecture
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Knowledge Base Rollout and Migration"
load: on-demand
---

# Knowledge Base Rollout

> Kapcsolodo schema: `docs/knowledge/knowledge-base-architecture.md`
> Migracios script: `docs/valuta-kb-migrate.py`

---

## S1 CEL

A rollout celja, hogy a jelenlegi `docs/valuta-knowledge.sqlite` adatbazis fokozatosan bovuljon:

1. a meglevo keresesi kepessegek megtartasa mellett
2. auditálható ingest-lanccal
3. deduplikalt forrasleltarral
4. topiconkenti coverage- es gap-bizonyitekkal

---

## S2 BEVEZETESI_SORREND

1. schema migracio
2. meglevo `felmeres_docs` es `agent_knowledge_segments` bootstrap
3. topic seedeles
4. baseline dedup-csoportok
5. baseline coverage es gap rekordok
6. keresesi script bovites
7. teljes `Anti` ingest
8. teljes `Felmeres` ingest
9. OCR/ASR ingest
10. domain-matrixok visszakotese forras artifactokra

---

## S3 MI MARAD KOMPATIBILIS

Meglevo reteg, amit nem torunk el:

- `felmeres_docs`
- `felmeres_fts`
- `agent_knowledge_segments`
- `agent_knowledge_segments_fts`
- domain matrix tablák

Elv:

- a rollout additive legyen
- a korabbi kereso tovabbra is fusson
- az uj audit-reteg a meglevo tartalmakat is visszafuzo bootstrapet kapjon

---

## S4 MIGRACIOS_LEPESEK

### 1. Schema létrehozás

A `docs/valuta-kb-migrate.py` letrehozza:

- `source_artifacts`
- `artifact_dedup_groups`
- `artifact_dedup_members`
- `artifact_ingest_runs`
- `artifact_text_extracts`
- `topics`
- `artifact_topics`
- `segment_topics`
- `knowledge_coverage`
- `knowledge_gaps`
- `ingest_checkpoints`
- `kb_schema_meta`

### 2. Bootstrap

A script:

- osszekoti a `felmeres_docs` rekordokat `artifact_id`-kkel
- letrehozza a kezdo `artifact_text_extracts` rekordokat
- hozzakoti az `agent_knowledge_segments` sorokat az uj artifact reteghez
- kezdo topic linkeket general heurisztikaval

### 3. Baseline audit

A script:

- coverage baseline-t szamol
- gap baseline-t general
- checkpointot rogzit

---

## S5 KERESO_BOVITES

A `docs/valuta-kb-search.py` scriptet az uj schemahoz kell igazitani ugy, hogy:

- schema summary-t tudjon mutatni
- source root statisztikat tudjon kiirni
- nyitott gap-eket tudjon listazni
- coverage adatokat tudjon mutatni

---

## S6 KOVETKEZO_INGEST_FAIZSOK

### Anti ingest

- teljes canonical inventory
- originals vs `_extracted` vs `_extracted_auto`
- db, binaris, source, archive, DAT csaladok

### Felmeres ingest

- direkt text ingest
- survey `.docx`
- `v2.0` html/markdown exportok
- operativ csv/txt mintak
- screenshot/pdf inventory
- audio/video inventory es transcript pipeline

---

## S7 ELFOGADASI_FELTETELEK

A rollout akkor tekintheto sikeresnek, ha:

1. a schema migracio lefut a jelenlegi adatbazison
2. a meglevo dokumentumok bootstrapelve vannak az uj artefakt-retegbe
3. minden knowledge segmenthez visszamutathato `artifact_id` tartozik
4. a dedup-csoportok es gap-ek lekerdezhetok
5. a kereso script legalabb alapszinten latja az uj audit reteg szamait

---

## S8 NEM_ALLITHATO

A rollout utan sem allithato automatikusan, hogy a tudastar teljes.

Csak ez allithato:

- milyen forrasokat lattunk
- melyeket ingestaltuk
- melyeket tettuk kereshetove
- melyek maradtak nyitott gap-kent

Ez a dokumentum szandekosan a bizonyithatosagot teszi a teljességi allitas ele.
