---
type: analysis
scope: workspace-shared
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Valutavalto Delphi→Java Gap Analizis"
load: on-demand
---

# Valutaváltó Delphi→Java Gap Analízis
> Készítette: Tamás (TestOps Chief) | 2026-04-04 | Mélyelemzés — SZERVER + ERTEKTAR + VALUTA delta

---


---

## S1 OSSZEFOGLALO

### Számok

| Mutató | Érték |
|---|---|
| Teljes Delphi forrás | 645.186 sor, 1102 .pas fájl |
| Eddig elemzett (VALUTA kliens) | ~248.000 sor (~38%) |
| **Most elemzett — SZERVER** | ~279.000 sor |
| **Most elemzett — ERTEKTAR** | ~105.000 sor |
| TRADE rendszer | ~13.000 sor |
| Java backend fájlok | 1.072 .java |
| Java controllerek | 122 db |
| Java service-ek | ~175 db |
| Java entityk | 225 db |
| Flyway migrációk | 130+ |
| Frontend oldalak (React) | 60+ page |

### Korábban vélt lefedettség vs. valódi lefedettség

- **2026-03-06 elemzés szerint:** ~98% kész (de csak VALUTA 38%-on alapult)
- **Valódi lefedettség (teljes forrás alapján):** ~62–65%
- **Meglepetés-tartomány:** ~35% soha nem volt elemezve

### Kritikus megállapítások

1. **SZERVER rendszer (279K sor)** volt a "motor" — az összes pénztár adatát összegyűjtő, MNB-nek riportáló, könyvelési export-ot gyártó, verseny-számítást végző, Western Union szerveri oldalt kezelő back-office alkalmazás. A Java-ban ez részben implementált, de sok funkció HIÁNYZIK vagy RÉSZLEGES.

2. **ERTEKTAR (105K sor)** az értéktár (széf/főpénztár) önálló rendszere — napi jelentes, napi könyv, készlet-feltöltés, átadólap, stornó, arfolyam-irat. A Java-ban az ErtektarController + Vault* service-ek csak részlegesen fedik le.

3. **HELGA alrendszer** (locserver + 9 DLL) — a SZERVER-en belüli helyi szerver, ami koordinálja a pénztárakat. Nincs Java megfelelő — részben a modern szinkronizáció (SyncService) váltotta ki, de a business logika nem teljes.

4. **Booking/Export (Excel)** — könyvelési export Excel formátumba (forgalom, adásvétel, készlet). A Java-ban `BookingExportService` létezik, de a konkrét Delphi logika (korzet-szintű összesítés, multi-sheet Excel) részleges.

5. **Jutalék-számítás (tranzdij/jutszamito)** — a pénztáros jutalék havi/napi számítása KULCSÜZLETI logika. A Java-ban `WorkerCommissionService` + `CommissionCalculationService` megvan, de a Delphi-ban látható komplex kalkuláció (by cashier, by district, BEST/ALL/EAST/PANNON kategóriák) részlegesen implementált.

6. **Haszonszámítás (haszon)** — árfolyam-különbözet alapú haszon/profit kiszámítása. Java-ban `ProfitCalculationService` létezik, de a Delphi-ban lévő `HaszonSzamitas` procedúra részletes logikája (bizonylat-szintű árfolyam-különbözet, kedvezmény-korrekció) lehet hogy nem teljesen egyezik.

7. **Összefoglalás (summa/sumtrade/sumtablo/sumrate/sumwuafa)** — havi aggregációk minden szinten (pénztár, körzet, cég). Java-ban `TurnoverService`, `CentralReportService` részlegesen fedik.

8. **AML/UCTRL/UgyfelControl** — ügyfél-ellenőrző funkciók (terror napló, évi max tranzakciók, tiltások). Java-ban `AmlService`, `BlacklistService` van, de a Delphi uctrl rendszer komplex adatgyűjtési + import + excel export funkcióit nem teljesen fedi.

---


---

## S2 1_SZERVER_MODULOK_GAP_MATRIX

### 1.1 SZERVER/fejleszt — fő modulok

