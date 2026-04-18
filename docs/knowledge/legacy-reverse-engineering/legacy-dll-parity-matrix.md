---
type: registry
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Legacy DLL Parity Matrix"
load: on-demand
---

# Legacy DLL Parity Matrix

> Cel: `legacy modul -> modern service/page/test` megfeleltetesi reteget adni a VALUTA es ERTEKTAR vilaghoz.
> Kiegeszito gepi forras: `generated/legacy-dll-parity-matrix-2026-04-09.csv`

---

## S1 AJANLOTT_OSZLOPOK

| Oszlop | Jelentes |
|--------|----------|
| `legacy_area` | `VALUTA`, `ERTEKTAR`, `SZERVER`, `ARFOLYAM` |
| `legacy_module` | DLL vagy modulnev (`vasarlas`, `napzar`, `atadvet`) |
| `legacy_cluster` | funkcionalis klaszter (`transaction-buy`, `closing`, `customer-aml`) |
| `legacy_role` | rovid uzleti leiras |
| `source_hint` | legacy forras/projekt utvonal vagy dokumentacios horgony |
| `modern_service` | fo Spring service |
| `modern_controller` | fo REST controller |
| `modern_ui` | React/Electron oldalak |
| `test_target` | letezo vagy javasolt tesztfajl |
| `parity_status` | `full`, `partial`, `replaced`, `obsolete`, `unknown` |
| `risk` | `P0`, `P1`, `P2`, `P3` |
| `notes` | nyitott gap, atalakitas vagy bizonytalansag |

---

## S2 MAGAS_ERTEKU_PARITY_MATRIX

