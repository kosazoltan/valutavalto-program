---
title: 2026-05-17 Codebase audit — VV-ELVI compliance (v1+v2 mandate szerint)
type: session-log
project: Valutavalto-program (BEC ERP)
created_at: 2026-05-17
operator: Claude Opus 4.7 (1M context) + 6 Explore subagent
status: COMPLETED — audit lefutott, finding-ek dokumentálva
---

# 2026-05-17 — Codebase audit eredmény (VV-ELVI compliance)

A felhasználó (Kósa Zoltán) kérte: "nézd végig a teljes programkódot az új elvek szerint". A v1 (`claude-code-korrekcios-mandate-2026-05-17.md`) + v2 (`claude-code-valutavalto-korrekcios-mandate-2026-05-17-v2.md`) mandate alapján 6 párhuzamos Explore subagent végezte az auditot.

## Audit-scope

| # | Mandate | VV-ELVI ref | Subagent eredmény |
|---|---|---|---|
| B.1 | Pmt. / AML invariáns | 9.1 | 6/6 IMPLEMENTED |
| B.2 | Pénzügyi adatintegritás | 16 | 5/7 IMPLEMENTED, 2 verify needed |
| B.3 / E.1 | Multi-tenant izoláció | 3 | **PARTIAL — kritikus IDOR gyanú 6 fájlon** |
| B.4 | Local-first outbox | 5.8 | Mostly IMPLEMENTED, 3 PARTIAL |
| B.6 | Sztornó + napzárás | 5.6 + 5.7 | 8/10 IMPLEMENTED |
| E.4 / E.5 | Állapotgép + enum | v2 5. | **MOSTLY MISSING — refaktor szükséges** |

## Részletes findings

### B.1 — Pmt. / AML (6/6 IMPLEMENTED) ✅

| Capability | Status | Fájl + sor |
|---|---|---|
| 100k / 300k küszöb backend-enforced | IMPLEMENTED | `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java:62-74` (`SIMPLIFIED_IDENTIFICATION_LIMIT`, `IDENTIFICATION_LIMIT`, `ANNUAL_ROLLING_LIMIT`) |
| Sanction-list fuzzy match (Levenshtein ≤2) | IMPLEMENTED | `backend/src/main/java/hu/puzzleir/valuta/service/SanctionScreeningService.java` |
| Cyclic customer (structuring) | IMPLEMENTED | `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java:925-947` (`isStructuring()`) |
| PEP-jelölés + 6-szintű kockázat | IMPLEMENTED | `backend/src/main/java/hu/puzzleir/valuta/entity/Customer.java:249` (`isPep`) + `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java:412-446` |
| SAR auto-flag + 2 nap deadline | IMPLEMENTED | `backend/src/main/java/hu/puzzleir/valuta/entity/AmlReport.java:110-111` + `backend/src/main/java/hu/puzzleir/valuta/controller/AmlController.java:79-82` |
| Sanction-list napi 06:00 refresh | IMPLEMENTED | `backend/src/main/java/hu/puzzleir/valuta/config/SanctionListScheduler.java:49-68` (UN + EU) |

**Konklúzió:** A Pmt. compliance **AML-területen** teljes mértékben implementálva backend-enforced REST endpointokkal (`/api/v1/aml/*`). Az AML endpoint-ok tenant-szűrést végeznek (companyId). **NB:** ez a kijelentés csak az AML területre vonatkozik — az általános multi-tenant izoláció státusza külön (B.3 **PARTIAL** — IDOR finding-ekkel).

---

### B.3 / E.1 — Multi-tenant izoláció (PARTIAL — ⚠️ kritikus gap)