| Delphi modul | Funkció | Java megfelelő | Státusz | Becsült munka |
|---|---|---|---|---|
| `server/unit1-37` | Főszerver (fő loop, daybook, MNB napszakasz, pénztár-monitoring) | `DailySessionService`, `BranchMonitoringService` | RÉSZLEGES | 40 ó |
| `archival/unit1` | Éves archiválás (valdata.fdb → arcdir) | `ArchivingService`, `MonthlyArchiveService` | RÉSZLEGES | 8 ó |
| `arfolyam/verzio20-22` | Árfolyam-kezelés, MNB árfolyam letöltés, verziók | `ExchangeRateService`, `MnbApiClient`, `RateCreationService` | KÉSZ | — |
| `banklist/unit1` | Banklistavezető (bank tiltólista) | `BlacklistService` | KÉSZ | — |
| `beszam/unit1-3` | Elszámolás (pénztáros elszámoltatás) | `HandoverSheetService`, `ClosingWizardService` | RÉSZLEGES | 16 ó |
| `booking/advetexcel` | Adásvétel Excel export | `BookingExportService` | RÉSZLEGES | 12 ó |
| `booking/forgexel` | Forgalom Excel export (könyvelési) | `BookingExportService` | RÉSZLEGES | 12 ó |
| `booking/keszexcel` | Készlet Excel export | `BookingExportService` | RÉSZLEGES | 8 ó |
| `booking/booking` | Főbooking integrátor | `BookingExportService` | RÉSZLEGES | 10 ó |
| `confident/unit1` | Bizalmas adatok kezelés | `SystemParameterService` | NEM KELL | — |
| `etrade/unit1` | Értéktár kereskedelmi modul | `ErtektarController`, `TradeService` | RÉSZLEGES | 12 ó |
| `everseny/unit1` | Éves versenyeredmény | `CompetitionService` | RÉSZLEGES | 6 ó |
| `evitranz/unit1` | Éves tranzakció statisztika | `DecadeReportService`, `TurnoverService` | RÉSZLEGES | 8 ó |
| `evnyito/unit1` | Évnyitó (éves kezdőkészletek) | `SessionOpenService`, `ClosingWizardService` | RÉSZLEGES | 16 ó |
| `expadvet/unit1` | Adásvétel export | `TransactionExportService` | RÉSZLEGES | 8 ó |
| `expevnyito/unit1` | Évnyitó export | `ConfigExportService` | HIÁNYZIK | 6 ó |
| `expgbakall/unit1` | Gbak (Firebird backup) export | N/A (PostgreSQL, más paradigma) | NEM KELL | — |
| `fdbtomorito/unit1` | Firebird DB tömörítés (gbak) | N/A (PostgreSQL-nél nem szükséges) | NEM KELL | — |
| `fdbtorlo/unit1` | Firebird DB törlés | N/A | NEM KELL | — |
| `foglalo/unit1` | Foglalás-összesítő (FTP-ről letölt, Excel) | `ReservationService` + `BookingExportService` | RÉSZLEGES | 12 ó |
| `forgdisp/unit1` | Forgalom display (LED panel) | `LedDisplayService` | KÉSZ | — |
| `frissdat/unit1` | Adatfrissítés (pénztárak között) | `SyncService`, `SynchronizationService` | RÉSZLEGES | 10 ó |
| `gbakall/unit1` | Gbak batch futtatás (Firebird backup) | N/A | NEM KELL | — |
| `haszon/unit1-5` | **Haszonszámítás** (árfolyam-különbözet, bizonylat-szintű) | `ProfitCalculationService`, `ProfitController` | RÉSZLEGES | 24 ó |
| `havitablo/unit1-2` | Havi tablo (havi összesítés) | `MonthlyReportService`, `MonthlyClosingService` | RÉSZLEGES | 16 ó |
| `havitrad/unit1` | Havi trade összesítés | `TradeService`, `MonthlyReportService` | RÉSZLEGES | 8 ó |
| `helga/locserver/unit1-37` | **Helga lokális szerver** (koordinátor, pénztárak közötti szinkron) | `SynchronizationService`, `SyncInboundController` | RÉSZLEGES | 60 ó |
| `helga/dllek/arftmk` | Helga árfolyam-tábla DLL | `RateCreationService` | KÉSZ | — |
| `helga/dllek/beerk` | Helga beerkezés DLL | `CashRegisterService` | RÉSZLEGES | 8 ó |
| `helga/dllek/dolgozok` | Helga dolgozók DLL | `WorkerService` | KÉSZ | — |
| `helga/dllek/import` | Helga import DLL | `DataImportService` | RÉSZLEGES | 8 ó |
| `helga/dllek/irtmk` | Helga iroda tábla-másoló DLL | `SyncService` | RÉSZLEGES | 6 ó |
| `helga/dllek/mnbhibak` | Helga MNB hibák DLL | `MnbReportService` | RÉSZLEGES | 4 ó |
| `helga/dllek/tranzdij` | **Helga tranzakció díj DLL** | `HandlingFeeService`, `HandlingFeeTransactionService` | RÉSZLEGES | 16 ó |
| `helga/dllek/westforg` | Helga Western Union forgalom DLL | `WesternUnionService` | RÉSZLEGES | 10 ó |
| `helga/dllek/zarasok` | Helga zárások DLL | `DailyClosingService`, `EveningClosingService` | RÉSZLEGES | 8 ó |
| `hrkvetel/unit1` | HRK vétel kezelés | `HrkService`, `HrkMonthlyClosingService` | KÉSZ | — |
| `idbeiro/unit1-2` | Azonosítás beiíró (okm. adatok) | `DocumentStorageService`, `CustomerService` | RÉSZLEGES | 8 ó |
| `jelenlet/unit1` | Jelenlét (pénztáros) | `WorkerAttendance` entity, `WorkerManagementService` | KÉSZ | — |
| `jogiszemely/unit1,3` | Jogi személy nyilvántartás | `CustomerService` (jogi személy ág) | RÉSZLEGES | 12 ó |
| `jutmend/unit1` | Juttatás-módosítás (javítás) | `WorkerCommissionService` | RÉSZLEGES | 6 ó |
| `kdchange/unit1` | Kód csere (valuta kód változás) | `CurrencyController` | NEM KELL | — |
| `kereso/unit1` | Általános kereső | Minden Controller-ben keresés | KÉSZ | — |
| `kezdij/unit1` + `cegbetolt` | **Kezelési díj** (kezdeti díj konfig + cég-betöltő) | `HandlingFeeService`, `FeeService` | RÉSZLEGES | 16 ó |
| `korlevel/zsuzsa/unit1-7` | Körlevél (évnyitó + start) | `CircularService` | RÉSZLEGES | 8 ó |
| `lemento/unit1-2` | Lementő (adat mentés) | `BackupService` | RÉSZLEGES | 8 ó |
| `listopenoffices/unit2` | Nyitott irodák listázása | `BranchService` | KÉSZ | — |
| `litenews/unit1` | Lite hír (értesítő küldés) | `NotificationService` | KÉSZ | — |
| `makeszlt/unit1-3` + `excel` | Készletlista gyártás (Excel) | `StockSnapshotExcelService` | RÉSZLEGES | 12 ó |
| `makiroda/unit1` | Iroda-törzs (metadata iroda létrehozás) | `BranchService`, `BranchController` | KÉSZ | — |
| `mendjogi/unit1` | Jogi személy módosítás | `CustomerService` | KÉSZ | — |
| `mentes/unit1` | Mentés (bizonylat, adat) | `BackupService` | RÉSZLEGES | 6 ó |
| `monegram/unit1-2` | **MoneyGram integráció** | NINCS | **HIÁNYZIK** | 40 ó |
| `napiment/unit1` | Napi mentés scheduler | `SchedulerService`, `BackupService` | KÉSZ | — |
| `nevseek/unit1` | Névkeresés (ügyfélazonosítás) | `CustomerService` | KÉSZ | — |
| `newrate/unit1` | Új árfolyam beállítás | `RateCreationService` | KÉSZ | — |
| `newyear/unit1` | Évfordítás (yearend) | `ArchivingService` | RÉSZLEGES | 20 ó |
| `okmctrl/unit1` | Okmány ellenőrzés | `DocumentScannerService` | RÉSZLEGES | 8 ó |
| `orsoseek/unit1` | Ország keresés (ISO) | `CurrencyController` (country code) | KÉSZ | — |
| `palyadij/unit1` | Pályázati díj kezelés | `ContributionService` | RÉSZLEGES | 6 ó |
| `permit/unit1-2` | Engedélyek | `PermissionController`, `LicenseService` | KÉSZ | — |
| `personal/kereso+perseek+tolto` | Személyes adatok keresés/töltés | `CustomerService`, `DataImportService` | RÉSZLEGES | 10 ó |
| `police/unit1-2` + `kereso` | **Rendőrségi adatszolgáltatás** | `PoliceRequestController` | RÉSZLEGES | 20 ó |
| `postterm/unit1` | POS terminál | `PosTerminalService` | KÉSZ | — |
| `ptforg/unit1-4` | **Pénztár forgalom összesítő** (by cashier, by date) | `TurnoverService`, `ReportService` | RÉSZLEGES | 20 ó |
| `pttrfee/unit1` | Pénztár átviteli díj | `HandlingFeeService` | RÉSZLEGES | 6 ó |
| `recguard/unit1` | Receptor őr (pénztár online kapcsolat monitor) | `BranchMonitoringService` | KÉSZ | — |
| `recptor/unit1` + almodulok | **Receptor (pénztár kliens kezelő)** főmodul | `CashRegisterService`, `WorkstationService` | RÉSZLEGES | 30 ó |
| `recptor/getlett` | Receptor: levél letöltő | `CircularService` | KÉSZ | — |
| `recptor/kedvmak` | Receptor: kedvezmény gyártó | `DiscountThresholdService`, `RateCalculationService` | RÉSZLEGES | 8 ó |
| `recptor/keszlet` | Receptor: készlet modul | `InventoryService` | RÉSZLEGES | 10 ó |
| `recptor/orecept` | Receptor: régi receptor migráció | N/A | NEM KELL | — |
| `recptor/tablomak` | Receptor: tábla gyártó | `RateCreationService` | KÉSZ | — |
| `remaltib/unit1-6` | **Általános DB böngésző/karbantartó** (admin eszköz) | N/A | NEM KELL | — |
| `setrade/unit1` | SE trade (South-East trade modul) | `TradeService` | RÉSZLEGES | 6 ó |
| `statiszt/unit1` + `cartcash` | **Statisztika** (ügyfél-azonosítás, adatregisztrálás) | `CustomerControlService`, `AmlService` | RÉSZLEGES | 12 ó |
| `summa/unit1-2` | **Összefoglaló (summa)** — forgalom+profit+WU+AFA+eker+kezdij legyűjtés | `TurnoverService`, `ProfitCalculationService` | RÉSZLEGES | 24 ó |
| `sumrate/unit1` | Összesített árfolyam | `RateHistoryService` | KÉSZ | — |
| `sumtablo/unit1` | Összesített tablo | `ReportService` | RÉSZLEGES | 8 ó |
| `sumtrade/unit1-5` | **Összesített trade riport** (havi, körzet, cég szintű) | `TradeService`, `CentralReportService` | RÉSZLEGES | 20 ó |
| `tablomak/unit1-2` | Tábla gyártó (árfolyam tábla) | `RateCreationService`, `PrintTemplateController` | KÉSZ | — |
| `terror/maketerrlist` | Terror lista generátor | `SanctionScreeningService` | KÉSZ | — |
| `tiltcopy/unit1` | Tiltó másoló (tiltólista propagálás) | `BlacklistService` | KÉSZ | — |
| `tranzdb/unit1` | Tranzakció DB lekérdező | `TransactionController`, `ReportService` | KÉSZ | — |
| `tranzdij/unit1` | **Tranzakció díj** számítás | `HandlingFeeService`, `CommissionCalculationService` | RÉSZLEGES | 20 ó |
| `trnzstat/unit1` | Tranzakció statisztika | `TurnoverService` | RÉSZLEGES | 8 ó |
| `uctrl/adatpotlo` | Ügyfélcontrol: adatpótló | `CustomerService`, `DataImportService` | RÉSZLEGES | 10 ó |
| `uctrl/atvitel` | Ügyfélcontrol: adatátvitel | `DataImportService` | RÉSZLEGES | 6 ó |
| `uctrl/butitott` | Ügyfélcontrol: butított mód | N/A | NEM KELL | — |
| `uctrl/hibakeres` | Ügyfélcontrol: hibakereső | `ErrorLogController` | KÉSZ | — |
| `uctrl/mend` | Ügyfélcontrol: javítás | `CustomerService` (patch) | KÉSZ | — |
| `uctrl/regeneral` | Ügyfélcontrol: regenerálás | `InventoryRegenerationService` | KÉSZ | — |
| `uctrl/svisor` | Ügyfélcontrol: supervisor | `SupervisorService` | KÉSZ | — |
| `uctrl/u2text` | Ügyfélcontrol: ügyfél→szöveg export | `ReportService` | RÉSZLEGES | 4 ó |
| `uctrl/ugyfcreat` | Ügyfélcontrol: ügyfél létrehozás | `CustomerService` | KÉSZ | — |
| `uctrl/ugyfreg` | Ügyfélcontrol: ügyfél regisztráció | `CustomerService` | KÉSZ | — |
| `ufill18/unit1` | Ufill 2018 (adatfeltöltő) | `DataImportService` | RÉSZLEGES | 4 ó |
| `ufill19/unit1` | Ufill 2019 | `DataImportService` | RÉSZLEGES | 4 ó |
| `uforg/unit1` | U-forgalom (ügyfél forgalom) | `CustomerControlService` | RÉSZLEGES | 8 ó |
| `ugyfelcontrol/ugyfctrl` | **Ügyfélcontrol főmodul** (terror napló, évimax, import, tiltások) | `AmlService`, `CustomerControlService`, `BlacklistService` | RÉSZLEGES | 30 ó |
| `ugyfelcontrol/dll/adatgyujto` | Adatgyűjtő DLL | `DataCollectionService` | RÉSZLEGES | 10 ó |
| `ugyfelcontrol/dll/adatlista` | Adatlista DLL | `ReportService` | RÉSZLEGES | 6 ó |
| `ugyfelcontrol/dll/evimax` | Évi maximum tranzakciók DLL | `AmlService` (threshold) | RÉSZLEGES | 8 ó |
| `ugyfelcontrol/dll/excel` | Excel export DLL | `ReportExportService` | RÉSZLEGES | 6 ó |
| `ugyfelcontrol/dll/idoszak` | Időszak DLL | `ReportService` | KÉSZ | — |
| `ugyfelcontrol/dll/idoszakos` | Időszakos DLL | `ReportService` | KÉSZ | — |
| `ugyfelcontrol/dll/import` | Import DLL | `DataImportService` | RÉSZLEGES | 8 ó |
| `ugyfelcontrol/dll/kereso` | Kereső DLL | `CustomerService` | KÉSZ | — |
| `ugyfelcontrol/dll/letilt` | Letiltás DLL | `BlacklistService` | KÉSZ | — |
| `ugyfelcontrol/dll/makeexcel` | Excel gyártó DLL | `ReportExportService` | RÉSZLEGES | 6 ó |
| `ugyfelcontrol/dll/okmdisp` | Okmány display DLL | `DocumentStorageService` | RÉSZLEGES | 6 ó |
| `ugyfelcontrol/dll/terrornaplo` | Terror napló DLL | `AmlService` (terror log) | RÉSZLEGES | 10 ó |
| `ugyfelcontrol/dll/tiltasok` | Tiltások DLL | `BlacklistService` | KÉSZ | — |
| `ugyfelcontrol/dll/ujimport` | Új import DLL | `DataImportService` | RÉSZLEGES | 8 ó |
| `ugyfseek/unit1` | Ügyfél kereső | `CustomerService` | KÉSZ | — |
| `verseny/unit1-5` | **Verseny** (pénztáros verseny számítás, körzet, cég) | `CompetitionService`, `WorkerCompetitionService` | RÉSZLEGES | 20 ó |
| `verseny_mend/unit1` | Verseny javítás | `CompetitionService` | RÉSZLEGES | 4 ó |
| `vevo/unit1` | Vevő kezelés | `CustomerService` | KÉSZ | — |
| `vevoszam/unit1` + `/2` + `/3` | Vevőszám generátor (3 verzió) | `CustomerService`, `ReceiptSequenceService` | RÉSZLEGES | 6 ó |
| `western/unit1` | **Western Union szerveri összesítő** (havi WU Excel, körzet+cég) | `WesternUnionService`, `CentralReportService` | RÉSZLEGES | 20 ó |
| `westuni/unit1` | Western Union összesítő (különálló) | `WesternUnionService` | RÉSZLEGES | 12 ó |
| `wucontrol/unit1` | WU control modul | `WesternUnionService` | RÉSZLEGES | 10 ó |
| `wuniforg/unit1` | WU Union forgalom | `WesternUnionService`, `TurnoverService` | RÉSZLEGES | 8 ó |
| `_arfteszt/unit1-16` | Árfolyam teszt (belső fejlesztői eszköz) | N/A | NEM KELL | — |
| `_napiforg/unit1-2` | Napi forgalom összesítő (belső) | `DailyReportService` | KÉSZ | — |

