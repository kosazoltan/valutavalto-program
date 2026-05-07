---
title: Backend audit follow-up — multi-tenant + index sprint
type: reference
created: 2026-05-06
status: PARTIALLY_IMPLEMENTED (F2 done, F1+F3+F4+F5 deferred)
---

# Backend audit follow-up — 2026-05-06

## Forrás

Háttér audit-agent eredménye (2026-05-06 22:25 CEST), tényalapú repo-olvasás után.
A user-direktíva: minden hibát javítani. Egy session-be egyszerre nem fér bele
mind, ezért a kritikus pénzügyi hatásút (F2) AZONNAL javítom, a többit
follow-up sprintnek dokumentálom.

## ✅ Implementálva ebben a session-ben

### F2 — `fee_discount` cross-tenant scope (V189)

- **Probléma:** A `fee_discount` tábla NEM volt `company_id`-vel scope-olt.
  Egy cég kedvezménykódja (pl. "VIP10") másik cégre is alkalmazható volt
  ha az is megadta ugyanazt a kódot a system_parameter-ben.
- **Pénzügyi hatás:** Helytelen díjszámítás multi-tenant üzemeltetés esetén.
- **Fix:**
  - V189 migration: `company_id` UUID NOT NULL oszlop + `(company_id, code)` unique
  - `FeeDiscount` entity: `@ManyToOne Company company`
  - `FeeDiscountRepository`: `findByCompanyId`, `findByCompanyIdAndCode`,
    `findByCompanyIdAndIsActiveTrue` metódusok
  - `DiscountThresholdService`: `findActiveDiscount` cég-szintű lookup
  - `FeeService`: `listDiscounts/createDiscount/updateDiscount/deleteDiscount`
    cég-szintű scope + cross-tenant védelem (más cég kedvezménye nem módosítható)
- **Verifikáció:** 1111/1111 backend test PASS.

## ⚠️ Deferred — follow-up sprint

A többi finding hasonló refaktort igényel, de nagyobb scope (több repo + service +
test). Külön sprintben (~2-3 nap):

### F1 — `role` + `worker_role_def` cross-tenant
- `RoleService.listRoles()` és `listPermissions()` `findAll()`-t használ.
- `role` és `worker_role_def` táblák V57-ben jöttek létre, NINCS company_id.
- **Hatás:** Admin minden tenant role-jait látja.
- **Sprint scope:** V190 migration + Role + WorkerRoleDef entity + RoleService refactor
  + RoleController + tests.

### F3 — `system_parameter` cross-tenant
- `SystemParameterService.listAll()` `findAll()`.
- V75 `organizational_system_parameter` létezik per-tenant override-ra,
  de a base `system_parameter` global.
- **Hatás:** ConfigExport ZIPbe minden tenant config-jét bele teszi.
- **Sprint scope:** Migration `system_parameter` per-tenant rekordokkal +
  ConfigExportService szigorítása.

### F4 — `worker_role_def` cross-tenant
- (F1 része lényegében)

### F5 — `exchange_rate_source.findAll()` controller-szinten
- `ExchangeRatePollingController:110`. Verifikálandó hogy a tábla per-tenant-e.

### F6-F9 — Hot query indexek
- `idx_tx_company_date` composite (transaction.created_at + company_id)
- `idx_branch_company_active_vault` covering composite
- `pg_trgm` extension + `idx_tx_receipt_lower_trgm` GIN
- `CameraTransactionLink.findByReceiptNumber` companyId scope

### F10 — Raiffeisen silent parse failure
- `RaiffeisenRateService:199-200, 257-258` `catch (NumberFormatException ignored) {}`
- **Sprint scope:** Strukturált logger.warn + Micrometer counter.

### F11 — BackupService failure event
- `BackupService:126-135` swallow-eli az IOException-t.
- **Sprint scope:** ApplicationEventPublisher + audit_log critical alert.

### F12 — `java.util.Date` modernizáció
- `JwtTokenProvider:16` import legacy Date-et használ.
- **Sprint scope:** Migration `java.time.Instant` + JJWT 0.12+ Instant API.

### F13 — `@Autowired` mixed style
- `BranchService:46-59`, `GlobalExceptionHandler` — Lombok @RequiredArgsConstructor preferred.
- **Sprint scope:** Refaktor csak ha @Lazy szempontok szét lehet választani.

### F14-F15 — Migration consistency
- `V3_5`, `V3_7`, `V108_1` decimal-style version (out-of-order risk).
- **Sprint scope:** CI lint script + dokumentáció.

## Notable POSITIVE findings (audit által megerősítve)

- ✅ Nincs SQL injection (Criteria API + parameterized native query)
- ✅ Nincs hardcoded jelszó (env-var override)
- ✅ Nincs `System.out.println` production code-ban
- ✅ Nincs üres catch block (csak named "ignored", de F10 folowup)
- ✅ Nincs duplicate Flyway version

## Top priority sorrend (jelenlegi P0/P1 bázisra)

1. F2 ✅ (DONE 2026-05-06)
2. F1 + F4 (role + worker_role_def cross-tenant) — P0
3. F3 (system_parameter cross-tenant) — P0
4. F9 (CameraTransactionLink companyId) — P0 GDPR
5. F6 (receipt_number GIN trgm index) — P1 perf at scale
6. F7 (transaction.transaction_date composite index) — P1 perf
7. F10 (Raiffeisen silent failure) — P1 stale rate risk
8. F11 (BackupService failure event) — P1 DR posture
9. F12 (java.util.Date modernization) — P2 hygiene
10. F13 (@Autowired hygiene) — P2

## Hivatkozott fájlok

- backend/src/main/resources/db/migration/V189__fee_discount_company_id.sql
- backend/src/main/java/hu/puzzleir/valuta/entity/FeeDiscount.java
- backend/src/main/java/hu/puzzleir/valuta/repository/FeeDiscountRepository.java
- backend/src/main/java/hu/puzzleir/valuta/service/DiscountThresholdService.java
- backend/src/main/java/hu/puzzleir/valuta/service/FeeService.java
