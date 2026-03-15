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
| Treasury cegszintu osszesites | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L36) | Company-wide summary implementalva |
| Treasury irodaszintu osszehasonlitas | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L88) | Branch comparison implementalva |
| Treasury bankflow osszesites | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L111) | Bank be/ki aggregacio implementalva |
| BranchGroup aggregacio parity | GAP | [backend/src/main/java/hu/puzzleir/valuta/entity/BranchGroup.java](backend/src/main/java/hu/puzzleir/valuta/entity/BranchGroup.java#L17), [backend/src/main/java/hu/puzzleir/valuta/service/BranchGroupService.java](backend/src/main/java/hu/puzzleir/valuta/service/BranchGroupService.java#L15) | Entitasok megvannak, treasury aggregacioban nincs bizonyitottan hasznalva |
| NAV integracio valodisag | GAP | [backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java](backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java#L13), [backend/src/main/java/hu/puzzleir/valuta/service/NavIntegrationService.java](backend/src/main/java/hu/puzzleir/valuta/service/NavIntegrationService.java#L11) | Placeholder/mock implementacio |

## 2. Security es multi-tenant bizonyitek

| Terulet | Statusz | Bizonyitek | Megjegyzes |
|---|---|---|---|
| Controller szintu auth guard jelenlet | PROVEN_CODE | [backend/src/main/java/hu/puzzleir/valuta/controller/DecadeReportController.java](backend/src/main/java/hu/puzzleir/valuta/controller/DecadeReportController.java#L20), [backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java](backend/src/main/java/hu/puzzleir/valuta/controller/NavIntegrationController.java#L17) | Szeleskoru `@PreAuthorize` jelenlet latszik |
| `@PreAuthorize` statikus lefedettseg (fajlszint) | PARTIAL | [backend/src/main/java/hu/puzzleir/valuta/controller](backend/src/main/java/hu/puzzleir/valuta/controller) | Audit eredmeny: 124 controller, ebbol 113 tartalmaz `@PreAuthorize`, 11 nem |
| `@PreAuthorize` hianyok kockazati bontas | PARTIAL | [backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java](backend/src/main/java/hu/puzzleir/valuta/controller/AuthController.java#L24), [backend/src/main/java/hu/puzzleir/valuta/controller/GoogleAuthController.java](backend/src/main/java/hu/puzzleir/valuta/controller/GoogleAuthController.java#L34), [backend/src/main/java/hu/puzzleir/valuta/controller/HealthController.java](backend/src/main/java/hu/puzzleir/valuta/controller/HealthController.java#L27), [backend/src/main/java/hu/puzzleir/valuta/controller/VersionController.java](backend/src/main/java/hu/puzzleir/valuta/controller/VersionController.java#L10), [backend/src/main/java/hu/puzzleir/valuta/controller/BranchController.java](backend/src/main/java/hu/puzzleir/valuta/controller/BranchController.java#L19), [backend/src/main/java/hu/puzzleir/valuta/controller/ClosingControlController.java](backend/src/main/java/hu/puzzleir/valuta/controller/ClosingControlController.java#L20), [backend/src/main/java/hu/puzzleir/valuta/controller/CustomerControlController.java](backend/src/main/java/hu/puzzleir/valuta/controller/CustomerControlController.java#L22), [backend/src/main/java/hu/puzzleir/valuta/controller/DenominationCalculatorController.java](backend/src/main/java/hu/puzzleir/valuta/controller/DenominationCalculatorController.java#L22), [backend/src/main/java/hu/puzzleir/valuta/controller/EmailAccountController.java](backend/src/main/java/hu/puzzleir/valuta/controller/EmailAccountController.java#L24), [backend/src/main/java/hu/puzzleir/valuta/controller/EmailController.java](backend/src/main/java/hu/puzzleir/valuta/controller/EmailController.java#L31), [backend/src/main/java/hu/puzzleir/valuta/controller/HrkController.java](backend/src/main/java/hu/puzzleir/valuta/controller/HrkController.java#L20) | 4 publikus endpoint-csoport elvart kivetel (auth/health/version), 7 eset policy-eltérés lehet (`@PreAuthorize` nelkul) |
| `companyId` teljes repo-audit | GAP | [backend/src/main/java/hu/puzzleir/valuta](backend/src/main/java/hu/puzzleir/valuta) | Kotelezo formalis ellenorzes nyitott |

## 3. Futtatasi bizonyitekok (aktualis session)

| Ellenorzes | Statusz | Eredmeny |
|---|---|---|
| Backend celzott regresszio | PROVEN_RUN | PASS: `InventoryControllerTest, ClosingFlowTest, CommissionCalculationServiceTest, SyncServiceTest, RatePublishServiceTest, SyncInboundControllerTest, OutboxSyncWorkerServiceTest` |
| Backend teljes teszt | PROVEN_RUN | PASS: `mvnw.cmd -q test` |
| penztar-client teszt csomag | PROVEN_RUN | PASS: `npm run test; npm run typecheck; npm run check:ipc` |
| frontend-react lint | PROVEN_RUN | PASS: `0 error / 0 warning` |
| penztar-client lint | PROVEN_RUN | PASS: `0 error / 0 warning` |

## 4. Nyitott parity bizonyitekek listaja

1. Foglalo keszlet-elkulonites UAT.
2. Dekad riport tartalmi parity (legacy outputtal osszevetve).
3. Nyitokeszlet automatikus atvitel E2E bizonyitek.
4. BranchGroup es KFT szintu treasury aggregacio parity.
5. NAV/POS/nyomtato valodi hardver E2E.
6. `companyId` es `@PreAuthorize` formalis, reprodukalhato coverage riport.