| Capability | Status | Mit jelent |
|---|---|---|
| Repository companyId szűrés | **PARTIAL (68/111)** | 43 Repository fájlból hiányzik a companyId. Globális entitások (Currency, Country, MnbRate, Role) OK kivétel, de a 43-ból nem minden globális. |
| @PreAuthorize coverage | IMPLEMENTED | 157 fájl, 523 occurrence |
| **IDOR vulnerability** | **CRITICAL — 6 fájl** | **gyanús `request.getCompanyId()` / `@RequestParam UUID companyId` / `dto.getCompanyId()` pattern** — kliens-kontrolled companyId direkt használat |
| UUID typing | IMPLEMENTED | `SecurityUtils.getCurrentCompanyId()` konzisztens UUID-ot ad vissza |
| SecurityUtils usage | IMPLEMENTED | 119 fájl, 353 invokáció |
| Cross-tenant integration test | **MISSING** | Nincs olyan teszt amelyik 2 különböző companyId-vel verifikálja az izolációt |

**P0 kritikus akció:**
- **6 IDOR-gyanús fájl** explicit átnézése (kézi review szükséges, NEM automatikus fix)
- **43 hiányzó Repository companyId szűrés** átnézése + javítás
- **Cross-tenant teszt-csomag** létrehozása

A jelen ülés nem fixálja ezeket — escalation Kósa Zoltánnak.

---

### B.2 — Pénzügyi adatintegritás (5/7 IMPLEMENTED)

| Invariáns | Status | Fájl-hivatkozás |
|---|---|---|
| `készlet = SUM(tranzakciók)` (no mutable counter) | IMPLEMENTED | Csak `InventorySummary` (materialized view) tartalmaz `currentStock` mezőt — allowlist-elt |
| `IdempotencyFilter` whitelist | IMPLEMENTED | 12 exclude prefix, 400 BAD_REQUEST missing key-re |
| Bizonylat-sorszám atomic | IMPLEMENTED | `ReceiptSequenceService` — `SELECT ... FOR UPDATE`, `@Transactional(MANDATORY)`, branch-scoped, monotonic, type-prefix |
| `roundHuf` 5 Ft kerekítés | IMPLEMENTED | `util/RoundHuf.java` — MNB-szabványos, BigDecimal overload, használat: `TransactionService`, `TransactionMultiLineService`, `TransactionConversionService`, `HandlingFeeCalculator` |
| Rate validity check | **VERIFY NEEDED** | Subagent visszakérdezett — kézi ellenőrzés |
| `@Transactional` write services | **PARTIAL** | `TransactionReversalService` verified (`@Transactional(rollbackFor = Exception.class)`); többi service verify needed |
| Cash inventory correction (MAIN_TREASURY only) | **VERIFY NEEDED** | `correctCash` / `adjustInventory` keresett, nincs találat — alternative naming (talán reversal-alapú) |

**P1 follow-up:**
- Manuális ellenőrzés a `Rate.validTo > now()` check-et minden tranzakció flow-ban
- Spot-check 5 fontos service `@Transactional` annotation-jén
- Cash korrekciós flow alternative naming keresése (`*Adjustment*`, `*Override*`)

---

### B.6 — Sztornó + napzárás (8/10 IMPLEMENTED)

**Sztornó 5 invariáns:**

| # | Szabály | Status | Hivatkozás |
|---|---|---|---|
| 1 | Csak ugyanazon a napon | IMPLEMENTED | `TransactionReversalService.java:69` (`original.getTransactionDate().equals(LocalDate.now())`) |
| 2 | Csak ugyanazzal a worker-rel (vagy SUPERVISOR) | IMPLEMENTED | `TransactionReversalService.java:82-84` |
| 3 | Csak napzárás ELŐTT | **PARTIAL** | `@Transactional` rollback OK, de explicit pre-closing time-window validáció nem található |
| 4 | Bizonylat-sorszám marad | IMPLEMENTED | STORNO-prefixed receipt + eredeti `REVERSED` status (line 154, non-deletion) |
| 5 | Készlet atomic visszaáll | IMPLEMENTED | Lines 159-169 + `@Transactional` scope |

**Napzárás 5 invariáns:**

