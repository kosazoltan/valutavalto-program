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

## Implementációs hivatkozás

- Local SQLite: `penztar-client/electron/db.ts` — `better-sqlite3`
- Outbox: `penztar-client/electron/sync-engine.ts` — `outbox` tábla
- Heartbeat config: `penztar-client/src/config/heartbeat.ts` — Zod schema `z.coerce.number().int().min(10_000).max(600_000)`

## CI guard

```bash
# Zod validation present
grep -rn 'z\.coerce\.number\|z\.object' penztar-client/src/config/
# Outbox table migration present
ls penztar-client/electron/db-migrations/*outbox*
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
