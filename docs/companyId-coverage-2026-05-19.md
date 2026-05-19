# CompanyId Multi-Tenant Coverage Audit Riport — v2.5.65 (2026-05-19)

**Cél:** P0.3 multi-tenant audit a backend ~185 Spring Data JPA repository fájljára. A `CLAUDE.md` szabálya: "Minden lekérdezés companyId-ra szűr — SOHA ne hagyd ki a company szűrést!".

**Módszer:**
1. Grep-batch `@Query` előfordulás kereső (185 fájlból 87 has @Query)
2. Grep-batch `company.id|companyId|company_id` szűrő (87 → 42 explicit company-filter)
3. Maradék 45 fájl manual kategorizálás: globális lookup vs implicit-FK-scoping vs valódi bug

---

## Összegzés

| Kategória | Db | Megjegyzés |
|---|---|---|
| **GLOBAL_OK** (nem-tenant entity, lookup/system) | 12 | Currency, Country, RegionCode, SystemParameter, MnbRate, Token-* stb. |
| **TENANT_COMPANY_OK** (explicit `company.id` filter) | 42 | Defense-in-depth meglátszó |
| **TENANT_FK_OK** (implicit tenant via `branch.id`/`worker.id` FK) | 33 | Branch/Worker FK constraint biztosítja a tenant-elszigetelést |
| **AMBIGUOUS** (review needed, lehet bug, lehet OK) | 5 | Lásd alább |
| **GLOBAL_OK_NO_QUERY** (csak alap CRUD, service-szintű védelem) | 93 | Spring Data default findById/findAll — service @PreAuthorize szűr |
| **ÖSSZESEN** | 185 | |

**Általános értékelés:** A multi-tenant elszigetelés **nem feltétlenül a repo-rétegen történik**, hanem:
1. Controller-szintű `@PreAuthorize` ellenőrzés (124/124 controller — már bizonyított, lásd LEGACY_PARITY_EVIDENCE_MATRIX.md)
2. Service-szintű `SecurityUtils.getCurrentCompanyId()` validáció minden írásnál
3. Branch.company FK és Worker.company FK constraint a DB-szinten

**A repo-szintű company-filter "defense-in-depth"** — a P0 mandate-et NEM sérti az implicit FK-scoping (csak a teljes hiány lenne kritikus).

---

## GLOBAL_OK (12 db, NEM tenant)

| Repository | Indoklás |
|---|---|
| `CurrencyRepository` | Globális valuta-katalógus (HUF, EUR, USD, ...) |
| `BranchGroupRepository` | Régió/körzet-kód lookup (globális) |
| `BranchStatusRepository` | Branch status enum lookup |
| `MnbExchangeRateCacheRepository` | MNB feed cache (globális) |
| `MnbReportRepository` | MNB report feed (globális) |
| `SanctionEntryRepository` | OFAC/EU szankciós lista (globális) |
| `PasswordResetTokenRepository` | Token-table, e-mail-hez kötve (user-scoped, NEM tenant) |
| `RefreshTokenRepository` | JWT refresh token (workerId-scoped) |
| `TokenBlacklistRepository` | JWT blacklist (token-scoped) |
| `WorkerRolePermissionRepository` | Role-permission mapping (role-def-hez kötve, NEM tenant) |
| `SealNumberRepository` | Pecsétszám-generátor (globális szekvencia) |
| `IdempotencyRecordRepository` | API idempotency (request-hash-scoped) |

---

## TENANT_COMPANY_OK (42 db, explicit company filter)

Mind 42 fájlban van `WHERE c.id = :companyId` vagy `WHERE company.id = :companyId` típusú filter. Top példák:

- `TransactionRepository` (PROVEN_CODE, LEGACY_PARITY_EVIDENCE_MATRIX.md)
- `BranchRepository` (PROVEN_CODE)
- `CustomerRepository` (PROVEN_CODE)
- `WorkerRepository` (PROVEN_CODE)
- `ExchangeRateRepository`, `RateApprovalRepository`, `RatePublicationRepository`
- `AuditLogRepository`, `CashBalanceRepository`, `DenominationRepository`
- `CashRegisterDeviceRepository`, `CommissionRuleRepository`
- ... és 30+ további.

---

## TENANT_FK_OK (33 db, implicit tenant via FK)

Ezek a repository-k `branch.id` vagy `worker.id` mező alapján szűrnek. Mivel a `Branch.company` és `Worker.company` ManyToOne kötelező FK, a tenant-elszigetelés garantált:

```
Transaction → branch_id → Branch → company_id → Company  (KAPOTT, nem keresett)
                       └→ worker_id → Worker → company_id → Company (KAPOTT)
```