| Legacy modul | Legacy szerep | Modern service | Modern controller | Modern UI | Test target | Status | Risk |
|--------------|---------------|----------------|-------------------|-----------|-------------|--------|------|
| `vasarlas.dll` | valuta vetel | `TransactionService` | `TransactionController` | `frontend-react/src/pages/transactions/TransactionPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/integration/TransactionFlowTest.java` | full | P0 |
| `eladas.dll` | valuta eladas | `TransactionService` | `TransactionController` | `frontend-react/src/pages/transactions/TransactionPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/TransactionServiceBusinessLogicTest.java` | full | P0 |
| `storno.dll` | sztorno | `StornoService` | `StornoController` | `frontend-react/src/pages/stornos/StornoPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/StornoServiceTest.java` | full | P0 |
| `napzar.dll` | napi zaras | `DailyClosingService` | closing endpoint family | `frontend-react/src/pages/closing/EveningClosingPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingServiceExtendedTest.java` | full | P0 |
| `havizar.dll` | havi zaras | `MonthlyClosingService` | closing endpoint family | `frontend-react/src/pages/closing/MonthlyClosingPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/MonthlyClosingServiceTest.java` | full | P1 |
| `arftmk.dll` | arfolyam karbantartas | `ExchangeRateService` | `ExchangeRateController` | `frontend-react/src/pages/rates/RatesPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/ExchangeRateServiceTest.java` | full | P0 |
| `getarf.dll` | legacy rate file ingest | `RateFileParserService`, `RatePublishService` | `ExchangeRateController` | `frontend-react/src/pages/rates/RatesPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/RateFileParserServiceTest.java` | partial | P0 |
| `arfreg.dll` | arfolyam regiszter / kijelzes | `ExchangeRateService` | `ExchangeRateController` | `frontend-react/src/pages/rates/RatesPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/RateApprovalServiceTest.java` | partial | P1 |
| `atadvet.dll` | penztar/ertektar atadas-atvetel | `VaultTransferService`, `TransferService` | `ErtektarController`, `TransferController` | `frontend-react/src/pages/transfers/TransferPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/TransferCounterTransactionTest.java` | full | P0 |
| `atadolap.dll` | atadolap nyomtatas | `HandoverSheetService` | `ErtektarController` alias family | `frontend-react/src/pages/handover/HandoverSheetPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/entity/HandoverSheetTest.java` | full | P0 |
| `cimlet.dll` | cimlet kezeles | denomination/treasury service family | treasury endpoints | `frontend-react/src/pages/cashdesk/DenominationPage.tsx` | javasolt: denomination service test | partial | P1 |
| `cimlctrl.dll` | cimlet ellenorzes | denomination/treasury service family | treasury endpoints | `frontend-react/src/pages/treasury/StockMatrix.tsx` | javasolt: denomination validator test | partial | P1 |
| `cimlmenu.dll` | cimlet menu | denomination/treasury service family | treasury endpoints | `frontend-react/src/pages/treasury/TreasuryDashboard.tsx` | javasolt: UI menu test | partial | P2 |
| `cimlnyom.dll` | cimlet nyomtatas | receipt/print service family | receipt endpoints | `frontend-react/src/pages/receipts/ReceiptPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingPdfServiceTest.java` | partial | P1 |
| `bizodisp.dll` | bizonylat tallozo | receipt query/service family | receipt endpoints | `frontend-react/src/pages/receipts/ReceiptPage.tsx`, `TransactionListPage.tsx` | `frontend-react/src/pages/transactions/TransactionListPage.test.tsx` | partial | P1 |
| `bloknyom.dll` | blokknyomtatas | `EscPosReceiptService`, `ReceiptGeneratorService` | receipt endpoints | `frontend-react/src/pages/receipts/ReceiptPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingPdfServiceTest.java` | full | P0 |
| `bigctrl.dll` | AML, limit, quarter/week rolling control | `AmlService` | AML/customer endpoints | customer/AML pages | `backend/src/test/java/hu/puzzleir/valuta/service/AmlBigctrlC1C2C3Test.java`, `backend/src/test/java/hu/puzzleir/valuta/integration/AmlFlowTest.java`, see `aml-bigctrl-rule-parity.md` | partial | P0 |
| `ugyfel*.dll` | ugyfelkezeles | `CustomerService` | customer endpoints | `frontend-react/src/pages/customers/CustomerListPage.tsx` | `frontend-react/src/pages/customers/CustomerListPage.test.tsx` | full | P0 |
| `terror.dll` | szankcios ellenorzes | `BlacklistService`, `AmlService` | blacklist endpoints | `frontend-react/src/pages/blacklist/BlacklistPage.tsx` | javasolt: blacklist service test | partial | P0 |
| `prosbe.dll` | penztaros login | auth/session stack | auth endpoints | `frontend-react/src/pages/auth/LoginPage.tsx` | `frontend-react/src/pages/auth/LoginPage.test.tsx` | full | P0 |
| `proski.dll` | penztaros logout | auth/session stack | auth endpoints | `frontend-react/src/pages/auth/LoginPage.tsx` | `frontend-react/src/stores/authStore.test.ts` | full | P1 |
| `prostmk.dll` | penztaros karbantartas | worker/user management | user endpoints | `frontend-react/src/pages/settings/UserPage.tsx` | javasolt: user admin test | partial | P1 |
| `super.dll` | supervisor jovahagyas | RBAC + override rules | protected controllers | storno/closing/user flows | `frontend-react/src/pages/auth/LoginPage.rbac.test.tsx` | partial | P0 |
| `terminal.dll` | terminal/periferialis integracio | `PosTerminalService` | `PosTerminalController` | POS settings/transaction flows | `backend/src/test/java/hu/puzzleir/valuta/controller/WesternUnionStubControllerTest.java` | partial | P2 |
| `wunion.dll` | Western Union | `WesternUnionService` | `WesternUnionController` | `frontend-react/src/pages/westernunion/WesternUnionPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/WesternUnionServiceTest.java` | full | P1 |
| `foglalo.dll` | foglalas | `ReservationService` | `ReservationController` | `frontend-react/src/pages/reservations/ReservationPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/ReservationServiceTest.java` | full | P1 |
| `korlevel.dll` | korlevel | `CircularService` | `CircularController` | `frontend-react/src/pages/circulars/CircularPage.tsx` | javasolt: circular service test | full | P2 |
| `kezdij.dll` | kezelesi dij | `HandlingFeeService` | fee endpoints | `frontend-react/src/pages/fees/FeePackagePage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/HandlingFeeTransactionServiceTest.java` | full | P1 |
| `pillall.dll` | pillanatnyi penztarallas | stock summary family | treasury/report endpoints | `frontend-react/src/pages/treasury/TreasuryDashboard.tsx` | javasolt: stock summary test | partial | P1 |
| `keszlex.dll` | keszlet export/osszesites | stock/export family | treasury/report endpoints | `frontend-react/src/pages/treasury/TrbExportPage.tsx` | javasolt: export service test | partial | P1 |
| `ptartmk.dll` | penztar karbantartas | `BranchService` | `BranchController` | `frontend-react/src/pages/branches/BranchPage.tsx` | javasolt: branch controller test | full | P1 |
| `listak.dll` | listak/riportok | `ReportService` | report endpoints | `frontend-react/src/pages/reports/ReportsPage.tsx` | `frontend-react/src/pages/reports/ReportsPage.test.tsx` | full | P1 |
| `regen.dll` | allapot regeneracio | archive/regeneration family | admin/report endpoints | admin tools | `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingArchiveServiceTest.java` | partial | P1 |
| `qrgener.dll` | QR generalas / kijelzes | receipt/qr helpers | receipt endpoints | QR/receipt flows | `frontend-react/src/utils/qrcode.test.ts` | full | P2 |
| `otp.dll` | OTP POS / terminal | `PosTerminalService` | `PosTerminalController` | POS flows | javasolt: POS controller test | partial | P2 |
| `ERTEKTAR/atadvet` | treasury transfer | `VaultTransferService` | `ErtektarController` | `frontend-react/src/pages/treasury/TreasuryDashboard.tsx` | `backend/src/test/java/hu/puzzleir/valuta/controller/ErtektarControllerAliasTest.java` | full | P0 |
| `ERTEKTAR/penztarak` | treasury branch registry | `BranchService` | `BranchController` | `frontend-react/src/pages/branches/BranchPage.tsx` | javasolt: branch alias test | partial | P1 |
| `ERTEKTAR/napzar` | treasury close | `DailyClosingService` | closing endpoints | `frontend-react/src/pages/closing/EveningClosingPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingServiceExtendedTest.java` | partial | P1 |
| `ERTEKTAR/havizar` | treasury monthly close | `MonthlyClosingService` | closing endpoints | `frontend-react/src/pages/closing/MonthlyClosingPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/MonthlyClosingServiceTest.java` | partial | P1 |
| `ERTEKTAR/bloknyom` | treasury receipt output | receipt/pdf stack | receipt endpoints | `frontend-react/src/pages/receipts/ReceiptPage.tsx` | `backend/src/test/java/hu/puzzleir/valuta/service/DailyClosingPdfServiceTest.java` | partial | P1 |
| `ERTEKTAR/pillkesz` | treasury stock snapshot | stock family | `ErtektarController` | `frontend-react/src/pages/treasury/StockMatrix.tsx` | `backend/src/test/java/hu/puzzleir/valuta/controller/ErtektarControllerAliasTest.java` | partial | P1 |

