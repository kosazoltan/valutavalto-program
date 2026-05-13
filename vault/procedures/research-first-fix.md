---
title: Research-first hibajavítás (NO trial-and-error)
type: procedural-memory
trigger: "Hibát találsz vagy bugfix feladat érkezik"
authority: KÖTELEZŐ (Globális CLAUDE.md "research-first" + feedback/hallucinacio-megszuntetese.md)
created: 2026-05-02
sources:
  - C:\Users\Kósa Zoltán\.claude\CLAUDE.md (Kötelező hibajavítási workflow)
  - feedback/hallucinacio-megszuntetese.md
  - feedback/no-hallucination-lateral-thinking.md
---

# Research-first hibajavítás

> **Szabály:** Hibajavításnál **TILOS** találgatni vagy próba-szerencse alapon módosítani. Forrás → diagnózis → célzott módosítás → ellenőrzés.

## Trigger felismerés

A workflow indul ha:
- Bug-jelentés érkezik
- Test failure
- Production outage
- AI review finding amit nem érted azonnal
- Új library / framework usage

## Prerequisites

- [ ] Hibás kód lokalizálva (file:line)
- [ ] Hibaüzenet teljes blokkban rendelkezésre áll (`npm run ci:errors -- --pr <PR>` ha CI/review eredetű)
- [ ] Reprodukciós lépések ismertek

## Steps

### 1. Hivatalos doc olvasás (Context7 vagy WebFetch)

**Sorrend:**
1. **Context7 MCP**: ha a library benne van, az a legfrissebb dokumentáció.
   ```
   mcp__892e2348-...__resolve-library-id "react"
   mcp__892e2348-...__query-docs <library-id> <topic>
   ```
2. **GitHub repo**: official source + issues + discussions
3. **Stack Overflow / blog**: csak konkrét, ellenőrizhető tényre

**Tilos:**
- ❌ Forrás nélküli sejtés
- ❌ "Ez biztos azért van" feltételezés
- ❌ Multiple próba-edit egymás után verifikáció nélkül

### 2. Iparági standard library használata

A `feedback/hallucinacio-megszuntetese.md` 2026-04-29 user-direktíva szerint:

| Domén | NE saját implementáció | HASZNÁLD |
|---|---|---|
| Validation | manuális regex / parseInt + range check | **Zod**, Valibot, Joi |
| Logger | console.log + saját filter | **electron-log**, Pino, Winston |
| State | useState + useEffect kombináció | **Zustand**, TanStack Query |
| Date / time | Date.parse + saját format | **date-fns**, Day.js, Luxon |
| HTTP | fetch + saját retry | **Axios**, Ky |
| Form | useState fields | **React Hook Form** + Zod |

### 3. Brainstorming komplex feature előtt

Ha a fix > 50 LOC vagy új feature: `superpowers:brainstorming` skill kötelező.

### 4. TDD (Test-Driven Development) implementáció előtt

Ha a fix bug-ot fix-el: `superpowers:test-driven-development` skill — write failing test FIRST, aztán fix.

### 5. Minimális célzott módosítás

- Csak az érintett fájl(ok)
- Nem kiragadott sorokat javítunk: a teljes érintett logikai blokkot kell megérteni és konzisztensen módosítani
- Egy logikai változás per commit
- 300 LOC plafon az új kódra (AI_CONTRACT.md)

### 6. Verify

- [ ] `npx tsc --noEmit` — TypeCheck zöld
- [ ] `npx eslint <changed files>` — 0 új error / warning
- [ ] Unit teszt zöld (ha van)
- [ ] Lokális reprodukció megszűnt
- [ ] Vite preview / Playwright e2e (ha UI érintett)

## Anti-patterns (TILOS)

- ❌ **Próba-hiba**: 3+ iteráció ugyanazon a fájlon AI review hibákat csak azután javítva
- ❌ **Apró iterációs PR-ek**: 9 darab Sourcery follow-up PR ugyanazon fájlra (lásd v2.3.13-v2.3.22 anti-példa)
- ❌ **Ad-hoc megoldás iparági lib helyett**: pl. `STRICT_INTEGER_PATTERN` regex Zod helyett
- ❌ **"Majd kiderül a Sourcery review-n"**: pre-emptív minőség kötelező

## Workflow példa: heartbeat config (rossz vs jó)

### ❌ Rossz (9 PR iteráció)
```typescript
// manual parse + range check + custom regex + logger.warn + comment-align...
const intervalMs = (() => {
  const raw = import.meta.env.VITE_HEARTBEAT_INTERVAL_MS;
  if (!raw) return 60_000;
  if (!/^[1-9]\d*$/.test(raw)) {
    logger.warn('Invalid VITE_HEARTBEAT_INTERVAL_MS, using default');
    return 60_000;
  }
  const parsed = parseInt(raw, 10);
  if (parsed < 10_000 || parsed > 600_000) {
    logger.warn('Out of range, using default');
    return 60_000;
  }
  return parsed;
})();
```

### ✅ Jó (1 PR, Zod-dal)
```typescript
import { z } from 'zod'

export const heartbeatConfig = z.object({
  intervalMs: z.coerce.number().int().min(10_000).max(600_000).default(60_000)
}).parse({ intervalMs: import.meta.env.VITE_HEARTBEAT_INTERVAL_MS })
```

Egyszer írt, type-safe, validált, iparági standard.

## Verify (workflow-szintű)

A research-first sikeres ha:
- [ ] Forrás-link a commit message-ben (Context7 / GitHub / official doc)
- [ ] Iparági lib használva (vagy indoklás miért nem)
- [ ] Egyetlen PR fixeli (nem 9 iteráció)
- [ ] AI review tiszta első körre (Sourcery: "looks great")
