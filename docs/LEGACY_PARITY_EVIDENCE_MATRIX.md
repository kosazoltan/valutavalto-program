# Legacy Parity Evidence Matrix

Frissitve: 2026-04-17

Ez a dokumentum kodszintu es futtatasi bizonyitekokat rendel a parity checklist pontokhoz.

Statuszok:
- `PROVEN_CODE`: kodban igazolt
- `PROVEN_RUN`: futtatassal igazolt
- `PARTIAL`: reszleges / tovabbi UAT kell
- `GAP`: nyitott hiany

## 1. Kritikus uzleti modulok

| Terulet | Statusz | Bizonyitek | Megjegyzes |
|---|---|---|---|
| Tranzakcio vetel/eladas | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java](backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java#L91), [backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java](backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java#L228) | `executeBuy` es `executeSell` jelen van |
| Foglalo modul | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/controller/ReservationController.java](backend/src/main/java/hu/puzzleir/valuta/controller/ReservationController.java#L36), [backend/src/main/java/hu/puzzleir/valuta/service/ReservationService.java](backend/src/main/java/hu/puzzleir/valuta/service/ReservationService.java#L46) | API + service implementacio megvan |
| Foglalo legacy statusz mapping | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/entity/ReservationStatus.java](backend/src/main/java/hu/puzzleir/valuta/entity/ReservationStatus.java#L8), [backend/src/main/java/hu/puzzleir/valuta/entity/ReservationStatus.java](backend/src/main/java/hu/puzzleir/valuta/entity/ReservationStatus.java#L24) | `_visszatipus` megfeleltetes dokumentalt |
| AML heti gongyoles | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java](backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java#L261), [backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java](backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java#L343) | `getWeeklyTotal` es hasznalata klasszifikacioban |
| AML 8M eves kuszob | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java](backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java#L247), [backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java](backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java#L365) | `THRESHOLD_8M` + TranzTipus 3 logika |
| Dekad riport endpoint + service | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/controller/DecadeReportController.java](backend/src/main/java/hu/puzzleir/valuta/controller/DecadeReportController.java#L24), [backend/src/main/java/hu/puzzleir/valuta/service/DecadeReportService.java](backend/src/main/java/hu/puzzleir/valuta/service/DecadeReportService.java#L35) | Generalas/lezaras/listazas jelen van |
| Napzarasban dekad hook | PARTIAL | [backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java](backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java#L400), [backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java](backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java#L503) | Audit-log szintu hook van, teljes parity UAT meg nyitott |
| Nyitokeszlet automatika (zaro -> kov. napi nyito) | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/DailySessionService.java](backend/src/main/java/hu/puzzleir/valuta/service/DailySessionService.java#L221), [backend/src/main/java/hu/puzzleir/valuta/service/DailySessionService.java](backend/src/main/java/hu/puzzleir/valuta/service/DailySessionService.java#L228) | Elozo lezart session `closingBalanceHuf` erteke lesz a nyito |
| Treasury cegszintu osszesites | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L36) | Company-wide summary implementalva |
| Treasury irodaszintu osszehasonlitas | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L88) | Branch comparison implementalva |
| Treasury bankflow osszesites | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L111) | Bank be/ki aggregacio implementalva |
| BranchGroup aggregacio | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L175), [backend/src/main/java/hu/puzzleir/valuta/controller/TreasuryController.java](backend/src/main/java/hu/puzzleir/valuta/controller/TreasuryController.java#L49) | Kodszinten implementalt korzet osszesites |
| Company/KFT aggregacio | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L278), [backend/src/main/java/hu/puzzleir/valuta/controller/TreasuryController.java](backend/src/main/java/hu/puzzleir/valuta/controller/TreasuryController.java#L55), [backend/src/main/java/hu/puzzleir/valuta/dto/treasury/TreasuryAggregateDto.java](backend/src/main/java/hu/puzzleir/valuta/dto/treasury/TreasuryAggregateDto.java#L17) | Kodszinten implementalt cegszintu aggregacios endpoint |
| NAV integracio valodisag | GAP | [backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java](backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java#L13), [backend/src/main/java/hu/puzzleir/valuta/service/NavIntegrationService.java](backend/src/main/java/hu/puzzleir/valuta/service/NavIntegrationService.java#L11) | Placeholder/mock implementacio |

## 2. Security es multi-tenant bizonyitek

| Terulet | Statusz | Bizonyitek | Megjegyzes |
|---|---|---|---|
| Controller szintu auth guard jelenlet | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/controller/DecadeReportController.java](backend/src/main/java/hu/puzzleir/valuta/controller/DecadeReportController.java#L20), [backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java](backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java#L17) | Szeleskoru `@PreAuthorize` jelenlet latszik |
| `@PreAuthorize` statikus lefedettseg (fajlszint) | PROVEN_RUN | [backend/src/main/java/hu/puzzleir/valuta/controller](backend/src/main/java/hu/puzzleir/valuta/controller), [backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java](backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java#L29), [backend/src/main/java/hu/puzzleir/valuta/controller/HealthController.java](backend/src/main/java/hu/puzzleir/valuta/controller/HealthController.java#L32), [backend/src/main/java/hu/puzzleir/valuta/controller/VersionController.java](backend/src/main/java/hu/puzzleir/valuta/controller/VersionController.java#L10) | Audit eredmeny: 124 controller, 124 tartalmaz `@PreAuthorize` |
| `companyId` teljes repo-audit | GAP | [backend/src/main/java/hu/puzzleir/valuta](backend/src/main/java/hu/puzzleir/valuta) | Kotelezo formalis ellenorzes nyitott |

## 3. Futtatasi bizonyitekok (aktualis session)

| Ellenorzes | Statusz | Eredmeny |
|---|---|---|
| Backend celzott regresszio | PROVEN_RUN | PASS: `InventoryControllerTest, ClosingFlowTest, CommissionCalculationServiceTest, SyncServiceTest, RatePublishServiceTest, SyncInboundControllerTest, OutboxSyncWorkerServiceTest` |
| Backend javito regresszio | PROVEN_RUN | PASS: `TransactionFlowTest, RateApprovalServiceTest` |
| Backend teljes teszt | PROVEN_RUN | PASS: `mvnw.cmd -q test` |
| penztar-client teszt csomag | PROVEN_RUN | PASS: `npm run test; npm run typecheck; npm run check:ipc` |
| frontend-react lint | PROVEN_RUN | PASS: `0 error / 0 warning` |
| penztar-client lint | PROVEN_RUN | PASS: `0 error / 0 warning` |
| AML wave 1 regression | PROVEN_RUN | PASS: `AmlServiceTest, AmlBigctrlC1C2C3Test, AmlDeadlineTrackingTest, AmlFlowTest, AmlServiceCompletionTest` |
| WU AML regression | PROVEN_RUN | PASS: `WesternUnionServiceTest` incl. IC AML, USD propagation, missing-rate fail-closed |
| Security gate after AML wave 1 | PROVEN_RUN | PASS: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1` |

### 3.1 2026-04-17 pipeline szuett (post AML wave 1 follow-up)

| Ellenorzes | Statusz | Eredmeny |
|---|---|---|
| Backend teljes teszt | PROVEN_RUN | PASS: `mvnw.cmd test` -> 956 tests, 0 failures, 0 errors, 0 skipped (BUILD SUCCESS, H2 in-memory) |
| Backend celzott parity regresszio | PROVEN_RUN | PASS: `AmlServiceTest (6), StornoServiceTest (7), TransactionConversionServiceTest (4), HungarianRounding suite (51)` |
| Frontend-react teljes teszt | PROVEN_RUN | PASS: `vitest run` -> 32 files / 505 tests |
| Frontend-react typecheck | PROVEN_RUN | PASS: `npm run typecheck` (exit 0) |
| penztar-client teljes teszt | PROVEN_RUN | PASS: `vitest run` -> 6 files / 97 tests |
| penztar-client typecheck + IPC contract | PROVEN_RUN | PASS (exit 0); WARN: 3 belso sync handler (`mark-conversion-synced`, `mark-bank-transaction-synced`, `mark-storno-synced`) preload invoke nelkul - review/whitelist szukseges |
| Business-layer kumulativ teszteredmeny | PROVEN_RUN | 1558/1558 tests pass (956 backend + 505 frontend + 97 penztar) |
| Security gate | FAILED | Blokkolok: (1) `mandatory_db_preflight` - lokalis Flyway migracio hianyos (Postgres 17 :5433 empty schema), (2) `backend_dependency_check` - Spring Boot 3.5.11 CVE-2026-22731 es swagger-ui DOMPurify mXSS |

### 3.2 2026-04-17 post-freeze resume session (CB-018 + CB-004 parity fix)

| Ellenorzes | Statusz | Eredmeny |
|---|---|---|
| Backend teljes teszt post-fix | PROVEN_RUN | PASS: `mvnw.cmd test` -> 957 tests (+1 regression: `TransactionConversionServiceTest#executeConversion_propagatesAmlFlagsToTransactionEntity`), 0 failures, 0 errors, 0 skipped |
| Backend celzott parity regresszio post-fix | PROVEN_RUN | PASS: `AmlServiceTest (6) + StornoServiceTest (7) + TransactionConversionServiceTest (5) + TransactionFlowTest + ClosingFlowTest + TransactionServiceIdentificationTest (5) + AmlFlowTest + HungarianRounding suite (51) + CurrencyCalculatorServiceTest (6)` - osszesen 113 parity teszt PASS |
| Frontend-react teljes teszt | PROVEN_RUN | PASS: 32 files / 505 tests |
| penztar-client teljes teszt | PROVEN_RUN | PASS: 6 files / 97 tests |
| Business-layer kumulativ teszteredmeny | PROVEN_RUN | 1559/1559 tests pass (957 + 505 + 97) |
| CB-018 parity fix | PROVEN_CODE+RUN | `Transaction.amlSuspicious` es `amlAnnualLimitReached` mostantol propagalodik `performAmlCheck` eredmenyebol BUY/SELL/CONVERSION-ra. Kod: [TransactionService](backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java), [TransactionOperationHelper](backend/src/main/java/hu/puzzleir/valuta/service/TransactionOperationHelper.java), [TransactionConversionService](backend/src/main/java/hu/puzzleir/valuta/service/TransactionConversionService.java). Teszt: regression teszt PASS. |
| CB-004 parity fix | PROVEN_CODE+RUN | CONVERSION tranzakciora mostantol ropul: `customerAddress`, `customerDocumentNumber`, `customerNationality`, `sourceOfFunds`, `customerIsPep`. Kod: [ConversionRequestDto](backend/src/main/java/hu/puzzleir/valuta/dto/transaction/ConversionRequestDto.java), [TransactionMapper](backend/src/main/java/hu/puzzleir/valuta/mapper/TransactionMapper.java), [TransactionConversionService](backend/src/main/java/hu/puzzleir/valuta/service/TransactionConversionService.java). Teszt: regression teszt asserts fields. |
| Security gate | FAILED | Eszkalacio: tomcat-embed-core-10.1.52 CVE-2026-29145 (CVSS 9.1) uj bejelentes, plusz 5 tovabbi tomcat 7.5 CVE. Lasd `security-reports/20260417-091257/backend_dependency_check.txt`. |

## 4. Nyitott parity bizonyitekek listaja

1. Foglalo keszlet-elkulonites UAT.
2. Dekad riport tartalmi parity (legacy outputtal osszevetve).
3. Nyitokeszlet automatikus atvitel E2E bizonyitek.
4. BranchGroup es Company aggregacio UAT parity.
5. NAV/POS/nyomtato valodi hardver E2E.
6. `companyId` formalis, reprodukalhato coverage riport.
