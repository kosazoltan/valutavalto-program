---
name: valutavalto-spec-driven-feature-delivery
description: >-
  Use when executing Valutavalto FK/FKH spec docs. Spec claims are verified
  against the repo first (Phase 0 + legacy memory lookup), then delivered
  spec-by-spec with RED-proofed tests, Flyway immutability, and additive
  extension. Also use for denomination Expected, handling-fee, day-close,
  and vault self-check money paths.
---

# Valutaváltó — FK/FKH spec-driven delivery

Specs arrive as `FK-0NN_*.md` / `FKH-0NN_*.md` (often under Downloads).
Hermes long form:
`C:\Users\Kósa Zoltán\AppData\Local\hermes\skills\software-development\valutavalto-spec-driven-feature-delivery\SKILL.md`

Gold-standard intake (copy this shape):
`.hermes/tickets/2026-09-13-fkh070-kezelesi-dij-cimletezes-elvart-forras.md`
plus pipeline `.hermes/pipeline/20260913-fkh070-handling-fee-expected/`.

## Phase 0 — every spec assertion is a CLAIM

In one batch: `git pull --ff-only` (clean tree) · `git log -1` ·
`git log --all --grep="FK-0NN"` · latest Flyway
`backend/src/main/resources/db/migration/` · version grep on the 4
`package.json` + `backend/pom.xml`.

| Spec claim | Check |
|---|---|
| "`V<N>` is free" | `sort -V` on migrations **and** open PR branches |
| "FK-0NN already merged" | `git log --all --grep=` — number collisions happen |
| `File.tsx:123` | grep the symbol; line numbers drift |
| `kozponti-client/src/pages/...` | **false** — screens live in `frontend-react/src/pages/` |
| `com.puzzleir...` | dual package; live code is `hu.puzzleir` |

Where ticket and spec disagree, **the ticket governs**. Keep a
claim-correction ledger (C1, C2…).

## Mandatory memory lookup (after spec, before code)

```
npm run memory:query -- "<kw>" --area legacy --limit 8
npm run memory:query -- "<kw>" --area specifikacio --limit 8
npm run memory:symbol -- "<feature>"
```

If legacy already solved it, describe how and justify every deviation.
Legacy legal rules are not overridden by an FR that forgot them.

Handling-fee denomination (FKH-070): Delphi/EXCMD `b5-kezeles-cimletezes-engedelyezes.md`
has a separate **KEZELÉSI KÖLTSEG CIMLETEZÉSE** surface. Expected must
be live customer `Transaction.handlingFee`, not KK `ShipmentHandlingFee`
(KK rows are never created on vault↔cashier transfer). Intentional
split: vault closing `handlingFeeRequired` may still be KK-based.

## Delivery rules

- One spec per branch. WU-1 is the RED test. Do not edit frozen tests.
- Flyway: applied `V<N>__*.sql` is immutable (not even a comment).
  Semantic fix = new migration. `active`/`is_active` duality: write both.
- Additive extension: overload, `@RequestParam(required = false)`,
  new finder — do **not** silently reuse a weaker SUM (FKH-070:
  Turnover SUM lacks `companyId` + `financialEffective`).
- New REST method → `@PreAuthorize`; never widen `archunit_store/`.
- Informational panel must not take down the host flow:
  `Array.isArray` before `.map()`; missing money ≠ 0 (show "n.a.").
- Frontend change in `frontend-react` = **both** installers.

## Rollout

`deploy-hetzner.yml` is path-triggered on backend/frontend-react.
Electron UI is `app://` bundle — server deploy does not update cashiers.
Client-first when a deleted endpoint would 404 a `Promise.all`.

## Done

Targeted test command + output. `memory:build` + `memory:stale-check`.
User decides merge. Then set `job.yaml` `status: pass` (do not leave
`planning` / `coding`).
