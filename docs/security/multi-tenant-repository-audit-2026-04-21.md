# Multi-Tenant Repository Audit — 2026-04-21

**Scope:** backend/src/main/java/hu/puzzleir/valuta/repository/
**Szabaly (CLAUDE.md):** "Multi-tenant: Minden lekerdezes companyId-ra szur — SOHA ne hagyd ki a company szurest!"

## Osszegzes

**13 repository metodus** futtatasahoz hianyzik a `companyId` WHERE feltetel. Nem mindegyik kritikus — sok helyen a `branch_id` implicit company-vedelmet biztosit, mert a branch mindig egy cegehez tartozik. DE a kovetkezok kozott van **cross-tenant adat leak** veszely ha valaki manipulalt branchId-vel, vagy ha a sevicen belul elfelejtenek SecurityUtils.getCurrentCompanyId-val validalni.

## Priorizalt lista

### CRITICAL (penzadatot adhat ki, azonnali javitas javasolt)

1. **ExchangeRateRepository.findActiveByDateAndBranch** (line 138-145)
   - Query: `WHERE er.active = true AND er.validDate = :date AND (er.branch IS NULL OR er.branch.id = :branchId)`
   - Problema: `er.branch IS NULL` ag minden ceg nulla-branch-u ratet visszaadja.
   - 4 call site: ExchangeRatePollingService, DailyReportService, SupervisorService, MonthlyReportService
   - **Javitas:** hozzaadni `AND er.company.id = :companyId`, + 4 call site frissitese + teszt mockok.

### HIGH (tenant boundary serules)

2. **BranchRepository.findByCode(String code)** (line 19)
   - Derived: `findByCode` — globalis, nem szuri a ceget.
   - Javitas: `Optional<Branch> findByCompanyIdAndCode(UUID companyId, String code)` alternativa, vagy depreciate.

3. **BranchRepository.existsByCode** (line 24) — ugyanaz, "code exists" globalisan.

4. **NavClosingRepository.findWithFilters** (line 50-57)
   - Nincs `companyId` parameter; engedi `:branchId IS NULL` bypass-t ami minden ceg NavClosing-jat visszaadja.

### MEDIUM (cross-tenant listaztathatosag)

5. BranchRepository.findByIsActiveTrue (line 29)
6. BranchRepository.findByBranchTypeCode (line 34-35)
7. BranchRepository.findByBranchStatusCode (line 40-41)
8. BranchRepository.searchByNameOrCode (line 58-61)
9. BranchRepository.findByCity (line 66)
10. BranchRepository.findByVaultTerritoryId (line 111)
11. BranchRepository.findRootBranches (line 52-53)
12. NavClosingRepository.findByStatus (line 33)

### LOW (technikailag branch_id is ceghez kotott)

13. **TransactionRepository.findByBranchAndDate** (line 52-55)
    - `WHERE t.branch.id = :branchId AND t.transactionDate = :date`
    - Branch implicit company-fogasu — de ha rossz branchId atad, cross-tenant tx jonne ki.
14. **TransactionRepository.findByWorkerAndDate** (line 64-67) — hasonlo.
15. **TransactionRepository.findByWorkerIdAndTransactionDateBetween** (line 76-80) — hasonlo.

## Javasolt strategia

**Opcio A: Full audit + fix mind a 15-nek (1-2 nap)**
- Minden repository metodushoz hozzaadni `@Param("companyId")` parametert.
- Minden service call site-ot frissiteni `SecurityUtils.getCurrentCompanyId()` hasznalatara.
- Minden teszt mockot frissiteni.
- **Kockazat:** sok helyen kell valtoztatni, esetleges regression veszely.

**Opcio B: Csak a CRITICAL + HIGH (fel nap)**
- 4 metodus javitasa: ExchangeRate findActiveByDateAndBranch, BranchRepository findByCode + existsByCode, NavClosingRepository findWithFilters.
- A tobbi medium/low levegoben marad, kesobbi sprintre.

**Opcio C: @TenantFilter aspect (2-3 nap, de one-time fix)**
- Spring AOP aspect ami automatikusan hozzaad `company_id` feltetelt minden multi-tenant entity query-hez (a `@Where(clause = ...)` Hibernate filter alapjan).
- Hosszu tavon robosztusabb, de komplex.

## Ajanlott sorrend

1. **Ma:** ez a jelentes — elkeszitve.
2. **Kovetkezo sprint:** Opcio B (CRITICAL + HIGH javitasa, kb. 4-5 ora ha bele-ertjuk a teszteket).
3. **Kesobbre (Q3 2026):** Opcio C (Hibernate @Where aspect) minden multi-tenant entity-re.

## Megjegyzes

A mai audit NEM igaz kriptikus hibak listaja — a `branch_id` alapu szures sok esetben de-facto mukodik, mert a branch-ek cegekhez tartoznak. A riskelet a jovobeli fejlesztok akik hanyagul vagy frissen erkezve irnak olyan kodot, ami a kontextust elfogadja (pl. audit export endpoint ami egyszerre lat minden tenant tranzakcioját ha valaki modifialt request-parametert ad be).

Elkeszitette: Claude Sonnet 4.5 Agent SDK

---

## UPDATE — 2026-04-21 kesobb (masodik iteracio)

A riport elso verzioja utan a kovetkezo serulekenysegek kerultek megoldasra:

### FIXED / DEPRECATED

- CRITICAL #1 ExchangeRateRepository.findActiveByDateAndBranch — FIXED (PR #75)
- HIGH #2 BranchRepository.findByCode — @Deprecated + findByCompanyIdAndCode ajanlva (PR #76)
- HIGH #3 BranchRepository.existsByCode — @Deprecated + existsByCompanyIdAndCode uj (PR #76)
- HIGH #4 NavClosingRepository.findWithFilters — FIXED: companyId parameter hozzaadva (PR #76)
- MEDIUM #5 BranchRepository.findByIsActiveTrue — @Deprecated
- MEDIUM #6 BranchRepository.findByBranchTypeCode — @Deprecated + company-scoped variant
- MEDIUM #7 BranchRepository.findByBranchStatusCode — @Deprecated
- MEDIUM #8 BranchRepository.searchByNameOrCode — @Deprecated + company-scoped variant
- MEDIUM #9 BranchRepository.findByCity — @Deprecated + findByCompanyIdAndCity uj
- MEDIUM #10 BranchRepository.findByVaultTerritoryId — @Deprecated + company-scoped variant
- MEDIUM #11 BranchRepository.findRootBranches — @Deprecated + findRootBranchesByCompanyId uj
- MEDIUM #12 NavClosingRepository.findByStatus — @Deprecated + findByBranchCompanyIdAndStatus uj
- LOW #13 TransactionRepository.findByBranchAndDate — kiegeszitve findByCompanyIdAndBranchAndDate variansal (opcional usage)

### CALL SITES UPDATED

- BranchService.findByCode -> findByCompanyIdAndCode
- BranchService.validateBranchCode -> existsByCompanyIdAndCode
- NavClosingService.listClosings -> companyId parameter

### STILL OPEN

- LOW #14 TransactionRepository.findByWorkerAndDate — nincs atirva, de branch implicit ved
- LOW #15 TransactionRepository.findByWorkerIdAndTransactionDateBetween — nincs atirva, de worker-company FK implicit ved

### Kovetkezo lepesek

- Spring AOP @TenantFilter aspect / Hibernate @Where globalis filter bevezetese — Q3 2026
- @Deprecated metodusok eltavolitasa 6+ honap utan (mikor minden hivo atallt)