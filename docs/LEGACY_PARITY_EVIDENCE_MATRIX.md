# Legacy Parity Evidence Matrix

Frissitve: 2026-03-15

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

## 4. Nyitott parity bizonyitekek listaja

1. Foglalo keszlet-elkulonites UAT.
2. Dekad riport tartalmi parity (legacy outputtal osszevetve).
3. Nyitokeszlet automatikus atvitel E2E bizonyitek.
4. BranchGroup es Company aggregacio UAT parity.
5. NAV/POS/nyomtato valodi hardver E2E.
6. `companyId` formalis, reprodukalhato coverage riport.