---

## S3 NAGY_KOCKAZATU_VAGY_NEM_1AZ1_MODULEK

| Modul | Problema | Mai allapot |
|-------|----------|-------------|
| `bigctrl.dll` | a fo BIGCTRL szabalyok rule-levelen mar bizonyitottak, de a teljes modul meg nem tekintheto lezartnak a `R-conversion-double` es a nem-rule UX/legal scope miatt | residualis P0 AML gap |
| `super.dll` | legacy supervisor felulbiralas sok helyen implicit | RBAC-ban reszben szetszorodott |
| `regen.dll` | fajl- es adatbazis-regeneracio | modernben nincs egyetlen azonos modul |
| `terminal.dll`, `otp.dll` | hardware/protocol fuggo | reszben kivaltva, reszben stub |
| `fnyujsag*` variansok | telephely-specifikus buildfragmentacio | erdemes egy logikai capability-kent kezelni |
| `METRO`, `TESCO`, `TRADE` kapcsolatok | uzletileg reszben kifutott | ne portoljuk automatikusan |
| `DayBook` jellegu modulok | legacy dinamikus tablazas | modernben query/model alapu megoldas |

---

## S4 AJANLOTT_PARITY_BIZONYITEK

1. Backend szolgaltatas-tesztek:
   - `TransactionServiceBusinessLogicTest`
   - `StornoServiceTest`
   - `ExchangeRateServiceTest`
   - `RateFileParserServiceTest`
   - `DailyClosingServiceExtendedTest`
   - `MonthlyClosingServiceTest`
   - `WesternUnionServiceTest`
   - `ReservationServiceTest`
   - `HandlingFeeTransactionServiceTest`
   - `WorkerAttendanceServiceTest`
2. Backend kontrollerek:
   - `ErtektarControllerAliasTest`
   - `CameraControllerSecurityTest`
   - `CameraAdminControllerSecurityTest`
   - `WesternUnionStubControllerTest`
3. Frontend:
   - `TransactionPage.test.tsx`
   - `TransactionListPage.test.tsx`
   - `RatesPage.test.tsx`
   - `ClosingWizardPage.test.tsx`
   - `ReportsPage.test.tsx`
   - `CustomerListPage.test.tsx`
   - `LoginPage.test.tsx`
4. Electron/offline:
   - `penztar-client/electron/__tests__/sync-engine.test.ts`
   - `penztar-client/electron/__tests__/sync-engine-network-disruption.test.ts`

---

## S5 HASZNALAT

- Gepi matrix: `generated/legacy-dll-parity-matrix-2026-04-09.csv`
- Binaris inventory: `generated/legacy-binary-inventory-2026-04-09.csv`
- SQL:

```sql
SELECT legacy_module, modern_service, modern_ui, parity_status
FROM legacy_dll_parity_matrix
WHERE risk IN ('P0', 'P1')
ORDER BY legacy_module;
```

```sql
SELECT legacy_module, notes
FROM legacy_dll_parity_matrix
WHERE parity_status IN ('partial', 'unknown');
```
