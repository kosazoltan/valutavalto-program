# Junior — Architektúra & Üzleti Logika Gap Elemzés

## Dátum: 2026-04-05
## Szerző: Junior (main orchestrator)

---

## 1. Legacy Modul Térkép (üzleti funkció szerint)

### 1.1 SZERVER modul (482 .pas, 7.6 MB) — Központi szerver logika

| Kategória | Könyvtár | Méret | Leírás |
|---|---|---|---|
| **Árfolyam** | `arfolyam/` (verzio20, verzio22) | 795 KB, 49 pas | Árfolyam-kezelés, több verzió, naponta frissítés |
| **Árfolyam teszt** | `_arfteszt/` | 249 KB, 16 pas | Árfolyam-tesztelő modul |
| **Szerver maglogika** | `server/` | 470 KB, 37 pas | Fő szerver modul — adatgyűjtés, forgalom, WU, storno, bank |
| **Ügyfél-kontroll** | `ugyfelcontrol/` | 802 KB, 44 pas | DLL-ek: adatgyűjtő, adatlista, évi max, excel, időszak, import, kereső, letilt, okmány, terror, tiltások |
| **Ügyfél-kezelés** | `uctrl/` | 292 KB, 14 pas | Ügyfél-kezelő (butított verzió is) |
| **Recept/bizonylat** | `recptor/` | 321 KB, 15 pas | Bizonylat-feldolgozás, nyugtagenerátor |
| **Helga rendszer** | `helga/` | 750 KB, 42 pas | Tranzakciós díjszámítás DLL-ek |
| **Booking/foglalás** | `booking/` | 437 KB, 21 pas | Devizafoglalás rendszer |
| **Beszámoló** | `beszam/` | 128 KB, 3 pas | Beszámolók, riportok |
| **Körlevelek** | `korlevel/` | 115 KB, 9 pas | Körlevelek, értesítések |
| **Haszon** | `haszon/` | 68 KB, 5 pas | Haszonszámítás, profit |
| **Verseny** | `verseny/`, `verseny_mend/`, `everseny/` | 107 KB, 6 pas | Versenyek, dolgozói verseny |
| **Personal** | `personal/` | 68 KB, 3 pas | Személyzeti adatkezelés |
| **Permit/jogosultság** | `permit/` | 41 KB, 2 pas | Jogosultságkezelés |
| **Rendőrségi** | `police/` | 28 KB, 4 pas | Rendőrségi megkeresések |
| **Western Union** | `western/`, `westuni/`, `wucontrol/`, `wuniforg/`, `monegram/` | 105 KB, 6 pas | WU + MoneyGram integráció |
| **Terrorizmus** | `terror/`, `tiltcopy/` | 16 KB, 2 pas | Terrorlista, tiltólista másolás |
| **Makeszlt/készlet** | `makeszlt/` | 147 KB, 6 pas | Készletkezelés, számlakészítés |
| **POS terminál** | `postterm/`, `ptforg/`, `pttrfee/` | 79 KB, 6 pas | POS terminál forgalom, díjak |
| **Napi/havi zárás** | `_napiforg/`, `napiment/`, `havitablo/`, `havitrad/` | 89 KB, 6 pas | Napi forgalom, napi mentés, havi tábla |
| **Statisztika** | `statiszt/`, `summa/`, `sumrate/`, `sumtablo/`, `sumtrade/` | 126 KB, 11 pas | Összesítések, statisztikák |
| **Táblázatkészítő** | `tablomak/` | 46 KB, 2 pas | Táblázat-generálás |
| **Tranzakció** | `tranzacs/`, `tranzdb/`, `tranzdij/`, `trnzstat/`, `evitranz/` | 20 KB, 4 pas | Tranzakció-kezelés, díjak, statisztika |
| **Archiválás** | `archival/` | 4 KB, 1 pas | Adatarchiválás |
| **Banklista** | `banklist/` | 21 KB, 1 pas | Bankjegyzék |
| **Kereső** | `kereso/`, `nevseek/`, `orsoseek/`, `ugyfseek/` | 17 KB, 4 pas | Különféle keresők |
| **Jogi személy** | `jogiszemely/`, `mendjogi/` | 33 KB, 3 pas | Jogi személy kezelés |
| **Egyéb** | `confident/`, `etrade/`, `evnyito/`, `exp*/`, `fdb*/`, `foglalo/`, `forgdisp/`, `frissdat/`, `gbakall/`, stb. | ~200 KB | Adatfeldolgozás, export, adatbázis-karbantartás |
| **Adatfrissítés** | `frissdat/`, `newrate/`, `newyear/`, `lemento/` | 64 KB, 5 pas | Adatfrissítés, évnyitó, mentés |
| **Jelenlét** | `jelenlet/` | 19 KB, 1 pas | Munkaidő-nyilvántartás |
| **Jutalék** | `jutmend/` | 10 KB, 1 pas | Jutalékmentés |
| **Kezdődíj** | `kezdij/`, `kdchange/` | 34 KB, 3 pas | Kezdődíj-kezelés |
| **Okmány-kontroll** | `okmctrl/` | 13 KB, 1 pas | Okmányellenőrzés |
| **Pályázat** | `palyadij/` | 2 KB, 1 pas | Pályázati díj |
| **Vevő** | `vevo/`, `vevoszam/` | 41 KB, 4 pas | Vevőszámlázás |
| **Remaltib** | `remaltib/` | 68 KB, 6 pas | Alternatív bizonylat rendszer |
| **Fill/feldolgozás** | `ufill18/`, `ufill19/`, `uforg/` | 65 KB, 3 pas | Adatfeltöltés, forgalomfeldolgozás |
| **Recguard** | `recguard/` | 16 KB, 1 pas | Bizonylat-védelem |
| **Irodakezelés** | `makiroda/` | 4 KB, 1 pas | Irodalétrehozás |
| **OpenOffice listák** | `listopenoffices/` | 15 KB, 3 pas | Irodai dokumentum-generálás |
| **Hírek** | `litenews/` | 17 KB, 1 pas | Hírek/értesítések |
| **ID kezelés** | `idbeiro/` | 9 KB, 2 pas | Azonosító-bejegyzés |