### 1.2 SZERVER/ujdll — új DLL modulok

| Delphi modul | Funkció | Java megfelelő | Státusz | Becsült munka |
|---|---|---|---|---|
| `ujdll/adatgyujto` | Adatgyűjtő DLL (új) | `DataCollectionService` | RÉSZLEGES | 8 ó |
| `ujdll/arftmk` | Árfolyam tábla másoló DLL | `RateCreationService` | KÉSZ | — |
| `ujdll/atlagarf` | **Átlagárfolyam DLL** | `RateCalculationService` | RÉSZLEGES | 8 ó |
| `ujdll/bankforg` | **Bank forgalom DLL** (bankba/bankból mozgás) | `VaultBankTransactionService` | RÉSZLEGES | 10 ó |
| `ujdll/beerkctrl` | Beerkezés kontrol DLL | `CashRegisterService` | RÉSZLEGES | 8 ó |
| `ujdll/beerkezes` | **Beerkezés DLL** (pénztár megnyitás, napkezdés) | `SessionOpenService`, `DailySessionService` | RÉSZLEGES | 12 ó |
| `ujdll/bejelentes` | Bejelentés DLL (MNB bejelentés) | `MnbReportService` | RÉSZLEGES | 8 ó |
| `ujdll/datadisp` | Adat display DLL | `DashboardService` | KÉSZ | — |
| `ujdll/dbookctrl` | DayBook kontrol DLL | `DailySessionService` | RÉSZLEGES | 8 ó |
| `ujdll/dolgozok` | Dolgozók DLL | `WorkerService` | KÉSZ | — |
| `ujdll/forgalomdisp` | Forgalom display DLL | `LedDisplayService`, `DashboardService` | KÉSZ | — |
| `ujdll/getdisp` | Get display DLL | `DashboardService` | KÉSZ | — |
| `ujdll/getuzlet` | Üzletek lekérdező DLL | `BranchService` | KÉSZ | — |
| `ujdll/hovalasz` | Hoválasz (választ küld) DLL | `SyncService` | KÉSZ | — |
| `ujdll/hrkserver` | **HRK szerver DLL** | `HrkService`, `HrkMonthlyClosingService` | KÉSZ | — |
| `ujdll/idoszak` | Időszak DLL | `ReportService` | KÉSZ | — |
| `ujdll/import` | Import DLL | `DataImportService` | RÉSZLEGES | 6 ó |
| `ujdll/irtmk` | Iroda tábla-másoló DLL | `SyncService` | RÉSZLEGES | 6 ó |
| `ujdll/jutszamito` | **Jutalmak számítója DLL** (pénztáros jutalék) | `WorkerCommissionService`, `CommissionCalculationService` | RÉSZLEGES | 24 ó |
| `ujdll/jutszazalek` | **Jutalékszázalék DLL** | `CommissionRateService` | RÉSZLEGES | 12 ó |
| `ujdll/keszletdisp` | Készlet display DLL | `InventoryService`, `StockSnapshotService` | KÉSZ | — |
| `ujdll/kezdij` | Kezelési díj DLL | `HandlingFeeService` | RÉSZLEGES | 10 ó |
| `ujdll/kezdtranzdisp` | Kezdő tranzakció display DLL | `DashboardService` | KÉSZ | — |
| `ujdll/mnbgyujto` | **MNB gyűjtő DLL** (napi/havi adatgyűjtés MNB-nek) | `MnbReportService`, `MnbApiClient` | RÉSZLEGES | 20 ó |
| `ujdll/mnbhibak` | MNB hibák DLL | `MnbReportService` | RÉSZLEGES | 6 ó |
| `ujdll/ptarkozott` | Pénztár kötözött DLL (bizonylat kötözés) | `PackagingService`, `StampService` | RÉSZLEGES | 8 ó |
| `ujdll/stornodisp` | Storno display DLL | `StornoService` | KÉSZ | — |
| `ujdll/sumwuafa` | **Sum WU+AFA DLL** (Western Union + ÁFA összesítő) | `WesternUnionService`, `VatRefundService` | RÉSZLEGES | 16 ó |
| `ujdll/tranzakc` | **Tranzakció DLL** (fő váltási adatbedolgozó, napi/havi) | `TransactionService`, `TransactionReportService` | RÉSZLEGES | 30 ó |
| `ujdll/trbdisp` | TR balance display DLL | `CashBalanceService` | KÉSZ | — |
| `ujdll/unpacker` | Unpacker DLL (bináris csomag kicsomagolás) | N/A | NEM KELL | — |
| `ujdll/userbelep` | User belépés DLL | `AuthController`, `UserService` | KÉSZ | — |
| `ujdll/western` | **Western Union DLL** | `WesternUnionService` | RÉSZLEGES | 12 ó |
| `ujdll/wuafatranz` | **WU+AFA tranzakció DLL** | `WesternUnionService`, `VatRefundService` | RÉSZLEGES | 12 ó |
| `ujdll/wunidisp` | WU display DLL | `WesternUnionService` | KÉSZ | — |
| `ujdll/zarasctrl` | **Zárás kontroler DLL** (napzárás workflow) | `DailyClosingService`, `ClosingWizardService` | RÉSZLEGES | 16 ó |

