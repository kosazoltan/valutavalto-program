---
type: implementation-plan
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "ASR pipeline integration plan for audio and video transcript ingestion"
load: on-demand
---

# ASR Pipeline Integration Plan

## A1 CEL

A jelenlegi ingest mar nyilvantartja az audio/video forrasokat, de nincs transcript pipeline.

Cel:

1. valasszunk helyi futtathato ASR megoldast
2. illesszuk a meglvo `artifact_text_extracts` es `artifact_ingest_runs` schemahoz
3. csokkentsuk az `asr-needed` gap-eket

---

## A2 AKTUALIS_HELYZET

Jelenlegi gap:

- `asr-needed`: `8`

Jelenlegi ingest allapot:

- az audio/video artefaktok inventoryban bent vannak
- nincs transcript
- nincs idobelyeges vagy nyelvi metaadat-reteg

---

## A3 JAVASOLT_ALAPMEGOLDAS

Javasolt alapirany:

- helyi Python-alapu ASR pipeline
- elsodleges default: `faster-whisper` jellegu megoldas

Indok:

- Python pipeline-ba jol illesztheto
- batch feldolgozasra alkalmas
- strukturalt transcript es nyelvi metaadat is nyerheto

Ha helyi GPU nincs:

- CPU-only fallback is tervezheto, lassabb batch futassal

---

## A4 BEVITELI_CSATORNA

Erintett formatumok:

- audio: `mp3`, `wav`, `m4a`, `flac`, `ogg`, `aac`, `wma`
- video: `mp4`, `mov`, `avi`, `mkv`, `webm`, `wmv`

Elokeszitesi lepesek:

1. audio/video hosszanak es meretenek rogzitese
2. video -> audio sáv kinyerese
3. normalizalt sampling rate
4. transcript generalas

---

## A5 SCHEMA_ILLESZTES

Jelenlegi tablakkal kompatibilis javaslat:

- `artifact_text_extracts`
  - `extract_type='asr-transcript'`
  - `language='hu'`, `language='mixed'`, vagy detektalt ertek
  - `quality_score` a modell confidence vagy becsult minoseg
  - `quality_notes` pl. `model=...;duration=...;segments=...`
- `artifact_ingest_runs`
  - `ingest_status='completed'` ha transcript kesz
  - `ingest_status='partial'` ha csak reszleges transcript keszult
  - `ingest_status='failed'` hiba eseten

Opcionis bovites kesobbre:

- kulon `artifact_transcript_segments` tabla idobelyeges szegmensekhez

---

## A6 INTEGRACIOS_PONT

Javasolt uj script:

- `docs/valuta-kb-extract-asr.py`

Feladata:

1. audio/video candidate-ek listazasa
2. transcript futtatasa
3. `artifact_text_extracts` feltoltese
4. `knowledge_gaps` frissitese

---

## A7 STATUSZ_ATMENET

Javasolt allapotvaltas:

- kezdetben: `asr-needed`
- transcript futas kozben: `partial`
- sikeres transcript utan: `completed`

Gap kezeles:

- `asr-needed` gap lezarhato, ha `asr-transcript` extract letrejott

---

## A8 MINOSEGI_SZABALYOK

ASR minosegi minimumok:

- a transcript ne legyen ures
- legalabb becsult nyelv vagy `mixed` rogzitve legyen
- hosszu media eseten szegmensszam vagy duration keruljon a notes mezobe
- rossz minosegu transcript maradhat `partial` allapotban

---

## A9 KOCKAZATOK

- hosszu videok erosen lassithatjak a batch ingestet
- gyenge hangminoseg torz transcriptet adhat
- tobb beszelos vagy zajos felvetelekhez mas modell-meret kellhet
- video demux vagy codec problemak miatt kulon ffmpeg-szeru elokeszites szukseges lehet

---

## A10 SIKERFELTETELEK

Az ASR integracio akkor tekintheto sikeresnek, ha:

- az `asr-needed` gap-ek csokkennek
- legalabb az osszes jelenlegi `8` media artefaktra letrejon transcript vagy reszleges transcript
- a transcript kereshetoen bekerul az `artifact_text_extracts` retegbe
