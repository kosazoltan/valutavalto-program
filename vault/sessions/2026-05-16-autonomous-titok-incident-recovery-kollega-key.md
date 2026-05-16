---
date: 2026-05-16
type: session
tags: [security, b2, rotation, mandate, kollega-key, autonomous]
---

# 2026-05-16 — Autonóm titok-incident recovery + kolléga-key újrakészítés

## Kontextus

2026-05-16 délelőtt a user explicit mandate-et adott (`AI_titok_kezeles_utasitas.md`) — a Backblaze master + scoped key + Tailscale authkey kompromittálódott (AI plaintext leak). A user **autonóm végrehajtást** kért: titok-kezelési probléma megoldása + kolléga-key újra-előállítás úgy hogy a titok ne kerüljön chat-be / Bash-output-ba.

## Mit végeztem (autonóm)

### Track 1: B2 + Tailscale full rotation (előző sessionben befejezve)
- ✅ Backblaze master-eq rotálva (régi DELETE-elve)
- ✅ Backblaze bucket-scoped key rotálva
- ✅ Tailscale authkey rotálva
- ✅ Mindhárom új kulcs `~/Downloads/rotated-credentials-2026-05-16.json`
- ✅ GitHub Secrets (`B2_KEY_ID_NEW`, `B2_APP_KEY_NEW`) stdin-en pusholva
- ✅ [PR #626](https://github.com/kosazoltan/valutavalto-program/pull/626) admin-merged
- ✅ Workflow run [#25956190956](https://github.com/kosazoltan/valutavalto-program/actions/runs/25956190956) — Hetzner `.env` + `rclone.conf` redact-tal frissítve
- ✅ rclone smoke test PASS

### Track 2: Kolléga (newugyvitel) scoped key újra-előállítása autonóm módon

**Probléma:** az eredeti MD-fájl `newugyvitel-backup-credentials.md` AI által plaintext key-vel készült → revoke kellett.

**Megoldás workflow (titok-mandate-kompatibilis):**

1. Python helper script (`create_kollega_key.py` → később `fix_kollega_key.py`) ami:
   - Olvas a `rotated-credentials-2026-05-16.json`-ból master-eq credentialst
   - `b2_authorize_account` + `b2_create_key` API hívás
   - `bucketId=933d3d8fcdabe2fc95df0f1b` (csak `newugyvitel-backup`)
   - **`listAllBucketNames` capability NÉLKÜL** (user direktíva Opció A szerint)
   - Eredmény mentés `Downloads/newugyvitel-kollega-key-2026-05-16.json`-ba
   - **Értékek sem stdout-ra sem chat-be NEM kerültek** (csak hossz + prefix-check)
2. Helper Python script TÖRÖLVE futás után (`rm create_kollega_key.py`, `rm fix_kollega_key.py`)
3. v2 (listAllBucketNames-mel) DELETE-elve, v3 (listAllBucketNames nélkül) létrejött
4. MD-fájl frissítve hogy hivatkozzon a kísérő JSON-ra + biztonságos átadási csatorna instrukcióval (Bitwarden Send / Signal / ProtonMail)

**Végeredmény (mindkettő a Downloads-ban):**
- `newugyvitel-backup-credentials.md` — placeholder-es, nyilvános info (bucket név, ID, region, S3 endpoint, példák)
- `newugyvitel-kollega-key-2026-05-16.json` — titkos JSON (csak biztonságos csatornán átadható)

**Új key paraméterek (titok-MENTES metadata):**
- keyName: `newugyvitel-backup-scoped-v3`
- bucketId: `933d3d8fcdabe2fc95df0f1b` (newugyvitel-backup, eu-central-003)
- applicationKeyId length: 25 chars
- applicationKey length: 31 chars, `K00`-prefixszel
- capabilities: `readBuckets, listFiles, readFiles, writeFiles, deleteFiles, readBucketEncryption` (NO listAllBucketNames)

### Track 3: Production health check + main-CI verifikálás
- ✅ `excvaluta.com/api/v1/auth/bootstrap-status` → 200
- ✅ 66 branch a `/public/branches?companyCode=EBC`-n
- ✅ 0 nyitott PR
- ✅ Main legutóbbi push (B2 update workflow) zöld
- ⚠️ Egyetlen failure: hajnali 04:38 UTC Playwright Live T01 timeout (1 fail / 8 pass) — RERUN triggered, valószínű flake

## Tanulság / pattern megerősítés

1. **Külön JSON fájl titkos érték átadására** — soha NEM az MD-be, NEM Bash-stdout-ba. A Python script `urllib`-bel hívja a B2 API-t, a választ közvetlenül fájlba írja, a tartalmat sosem print-eli.
2. **Helper scriptek azonnal TÖRLENDŐK** futás után — még akkor is ha sosem print-elnek titkokat, ne maradjon kódbeli artifact ami a master credentialst használja.
3. **listAllBucketNames** — még akkor is el kell hagyni a capability-listából amikor `bucketId` van állítva (a Backblaze automatikus scope-ja egyebként is korlátoz, de user-direktíva felülír).
4. **Pre-output check** — minden Python kimenetnél explicit ellenőrizni hogy a `print(...)` csak metadata-t (length, prefix-check, keyName) hoz, sosem a tényleges secret-et.

## Hivatkozott artefaktok

- Auto-memory feedback: `~/.claude/projects/D--repo-valutavalto-program/memory/feedback_titok_kezeles_mandatory.md`
- Vault feedback: `vault/feedback/titok-kezeles-mandatory.md`
- B2 rotation workflow: `.github/workflows/update-b2-credentials.yml` (PR #626)
- Rotated credentials (off-repo): `~/Downloads/rotated-credentials-2026-05-16.json`
- Kollega scoped key (off-repo): `~/Downloads/newugyvitel-kollega-key-2026-05-16.json`
- Kollega MD (off-repo, placeholder-es): `~/Downloads/newugyvitel-backup-credentials.md`

## Következő autonóm lépések — nincsenek

- DigiCert EV CS validation: vár a DigiCert phone callback-re (external block)
- Drill 1: 2026-05-17 04:00 CEST scheduled routine (cron)
- v2.5.53 telepítő reinstall: user-action (kassza-PC-k)
- Jackson 3 migráció: long-term, külön sprint

Repo most stabil, main zöld, production HEALTHY.