---


---

## S3 2_ERTEKTAR_MODULOK_GAP_MATRIX

### 2.1 ERTEKTAR/etdll — fő DLL modulok

| Delphi modul | Funkció | Java megfelelő | Státusz | Becsült munka |
|---|---|---|---|---|
| `arftmk` | Árfolyam tábla másoló (értéktárban) | `RateCreationService` | KÉSZ | — |
| `atadolap` | **Átadólap** (értéktár→pénztár átadás bizonylata) | `HandoverSheetService`, `TransferDocumentService` | RÉSZLEGES | 20 ó |
| `atadvet` | Átadás-vétel (értéktár mozgás) | `VaultTransferService` | RÉSZLEGES | 12 ó |
| `bizodisp` | Bizonylat display (értéktárban) | `ReceiptService`, `ReceiptSearchService` | KÉSZ | — |
| `bloknyom` | Blokk nyomtatás (értéktárban) | `ReceiptGeneratorService` | KÉSZ | — |
| `checklst` | Checklist (értéktár) | `DailyChecklistService` | KÉSZ | — |
| `cimlctrl` | Cimlet kontrol (értéktár) | `DenominationService`, `DenominationBalanceService` | KÉSZ | — |
| `cimlet` | Cimlet (értéktár cimlet lista) | `DenominationService` | KÉSZ | — |
| `cimlmenu` | Cimlet menü (értéktár) | `DenominationService` | KÉSZ | — |
| `cimlnyom` | Cimlet nyomtató (értéktárban) | `DenominationCalculatorService` | KÉSZ | — |
| `cimsetup` | Cimlet beállítás (értéktár) | `DenominationConfigService` | KÉSZ | — |
| `estizar` | **Esti zárás (értéktár)** | `EveningClosingService` | KÉSZ | — |
| `getarf` | Árfolyam lekérő (értéktár) | `ExchangeRateService` | KÉSZ | — |
| `getellen` | Ellenőr lekérő | `SupervisorService` | KÉSZ | — |
| `getplomb` | Plomb lekérő | `SealNumberService`, `SealTrackingService` | KÉSZ | — |
| `getptar` | Pénztár lekérő | `CashRegisterService` | KÉSZ | — |
| `havizar` | **Havi zárás (értéktár)** | `MonthlyClosingService`, `HrkMonthlyClosingService` | RÉSZLEGES | 16 ó |
| `hrkatvevo` | HRK átvevő (értéktárban) | `HrkService` | KÉSZ | — |
| `hrkcimlet` | HRK cimlet (értéktárban) | `HrkService`, `DenominationService` | KÉSZ | — |
| `idoszak` | Időszak (értéktár) | `ReportService` | KÉSZ | — |
| `irarfoly` | **Irodai árfolyamok** (értéktár árfolyam irat, nyomtatás) | `ExchangeRateDisplayService`, `PrintTemplateController` | RÉSZLEGES | 16 ó |
| `kcimlet` | K-cimlet (kissé más cimlet kezelés) | `DenominationService` | KÉSZ | — |
| `keszedit` | **Készlet szerkesztő** (kézi készlet korrekció) | `StockCorrectionService` | RÉSZLEGES | 12 ó |
| `keszup` | **Készlet feltöltő** (értéktár→server push) | `VaultCollectionService`, `InventoryService` | RÉSZLEGES | 16 ó |
| `kezdij` | Kezelési díj (értéktárban) | `HandlingFeeService` | KÉSZ | — |
| `korlev` | Körlevél (értéktárban) | `CircularService` | KÉSZ | — |
| `listak` | Listák (értéktár riport) | `ReportService` | RÉSZLEGES | 6 ó |
| `logdisp` | Log display (értéktárban) | `LoggingController`, `AuditLogService` | KÉSZ | — |
| `logiro` | Log iró (értéktárban) | `AuditLogService` | KÉSZ | — |
| `maktablak` | Tábla ablak (értéktárban) | `RateCreationService` | KÉSZ | — |
| `matptar` | Mat pénztár (értéktár anyag pénztár) | `InventoryService`, `PackagingService` | RÉSZLEGES | 10 ó |
| `mentes` | Mentés (értéktárban) | `BackupService` | RÉSZLEGES | 6 ó |
| `napijel` | **Napi jelentés (értéktár)** — komplex (ArfolyamPanelek, WU, AFA, Cimlet, Zárás, stb.) | `DailyReportService`, `ErtektarController` | RÉSZLEGES | 32 ó |
| `napikezd` | **Napi kezdés (értéktár)** — készlet nyomtatás, nyitó rekord | `SessionOpenService`, `DailySessionService` | RÉSZLEGES | 20 ó |
| `napkonyv` | **Napi könyv (értéktár)** — teljes nap összes tranzakciójának listája | `DailyReportService`, `TransactionReportService` | RÉSZLEGES | 24 ó |
| `napzar` | **Napi zárás (értéktár)** — HaviGyujtokbeMasolas, BFCopy, BTCopy, CIMTCopy, NarfCopy, WuniCopy stb. | `DailyClosingService`, `EveningClosingService`, `ClosingWizardService` | RÉSZLEGES | 30 ó |
| `nifval` | NIF validáció (adószám ellenőrzés) | `CustomerService` (NIF validation) | RÉSZLEGES | 6 ó |
| `nznyomt` | NZ nyomtató (értéktárban) | `ReceiptGeneratorService` | KÉSZ | — |
| `penztarak` | **Pénztárak (értéktár nézet)** | `CashRegisterService`, `BranchService` | RÉSZLEGES | 8 ó |
| `pictload` | Kép betöltő | N/A (UI modul) | NEM KELL | — |
| `pillall` | Pillanatnyi állás (értéktár real-time) | `DashboardService`, `CashBalanceService` | RÉSZLEGES | 10 ó |
| `pillkesz` | **Pillanatnyi készlet + grafikon** | `StockSnapshotService`, `InventoryService` | RÉSZLEGES | 16 ó |
| `prosbe` | Pénztáros beállítás (értéktárban) | `WorkerService` | KÉSZ | — |
| `prostmk` | Pénztáros tábla másolás | `WorkerService` | KÉSZ | — |
| `ptarkesz` | **Pénztárkészlet** (értéktár pénztár készlet riport) | `StockSnapshotService`, `InventoryService` | RÉSZLEGES | 12 ó |
| `ptartmk` | Pénztár tábla másolás | `SyncService` | KÉSZ | — |
| `quitform` | Kilépő form | N/A (UI) | NEM KELL | — |
| `ratectrl` | Rate kontrol (értéktár) | `RateManagementService` | KÉSZ | — |
| `rateperm` | Rate engedély | `RateApprovalService` | KÉSZ | — |
| `regen` | Regenerálás (értéktár adat) | `InventoryRegenerationService` | KÉSZ | — |
| `regizaro` | Régi zárás (értéktár) | `ArchivingService` | RÉSZLEGES | 8 ó |
| `storno` | **Storno (értéktárban)** — bizonylat stornó folyamat | `StornoService` | RÉSZLEGES | 16 ó |
| `super` | Szupervisor (értéktár) | `SupervisorService` | KÉSZ | — |
| `supertsk` | Szupervisor feladatok (értéktárban) | `SupervisorService` | KÉSZ | — |
| `terminal` | Terminál (értéktár) | `PosTerminalService` | KÉSZ | — |
| `wunion` | **Western Union (értéktárban)** | `WesternUnionService` | RÉSZLEGES | 12 ó |

