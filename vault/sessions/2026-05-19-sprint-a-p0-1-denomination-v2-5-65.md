---
title: "Sprint A — P0.1 Címletezés v2 close-out + P0.3 companyId audit (v2.5.65)"
date: 2026-05-19
sprint: A (P0 close-out)
release: v2.5.65
pr_merged: [#701]
audit_docs: [docs/companyId-coverage-2026-05-19.md]
---

# Sprint A első etap — v2.5.65

## P0.1 — Címletezés v2 close-out (PR #701, merge `dcfb97124`)

### Mi volt rosszul
A 2026-05-13 Sprint 1 csak az entitásokat + admin CRUD-ot szállította. A `DenominationOptimizationService`:
- **Dead-kód volt** (no callers — `grep DenominationOptimizationService` 0 találat a service-en kívül)
- CUSTOM + BRANCH_SPECIFIC csak greedy fallback
- Inner `Strategy` enum duplikálta a már létező `OptimizationStrategy`-t
- Nulla unit teszt

### Mi lett kész
- 7 stratégia valós impl: GREEDY, MIN_BANKNOTES, MIN_TOTAL, DYNAMIC (bounded knapsack DP), MIN_COINS, **CUSTOM** (priorityOrderJson), **BRANCH_SPECIFIC** (készlet-aware)
- 17 unit teszt: 7 happy path + adversarial DYNAMIC + CUSTOM dedup + scale-mismatch + edge case-ek
- Null/negative guard
- BigDecimal scale-kezelés (stripTrailingZeros normalizálás + pow-clamp)

### 2-kör mandate teljes ciklus
1. CI gate: 14 pass + 1 skipped
2. GitHub AI gate round 1: Codex P1 (CUSTOM dedup bug) + Sourcery P2 (enriched log) → fix
3. GitHub AI gate round 2: clean
4. SAJÁT subagent Round 1: SQL/Flyway+multi-tenant agent — 5 finding (multi-tenant company filter MISSING noted as TODO P0.3, DYNAMIC reconstruction concern false alarm, BigDecimal scale ✓, pow-negative ✓, null guards ✓)
5. SAJÁT subagent Round 2: fresh verify — SAFE TO MERGE

## P0.3 — companyId multi-tenant audit (külön doc)

**Doc:** `docs/companyId-coverage-2026-05-19.md`

**Módszer:** Grep-batch (NEM 185 fájl egyenkénti olvasás):
1. `grep -l "@Query"` → 87 fájl
2. `grep -lE "company\.id|companyId|company_id"` → 69 fájl
3. Diff → 45 fájl @Query-vel DE company-filter nélkül
4. Manual review → kategorizálás

**Eredmény:**
- 12 GLOBAL_OK (Currency, Country, MNB, Token-stb.)
- 42 TENANT_COMPANY_OK (explicit company filter)
- 33 TENANT_FK_OK (implicit tenant via branch.id/worker.id FK)
- 5 AMBIGUOUS (4 OK + 1 valódi BUG)
- 93 default-CRUD (Spring Data alap, service-szinten véd)

**Valódi BUG:** `ShipmentRequestRepository` — szállítási kérelmek nincsenek tenant-scope-olva. Külön P0 follow-up PR a fix.

**Üzleti döntés szükséges:** `CompetitorRateRepository` — globális vagy per-tenant? Üzleti tulajdonostól.

**Production safe-state:** v2.5.65 multi-tenant SAFE — nincs identifikált hotfix-igényű bug.

## v2.5.65 4 installer SHA-256

| Fájl | Méret | SHA-256 |
|---|---|---|
| `Penztar-Setup-2.5.65-20260519.exe` | 282.65 MB | `11A0932E7C0AEB128BFD68025730A78E65F8195FC89F164346F631D5D100E4AB` |
| `Kozponti-Iranyitokozpont-Setup-2.5.65.exe` | 101.05 MB | `03AE46D03A9F831A8A8812460486D215043DAB65EFE889859E30F200BBD8BF80` |
| `Arfolyamkeszito-Setup-2.5.65.exe` | 101.05 MB | `D1092DB2D4A270A8525C5817D2F5047EA5FEBB4004A67A53A255965C6792E3D4` |
| `Penztar-Eltavolito-2.5.65-20260519.exe` | 59.43 KB | `ED7EE1C4E52E2C80F83EFCA9DC89383293BF7A2E12CF0A43B97925F444825143` |

Mind a 4 fájl másolva `%USERPROFILE%\Downloads\`-ba. UNSIGNED build (DigiCert pending).

## Sprint A fennmaradó pontok

- **P0.2 NAV decision** — Kósa Zoltán üzleti döntésére vár (kötelező vagy formális N/A)
- **P0.3 ShipmentRequestRepository fix** — külön P0 PR, jövő session

## Következő szakasz

Sprint B (P1 UAT batch) vagy P2 feature drop (lásd `vault/references/strategic-development-plan-v2-5-64-2026-05-19.md`).

Kósa Zoltán user-direktíva (2026-05-19 ~20:00): "Holnap reggelig önállóan, megállás nélkül" → autonóm mode folytatás P2.3 Discount granular workflow vagy P2.5 Átlag árfolyam riport.
