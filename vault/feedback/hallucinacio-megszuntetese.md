---
date: 2026-04-29
type: mandate
priority: P0 — KÖTELEZŐ ÉRVÉNYŰ
source: User direktíva (Kósa Zoltán) 2026-04-29 21:25 CEST
trigger: 9 sorozatos Sourcery P2 follow-up PR (v2.3.13 → v2.3.22) ugyanazon a fájlon
---

# Hallucinációs Kör Megszüntetése — Iparági Standard Kötelező

## A probléma (mai tanulság)

**v2.3.13 → v2.3.22 = 9 verzió 1 órán belül**, mind ugyanazon a heartbeat-config fájlon:
- v2.3.13: `logger.info` → `logger.warn`
- v2.3.16: `logger.warn` → dedikált `logger.heartbeat()` (`console.log`)
- v2.3.17: `console.log` → `console.warn` (Codex P1: Electron filter level >= 2)
- v2.3.19: rate-limiter komment
- v2.3.20: extract config module
- v2.3.21: MIN/MAX export + `logger.warn` invalid env
- v2.3.22: `parseInt` → strict regex + komment align

**Minden iterációban új P2 finding** a **saját kódom hibái miatt**. NEM lett kész a feature, csak körkörös visszafejlesztés. **Token-pazarlás + idő-pazarlás**.

## A gyökér-ok

1. **NEM iparági standardot használtam** (Zod / valibot / config-validation libs)
2. **Saját ad-hoc megoldásokat találgattam** (`STRICT_INTEGER_PATTERN`, manual range check, manual logger.warn)
3. **NEM olvastam el a hivatalos dokumentációt** Context7-tel
4. **Nem ismertem a Sourcery + Codex review szabályait**

## Az új mandate (KÖTELEZŐ ÉRVÉNYŰ)

> **Ezentúl minden programozási feladat előtt KÖTELEZŐ:**
>
> 1. **Context7 MCP** használata (`mcp__892e2348-f110-4f49-afe2-e16ee93cb2f4__resolve-library-id` + `query-docs`):
>    - Hivatalos library docs olvasása
>    - Iparági best-practice patterns
>    - NE saját ad-hoc kódot írj — használd a meglévő, validált library-ket
>
> 2. **Iparági standardokra hivatkozni** (NEM saját megoldás):
>    - Validation: **Zod** (már a projektben), **Valibot**, **Joi**
>    - Config: **dotenv + Zod schema** (Vite env hash-pattern)
>    - Logger: **electron-log**, **Pino**, **Winston** (a projekt már `electron-log`-ot használ)
>    - State: **Zustand**, **TanStack Query** (mind a projektben)
>
> 3. **Brainstorming + Plan ELŐTT a kódolás**:
>    - 1. Context7-ben utánanézés
>    - 2. Brainstorming skill (`superpowers:brainstorming`) komplex feature előtt
>    - 3. Test-driven development (`superpowers:test-driven-development`)
>
> 4. **TILOS** a próbálkozás-alapú iteráció:
>    - ❌ "Csinálok valamit, aztán majd a Sourcery review jelzi a hibát"
>    - ❌ "Próbálok egy regex-et, ha rossz, javítom"
>    - ❌ "Saját helper függvény írok ahelyett, hogy ismert library-t használnék"

## Konkrét hatás (heartbeat config példa)

**Helytelen iterációs ciklus (v2.3.13-v2.3.22):**
```
v2.3.13: const HEARTBEAT_INTERVAL_MS = 60_000  // hardcoded
v2.3.16: logger.heartbeat() — console.log
v2.3.17: console.warn (Codex P1 Electron filter)
v2.3.19: extract const + plan-comment
v2.3.20: új module config/heartbeat.ts
v2.3.21: MIN/MAX export + logger.warn invalid env
v2.3.22: STRICT_INTEGER_PATTERN regex
```

**Helyes egyszeri megoldás Zod-dal:**
```typescript
import { z } from 'zod'

const HeartbeatConfigSchema = z.object({
  intervalMs: z.coerce.number()
    .int()
    .min(10_000)
    .max(600_000)
    .default(60_000)
})

export const heartbeatConfig = HeartbeatConfigSchema.parse({
  intervalMs: import.meta.env.VITE_HEARTBEAT_INTERVAL_MS,
})
```

**Egyetlen 8-soros megoldás lefedi:**
- ✅ Strict numeric parse (`z.coerce.number()`)
- ✅ Integer-only (`.int()`)
- ✅ Range validation (`.min(10000).max(600000)`)
- ✅ Default fallback (`.default(60000)`)
- ✅ Type-safe (TypeScript inferenct)
- ✅ Iparági standard (Zod 3.22.4 már a `package.json`-ben)
- ✅ Hibaüzenet beépítve (`ZodError`)

## Hatálybalépés

**2026-04-29 21:25 CEST** — minden új feladatra. Visszamenőleg a heartbeat-config refaktor Zod-ra (v2.3.23 utolsó iteráció, ezzel a Sourcery-cycle lezárul).

## Tilos

- ❌ Próbálkozás-alapú kódolás
- ❌ Saját ad-hoc validáció iparági lib helyett
- ❌ Sourcery/Codex review-ra "majd kiderül" — `Context7 + brainstorming ELŐRE`
- ❌ Apró iterációs PR-ek folyamatos generálása

## Engedélyezett

- ✅ Context7 query minden új feature előtt
- ✅ Iparági lib reuse (a projekt-ben elérhetőkből)
- ✅ Brainstorming skill komplex feature előtt
- ✅ Egyszer írt, validált, end-state kód

---

## Implementáció checklist (új workflow)

```
Új feladat → 1. Context7 query iparági standardra
            → 2. Brainstorming (ha komplex)
            → 3. TDD (test-first)
            → 4. Implementáció iparági lib-bel
            → 5. Egyszeri Sourcery/Codex review (várhatóan tiszta)
            → 6. Merge
```

NEM:
```
Új feladat → kód iter1 → review → kód iter2 → review → kód iter3 → ...
```