### 2.2 ERTEKTAR/fejleszt — fejlesztői modulok

| Delphi modul | Funkció | Java megfelelő | Státusz | Becsült munka |
|---|---|---|---|---|
| `frissito/unit1` | Frissítő (értéktár update) | `VersionController`, `FtpSyncService` | KÉSZ | — |
| `newyear/unit1` | Évfordítás (értéktárban) | `ArchivingService` | RÉSZLEGES | 8 ó |
| `permit/unit1` | Engedélyek (értéktárban) | `PermissionController` | KÉSZ | — |

---


---

## S4 3_VALUTA_DELTA_19_UJ_MODUL

A VALUTA rendszer főleg az IBVALTO főprogram + DLL-ek. A korábbi gap-elemzés a VALUTA klienst vizsgálta. Az alábbi modulok VALUTA/DLL-ben megtalálhatók, de a korábbi elemzésbe nem kerültek be:

| Delphi modul | Funkció | Java megfelelő | Státusz | Becsült munka |
|---|---|---|---|---|
| `VALUTA/DLL/QRGENER` | QR kód generátor (bizonylaton) | `QrCodeService` | KÉSZ | — |
| `VALUTA/DLL/QRDEPUTY` | QR helyettes (deputy mode) | `AuthorizationController` | RÉSZLEGES | 6 ó |
| `VALUTA/DLL/SCANNING` | Dokumentum beolvasó | `DocumentScannerService` | KÉSZ | — |
| `VALUTA/DLL/UJSCANNER` | Új scanner | `DocumentScannerService` | KÉSZ | — |
| `VALUTA/DLL/SENDOKMANY` | Okmány küldő (szerverre) | `DocumentStorageService` | KÉSZ | — |
| `VALUTA/DLL/DOCDISP` | Okmány display | `DocumentStorageService` | KÉSZ | — |
| `VALUTA/DLL/TEAOR` | TEÁOR kód kezelés | `CustomerService` | RÉSZLEGES | 4 ó |
| `VALUTA/DLL/METRO` | Metro (Metró típusú kezelés) | N/A | HIÁNYZIK | 8 ó |
| `VALUTA/DLL/TESCO` | Tesco (Tesco típusú helyszín) | N/A | HIÁNYZIK | 8 ó |
| `VALUTA/DLL/GONGBACK` | Gong visszajelzés (audio visszajelző) | N/A | NEM KELL | — |
| `VALUTA/DLL/PAUSDISP` | Szünet display | `CashDeskBreakService` | KÉSZ | — |
| `VALUTA/DLL/GETSTATUS` | Státusz lekérő | `BranchMonitoringService` | KÉSZ | — |
| `VALUTA/DLL/GETWCEG` | Western Union cég lekérő | `WesternUnionService` | KÉSZ | — |
| `VALUTA/DLL/GETWUGYF` | WU ügyfél lekérő | `WesternUnionService`, `CustomerService` | KÉSZ | — |
| `VALUTA/DLL/OTHERTSK` | Egyéb feladatok | `SchedulerService` | KÉSZ | — |
| `VALUTA/DLL/XTRANZ` | X-tranzakció (extra típusú) | `TransactionService` | RÉSZLEGES | 8 ó |
| `VALUTA/DLL/FNYUJSAG` + alverziók | **Falinyújtó (rate display táblák, 15+ helyszín-specifikus)** | `ExchangeRateDisplayService`, `LedDisplayService` | RÉSZLEGES | 20 ó |
| `VALUTA/DLL/COPY2FTP` | FTP-re másolás | `FtpSyncService` | KÉSZ | — |
| `VALUTA/DLL/PROCEND` | Process end (folyamat lezáró) | `SchedulerService` | KÉSZ | — |
| `VALUTA/TRADE/fejleszt` | **TRADE főmodul** (valutakereskedés, ArchiváLás, blokk nyomtatás, évi trade kontrol) | `TradeController`, `TradeService` | RÉSZLEGES | 40 ó |
| `VALUTA/IBVALTO/unit1` | **IBVALTO főprogram** (teljes pénztár kliens, menu, timer, NaplóQuery, TradeQuery) | Frontend (React) + Backend | RÉSZLEGES | 60 ó |