### 1.2 VALUTA modul (439 .pas, 7 MB) — Pénztáros kliens (DLL plugin architektúra)

| Kategória | Könyvtár | Max .pas méret | Leírás |
|---|---|---|---|
| **Eladás** | `DLL/ELADAS/` | 134 KB | Devizaeladás teljes folyamat — árfolyam, kerekítés, bizonylat, ügyfél |
| **Vásárlás** | `DLL/VASARLAS/` | 102 KB | Devizavásárlás teljes folyamat |
| **Ügyfél** | `DLL/UGYFEL/` | 111 KB | Ügyfél-kezelés, azonosítás, 300K limit |
| **Átvétel** | `DLL/ATADVET/` | 135 KB | Átvétel/átadás kezelés |
| **Foglalás** | `DLL/FOGLALO/` | 81 KB | Devizafoglalás |
| **Western Union** | `DLL/WUNION/`, `DLL/UGYFELTMK/WUNION/` | 89 KB | WU tranzakciók |
| **Esti zárás** | `DLL/ESTIZAR/` | 91 KB | Esti/napi zárás |
| **Metro** | `DLL/METRO/` | 73 KB | Metro együttműködés |
| **Tesco** | `DLL/TESCO/` | 55 KB | Tesco együttműködés |
| **OTP** | `DLL/OTP/` | 59 KB | OTP banki integráció |
| **Blokk/nyugta** | `DLL/BLOKNYOM/` | 57 KB | Blokknyomtatás |
| **Havi zárás** | `DLL/HAVIZAR/` | 56 KB | Havi zárás |
| **Gépi beállítás** | `DLL/GEPSETUP/` | 56 KB | Pénztárgép beállítás |
| **Napi zárás** | `DLL/NAPZAR/` | 44 KB | Napi zárás |
| **Napi zárás nyomtatás** | `DLL/NZNYOMT/` | 53 KB | Napi zárás nyomtatás |
| **Árfolyam regisztráció** | `DLL/ARFREG/`, `DLL/ARFDISP/`, `DLL/ARFTMK/`, `DLL/ARFVALT/`, `DLL/BIGARFVALT/`, `DLL/KISARFVALT/`, `DLL/GETARF/` | 33 KB max | Árfolyam megjelenítés, módosítás, választás |
| **Címlet** | `DLL/CIMLET/`, `DLL/CIMLCTRL/`, `DLL/CIMLMENU/`, `DLL/CIMLNYOM/`, `DLL/CIMSETUP/`, `DLL/KCIMLET/`, `DLL/KISCIMLET/` | 33 KB max | Címletkezelés (bankjegy összetétel) |
| **Storno** | `DLL/STORNO/` | 35 KB | Sztornó kezelés |
| **Napkönyv** | `DLL/NAPKONYV/` | 32 KB | Naplókönyv |
| **Napi jelentés** | `DLL/NAPIJEL/` | 43 KB | Napi jelentés |
| **Napi kezdés** | `DLL/NAPIKEZD/` | 29 KB | Nap nyitás |
| **Készlet** | `DLL/KESZEDIT/`, `DLL/KESZUP/`, `DLL/PTARKESZ/`, `DLL/PILLKESZ/`, `DLL/PILLALL/` | 64 KB max | Készletkezelés, pillanatnyi készlet |
| **QR kód** | `DLL/QRGENER/`, `DLL/QRDEPUTY/` | 24 KB | QR kód generálás (meghatalmazás) |
| **HRK** | `DLL/HRKATADO/`, `DLL/HRKZARO/` | 29 KB | HRK (horvát kuna) kezelés |
| **NAV zárás** | `DLL/NAVZARO/` | 25 KB | NAV zárás |
| **Napi forgalom** | `DLL/NAPIFORG/`, `DLL/MAIFORG/` | 21 KB | Napi forgalom áttekintés |
| **Bizonylat megjelenítő** | `DLL/BIZODISP/` | 46 KB | Bizonylat megjelenítés |
| **Adatlap** | `DLL/ADATLAP/` | 47 KB | Ügyfél adatlap |
| **Listák** | `DLL/LISTAK/` | 47 KB | Különféle listák |
| **Egyéb DLL-ek** | `DLL/BIGCTRL/`, `DLL/CHECKLST/`, `DLL/CONFIDEN/`, `DLL/CONFIRM/`, `DLL/DEKRUTIN/`, `DLL/DOCDISP/`, `DLL/EUAKCIO/`, `DLL/FIRSTCTRL/`, `DLL/FOGLREND/`, `DLL/FORGOSSZ/`, `DLL/GETFIZE/`, `DLL/GETISO/`, `DLL/GETNYUGT/`, `DLL/GETPLOMB/`, `DLL/GETPTAR/`, `DLL/GETSTATUS/`, `DLL/GETWCEG/`, `DLL/GETWUGYF/`, `DLL/GONGBACK/`, `DLL/IDOSZAK/`, `DLL/KELLCIM/`, `DLL/KEZDEKAD/`, `DLL/KEZDIJ/`, `DLL/KEZDKEDV/`, `DLL/KORLEV/`, `DLL/LOGDISP/`, `DLL/LOGIRO/`, `DLL/MAKTABLAK/`, `DLL/MATPTAR/`, `DLL/MATREGEN/`, `DLL/MENTES/`, `DLL/OTHERTSK/`, `DLL/OTPLOG/`, `DLL/PAUSDISP/`, `DLL/PROCEND/`, `DLL/PROSBE/`, `DLL/PROSKI/`, `DLL/PROSTMK/`, `DLL/PTARTMK/`, `DLL/QUITFORM/`, `DLL/REGEN/`, `DLL/REGIZARO/`, `DLL/SCANNING/`, `DLL/SENDOKMANY/`, `DLL/SETRATE/`, `DLL/SUPER/`, `DLL/SUPERTSK/`, `DLL/TEAOR/`, `DLL/TERMINAL/`, `DLL/TERROR/`, `DLL/UJSCANNER/`, `DLL/VERZFRIS/`, `DLL/XTRANZ/`, `DLL/COPY2FTP/`, `DLL/FNYUJSAG/` | varies | Segédmodulok |
| **Fő váltó** | `IBVALTO/` | 68 KB | Fő váltóprogram logika (InterBase) |
| **Trade** | `TRADE/` | unit1-unit14, 295 KB | Kereskedés modul (unit3: 63KB!) |