| # | Szabály | Status | Hivatkozás |
|---|---|---|---|
| 1 | Címletezés reconciliation (1 Ft tolerance) | IMPLEMENTED | `DailyClosingService.checkEveningDenomination():224-250` |
| 2 | Eltérés-szabály (rounding + NAV control) | IMPLEMENTED | Lines 244 + 389-410 |
| 3 | Per-company aggregálás | IMPLEMENTED | `DailyClosingArchiveService.java:94-95` (`SecurityUtils` branchIds filtering) |
| 4 | Immutable archive snapshot | IMPLEMENTED | `DailyDenominationSnapshot`, `DailySubledgerSnapshot`, `DailyWuAfaTransaction` |
| 5 | Test coverage | **PARTIAL** | `DailyClosingArchiveServiceTest` 415 sor + 10 metódus erős; `TransactionReversalServiceTest` 214 sor + 3 metódus — hiányzó: same-worker + before-closing teszt |

**P2 follow-up:**
- `TransactionReversalServiceTest` bővítése: same-worker + before-closing negatív tesztek
- Explicit `dailyClosing.status != 'CLOSED'` ellenőrzés a sztornó flow-ban (jelenleg `@Transactional` rollback függő)

---

### E.4 / E.5 — Állapotgép + enum (MOSTLY MISSING — ⚠️ refaktor)

| Capability | Status | Mit jelent |
|---|---|---|
| `TransactionStatus` enum | **MISSING** | Létezik `TransactionStatus.java`, de értékei: `PENDING, COMPLETED, REVERSED, FAILED, CANCELLED, ARCHIVED` — **NEM EGYEZIK** a v2 spec-szel (`DRAFT, PENDING_SYNC, COMMITTED, REVERSED, VOIDED`) |
| `RateStatus` enum | **MISSING** | Létezik `RateApprovalStatus.java`, értékek: `PENDING, APPROVED, REJECTED, APPLIED` — **NEM EGYEZIK** a v2 spec-szel (`DRAFT, REVIEW, PUBLISHED, EXPIRED, SUPERSEDED`) |
| Centralized state machine (transition()) | **MISSING** | Direkt ORM setterek: `approval.setStatus(RateApprovalStatus.APPROVED)` (`RateApprovalService.java:81-104`). 25+ Status enum scattered, nincs unified pattern. |
| Raw SQL UPDATE status | PARTIAL | Nem találtam, de Hibernate setter használat áll fenn |
| JPQL/HQL UPDATE | PARTIAL | Nem találtam |
| Transition validation whitelist | **MISSING** | Csak ad-hoc validáció: `approveRateChange()` PENDING-only check (line 85-86) |
| Audit logging at transition | PARTIAL | `AuditLogRepository` infrastruktúra létezik (tamper-evidence hash chain), de invokáció state transition handler-ben nem verifikált |
| WebSocket broadcast RFM publish | PARTIAL | `WebSocketConfig.java`, `ExchangeRateMasterService.java`, `OutboxSyncWorkerService.java` léteznek, integráció verify needed |

**P1 follow-up (külön sprint, jelentős refaktor):**
- TransactionStatus + RateStatus enum **átnevezés / újraértékek** v2 spec szerint
- `TransactionStateMachine` + `RateStateMachine` osztály létrehozása (transition() metódus: validate + audit + outbox + WS broadcast)
- Direkt `setStatus()` hívások (`RateApprovalService:81-104`, `136-155`, +25 más helyen) átírása `Machine.transition()`-re
- Audit-log invokáció minden státusz-átmenetnél kötelező

---

### B.4 — Local-first outbox (mostly IMPLEMENTED)

| Capability | Status | Hivatkozás |
|---|---|---|
| Local SQLite (sql.js, WASM) | IMPLEMENTED | `penztar-client/electron/sqlite.ts` — `~/.valuta/local.db` |
| 9 pending_* outbox tábla | IMPLEMENTED | `pending_transactions`, `pending_conversions`, `pending_bank_transactions`, `pending_stornos`, `pending_handover_operations`, `pending_transfers`, `pending_distributions`, `pending_collections`, `pending_stocktake_items` |
| Idempotency key (UUID) | IMPLEMENTED | minden pending táblán `idempotency_key TEXT` |
| 3× retry max threshold | **PARTIAL** | `retry_count INTEGER` mező + increment logika, **DE max threshold (3) NEM hardcoded** — verify needed |
| Local write FIRST | IMPLEMENTED | minden write a pending_* táblákba MIELŐTT bármilyen network |
| Heartbeat 60s | **PARTIAL** | jelenleg **30s** (NEM 60s) — minor inconsistency |
| Zod validation schemas | **PARTIAL** | nem találva — verify needed |
| Conflict resolution 5s window | **PARTIAL** | `lf_conflict_log` tábla létezik, **algoritmus implementálva-e?** verify needed |
| IdempotencyFilter backend | PARTIAL (client OK) | backend-replay protection verify needed |
| Offline képesség | IMPLEMENTED | pending táblák szinkron write OK |

