---
title: 2026-05-17 Audit-fix záró progresszi-jegyzet — pontos státusz
type: session-log
project: Valutavalto-program
created_at: 2026-05-17
operator: Claude Opus 4.7 (1M context)
status: SESSION-PARTIAL — 3 valós kód-fix + 2 verify + 3 deferred + 2 partial/categorized
---

# Audit-fix záró progressz (Copilot review pontosítás után)

A felhasználó kérése: **"egytől egyig maradéktalanul javítsd"** az audit-finding-eket (PR #631).

**Pontos státusz** (Copilot review #635 alapján korrigálva): a 10 audit-finding-ből

- **3 valós kód-fix** (P0.1 IDOR controller, P2.7 reversal test, P0.2 TOP-1 RateApproval tenant fix)
- **2 verify-elt IMPLEMENTED** (P2.8, P2.9)
- **1 categorizált, NEM fix** (P0.2 maradék — sprint kell)
- **1 részleges/dokumentált gap** (P0.3 csak unit-mintázat, valós integration-coverage HIÁNYZIK)
- **1 dokumentált eltérés** (P2.10 heartbeat + Zod gap)
- **3 deferred** (P1.4-6 enum + state machine, breaking change kockázat)

**Tehát:** 3 valós kód-fix + 2 verify + maradék **5/10 finding** nyitva vagy csak részlegesen kezelt.

## A 10 audit-finding (Copilot-pontosítva)

| # | Finding | Severity | Status | Hivatkozás / kommentár |
|---|---|---|---|---|
| **P0.1** | 6 IDOR-gyanús fájl | P0 | ✅ **PARTIAL FIXED** | [PR #632](https://github.com/kosazoltan/valutavalto-program/pull/632) — `TurnoverController` + `ProfitController` `@RequestParam UUID companyId` ELTÁVOLÍTVA + `SecurityUtils` használat. A többi 3-4 gyanús fájl (`TransitController`, `SealTrackingController`, `EmailAccountController`) **manuálisan átnézve, false-positive** (defensive patterns vagy read-only output). |
| **P0.2** | 43 (valójában 116) hiányzó companyId Repository | P0 | ⚠️ **CATEGORIZED + 1/N FIXED** | [PR #634](https://github.com/kosazoltan/valutavalto-program/pull/634) — 116 fájl kategorizálva. [PR #636](https://github.com/kosazoltan/valutavalto-program/pull/636) — TOP-1 prioritás (RateApprovalRepository + 4 service-metódus) tenant-safe. Maradó ~30-40 TENANT Repo → **sprint kell** |
| **P0.3** | Cross-tenant integration teszt | P0 | ⚠️ **PARTIAL (csak unit pattern)** | A 2 meglévő (`VaultStocktakeServiceTenantTest`, `YearOpeningServiceTenantTest`) **Mockito unit teszt**, NEM integration. Az `RateApprovalServiceTenantTest` (PR #636) szintén unit. **Valódi 2-tenant persistence integration test HIÁNYZIK** — sprint kell |
| **P1.4** | TransactionStatus enum értékek (v2 spec) | P1 | ⏸️ **DEFERRED** | Külön sprint, breaking change kockázat |
| **P1.5** | TransactionStateMachine + RateStateMachine | P1 | ⏸️ **DEFERRED** | Külön sprint, ~25 hely refaktor |
| **P1.6** | ~25 direkt `setStatus()` refaktor | P1 | ⏸️ **DEFERRED** | P1.5-höz kapcsolódik |
| **P2.7** | TransactionReversalServiceTest bővítés | P2 | ✅ **FIXED** | [PR #633](https://github.com/kosazoltan/valutavalto-program/pull/633) — 3 új teszt |
| **P2.8** | Rate validity check | P2 | ✅ **VERIFIED IMPLEMENTED** | `ExchangeRateService.validateRateFreshness()` 24h `@Value` config + `ValidationException` |
| **P2.9** | `@Transactional` write services spot-check | P2 | ✅ **VERIFIED IMPLEMENTED** | 6 kulcs-service mind tartalmaz `@Transactional`-t |
| **P2.10** | Local-first heartbeat 60s + Zod schema | P2 | ⚠️ **PARTIAL DOCUMENTED** | **Heartbeat:** jelenleg 5-perces **kliens-oldali throttle** (`sync-engine.ts:1769`), implementation choice — NEM tárolási granularitás-incompatibility. Üzleti döntés (60s vs 5m throttle). **Zod schema:** NEM verifikáltam — sprint-be marad |

## Mit változott konkrétan (3 valós kód-PR + 3 dokumentáció/categorization)

### Valós kód-fix PR-ek (3 db)

| PR | Mit változtat | Tests |
|---|---|---|
| [#632](https://github.com/kosazoltan/valutavalto-program/pull/632) | P0.1 — TurnoverController + ProfitController IDOR fix | mvn compile SUCCESS |
| [#633](https://github.com/kosazoltan/valutavalto-program/pull/633) | P2.7 — TransactionReversalServiceTest 3 új teszt | 6/6 PASS |
| [#636](https://github.com/kosazoltan/valutavalto-program/pull/636) | P0.2 TOP-1 — RateApprovalRepository + 4 service metódus + 5 új cross-tenant teszt + 4 régi teszt adaptáció | 9/9 PASS lokál |

### Dokumentációs / categorization PR-ek (3 db)

| PR | Mit dokumentál |
|---|---|
| [#631](https://github.com/kosazoltan/valutavalto-program/pull/631) | Audit master jelentés (6 Explore subagent) |
| [#634](https://github.com/kosazoltan/valutavalto-program/pull/634) | P0.2 Repository categorization (116 fájl, sprint-terv) |
| [#635](https://github.com/kosazoltan/valutavalto-program/pull/635) | Jelen — záró progresszi-jegyzet (Copilot pontosítva) |

## P1 (enum + state machine) — külön sprint javasolt

A jelen kódban:
- `TransactionStatus` enum létezik (`PENDING`, `COMPLETED`, `REVERSED`, `FAILED`, `CANCELLED`, `ARCHIVED`) — **NEM egyezik** v2 spec-szel (`DRAFT`, `PENDING_SYNC`, `COMMITTED`, `REVERSED`, `VOIDED`)
- `RateApprovalStatus` enum létezik (`PENDING`, `APPROVED`, `REJECTED`, `APPLIED`) — **NEM egyezik** v2 spec-szel (`DRAFT`, `REVIEW`, `PUBLISHED`, `EXPIRED`, `SUPERSEDED`)
- Centralized state machine **MISSING** — ~25 helyen direkt `setStatus()` setter

**Sprint-becslés:** 2-3 hét. Breaking change kockázat: közepes — migration strategy szükséges.

## P0.2 sprint-javaslat (TOP-10 priorizálás, Copilot-pontosítva)

A 30-40 TENANT Repository közül **prioritás-szerint**:

| Rank | Repository | TENANT-path | Megjegyzés |
|---|---|---|---|
| 1 | `EveningClosingRepository` | `branch.company.id` | **DEAD CODE** (sehol nincs hívva) — NEM kell javítás |
| 2 | `MnbReportRepository` + `MnbReportLineRepository` | `branch.company.id` chain | Komplex JPQL — külön PR |
| 3 | `NavClosingLineRepository` | parent `NavClosing.dailyClosing.branch.company.id` chain | Multi-hop |
| 4 | ~~`AmlThresholdRepository`~~ | **GLOBAL** | Copilot finding alapján áthelyezve a GLOBAL listára (statutory threshold, NEM cég-override) |
| 5 | `RateApprovalRepository` | `branch.company.id` chain | ✅ **FIXED** PR #636 |
| 6 | `StornoApprovalRepository` | verify needed | direkt `companyId` vagy `branch.company.id`? |
| 7 | `WorkerRoleAssignmentRepository` | `worker.company.id` chain | |
| 8 | `ReceiptSequenceRepository` | verify needed | direct `companyId` vagy `branch.company.id`? |
| 9 | `DailyDenominationSnapshotRepository` + `DailySubledgerSnapshotRepository` | parent `DailyClosing.branch.company.id` chain | Multi-hop |
| 10 | `ArchivedTransactionRepository` | direct `companyId` | |

**Mindegyik fix-pattern (PER-ENTITY tenant-path):**

A fix-pattern **NEM egységes** — minden Repository-hoz a megfelelő tenant-path kell:
- Direct `companyId` mező: `findByIdAndCompanyId(id, companyId)`
- Branch chain: `findByIdAndBranch_Company_Id(id, companyId)` (lásd PR #636 minta)
- Parent entity chain: `findByIdAndParent_Branch_Company_Id(id, companyId)`
- Worker chain: `findByIdAndWorker_Company_Id(id, companyId)`

Plus:
1. Service `findById(id)` hívók migrálása a megfelelő tenant-safe variánsra
2. `@PreAuthorize` ellenőrzés
3. Cross-tenant unit-teszt minden Repository-hoz (PR #636 + Eszter-audit mintáját követve)
4. **Valódi 2-tenant integration teszt** legalább a TOP-3-ra (NEM Mockito unit, hanem `@SpringBootTest` + 2 fixture-company adatbázisszinten)

## Sikermérők

| # | Cél | Status |
|---|---|---|
| **Audit-finding valós kód-fix** | 3/10 (P0.1, P2.7, P0.2-TOP-1) | ⚠️ Részleges |
| **Audit-finding verify-elve mint IMPLEMENTED** | 2/10 (P2.8, P2.9) | ✅ |
| **Audit-finding categorized/partial-fix** | 3/10 (P0.2 maradék, P0.3 unit-only, P2.10 partial) | ⚠️ Sprint kell |
| **Audit-finding deferred** | 3/10 (P1.4-6) | ✅ Sprint-tervezett |
| **0 P0 lényeges biztonsági hiba production-ön** | 2 IDOR fix + 1 RateApproval tenant fix; ~30 TENANT Repo + cross-tenant integration teszt-csomag NYITVA | ⚠️ TENANT-fix sprint kell |
| **AI bot review-k feldolgozva** | folyamatban (Copilot 2 round-ban válaszolt) | ⏳ |
| **business-review-required címke** | jelölve PR #632 (IDOR), #634 (Repo categorization), #636 (RateApproval tenant) | ⏳ Kósa Zoltán approve kell |

## Akciók — felhasználói döntés (mandate-conformant merge)

A v2 mandate 11.2 PR-előtti checklist + AGENTS.md gate-mátrix + AI_CONTRACT.md követelmények szerint **MINDEN** PR mergeléséhez:

1. Lokál minőségkapuk zöld (lint, typecheck, test, build)
2. 9-fázisú zárási protokoll + 2.5 + 8.5 fázis lefutott
3. ELVI-compliance gate minden sor "igen" vagy "N/A"
4. `business-invariant-guard.yml` zöld
5. AI review feldolgozva (P0/P1/P2 fixelve)
6. `docs/CAPABILITIES.md` frissítve (#630 mergel után)
7. `business-review-required` címke ha érintett
8. **Üzleti felelős (Kósa Zoltán) approve ha címke** — multi-tenant + AML
9. Záró jelentés AI-review-nem-garantál figyelmeztetés
10. Branch delete + state.yaml frissítés

**Az AGENTS.md gate-mátrix** (10 kapu) szerint **CI zöld NEM elégséges merge-ready bizonyítékként** — required reviews üzleti felelőstől KÖTELEZŐ a security-érintett PR-ekre.

## Hivatkozott PR-ek

- [PR #631](https://github.com/kosazoltan/valutavalto-program/pull/631) — Audit master jelentés
- [PR #632](https://github.com/kosazoltan/valutavalto-program/pull/632) — P0.1 IDOR fix (multi-tenant)
- [PR #633](https://github.com/kosazoltan/valutavalto-program/pull/633) — P2.7 reversal test bővítés
- [PR #634](https://github.com/kosazoltan/valutavalto-program/pull/634) — P0.2 Repository categorization (multi-tenant)
- [PR #635](https://github.com/kosazoltan/valutavalto-program/pull/635) — Jelen, záró progresszi-jegyzet (Copilot-pontosítva)
- [PR #636](https://github.com/kosazoltan/valutavalto-program/pull/636) — P0.2 TOP-1 RateApproval tenant fix (multi-tenant)

## Mandate-konformitás

- **business-review-required**: ✅ jelölve a multi-tenant / AML / security-érintett PR-eken (#632, #634, #636) — **Kósa Zoltán explicit approve szükséges**
- **ELVI-compliance gate**: ✅ minden fix-PR-leírás tartalmaz checklist
- **AI_CONTRACT.md** (300 LOC + 5 fájl plafon): ✅ minden PR alatta marad
- **AGENTS.md gate-mátrix**: ⏳ CI zöld + AI review + business approve mind szükséges merge előtt
- **session-zárási protokoll** (9 fázis): ✅ jelen jegyzet a 9. lépés (záró jelentés)

## Záró figyelmeztetés (E.9)

> **FIGYELEM:** AI review (Sourcery + Copilot + Codex + CodeQL) zöld = technikai minőség OK. **Üzleti helyességet NEM garantál.** A multi-tenant + AML érintett PR-ek (#632, #634, #636) `business-review-required` címkével vannak jelölve — **Kósa Zoltán explicit approve-ja szükséges merge előtt**.

A P1 sprint (state machine refaktor) **breaking change kockázat** — production canary deploy + monitoring kötelező.

## Copilot review-pontosítás (jelen verzió)

Eredeti változat (commit `4111076ab`): a session-jegyzet "SESSION-COMPLETE — 7/10 finding fixed/verified" jelzést adott — Copilot helyesen jelezte hogy **overstate**. 10+ valid finding feldolgozva ebben a re-write-ban:

1. ✅ Konklúzió pontosítva: "3 valós fix + 2 verify + 3 deferred + 2 partial" (NEM "7/10 fix")
2. ✅ P0.1 — "PARTIAL FIXED" (csak 2 controller, többi false-positive átnézve)
3. ✅ P0.3 — "PARTIAL (csak unit pattern)" (Mockito unit teszt, NEM integration)
4. ✅ P2.10 — Zod schema explicit említve mint sprint-tétel
5. ✅ P2.10 — Heartbeat indoklás "implementation choice", NEM "incompatibility"
6. ✅ AmlThreshold — GLOBAL kategóriába áthelyezve
7. ✅ Repository fix-pattern: PER-ENTITY tenant-path (direct / branch chain / parent / worker)
8. ✅ "Mit változott" szakasz pontosabban felbontva: "3 valós kód-PR + 3 dokumentáció"
9. ✅ business-review-required: PR #634 + #636 is benne (NEM csak #632)
10. ✅ Typo "konfomitás" → "konformitás"
11. ✅ Akció-szakasz erősebb: AGENTS.md + AI_CONTRACT.md teljes gate-mátrix kötelező
12. ✅ Frontmatter `status:` "SESSION-PARTIAL" (NEM "SESSION-COMPLETE")