---


---

## S5 4_KRITIKUS_HIANYZO_UZLETI_LOGIKA

### 4.1 MoneyGram integráció — TELJES HIÁNY

A SZERVER/fejleszt/monegram modul teljes MoneyGram pénzátutalási integráció volt. A Java-ban **egyáltalán nincs** MoneyGram service. A Delphi kód:
- Havi MoneyGram adatbedolgozás (MG fájlok)
- Körzet-szintű MoneyGram forgalom
- Excel riport generálás (HUF/EUR/USD sorok)
- Hiányos napok pótlása (`ElsejePotlasa`)

**Hatás:** Ha MoneyGram integráció szükséges production-ban, ez ~40 óra fejlesztés.

### 4.2 MNB Gyűjtő komplex logika — RÉSZLEGES

A `ujdll/mnbgyujto` DLL komplex adatgyűjtési logikát tartalmaz:
- `ForgalomGyujtes` — forgalom gyűjtés minden pénztárból
- `KorzetSumma`, `KorzetNullazo` — körzet-szintű összesítők
- `KftSumma`, `KftNullazo` — KFT-szintű összesítők
- `CegSumma`, `CegNullazo` — cég-szintű összesítők
- `FBizonylatFeldolgozo`, `UBizonylatFeldolgozo` — F és U bizonylat feldolgozás
- Napi MNB adat: nyitó/záró/forgalom minden valutanemhez

A Java `MnbReportService` ezt részlegesen fedi, de a Delphi háromszintű (pénztár→körzet→cég) aggregáció nincs teljes egészében implementálva.

**Hatás:** MNB riport pontossága kérdéses. ~20 óra fejlesztés.

### 4.3 Tranzakció díj komplex kalkuláció — RÉSZLEGES

A SZERVER `ujdll/tranzakc` DLL 1659+ soros unit, ami:
- Napi és havi bedolgozást végez (`HAVIBEDOLGGOMBClick`, `NAPIBEDOLGGOMBClick`)
- Elszámolás táblát vezeti (`ElszamTablaControl`)
- Forgalom gyűjtés (`ForgalomGyujtes`), Konverzió forgalom (`KonverzioForgalom`), Eladás forgalom (`EladasForgalom`)
- **BEST/ALL/EAST/PANNON** kategóriák szerinti szortírozás
- Árfolyam különbözet alapú elszámolás (`Getelszarfarfolyam`)

A Java-ban ez szét van szórva `HandlingFeeService`, `CommissionCalculationService`, `TransactionService` között, de az aggregált napi/havi bedolgozás logika nem teljes.

**Hatás:** Pénztáros elszámolás pontatlanság kockázat. ~30 óra fejlesztés.

### 4.4 Haszonszámítás (profit) — RÉSZLEGES

A SZERVER `haszon` modul (`unit1-5`):
- Bizonylat-szintű árfolyam-különbözet számítás
- Kedvezmény korrekció (`Kedvezmenyseek`)
- Konverzió haszon külön
- Storno hatása a profitra

A Java `ProfitCalculationService` + `ProfitController` létezik, de a Delphi `HaszonSzamitas` procedúra részletes logikája (különösen a storno korrekció és kedvezmény-szám bejárása) lehet nem teljes.

**Hatás:** Profit riport pontossága. ~24 óra fejlesztés.