**P2 follow-up:**
- Heartbeat 30s → 60s konfigváltás (vagy v2 mandate frissítse 30s-ra)
- Zod schema explicit definíció verify
- 5s konfliktus-window algoritmus verify
- 3× retry max threshold hardcode verify

---

## Konklúzió + priorizált akciók

### P0 (azonnali) — 3 db
1. **6 IDOR-gyanús fájl** explicit átnézése multi-tenant izoláció szempontjából (B.3)
2. **43 missing companyId Repository** felülvizsgálata (globális vs. tenant-scope)
3. **Cross-tenant integration teszt-csomag** létrehozása

### P1 (külön sprint) — 4 db
4. **TransactionStatus + RateStatus enum** újraértékek (v2 spec)
5. **TransactionStateMachine + RateStateMachine** osztály
6. **Direkt `setStatus()` → Machine.transition()** refaktor (~25 helyen)
7. **Audit-log invokáció** minden státusz-átmenetnél

### P2 (kényelmi) — 4 db
8. `TransactionReversalServiceTest` bővítése (same-worker, before-closing)
9. Rate validity check kézi ellenőrzés
10. `@Transactional` spot-check 5 service-en
11. Local-first outbox: heartbeat 60s, Zod schema, 5s konfliktus window, 3× retry threshold verify

### NO ACTION (IMPLEMENTED)
- Pmt./AML 6/6 (B.1) ✅
- Bizonylat-sorszám, IdempotencyFilter, roundHuf (B.2 részben) ✅
- Sztornó (B.6) — **4/5 invariáns IMPLEMENTED**, a #3 (before-closing explicit time-window) **PARTIAL** ⚠️ (lásd B.6 részlet — `@Transactional` rollback függő, explicit `dailyClosing.status != 'CLOSED'` ellenőrzés a sztornó flow-ban hiányzik)
- Napzárás 4/5 invariáns ✅
- Local SQLite + outbox tábla (B.4) ✅

---

## Capability map frissítés (a #630 v2 mandate mergelődése után)

A `docs/CAPABILITIES.md` (jelen állapotban a #630 PR-ben van) az audit eredmények alapján frissítendő:
- `Multi-tenant izoláció` IMPLEMENTED → **PARTIAL** (IDOR + 43 Repo gap)
- `TransactionStatus / RateStatus` MISSING marad
- `RFM optimistic locking` MISSING marad
- `MNB 14:30 cron` MISSING (manuális process)
- `Sanction list valós idejű` PARTIAL → **IMPLEMENTED** (audit szerint napi 06:00 cron + fuzzy match)
- `SAR auto-flag` PARTIAL → **IMPLEMENTED** (audit szerint AmlReport + 2 nap deadline)

## Memóriába mentve

- `vault/sessions/2026-05-17-codebase-audit-vv-elvi-compliance.md` (jelen fájl)

## Felhasználói akciók

A user feladata eldönteni:
1. A 6 IDOR-gyanús fájlt **én vagy a fejlesztő csapat** nézze át?
2. Az enum-refaktor (E.4/E.5) **mikor** induljon külön sprint-ként?
3. A 43 missing companyId Repository — automatikus fix-szel javítható-e (Agent-tel), vagy kézi review szükséges üzleti döntéssel (mely globális, mely tenant)?

Az audit-jelentés ezeket nem fixálja — csak dokumentálja. A jelen PR megnyitásával a finding-ek auditálhatóvá válnak.