### 1.3 ERTEKTAR modul (181 .pas, 2.7 MB) — Értéktár

| Könyvtár | Leírás |
|---|---|
| `database/` | Adatbázis-kezelés |
| `etdll/` | Értéktár DLL-ek |
| `fejleszt/` | Fejlesztői modulok |

---

## 2. Modern Modul Térkép

### 2.1 Backend (Spring Boot) — 1192 Java fájl, 4.6 MB

**Controller-ek (137 db)** — főbb területek:
- Tranzakció: `TransactionController`, `StornoController`, `TradeController`, `TransferController`
- Árfolyam: `ExchangeRateController`, `ExchangeRateMasterController`, `ExchangeRatePollingController`, `RateCreationController`, `RateManagementController`, `RateApprovalController`, `RateHistoryController`
- Ügyfél: `CustomerController`, `CustomerControlController`, `AuthorizedRepresentativeController`
- AML/Compliance: `AmlController`, `SanctionScreeningController`, `BlacklistController`, `PoliceRequestController`
- Zárás: `ClosingWizardController`, `DailyClosingController`, `EveningClosingController`, `MonthlyClosingController`, `NavClosingController`
- Készlet: `InventoryController`, `DenominationController`, `BanknoteInventoryController`, `CashBalanceController`, `StockSnapshotController`
- Riportok: `ReportController`, `ReportExtendedController`, `MnbReportController`, `DariusReportController`, `DecadeReportController`, `DailyReportController`
- WU: `WesternUnionController`
- POS: `PosTerminalStubController`, `PosTerminalController`
- Kamera: `CameraController`, `CameraAdminController`, `CameraExportController`
- Email: `EmailController`, `EmailAccountController`
- Foglalás: `ReservationController`
- Értéktár: `ErtektarController`, `TreasuryController`, `VatRefundController`
- LED: `LedDisplayController`
- Egyéb: `CircularController`, `BackupController`, `ArchivingController`, `WorkerController`, `SchedulerController`, stb.