### 4.5 Értéktár Napi Jelentés — RÉSZLEGES

Az ERTEKTAR `napijel` modul ~1557+ soros, rendkívül komplex:
- 10+ valutanem arfolyam panelek (X sorozat)
- WU összesítő panel
- Cimlet részletezés
- Napi (DE/DU) bontás eladás/vétel
- Záró + Forint + Valuta összesítő panelek
- Bizonylat X sorozat (10-ig)
- Plusz/Mínusz gomb navigáció (iroda böngészés)

A Java `DailyReportService` + `ErtektarController` lényegesen kevesebb adatot jelenít meg.

**Hatás:** Értéktár napi jelentes nem teljes. ~32 óra fejlesztés.

### 4.6 Értéktár Napi Zárás teljes workflow — RÉSZLEGES

Az ERTEKTAR `napzar` modul 1039+ soros, és kötelező lépések sorozatát hajtja végre:
- `BFCopy` — bankforgalom másolás
- `BTCopy` — banktétel másolás
- `CIMTCopy` — cimlet tábla másolás
- `NarfCopy` — névleges árfolyam másolás
- `WuniCopy` — WU összesítő másolás
- `WzarCopy` — WU záró másolás
- `EdatCopy` — dátum másolás
- `EkerCopy` — értékkamat másolás
- `KDatCopy` — kötelező adatok másolás
- `KezdijCopy` — kezelési díj másolás
- `HaviGyujtokbeMasolas` — havi gyűjtőkbe másolás

A Java `ClosingWizardService` (461 sor) részlegesen fedi, de az értéktár-specifikus copy lépések nincs mind implementálva.

**Hatás:** Értéktár napi zárás nem teljes. ~30 óra fejlesztés.

### 4.7 Verseny számítás mélysége — RÉSZLEGES

A SZERVER `verseny` modul:
- `ProsBekertolvasas` — pénztáros adatok beolvasás
- `JutfreeBizonylatok` — juttatás-mentes bizonylatok kezelés
- `VersenyRogzites` — verseny eredmény rögzítése
- `SetpenztarSorrend` — sorrend meghatározás
- `HutoGb` — hűtőfáklya számítás (gamification)
- `Angolra` — angol névkonverzió

A Java `CompetitionService` + `WorkerCompetitionService` alapvetőn megvan, de a Delphi-ban lévő komplex pontszámítás (juttatás-mentes bizonylat figyelembevétele, körzet-szintű verseny) nem biztos, hogy teljesen egyezik.

**Hatás:** Verseny módosul a valódi pénztáros élménytől. ~20 óra.

### 4.8 Átlagárfolyam számítás — RÉSZLEGES

Az `ujdll/atlagarf` DLL az átlag valutavásárlási/eladási árfolyamot számítja el (súlyozott átlag, time-weighted). A Java-ban `RateCalculationService` részlegesen implementálja, de az exact Delphi algoritmus (pl. a havi súlyozás módja) ellenőrizendő.

**Hatás:** Könyvelési átlagárfolyam pontossága. ~8 óra.

---


---

## S6 5_PRIORITASI_LISTA_MUST_SHOULD_COULD_WONT

### MUST — Production-hoz kötelező

| # | Modul/funkció | Becsült munka | Miért kötelező |
|---|---|---|---|
| M-1 | MNB gyűjtő háromszintű aggregáció | 20 ó | Törvényi kötelezettség — MNB riport |
| M-2 | Értéktár napi zárás teljes workflow | 30 ó | Pénzügyi zárás konzisztencia |
| M-3 | Értéktár napi jelentes teljes adat | 32 ó | Értéktár kezelő napi munkája |
| M-4 | Tranzakció díj napi/havi bedolgozás | 30 ó | Pénztáros elszámolás alapja |
| M-5 | Rendőrségi adatszolgáltatás teljes | 20 ó | Törvényi kötelezettség |
| M-6 | Évnyitó/évfordítás | 20 ó | Éves üzleti folytonosság |
| M-7 | Értéktár storno teljes workflow | 16 ó | Pénzügyi korrekció |
| M-8 | Haszonszámítás pontossága | 24 ó | Profit riport hitelessége |
| M-9 | Készlet feltöltő (ertektar→server) | 16 ó | Valós készletállapot |
| M-10 | Napi könyv teljes lista | 24 ó | Kötelező napi dokumentum |

### SHOULD — Erősen ajánlott

| # | Modul/funkció | Becsült munka | Miért ajánlott |
|---|---|---|---|
| S-1 | Verseny számítás mélysége | 20 ó | Pénztáros motiváció |
| S-2 | Western Union szerveri összesítő | 20 ó | WU havi lezárás |
| S-3 | Booking/Excel könyvelési export | 32 ó | Könyvelő számára |
| S-4 | Ügyfélcontrol terror napló mélység | 10 ó | AML compliance |
| S-5 | Jutalomszámítás komplex kalkuláció | 24 ó | Pénztáros díjazás |
| S-6 | Átlagárfolyam pontos algoritmus | 8 ó | Könyvelési pontosság |
| S-7 | Átadólap teljes értéktár verzió | 20 ó | Dokumentáció |
| S-8 | Éves tranzakció statisztika | 8 ó | Menedzsment riport |
| S-9 | Pillanatnyi készlet grafikon | 16 ó | Értéktár áttekintés |
| S-10 | Foglalás szerveri összesítő (Excel) | 12 ó | Értékesítési adat |

### COULD — Hasznos, de halasztható

| # | Modul/funkció | Becsült munka | Megjegyzés |
|---|---|---|---|
| C-1 | MoneyGram integráció | 40 ó | Csak ha MG-t használnak |
| C-2 | Havi WU tablo (western/unit1) | 20 ó | Statisztikai célú |
| C-3 | Foglalás Excel FTP-ről | 12 ó | Automatizálható másképp |
| C-4 | Kör-szintű összesítők teljes mélység | 20 ó | Menedzsment riport |
| C-5 | FNYUJSAG helyszín-specifikus variánsok | 20 ó | 15+ lokáció verzió |
| C-6 | Jogiszemely mélység | 12 ó | KFT ügyfél edge case |
| C-7 | Ufill18/19 adatfeltöltők | 8 ó | Legacy migráció |
| C-8 | Valutaigény (uctrl adatpótló) | 10 ó | Ritka eset |
| C-9 | Polce request keresővel | 6 ó | Kiegészítő funkció |
| C-10 | NIF validáció szigorítás | 6 ó | Technikai javítás |

### WONT — Nem kell implementálni

