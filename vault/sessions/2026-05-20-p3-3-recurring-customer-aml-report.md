---
date: 2026-05-20
topic: P3.3 — Visszatérő ügyfél AML monitoring riport (v2.5.74)
pr: "#712"
branch: feat/v2-5-74-recurring-customer-report
mandate-demo: C.25 pre-PR self-review gate
---

# P3.3 — Visszatérő ügyfél AML monitoring riport (v2.5.74)

## Mit építettünk
Legacy `ugyfelcontrol/idoszakos` parity. Azon ügyfelek listája, akik egy
időszakban ≥ `minTransactions` (default 3, min 2) alkalommal tranzaktáltak.
Pmt. 16. § fokozott ügyfél-átvilágítás (enhanced due diligence) jelölthöz.

### Komponensek
- `dto/report/RecurringCustomerDto.java` — customerId, customerName,
  transactionCount, totalHufAmount, periodStart, periodEnd.
- `service/RecurringCustomerReportService.java` — JPQL `GROUP BY customerId
  HAVING COUNT(t) >= :minTx`, multi-tenant `company.id = :companyId`,
  `financial_effective = TRUE` (CONVERSION parent kizárás), `COMPLETED` status,
  `customerId IS NOT NULL` (anonim kihagyva), null hufAmount → `BigDecimal.ZERO`.
- `controller/RecurringCustomerReportController.java` —
  `GET /api/v1/reports/recurring-customers?from&to&minTransactions`,
  `@PreAuthorize` compliance/vezetői szerepkör, companyId a SecurityUtils-ből
  (NEM request param → nincs IDOR).
- `RecurringCustomerReportServiceTest.java` — 10 unit teszt.

## C.25 mandate első éles demonstrációja (pre-PR self-review gate)
A 2026-05-20 user-direktíva ("még mindig nagyon sok a CI/Copilot/Sourcery/Codex
hibatalálat... javítsd a saját önellenőrző mechanizmusodat") után épített
C.25 4-fázisú gate első teljes alkalmazása:

1. **Lokális kapuk:** célzott unit teszt 10/10 PASS; teljes backend regresszió
   korábban zöld; comment-only DTO/service módosítás nem érinti a fordítást.
2. **10-pontos checklist:** multi-tenant ✓, null-safety ✓, BigDecimal compareTo ✓,
   financial_effective ✓, @PreAuthorize ✓, CodeQL log-injection (csak UUID/LocalDate
   logolva) ✓, JPQL parametrizált ✓, version-sync ✓.
3. **2-kör saját subagent review:**
   - Round 1 → SAFE TO MERGE + 2 P2-cosmetic finding (DTO javadoc "utolsó ismert"
     vs `MAX(customerName)` lexikografikus; `minTx` Long-bind teszt hiánya).
     **Mindkettő javítva a PR ELŐTT** (ez a C.25 lényege — a GitHub AI gate elé).
   - Round 2 (fresh-eye) → SAFE TO MERGE, nincs P0/P1.
4. **Push + PR #712 + GitHub CI/AI gate** (folyamatban).

**Tanulság:** a Round 1 subagent pre-emptálta azt a 2 cosmetic finding-et, amit
a Sourcery/Codex amúgy a PR-en jelzett volna → cél: ≤1 finding/PR.

## Verzió
4-way bump 2.5.73 → 2.5.74 (penztar + frontend-react + kozponti + arfolyam
package.json + package-lock.json root + packages[""]).

## Végkimenet — PR #712 MERGED (commit acf8d435f)
- **CI**: minden required check ZÖLD (backend build+test, java-kotlin Analyze,
  javascript-typescript Analyze, CodeQL, Playwright Auth Reload Smoke, frontend
  lint+typecheck, penztar-client, Trivy, GitLeaks, dep-review, UTF-8 guardrail).
- **AI gate (3 finding, mind javítva commit 773fd413f-ben PR-en belül):**
  1. Codex P2 + Copilot — üres-string `customerId` fals csoport → `AND t.customerId <> ''`
     (sibling-minta `TransactionRepository:472`). JPQL-content teszt bővítve.
  2. Copilot — root package.json + pom.xml 2.5.73 maradt → version-sync TELJES set
     (root + pom + lockfile) bump 2.5.74; `check-four-area-alignment.mjs` OK.
  3. Copilot — AI_CONTRACT 300 LOC: dokumentált bundled-feature kivétel (PR-kommentben).
- **admin-merge** `--squash --admin --delete-branch` → main HEAD acf8d435f.
- **Hetzner deploy**: in_progress (V710 pre-flight Flyway dup-guard; nincs új migration).

## C.25 mandate erősítés (a #712 2 elcsúszott findingje alapján)
A C.25 checklist + auto-memory bővítve:
- **Sibling-konzisztencia (QUERY)**: új JPQL-nél grep a meglévő AML/riport query-kre
  az EXTRA szűrőkért (`<> ''` nem csak `IS NOT NULL`).
- **Version-sync TELJES set**: ROOT package.json + ROOT lockfile + pom.xml + 4 kliens,
  majd `node scripts/check-four-area-alignment.mjs` lokálisan push ELŐTT.

## Következő (autonóm terv)
- v2.5.74 4-installer build (ALLOW_UNSIGNED_BUILD=1) — release-checkpointon (nem
  feature-önként; több feature batch-elve).
- Következő legacy/strat. szakasz folytatása.
