---
type: architecture
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Knowledge Base Architecture for Legacy Evidence Ingestion"
load: on-demand
---

# Knowledge Base Architecture

> Cel: a `docs/valuta-knowledge.sqlite` adatbazis kiterjesztese ugy, hogy a legacy tudas ne csak keresheto, hanem auditálható is legyen.
> Migracios script: `docs/valuta-kb-migrate.py`

---

## S1 CEL_ES_ALAPELV

A tudastarban minden allitasnak vissza kell mutatnia:

1. eredeti forrasra
2. ingest-allapotra
3. dedup-dontesre
4. topic-besorolasra
5. bizonyiteki szintre

Ezert a schema kulon kezeli a forrasleltart, a deduplikaciot, a feldolgozasi futasokat, a nyers szovegkivonatokat, a tudasszegmenseket es a coverage/gap audit reteget.

---

## S2 TABLARETEGEK

### Forrasleltar

- `source_artifacts`
- `artifact_dedup_groups`
- `artifact_dedup_members`

### Ingest es kivonat

- `artifact_ingest_runs`
- `artifact_text_extracts`

### Tematikus es kereso reteg

- `topics`
- `artifact_topics`
- `segment_topics`
- meglévo: `agent_knowledge_segments`, `felmeres_docs`

### Audit es teljesség

- `knowledge_coverage`
- `knowledge_gaps`
- `ingest_checkpoints`
- `kb_schema_meta`

---

## S3 FO_TABLAK

### `source_artifacts`

Kulcsmezok:

- `artifact_id`
- `source_root`
- `absolute_path`
- `canonical_path`
- `artifact_kind`
- `format_family`
- `sha256`
- `visibility_status`
- `ingest_priority`

Hasznalat:

- egy sor = egy eredeti vagy szarmaztatott artefakt
- itt latszik, hogy a forras `Anti`, `Felmeres` vagy `RepoDocs`
- itt dől el, hogy kozvetlenul olvashato-e, binary-only-e, vagy csak index-hidden

### `artifact_dedup_groups`

Kulcsmezok:

- `dedup_group_id`
- `dedup_key`
- `canonical_artifact_id`
- `dedup_reason`
- `confidence`

Hasznalat:

- `Anti/SZERVER/_extracted`, `_extracted_auto`, `forrasok_unpacked` jellegu tukrok egy logikai csoportba kothetok
- survey-masolatok is kezelhetok vele

### `artifact_ingest_runs`

Kulcsmezok:

- `artifact_id`
- `ingest_stage`
- `ingest_status`
- `tooling`
- `error_summary`

Hasznalat:

- itt latszik, hogy egy fájllal mi tortent
- kulon nyilvantartja a `read`, `ocr`, `asr`, `segmented`, `indexed` es `failed` allapotokat

### `artifact_text_extracts`

Kulcsmezok:

- `artifact_id`
- `extract_type`
- `text_content`
- `quality_score`
- `quality_notes`

Hasznalat:

- a nyers vagy szovegesitett kivonat tarhelye
- forras lehet `fulltext`, `ocr-text`, `asr-transcript`, `html-text`, `csv-normalized`, `manual-summary`

### `topics`, `artifact_topics`, `segment_topics`

Hasznalat:

- hierarchikus topic-rendszer
- kulon artifact-szintu es segment-szintu hozzarendelessel
- lehetove teszi a coverage szamolast es a fokuszalt kerest

### `knowledge_coverage`

Hasznalat:

- topiconkent es source rootonkent mutatja:
  - hany artefaktot lattunk
  - hanyat ingestaltunk
  - hanybol lett text extract
  - hany maradt blocked

### `knowledge_gaps`

Hasznalat:

- az is explicit tudás, ami még nincs feldolgozva
- tipikus gap-ek:
  - `ocr-needed`
  - `asr-needed`
  - `not-searchable`
  - `dedup-unresolved`
  - `low-confidence`

---

## S4 INGEST_STATUSZOK

### Fajlszintu statusz

- `discovered`
- `hashed`
- `classified`
- `deduplicated`
- `queued`
- `processed`
- `indexed`
- `blocked`
- `unsupported`
- `missing`

### Feldolgozasi statusz

- `pending`
- `in_progress`
- `completed`
- `partial`
- `failed`
- `duplicate-skipped`
- `manual-review-required`
- `ocr-required`
- `asr-required`
- `archive-expand-required`

Szabaly:

- `indexed` csak akkor lehet valami, ha van hozza `artifact_text_extracts` vagy kozetlen strukturalt rekord es forrashivatkozas

---

## S5 TOPIC_RENDSZER

Fo topicok:

- `cashdesk-shell`
- `transactions-buy-sell-conversion`
- `receipts-printing`
- `customers-aml-kyc`
- `sanctions-blacklist`
- `rates-rate-publication`
- `reservations-booking`
- `closing-daily-monthly-yearly`
- `denomination-cash-stock`
- `treasury-vault-transfer`
- `server-import-receptor`
- `dat-file-formats`
- `firebird-schema-and-db-artifacts`
- `camera-core`
- `camera-export-custody`
- `western-union`
- `partner-integrations`
- `survey-requirements`
- `ui-screenshots-and-receipt-images`
- `audio-video-transcripts`

---

## S6 DEDUP_LOGIKA

Elso szint:

- `same-hash`

Masodik szint:

- `canonical_path` normalizalas
- `_extracted`, `_extracted_auto`, `*_unpacked` csaladok osszefogasa

Harmadik szint:

- `semantic-duplicates`
- survey masolatok es paralel dokumentumfak manual-reviewval

Nem deduplikalhato vakon:

- azonos nev, eltero datum vagy tartalom
- verziozott `DAT` csaladok
- kulonbozo riportidopontok

---

## S7 TELJESSEG_BIZONYITAS

A teljességet nem deklaraljuk, hanem merjuk.

Kotelezo bizonyitek:

1. forrasleltar darabszamok `Anti` es `Felmeres` szerint
2. dedup-csoport szam
3. fajltipusonkenti ingest-matrix
4. topiconkenti coverage mutato
5. nyitott gap-ek listaja
6. mintaveteles visszakovetesi proba eredeti fajlig

---

## S8 JELENLEGI_IMPL

A schema implementacioja a `docs/valuta-kb-migrate.py` scriptben tortenik.

Bootstrappel mar most:

- a meglevo `felmeres_docs` sorokat
- a meglevo `agent_knowledge_segments` sorokat
- topic seedeket
- baseline dedup, coverage es gap rekordokat

Ez nem vegleges ingest, hanem auditálható alap, amire a teljes `Anti` es `Felmeres` bejaras kesobb raepulhet.