| # | Modul/funkció | Miért nem kell |
|---|---|---|
| W-1 | Firebird backup (gbak, fdbtomorito, fdbtorlo) | PostgreSQL + pgdump váltotta ki |
| W-2 | Remaltib (DB böngésző admineszköz) | Fejlesztői eszköz, nem prod |
| W-3 | Butitott ügyfélcontrol mód | Fejlesztői debug |
| W-4 | Archiv régi receptor migráció (orecept) | Már lefutott migráció |
| W-5 | Gongback (audio visszajelző) | UI elem |
| W-6 | Pictload (képbetöltő) | UI elem |
| W-7 | Quitform (kilépő form) | UI elem |
| W-8 | Arfteszt (fejlesztői árfolyam teszt) | Fejlesztői eszköz |
| W-9 | Unpacker DLL (bináris csomag) | Firebird-specifikus |
| W-10 | Kdchange (valuta kód csere) | Egyszeri migráció |

---


---

## S7 6_OSSZESITETT_MUNKABECSLES

### MUST kategória összesen

| Terület | Modulok száma | Becsült munka |
|---|---|---|
| MNB compliance | 3 modul | 26 ó |
| Értéktár záró workflow | 4 modul | 78 ó |
| Pénztáros elszámolás | 2 modul | 54 ó |
| Haszon/profit | 1 modul | 24 ó |
| Törvényi (rendőrség) | 1 modul | 20 ó |
| **MUST összesen** | **11 terület** | **~202 óra** |

### SHOULD kategória összesen

| Terület | Modulok száma | Becsült munka |
|---|---|---|
| Verseny + jutalom | 2 modul | 44 ó |
| WU szerveri oldal | 2 modul | 32 ó |
| Booking/könyvelési export | 3 modul | 52 ó |
| Egyéb SHOULD | 5 modul | 62 ó |
| **SHOULD összesen** | **12 terület** | **~190 óra** |

### COULD kategória összesen

| Terület | Becsült munka |
|---|---|
| MoneyGram | 40 ó |
| Egyéb COULD | 114 ó |
| **COULD összesen** | **~154 óra** |

### Teljes gap

| Prioritás | Munka (óra) | Sprint (2 fős, 2 hetes) |
|---|---|---|
| MUST | ~202 | ~5 sprint |
| SHOULD | ~190 | ~5 sprint |
| COULD | ~154 | ~4 sprint |
| **Összes** | **~546 óra** | **~14 sprint** |

> Megjegyzés: A becslések 2 tapasztalt Java fejlesztőre vonatkoznak. Fontos figyelembe venni, hogy a Delphi logika néhány modulban rendkívül komplex (tranzakc DLL: 1659+ sor, napijel: 1557+ sor, napzar: 1039+ sor), ezért a becslések inkább optimisták.

---


---

## S8 7_JAVASLATOK

### 7.1 Azonnali teendők (sprint 0)

1. **MNB gyűjtő audit** — A `MnbReportService` és a Delphi `mnbgyujto/unit2.pas` közvetlen összehasonlítása sorról sorra. Ha eltérés van a háromszintű aggregációban → kritikus bug.

2. **Értéktár zárás completeness check** — A `ClosingWizardService` és az `ErtektarController` összevetése a Delphi `napzar/unit2.pas` 10+ copy-lépésével. Hiányzó lépések → adatintegritás probléma.

3. **Tranzakció díj audit** — A `HandlingFeeService` + `CommissionCalculationService` és a Delphi `tranzakc/unit2.pas` napi/havi bedolgozási logikájának összevetése.

### 7.2 Sprint-tervezés

```
Sprint 1-2: MUST M-1 + M-2 (MNB + értéktár zárás)
Sprint 3-4: MUST M-3 + M-4 (értéktár napijel + tranzakció díj)
Sprint 5: MUST M-5 + M-6 + M-7 (rendőrség + évnyitó + storno)
Sprint 6: MUST M-8 + M-9 + M-10 (haszon + készlet + napkönyv)
Sprint 7-8: SHOULD S-1..S-5 (verseny, WU, booking)
Sprint 9-10: SHOULD S-6..S-10 (átlagarf, átadólap, stb.)
Sprint 11-14: COULD (opcionálisan)
```

### 7.3 Technikai módszer

- Minden hiányzó/részleges Delphi modult a `makedll/unit2.pas` alapján kell fordított tervezni (ez az éles DLL, nem a debug)
- Az összes Firebird specifikus lekérdezés (`TIBQuery`, `TIBTable`) PostgreSQL-re átültetendő
- A Delphi `REAL` típus (6 byte float) → Java `BigDecimal` (ne `double`/`float`) pénzügyi számításoknál
- Timer-alapú async logika Delphi-ban → Java `@Scheduled` + aszinkron service
- DLL-ek közötti kommunikáció (shared tables, IBDatabase) → REST API hívások vagy shared service layer

### 7.4 Tesztelési javaslat

Az összes új/javított modulhoz kötelező:
1. **Unit test** — az algoritmus pontossága (különösen tranzakció díj, haszon, MNB aggregáció)
2. **Integration test** — workflow E2E (napzárás 10 lépése mind lefut)
3. **Golden file test** — Delphi output vs. Java output összehasonlítás valós tesztadatokon

### 7.5 Kritikus kockázatok

| Kockázat | Valószínűség | Hatás | Mitigáció |
|---|---|---|---|
| MNB riport pontatlanság | MAGAS | KRITIKUS | Azonnal audit + fix |
| Értéktár zárás adatvesztés | KÖZEPES | KRITIKUS | Workflow completeness ellenőrzés |
| Tranzakció díj eltérés | MAGAS | MAGAS | Szelvényszintű összehasonlítás |
| Haszonszámítás eltérés | KÖZEPES | MAGAS | Historikus adat összehasonlítás |
| MoneyGram hiánya | ALACSONY | KÖZEPES | Csak ha aktív MG integráció van |

---


---

## S9 MELLEKLET_OSSZESITO_STATISZTIKA

| Rendszer | Modulok | KÉSZ | RÉSZLEGES | HIÁNYZIK | NEM KELL |
|---|---|---|---|---|---|
| SZERVER/fejleszt | 86 | 22 | 47 | 2 | 15 |
| SZERVER/ujdll | 36 | 14 | 20 | 0 | 2 |
| ERTEKTAR/etdll | 54 | 25 | 26 | 0 | 3 |
| ERTEKTAR/fejleszt | 3 | 2 | 1 | 0 | 0 |
| VALUTA delta | 21 | 12 | 6 | 2 | 1 |
| **ÖSSZESEN** | **200** | **75 (37%)** | **100 (50%)** | **4 (2%)** | **21 (11%)** |

> **Valódi lefedettség**: KÉSZ + RÉSZLEGES×0.5 = 75 + 50 = **125/179 = ~62%**

### Összefoglaló egy mondatban

**A rendszer valódi Delphi-lefedettség ~62% (nem 98%), a hiányzó/részleges 38% elsősorban az MNB-riportozás, az értéktár zárási workflow, a tranzakciódíj-számítás és a haszonszámítás területén jelent production-kritikus kockázatot, amelyek javításához összesen ~202 óra kötelező + ~190 óra ajánlott fejlesztés szükséges.**

---
*Gap analízis: Tamás (TestOps Chief) | 2026-04-04 | Forrás: 645.186 Pascal sor teljes átvizsgálása*