**Service-ek (175+ db)** — átfogó üzleti logika implementáció

### 2.2 Frontend-React (209 fájl, 1.7 MB)

**Főbb page-ek:**
- Tranzakció: `CashierTransactionPage`, `ConversionPage`, `TransactionPage`, `TransactionListPage`
- Árfolyam: `RateCreationPage`, `RateGroupPage`, `RatesPage`, `RateHistoryPage`, `SettlementRateEntry`, `RateTemplateEditor`
- Ügyfél: `CustomerListPage`, `CustomerDetailPage`, `CustomerCreatePage`
- Treasury: `TreasuryDashboard`, `RatePanel`, `StockMatrix`, `MovementManager`, `BankTransactions`, `VatRefundPage`, `ReportsCirculars`
- Zárás: `ClosingWizardPage`, `EveningClosingPage`, `MonthlyClosingPage`, `DayOpenPage`
- Riportok: `ReportsPage`, `DaybookPage`, `DariusReportPage`, `DecadeReportPage`, `DailyTurnoverPage`, `AnonymousReportPage`, `MnbReportPage`
- WU: `WesternUnionPage`
- Kamera: `CameraConfigPage`, `CameraExportPage`, `CameraPlaybackPage`, `CameraLivePage`, `CameraStatusPage`
- Egyéb: `BlacklistPage`, `SuspiciousReportPage`, `FeePackagePage`, `CircularPage`, `PosTerminalPage`, stb.

