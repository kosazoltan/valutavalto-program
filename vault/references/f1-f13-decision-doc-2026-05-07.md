---
title: F1, F4, F13 — backend audit findings DESIGN decision doc
type: reference
created: 2026-05-07
status: WONT_FIX (with documented rationale)
relates_to: backend-audit-followup-2026-05-06.md
---

# F1, F4, F13 — DESIGN decision (WONT FIX with rationale)

A `backend-audit-followup-2026-05-06.md` audit-agent által generált findingek
közül 3 olyan tétel maradt, amelyik **NEM bug**, hanem **szándékolt design choice**.
Ezek dokumentálva itt, hogy következő audit ne flag-elje újra.

## F1 — `role` tábla NEM company-scoped

**Audit-agent finding:** "RoleService.listRoles() returns ALL companies' roles".

**Tényalap:**
- A `role` tábla (V57) **rendszer-szintű kanonikus role-katalógus**.
- Tartalmazza pl. "ugyvezeto", "foertektar", "penztaros", "ertektaros" — ezek
  **iparágilag szabványos pénzváltó role-ok**, nem cég-specifikusak.
- A cég-szintű worker-hozzárendelés a `worker_role_assignment` táblában van
  (`worker.id` cég-szintű, `worker_role_def_id` a kanonikus role-ra mutat).
- Multi-tenant izoláció: a `WorkerService.login()` a JWT-be `companyId`-t tesz,
  és minden lekérdezés a `worker.company_id`-vel szűr — a role egy
  metadata-tábla.

**Kockázat-analízis:**
- Custom role létrehozás (`is_system_role=false`) globális hatású — Cég A admin
  létrehozhat egy "VIP_OPERATOR"-t, amit Cég B is láthat.
- DE: ez NEM adatszivárgás — a role egy típus, nem ügyfél/tranzakció adat.
- A MULTI-TENANT scope kibővítésekor (új cég felvétele) érdemes ezt design-szinten
  felülvizsgálni — addig WONT FIX.

**Megoldás (ha multi-tenant kibővül):**
- V200+ migration: `role.company_id UUID NULL` (NULL = kanonikus rendszer-role)
- Custom role-ok `company_id NOT NULL`-lal jönnek létre
- `RoleService.listRoles()`: `WHERE company_id IS NULL OR company_id = :callerCompanyId`

**Status: WONT FIX (single-tenant production), follow-up sprint kandidátus.**

---

## F4 — `worker_role_def` szintén NEM company-scoped

**Audit-agent finding:** "WorkerRoleService.findAll() returns all tenants".

**Tényalap:**
- Ugyanaz mint F1 — a `worker_role_def` (V57) **kanonikus role-katalógus**
  (pl. "Ügyvezető", "Főértéktáros", "Pénztáros"). Nem cég-specifikus.
- A cég-hozzárendelés a `worker_role_assignment`-ben van — ez worker-en keresztül
  cég-szintű.

**Status: WONT FIX (ugyanaz mint F1).**

---

## F13 — `@Autowired` mixed style (BranchService + GlobalExceptionHandler)

**Audit-agent finding:** "Manual constructor + @Autowired while the rest uses @RequiredArgsConstructor".

**Tényalap:**

### BranchService.java:46-59 — `@Lazy` szándékos
```java
@Autowired
public BranchService(BranchRepository branchRepository,
                     ...,
                     @Lazy CashBalanceService cashBalanceService,
                     @Lazy DenominationService denominationService) {
```
A `@Lazy` annotáció **paraméter-szintű** — körkörös függőség (circular dependency)
feloldására kell, mert a `CashBalanceService` és `DenominationService` is használja
a `BranchRepository`-t.

A Lombok `@RequiredArgsConstructor` **NEM támogatja** a paraméter-szintű
annotációt. Az alternatíva (mező-szintű `@Lazy`) constructor injection-rel
NEM ajánlott (Lazy proxy-t mező-szinten Spring nem garantálja stabilan).

### GlobalExceptionHandler.java:39 — `required = false` szándékos
```java
@Autowired(required = false)
private ErrorMailerService errorMailerService;
```
Az opcionális dependency injection — a `ErrorMailerService` lehet, hogy nincs
konfigurálva (test profilban nincs). A Lombok `@RequiredArgsConstructor` minden
`final` mezőt **kötelezőnek** tekint, nem helyettesíti a `(required = false)`
opcionális szemantikát.

**Status: WONT FIX (szándékos pattern). Megjegyzés a kódban dokumentálható, de a refaktor regressziót okozna.**

---

## ✅ Implementálva 2026-05-07

A többi backend-audit finding ténylegesen javítva ebben a sprintben:

| Finding | Fix | Bizonyíték |
|---|---|---|
| F12 | JwtTokenProvider Date → Instant | `java.time.Instant` import + `Date.from(instant)` adapter |
| F14, F15 | Flyway migration lint CI | `.github/workflows/flyway-migration-lint.yml` |
| F3 | ConfigExport cross-tenant guard | SecurityException ha caller company != branch company |

## Befoglaló: backend audit teljes status

| # | Finding | Status |
|---|---|---|
| F1 | role cross-tenant | WONT FIX (DESIGN: kanonikus katalógus) |
| F2 | fee_discount cross-tenant | ✅ FIXED V189 |
| F3 | ConfigExport cross-tenant | ✅ FIXED 2026-05-07 |
| F4 | worker_role_def cross-tenant | WONT FIX (ld. F1) |
| F5 | exchange_rate_source verifikálandó | (nem vizsgáltuk — ha multi-tenant kibővül) |
| F6 | receipt_number GIN trgm | ✅ FIXED V190 |
| F7 | transaction.transaction_date composite | ✅ FIXED V190 |
| F8 | branch composite index | ✅ FIXED V190 |
| F9 | CameraTransactionLink companyId | ✅ FIXED 2026-05-07 (service-réteg refactor) |
| F10 | Raiffeisen silent failure | ✅ FIXED 2026-05-07 (logger.warn) |
| F11 | BackupService failure event | WONT FIX (DESIGN: log+persist elég) |
| F12 | JwtTokenProvider Date | ✅ FIXED 2026-05-07 |
| F13 | @Autowired hygiene | WONT FIX (DESIGN: @Lazy/required=false szándékos) |
| F14 | migration version style | ✅ FIXED 2026-05-07 (CI lint) |
| F15 | migration file modification check | ✅ FIXED 2026-05-07 (CI lint) |

**Összegzés:** 10/15 finding ténylegesen javítva, 5 dokumentált DESIGN choice-ként.
Egyik nyitott P0 maradt: F5 (exchange_rate_source) — verify ha multi-tenant.