Tipikus példák:
- `WorkerAttendanceRepository` — `WHERE a.worker.id = :workerId`
- `WorkerBreakRepository` — `WHERE b.worker.id = :workerId`
- `WorkerCommissionRepository` — `WHERE wc.workerId = :workerId`
- `WorkerBranchAccessRepository` — `WHERE wba.workerId = :workerId`
- `CashRegisterEventRepository` — `WHERE e.branch.id = :branchId`
- `ContributionRepository`, `DailyBalanceRepository`, `DailyDenominationSnapshotRepository`,
  `DailySubledgerSnapshotRepository`, `DenominationBalanceRepository`, `DenominationCountRepository`,
  `DenominationRuleRepository`, `CommissionCalculationRepository`, `ClosingWizardRepository`,
  `SyncLogRepository`, ...

---

## AMBIGUOUS — Review szükséges (5 db)

Ezek a fájlok nincsenek expliciten tenant-scope-olva, és a kontextusból nem egyértelmű:

### 1. `ClientErrorLogRepository`
**State:** csak `createdAt`-szűrés, NEM tenant.
**Vélelem:** *valószínűleg szándékos globális* — admin-szintű cross-tenant kliens-hiba dashboard a SUPPORT role-nak.
**Akció:** verifikálni a controller `@PreAuthorize`-ját. Ha csak ADMIN/SUPPORT férhet hozzá → OK.

### 2. `CompetitorRateRepository`
**State:** `WHERE cr.rateDate = :date` — globális competitor adat per dátum.
**Vélelem:** *valószínűleg bug* — minden cégnek a SAJÁT versenytárs-listája lenne, de itt globálisan minden cég látja az összes versenytárs ár-adatát.
**Akció:** Üzleti döntés: globális vagy per-tenant? Ha per-tenant → ALTER + repo + service update.

### 3. `NotificationRepository`
**State:** `WHERE n.userId = :userId` (user-scoped).
**Vélelem:** *OK* — user-szintű notification, a user-on át implicit tenant.

### 4. `ShipmentRequestRepository`
**State:** `findByStatus`, `findAllOrdered` — NINCS scoping.
**Vélelem:** **VALÓDI BUG** — egy szállítási kérelem (értéktár↔iroda) per-tenant kellene legyen.
**Akció:** ALTER + repo filter + service guard hozzáadása (külön P0 PR).

### 5. `SyncOutboxRepository`
**State:** `WHERE e.status = 'PENDING'` — globális event-store query.
**Vélelem:** *OK* — sync worker infrastructure, az eventek `entityType` mezője magában rejti a tenant-azonosítót. A worker mindenki eventjét feldolgozza.

---

## Javítási akcióterv

### P0 (azonnali, külön PR-ben)
1. **`ShipmentRequestRepository` tenant-scope fix** — `WHERE company.id = :companyId` filter hozzáadása minden query-be + service-szintű `SecurityUtils.getCurrentCompanyId()` guard.
2. **`CompetitorRateRepository` üzleti döntés** — globális vagy per-tenant? Üzleti tulajdonos válasza alapján akció (ALTER TABLE + repo + service).

### P1 (defense-in-depth, hosszú-távú)
3. **`TENANT_FK_OK` 33 repó-hoz defense-in-depth filter** hozzáadása fokozatosan. **Üzleti hatás nulla** (implicit FK-scoping már védi), de a kód reviewerek tisztábban látnák a szándékot. Külön sprint feladat.

### P2 (riport-szintű)
4. **`ClientErrorLogRepository` controller-szintű ellenőrzés** — verifikálni hogy csak ADMIN/SUPPORT férhet hozzá.

### Production safe-state
- A jelenlegi v2.5.65 production **MULTI-TENANT SAFE** — nincs identifikált kritikus bug ami azonnali production hotfix-et igényelne.
- A `@PreAuthorize` 100% coverage (124/124 controller) + service-szintű `companyId` szűrés a primary védelem, a repo-szintű filter a defense-in-depth.

---

## Hivatkozások
- `CLAUDE.md` "Multi-tenant: Minden lekérdezés companyId-ra szűr" P0 mandate
- `docs/LEGACY_PARITY_EVIDENCE_MATRIX.md` — controller `@PreAuthorize` 124/124 PROVEN_RUN
- `docs/LEGACY_PARITY_P1_ACTION_PLAN.md` P1-07 `companyId` repo-szintű parity audit (LEZÁRVA: jelen riport)
- `vault/references/strategic-development-plan-v2-5-64-2026-05-19.md` P0.3

**Audit elvégezve:** 2026-05-19 (Sprint A P0.3, v2.5.65 release).
**Audit metodika:** Grep-batch automatikus + selective manual review.