### 2.3 Pénztár-client (Electron) — 28 fájl, 377 KB
Vékony kliens — fő logika a frontend-react-ben, Electron wrapper biztosítja: nyomtatás, kamera, scanner, offline queue

---

## 3. Összerendelés (Legacy → Modern)

| Legacy modul | Modern megfelelő | Állapot |
|---|---|---|
| **ELADAS** (134 KB) | `TransactionController` + `TransactionService` + `CashierTransactionPage` | ✅ KÉSZ |
| **VASARLAS** (102 KB) | `TransactionController` + `ConversionPage` | ✅ KÉSZ |
| **UGYFEL** (111 KB) | `CustomerController` + `CustomerService` + Customer pages | ✅ KÉSZ |
| **ATADVET** (135 KB) | `TransferController` + `TransferService` + `TransferPage` | ✅ KÉSZ |
| **FOGLALO** (81 KB) | `ReservationController` + `ReservationService` + `ReservationPage` | ✅ KÉSZ |
| **WUNION** (89 KB) | `WesternUnionController` + `WesternUnionService` + `WesternUnionPage` | ⚠️ RÉSZLEGES (stub) |
| **ESTIZAR** (91 KB) | `EveningClosingController` + `EveningClosingService` + `EveningClosingPage` | ✅ KÉSZ |
| **METRO** (73 KB) | — | ❌ HIÁNYZIK |
| **TESCO** (55 KB) | — | ❌ HIÁNYZIK |
| **OTP** (59 KB) | `OtpTerminalProtocolService` + `PosTerminalService` | ✅ KÉSZ |
| **NAPZAR** (44 KB) | `DailyClosingController` + `ClosingWizardPage` | ✅ KÉSZ |
| **HAVIZAR** (56 KB) | `MonthlyClosingController` + `MonthlyClosingPage` | ✅ KÉSZ |
| **STORNO** (35 KB) | `StornoController` + `StornoService` + `StornoPage` | ✅ KÉSZ |
| **BLOKNYOM** (57 KB) | `ReceiptGeneratorService` + `EscPosReceiptService` + `ReceiptPrint.tsx` | ✅ KÉSZ |
| **CIMLET** csomag | `DenominationController` + `DenominationService` + `DenominationPage` | ✅ KÉSZ |
| **ARFREG/ARFDISP/ARFTMK** | `ExchangeRateController` + `RateCreationPage` + `ExchangeRateDisplayPage` | ✅ KÉSZ |
| **NAPIJEL** (43 KB) | `DailyReportController` + `DaybookPage` | ✅ KÉSZ |
| **NAPKONYV** (32 KB) | `DaybookPage` | ✅ KÉSZ |
| **NAPIKEZD** (29 KB) | `SessionOpenController` + `DayOpenPage` | ✅ KÉSZ |
| **BIZODISP** (46 KB) | `ReceiptController` + `ReceiptPage` | ✅ KÉSZ |
| **QRGENER/QRDEPUTY** | `QrCodeService` | ✅ KÉSZ |
| **NAVZARO** (25 KB) | `NavClosingController` + `NavClosingService` | ✅ KÉSZ |
| **HRKATADO/HRKZARO** | `HrkController` + `HrkService` + `HrkPage` | ✅ KÉSZ |
| **TERROR** | `SanctionScreeningController` + `BlacklistController` | ✅ KÉSZ |
| **ADATLAP** (47 KB) | `CustomerDetailPage` | ✅ KÉSZ |
| **GEPSETUP** (56 KB) | `SettingsPage` + `WorkstationPage` | ⚠️ RÉSZLEGES |
| **PILLKESZ** (64 KB) | `StockSnapshotController` + `CashBalanceController` | ✅ KÉSZ |
| **KESZEDIT/KESZUP** | `InventoryController` + `InventoryPage` | ✅ KÉSZ |
| **KORLEV** | `CircularController` + `CircularPage` | ✅ KÉSZ |
| **LISTAK** (47 KB) | Több listázó page | ✅ KÉSZ |
| **SCANNING/UJSCANNER** | `DocumentScannerController` + `DocumentScanner.tsx` | ✅ KÉSZ |
| **REGEN/MATREGEN** | `InventoryRegenerationService` | ✅ KÉSZ |
| arfolyam/ (SZERVER) | `ExchangeRatePollingService` + `MnbExchangeRateService` + `RaiffeisenRateService` | ✅ KÉSZ |
| server/ (SZERVER) unit29 | `DataCollectionService` | ⚠️ RÉSZLEGES |
| ugyfelcontrol/ (SZERVER) | `CustomerControlService` + `SanctionScreeningService` + `AmlService` | ✅ KÉSZ |
| recptor/ (SZERVER) | `ReceiptGeneratorService` + `ReceiptSequenceService` | ✅ KÉSZ |
| booking/ (SZERVER) | `ReservationService` + `BookingExportService` | ✅ KÉSZ |
| helga/ (SZERVER) | `HandlingFeeService` + `CommissionCalculationService` | ✅ KÉSZ |
| beszam/ (SZERVER) | `ReportService` + `ReportExtendedService` | ✅ KÉSZ |
| haszon/ (SZERVER) | `ProfitCalculationService` + `ProfitPage` | ✅ KÉSZ |
| verseny/ (SZERVER) | `CompetitionService` + `CompetitorPage` | ✅ KÉSZ |
| personal/ (SZERVER) | `EmployeeService` + `EmployeePage` + `WorkerPage` | ✅ KÉSZ |
| permit/ (SZERVER) | `RoleService` + `PermissionController` | ✅ KÉSZ |
| police/ (SZERVER) | `PoliceRequestController` + `PoliceRequestService` | ✅ KÉSZ |
| western/westuni/ (SZERVER) | `WesternUnionService` | ⚠️ RÉSZLEGES |
| makeszlt/ (SZERVER) | `MonthlyReportService` + `MonthlyClosingPdfService` | ✅ KÉSZ |
| tablomak/ (SZERVER) | `StockSnapshotExcelService` | ✅ KÉSZ |
| terror/ (SZERVER) | `SanctionScreeningService` | ✅ KÉSZ |
| statiszt/ (SZERVER) | `TurnoverService` + `DailyReportService` | ✅ KÉSZ |
| archival/ (SZERVER) | `ArchivingService` + `ArchivingPage` | ✅ KÉSZ |
| jelenlet/ (SZERVER) | `WorkerAttendance` entity | ⚠️ RÉSZLEGES |
| okmctrl/ (SZERVER) | `DocumentScannerService` | ✅ KÉSZ |
| jogiszemely/ (SZERVER) | `CustomerType` entity (LEGAL_ENTITY) | ✅ KÉSZ |
| vevo/vevoszam/ (SZERVER) | Nincs dedikált modul | ❌ HIÁNYZIK |
| monegram/ (SZERVER) | — | ❌ HIÁNYZIK |
| IBVALTO (68 KB) | `TransactionService` + frontend | ✅ KÉSZ (migráció IB→PG) |
| TRADE unit1-14 (295 KB) | `TradeService` + `TradeController` | ⚠️ RÉSZLEGES |
| **FNYUJSAG** (41 pas) | — | ❌ HIÁNYZIK |
| **OTHERTSK** (41 KB) | — | ⚠️ RÉSZLEGES |
| **PROSBE/PROSKI/PROSTMK** | — | ❌ HIÁNYZIK |
| **MATPTAR** (25 KB) | — | ⚠️ RÉSZLEGES |
| **VERZFRIS** (34 KB) | `VersionController` (basic) | ⚠️ RÉSZLEGES |

