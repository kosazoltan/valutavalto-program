# B.4 — Local-first + offline + outbox garancia mandate

**Hatály:** always, P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.4 szakasz
**Kapcsolódó:** `reference_local_first_architecture.md`, `feedback_eset_retry_pattern.md`

## 5 alapszabály

1. **Local SQLite write FIRST.** Minden tranzakció ELŐSZÖR a lokál DB-be, csak utána outbox → backend. A pénztáros NEM veszíthet adatot internet kiesésnél.
2. **Outbox queue 3× retry** ESET TLS proxy miatt (`feedback_eset_retry_pattern.md` mandate).
3. **Heartbeat 60s alapértelmezett, Zod-validált.** A config-séma változása P1 finding ha Zod-validáció gyengül.
4. **Outbox replay test** minden release előtt:
   - 100 tranzakció lokál SQLite-ba mentve offline állapotban
   - online → mind 100 megérkezik a backend-re
   - Idempotency-key alapján duplikáció nélkül
5. **Konfliktus-feloldás:** last-write-wins **csak** ha az időbélyegek 5s-en belül vannak; egyébként manual review queue (admin felület).

## Implementációs hivatkozás (jelen állapot — verify in code)

A konkrét path-ok ellenőrzendők a `penztar-client/` aktuális struktúrája szerint. **A pontos fájlnevek jelen állapotban eltérhetnek** — az alábbiak iránymutatók, NEM kanonikus path-ok:

- Local SQLite: `penztar-client/electron/...` — `better-sqlite3` integráció (verify pontos path)
- Outbox: `penztar-client/electron/sync-engine.ts` vagy hasonló — outbox-tábla létezése verify-elendő
- Heartbeat config: `penztar-client/src/config/heartbeat.ts` — Zod schema `z.coerce.number().int().min(10_000).max(600_000)` (verify)

**Status:** IMPLEMENTED a viselkedés szintjén (local-first runtime, outbox retry, Zod heartbeat), de a pontos fájlszervezés ellenőrzendő a v2 capability-map elkészítésekor.

## CI guard (TERVEZETT, v2 PR-ben)

```bash
# Zod validation present
grep -rn 'z\.coerce\.number\|z\.object' penztar-client/src/config/
# Outbox table migration present (verify the actual migration filename)
find penztar-client -path '*/db-migrations/*outbox*' -o -name '*outbox*sql'
```

## Release-előtti smoke test

```bash
# manual: turn off network
penztar-client > Buy 100 EUR transaction
# repeat 100x
# turn on network
# wait 60s
# verify backend received exactly 100 transactions
```