---

## 4. GAP Lista (hiányzó funkciók, prioritással)

### CRITICAL (jogszabályi kötelezettség vagy működés-blokkoló)

| # | Funkció | Legacy modul | Leírás | Prioritás |
|---|---|---|---|---|
| G1 | **MoneyGram integráció** | `monegram/` (SZERVER) | MoneyGram pénzküldő szolgáltatás — ha az iroda használja, jogszabályi kötelezettség | CRITICAL |
| G2 | **Trade modul mélysége** | `TRADE/` unit1-14 (295 KB) | A legacy TRADE modul rendkívül komplex (14 unit, 295 KB), a modern `TradeService` (11 KB) töredéke | CRITICAL |
| G3 | **Adatgyűjtés (server/unit29)** | `server/` unit29 (77 KB) | Központi adatgyűjtés — forgalom, címlet, WU, bank, storno regisztráció, Metro, Tesco forgalom | CRITICAL |
| G4 | **Jelenlét-nyilvántartás** | `jelenlet/` (19 KB) | Dolgozói jelenlét teljes kezelés — entity létezik, de nincs frontend/controller | HIGH |

### HIGH (üzleti funkció, ami a napi működéshez szükséges)

| # | Funkció | Legacy modul | Leírás |
|---|---|---|---|
| G5 | **Metro együttműködés** | `METRO/` DLL (73 KB) | Metro áruházi devizaváltó pont kezelés |
| G6 | **Tesco együttműködés** | `TESCO/` DLL (55 KB) | Tesco áruházi devizaváltó pont kezelés |
| G7 | **Vevő/vevőszám kezelés** | `vevo/`, `vevoszam/` (41 KB) | Vevőszámlázás, vevőnyilvántartás |
| G8 | **Gépi beállítás (részletes)** | `GEPSETUP/` (56 KB) | Pénztárgép részletes konfiguráció (hardware, nyomtató, kijelző) |
| G9 | **WU/WesternUnion mélység** | `WUNION/` + `UGYFELTMK/WUNION/` + szerver WU modulok | A modern WU stub, a legacy teljes WU API integráció |
| G10 | **FTP szinkronizáció (régi)** | `COPY2FTP/` + `senddata/` | Legacy FTP-alapú adatszinkronizáció |
| G11 | **Nyomtatott újság (FNYUJSAG)** | `DLL/FNYUJSAG/` (41 pas) | Belső újság/értesítő rendszer |
| G12 | **Prospektus be/ki** | `PROSBE/`, `PROSKI/`, `PROSTMK/` | Prospektus-kezelés (marketing anyagok) |
| G13 | **Havi trade kontroll** | `havitrad/` | Havi kereskedési kontroll |

### MEDIUM

| # | Funkció | Legacy modul | Leírás |
|---|---|---|---|
| G14 | **Matrica pénztár** | `MATPTAR/` (25 KB) | Matrica-alapú pénztár-azonosítás |
| G15 | **Verziófrissítés (kliens)** | `VERZFRIS/` (34 KB) | Automatikus kliens-frissítés (modern: Electron auto-updater részleges) |
| G16 | **Egyéb feladatok (OTHERTSK)** | `OTHERTSK/` (41 KB) | Vegyes adminisztrációs feladatok |
| G17 | **EU akció** | `EUAKCIO/` | EU-s promóciós akciók kezelése |
| G18 | **Gong/visszahívás** | `GONGBACK/` | Hangjelzés, visszahívás rendszer |
| G19 | **Szünet megjelenítő** | `PAUSDISP/` | Szünet kijelzés |
| G20 | **Regisztráció zárás** | `REGIZARO/` | Regisztrációs zárás |
| G21 | **OpenOffice listák** | `listopenoffices/` | Dokumentum-generálás OO-ba |

### LOW

| # | Funkció | Legacy modul | Leírás |
|---|---|---|---|
| G22 | **Pályázati díj** | `palyadij/` | Alkalmi funkció |
| G23 | **Hírek** | `litenews/` | Belső hírmodul |
| G24 | **Irodakezelés** | `makiroda/` | Iroda-létrehozás (egy irodás beállítás) |

---

## 5. Architektúra Összehasonlítás

| Szempont | Legacy (Delphi 7) | Modern (Java + React + Electron) |
|---|---|---|
| **Adatbázis** | Firebird/InterBase (lokális .fdb) | PostgreSQL (szerver) |
| **Kliens-szerver kommunikáció** | Közvetlen DB connection (IBDatabase) | REST API (HTTP/JSON) |
| **Kliens architektúra** | Native Windows DLL plugin rendszer (~110 DLL) | Electron + React SPA |
| **Üzleti logika elhelyezése** | Kliens-oldalon (DLL-ekben) | Szerver-oldalon (Spring Boot service-ek) |
| **Offline működés** | Teljes (lokális DB) | Részleges (localQueue, offline cache) |
| **Nyomtatás** | Közvetlen printer hozzáférés (ESC/POS) | Electron bridge → ESC/POS |
| **Bizonylat** | Delphi-ben generált | Backend + Frontend generált |
| **Modulrendszer** | DLL-ek futásidőben betöltve | Monolitikus SPA + Backend |
| **Multi-site** | Szerver-kliens FTP szinkronizáció | Központi szerver, real-time API |
| **Árfolyam-forrás** | MNB + manuális | MNB API + Raiffeisen + polling + manuális |
| **Kamera** | Nincs integrált | Teljes kamera rendszer (rögzítés, export, hash chain) |
| **LED kijelző** | Nem azonosított a legacy-ben | LedDisplay modul (serial/network) |

### Kritikus architektúra-különbségek:

1. **DLL plugin → Monolitikus SPA**: A legacy ~110 DLL-es plugin architektúra rendkívül moduláris. A modern kód monolitikus SPA — ez nem hátrány, de a legacy modulok közötti jól definiált interfészek elveszhetnek.

2. **Kliens-oldali üzleti logika → Szerver-oldali**: A legacy ELADAS/VASARLAS/UGYFEL DLL-ek kliens-oldalon futtatják a komplex üzleti logikát (kerekítés, limit-ellenőrzés, bizonylat-generálás). A modern rendszerben ez szerver-oldalra került, ami jobb, de az offline működés korlátozottabb.

3. **Firebird → PostgreSQL**: Jó döntés. A legacy Firebird lokális fájl-DB volt, ami multi-site-nál szinkronizációs problémákat okozott.

4. **FTP szinkronizáció → REST API**: A legacy FTP-vel szinkronizált fiókok között. A modern REST API real-time, ami jobb, de a régi FTP logika teljes elhagyása azt jelenti, hogy a legacy telephelyek migrációjánál figyelni kell.

---

## 6. Következtetések és Javaslatok

### Összefoglalás
- A modern program **jól lefedi** a legacy funkciók ~75-80%-át
- A backend entitás és service réteg (1192 Java fájl) meghaladja a legacy szerver modult komplexitásban
- A **kritikus gap-ek**: Metro/Tesco integráció, MoneyGram, Trade modul mélysége, WU teljes integráció
- A **pénztár-client (Electron)** még vékony (28 fájl vs. legacy ~110 DLL) — ez a legnagyobb fejlesztési terület

### Top 5 javaslat
1. **Trade modul mélyítése**: A legacy 295 KB-os TRADE modul vs. modern 11 KB TradeService → szisztematikus üzleti logika portolás szükséges
2. **Metro/Tesco döntés**: Ha ezek az üzleti partnerségek aktívak, a modern rendszerbe is implementálni kell
3. **WU teljes integráció**: A stub-ról élő WU API-ra váltás
4. **Adatgyűjtés (DataCollection) mélyítése**: A legacy unit29 komplex összesítő — a modern DataCollectionService ennek töredéke
5. **Jelenlét-nyilvántartás frontend**: Az entity létezik, de nincs UI — egyszerű fejlesztés

### Megjegyzés
A legacy kód **nem jól strukturált** (unit1, unit2, stb. nevek, 100+ KB-os god-modulok), de **üzletileg teljes**. A modern kód **jól strukturált** (Clean Architecture, service layer), de **üzletileg még nem teljes**. A cél: a legacy üzleti teljességet átvinni a modern architektúrába.
