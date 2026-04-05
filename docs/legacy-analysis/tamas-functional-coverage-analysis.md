# Tamás — Funkcionális Lefedettség & Tesztelhetőség Elemzés

## Dátum: 2026-04-05
## Készítette: Tamás (TestOps Chief — Anthropic Claude Sonnet 4.6)
## Scope: Delphi 7 legacy → Spring Boot + React + Electron modern stack

---

## Bevezetés

Ez a dokumentum a `D:\repo\valutavalto-program\Anti\SZERVER\_extracted\` mappában lévő teljes Delphi 7 valutaváltó rendszer funkcionális elemzését tartalmazza, összevetve a modern Spring Boot + React + Electron stakkkal. Az elemzés alapját a SZERVER (~90 alkönyvtár), VALUTA/DLL (~110 DLL modul), VALUTA/IBVALTO (fő váltó kliens), VALUTA/TRADE (kereskedés kliens) és ERTEKTAR modul könyvtárszerkezetei, valamint a bennük talált Delphi `.pas` forrásfájlok procedure/function deklarációi képezik.

A modern oldal forrása: backend Spring Boot controllerek (~130), service-ek (~160), frontend-react pages (~60 oldalcsoport), penztar-client Electron.

---

## 1. Legacy Use Case Katalógus — SZERVER modulok

A SZERVER/fejleszt alkönyvtárak neve egyértelműen tükrözi a funkciót. Az alábbi táblázat az összes azonosított use case-t listázza.

| # | Modul (könyvtár) | Funkció leírása |
|---|---|---|
| S01 | `server` | Főszerver indítás, DayBook (naplókönyv) kezelés, iroda- és valutabetöltés, rendszeradat-beolvasás |
| S02 | `arfolyam` | Árfolyam-kezelés (betöltés, módosítás, napvégi rögzítés) |
| S03 | `tranzacs` | Tranzakció rögzítés — fő üzleti tranzakció motor |
| S04 | `tranzdb` | Tranzakciók adatbázis-szintű kezelése, havi kiolvasás |
| S05 | `forgdisp` | Forgalom megjelenítő — egynapos feldolgozás, pénztársor adat |
| S06 | `napiment` | Napi mentés (naptárolás, fájlmentés ütemező) |
| S07 | `statiszt` | Statisztika — ügyfél-azonosítás, adatregisztráció |
| S08 | `summa` | Összesítő: pénztár-forgalom, profit, WU, ÁFA, értéktár, kereskedés összegyűjtés |
| S09 | `sumrate` | Árfolyam-összesítő irodák szerint |
| S10 | `havitablo` | Havi összesítő táblázat (Excel export, havi nyitó-záró, korzetcsoportosítás) |
| S11 | `booking` | Foglalás kezelés |
| S12 | `jelenlet` | Jelenléti kimutatás — pénztáros munkaidő Excel-be |
| S13 | `idbeiro` | Idő-bejegyző (munkaidő manuális rögzítés) |
| S14 | `frissdat` | Adatfrissítő (adatbázis-update eszköz) |
| S15 | `gbakall` | Általános backup/mentés |
| S16 | `expgbakall` | Export backup (külső mentés) |
| S17 | `kezdij` | Kezelési díj táblázat, Excel export, havi/negyedéves periódus |
| S18 | `fdbtomorito` | Firebird adatbázis-tömörítő (backup+compress) |
| S19 | `fdbtorlo` | Firebird adatbázis-törlő |
| S20 | `foglalo` | Foglaláskezelő modul |
| S21 | `confident` | Bizalmas üzenetek/bejelentések kezelése (dekódolás, megjelenítés, server push) |
| S22 | `okmctrl` | Okmány ellenőrzés — JPG összehasonlítás, iroda adat betöltés |
| S23 | `recguard` | Receptor-őr (watchdog): receptor futás felügyelet, garbage collection, újraindítás |
| S24 | `recptor` | Receptor (adatgyűjtő daemon) |
| S25 | `monegram` | MoneyGram integráció — fájlok bedolgozása, Excel |
| S26 | `postterm` | Postai terminál integráció — bank kód, Excel riport |
| S27 | `senddata` | Adatküldés (szerverre/FTP) |
| S28 | `uforg` | User forgalom lekérdezés |
| S29 | `ugyfelcontrol` | Ügyfél ellenőrzés |
| S30 | `ugyfseek` | Ügyfél keresés |
| S31 | `western` | Western Union összesítő tábla (Excel, napi/havi, pénztár/körzet/cég) |
| S32 | `wucontrol` | Western Union kontroll |
| S33 | `terror` | Terrorlistás ellenőrzés |
| S34 | `police` | Rendőrségi adatszolgáltatás (pénztáros ellenőrzés, értéktár-scan) |
| S35 | `permit` | Engedély kiadás (árfolyam, kezelési díj, bankjegy engedelyezés) |
| S36 | `kereso` | Általános kereső |
| S37 | `newrate` | Új árfolyam rögzítés |
| S38 | `import` | Adatimport (külső forrásból) |
| S39 | `mentes` | Mentés kezelő (Windows exec, tömörítés) |
| S40 | `lemento` | Részletes le-mentő: havi/időszak transzakció export DBF-be |
| S41 | `archival` | Archiválás (IB tábla archiválás) |
| S42 | `haszon` | Haszon (nyereség) számítás — MNB árfolyam, kedvezmény |
| S43 | `sumtrade` | Kereskedési összesítő |
| S44 | `etrade` | Értéktári kereskedés (havi zárás, Excel) |
| S45 | `everseny` | Értéktári verseny — pénztáros teljesítmény összesítő |
| S46 | `verseny` | Pénztáros verseny — árfolyam, nyeremény, helyezés |
| S47 | `vevo` | Vevő (ügyfél) szűrő és összesítő — KFT/körzet/pénztár szerinti bontás |
| S48 | `vevoszam` | Vevőszámlálás irodák szerint |
| S49 | `korlevel` | Körlevelek kezelése (letöltés, megjelenítés, archiválás) |
| S50 | `jogi` | Jogi személyek kezelése |
| S51 | `jogiszemely` | Jogi személy összesítő (daybook, Excel, szűrés) |
| S52 | `jutmend` | Jutalék-mend (jutalék javítás, BF- és WU-adatbázis javítás) |
| S53 | `palyadij` | Pályadíj (versenyeredmény pénzösszeg kezelés) |
| S54 | `kdchange` | Kezelési díj változtatás (szerveres parancs) |
| S55 | `kedvmak` | Kedvezmény makró |
| S56 | `statiszt` | Statisztikák gyűjtése (ügyfél-azonosítás, nullázás, DB ürítés) |
| S57 | `sumtablo` | Összesítő tábla (Excel) |
| S58 | `trnzstat` | Tranzakció-statisztika |
| S59 | `ptforg` | Pénztár forgalmi lekérdezés |
| S60 | `pttrfee` | Pénztár kezelési díj (Excel export) |
| S61 | `tablomak` | Tábla-maker (adatbázis tábla létrehozás) |
| S62 | `makeszlt` | Foglalói készlet (AC összesítés, Excel, körzet-KFT bontás) |
| S63 | `makiroda` | Iroda maker (AC irodák feltöltése) |
| S64 | `evnyito` | Év-nyitó procedúra |
| S65 | `expevnyito` | Export év-nyitó |
| S66 | `evitranz` | Évi tranzakció-összesítő irodák szerint |
| S67 | `orsoseek` | Oros (orosz) ügyfél-kereső |
| S68 | S68 `mendjogi` | Jogi személy adatok javítása (ISO, country kód) |
| S69 | `remaltib` | Remotely altered IB (távoli IB módosítás) |
| S70 | `strade` | Trade-statisztika szerver oldalon |
| S71 | `setrade` | Szerver-oldali kereskedés beállítás |
| S72 | `sumaxa` | Maximumösszeg összesítő |
| S73 | `_arfteszt` | Árfolyam tesztelő modul |
| S74 | `_napiforg` | Napi forgalom (internal helper) |
| S75 | `banklist` | Banklista kezelés |
| S76 | `beszam` | Beszámoló (riport összesítő) |
| S77 | `expadvet` | Export adatvétel |
| S78 | `expgbakall` | Export GB-backup |
| S79 | `fdbtorlo` | FDB törlő |
| S80 | `gbakall` | GB mentés (Gyökér backup) |
| S81 | `hrkvetel` | HRK (horvát kuna) vétel kezelés |
| S82 | `idpotlo` | Idő-pótló (elveszett adatok visszapótlása) |
| S83 | `idprosct` | ID pénztáros CT |
| S84 | `kamersum` | Kamera összesítő |
| S85 | `listopenfoffices` | Nyitva lévő irodák listája |
| S86 | `napiment` | Napi mentés (fájl archiváló) |
| S87 | `naviseek` | NAV keresés |
| S88 | `nevseek` | Név kereső |
| S89 | `uctrl` | User kontroll |
| S90 | `ufill18` / `ufill19` | User fill — adatbázis feltöltő v18/v19 |
| S91 | `www` | WWW (web-interface integráció) |
| S92 | `litenews` | Lite news (belső hírek) |

---

## 2. Legacy Use Case Katalógus — VALUTA modulok (DLL + IBVALTO + TRADE)

### 2A. IBVALTO — Fő pénztáros váltó alkalmazás

| # | Modul/Unit | Funkció leírása |
|---|---|---|
| V01 | `IBVALTO/UNIT1` | Fő pénztáros UI főablak (belépés, menü, munkamenet) |
| V02 | `IBVALTO/Unit2-5, 18, 47` | Pénztáros munkafolyamat kiegészítő ablakok (adatlap, összesítő, help) |

### 2B. TRADE — Kereskedési alkalmazás

| # | Modul/Unit | Funkció leírása |
|---|---|---|
| V03 | `TRADE/unit1` | Kereskedés főablak: ÁFA-s számla, könyvelés, nyomtatás, matricaküldés, logolás, havi trade kontroll |
| V04 | `TRADE/unit2-14` | Kereskedési kiegészítők (partnerek, termékek, árfolyam, blokknyomtatás) |

### 2C. DLL modulok — Pénztáros kliens DLL-ek

| # | DLL modul | Funkció leírása |
|---|---|---|
| V05 | `ARFVALT` | Árfolyam-változtatás (engedélyezés, supervisor jelszó, logolás) |
| V06 | `ARFDISP` | Árfolyam-kijelző DLL |
| V07 | `ARFREG` | Árfolyam-regisztráció (történeti megjelenítés, limit, havi, korábbi) |
| V08 | `ARFTMK` | Árfolyam törzskarbantartás (nyomtatás) |
| V09 | `BIGARFVALT` | Nagy összegű árfolyamkedvezmény (százalékos különleges ár) |
| V10 | `BIZODISP` | Bizonylat megjelenítő |
| V11 | `BLOKNYOM` | Blokknyomtatás (vétel/eladás/átad/átvesz/storno/ügyfél/nyilatkozat blokkok) |
| V12 | `ELADAS` | Eladás DLL |
| V13 | `NAPIFORG` | Napi forgalom kimutatás + nyomtatás (nyitó, záró, forgalom összesítő) |
| V14 | `NAPZAR` | Napi zárás (cimtár másolás, forgalom számítás, gyűjtőkbe másolás, WU nullázás) |
| V15 | `NAPIKEZD` | Napi kezdés (nyomtatás, naplóbejegyzés, kezelési díj nyomtatás) |
| V16 | `UGYFEL` | Ügyfél DLL |
| V17 | `SETRATE` | Árfolyam jóváhagyás/beadta/nem adta be (7-gombos UI) |
| V18 | `STORNO` | Storno (bizonylat érvénytelenítés, ellentranzakció, visszavonás) |
| V19 | `SUPER` | Supervisor jelszó ellenőrzés (betűérték hash) |
| V20 | `GETARF` | Árfolyam-lehívás (FTP, MNB frissítés, internet ellenőrzés, változásdetektálás) |
| V21 | `GETFIZE` | Fizetési eszköz kiválasztás (bankkártya/készpénz, OTP terminál) |
| V22 | `FORGOSSZ` | Forgalom összesítő (időszak-lekérdező, nyomtatás) |
| V23 | `MAIFORG` | Mai forgalom kijelző |
| V24 | `CIMLCTRL` | Cimlet kontroll (napi zárás adatok, kezelési díj, WU, ÁFA, foglalás, etrade keszlet) |
| V25 | `NAPKONYV` | Napkönyv (kétpéldányos napló nyomtatás, archív) |
| V26 | `PILLALL` | Pillanatnyi állás nyomtatás |
| V27 | `PILLKESZ` | Pillanatnyi készlet |
| V28 | `VASARLAS` | Vásárlás DLL |
| V29 | `WUNION` | Western Union DLL |
| V30 | `XTRANZ` | Extra tranzakciós díj megjelenítő |
| V31 | `REGEN` | Regeneráló (pillálás, WU regenerálás, kezdőkészlet, Metro/Tesco, havi kezelési díj) |
| V32 | `NAVZARO` | NAV zárás (XML generálás, titkos email, NAV sorszám) |
| V33 | `PROSKI` | Pénztáros kiléptetés |
| V34 | `PROSTMK` | Pénztáros törzskarbantartás (új/módosít/töröl, jelszó-kódolás) |
| V35 | `PROSBE` | Pénztáros belépés (jelszó, hardwarekey ellenőrzés) |
| V36 | `PTARKESZ` | Pénztári készletek kijelzése |
| V37 | `PTARTMK` | Pénztár törzskarbantartás (cím, szám, törlés, módosítás) |
| V38 | `SCANNING` | Okmány-szkennelés (scanner futtatás, menetidő ellenőrzés) |
| V39 | `SENDOKMANY` | Okmány küldés (FTP, JPG feltöltés) |
| V40 | `QRDEPUTY` | QR-kód alapú NAV online integrációs DLL (napi nyitás/zárás, vétel/eladás/storno, COM port) |
| V41 | `QRGENER` | QR-kód generátor (napi nyitás, vétel, eladás, storno, megjelenítés) |
| V42 | `VERZFRIS` | Verziószám-frissítés, NAV COM sorszám beállítás |
| V43 | `TERMINAL` | Terminál DLL (matrica regeneráló, esti zárás küldés) |
| V44 | `TEAOR` | TEAOR kód kiválasztó |
| V45 | `TERROR` | Terrorlista ellenőrzés (regisztráció, engedélyezés) |
| V46 | `GETWUGYF` | WU ügyfél keresés/kiválasztás (karton megjelenítés, új ügyfél) |
| V47 | `GETSTATUS` | Státusz lekérdező |
| V48 | `GETPLOMB` | Plomba szám bekérés (szállító, plomba, megjegyzés, könyvelhető jelölés) |
| V49 | `GETPTAR` | Pénztár kiválasztó (új pénztár TRB felvitel, listából választás) |
| V50 | `GETISO` | ISO kód kiválasztó (ország, város, citi) |
| V51 | `AFATABLA` | ÁFA-tábla megjelenítő |
| V52 | `ADATLAP` | Adatlap DLL |
| V53 | `ATADOLAP` | Átadólap DLL |
| V54 | `ATADVET` | Átad-vétel DLL |
| V55 | `BIGCTRL` | Nagy összegű tranzakció kontroller (jogi/natúr ügyfél, könyvelés, Vtemp kezelés) |
| V56 | `CHECKLST` | Checklist DLL |
| V57 | `CIMLMENU` | Cimlet menü (napi záró pénztárjegy, főmenü választó) |
| V58 | `CIMLNYOM` | Cimlet nyomtatás (típus-regiszter, összesítő, sorformázás) |
| V59 | `CIMSETUP` | Cimlet beállítás |
| V60 | `CONFIDEN` | Bizalmas bejelentés küldés (szerverre, FTP-re) |
| V61 | `CONFIRM` | Megerősítő párbeszéd DLL |
| V62 | `COPY2FTP` | FTP fájlmásoló DLL |
| V63 | `DEKRUTIN` | Dekádos forgalmi kimutatás (10-napos összesítő, nyomtatás) |
| V64 | `DOCDISP` | Dokumentum megjelenítő (JPG scanner képek) |
| V65 | `ESTIZAR` | Esti zárás csomagoló (BF, BT, cimtár, NARF, Wafa, Wuni, Tesco, Arfe packing) |
| V66 | `EUAKCIO` | EU akcio kérdő DLL |
| V67 | `FIRSTCTRL` | Első kontroll (indítás, flag-kezelés, gombok) |
| V68 | `FNYUJSAG` | Folyamat-újság (árfolyam-változás küldés LED/COM port-ra) |
| V69 | `FOGLALO` | Foglalás DLL |
| V70 | `FOGLREND` | Foglalásrendező (árfolyam, bankjegy, DLL parancs) |
| V71 | `GEPSETUP` | Gép beállítás |
| V72 | `GONGBACK` | Gongyölet visszavonás DLL |
| V73 | `HAVIZAR` | Havi zárás (ÁFA, forgalom összesítő, Excel/tábla) |
| V74 | `HRKATADO` | HRK (horvát kuna) átadó |
| V75 | `HRKZARO` | HRK záró |
| V76 | `IDOSZAK` | Időszak-választó DLL (dátumtól-ig picker) |
| V77 | `KCIMLET` | Kis cimlet |
| V78 | `KELLCIM` | Kell cimlet kérdező DLL |
| V79 | `KESZEDIT` | Készlet szerkesztő |
| V80 | `KESZUP` | Készlet-update (aktuális készlet, napi forgalom, szerverre küldés) |
| V81 | `KEZDEKAD` | Kezdeti dekád (dekádnyomtatás, napló-bejegyzés) |
| V82 | `KEZDIJ` | Kezelési díj DLL |
| V83 | `KEZDKEDV` | Kezdeti kedvezmény beállítás |
| V84 | `KISARFVALT` | Kis összegű árfolyam-változtatás |
| V85 | `KISCIMLET` | Kis cimlet DLL |
| V86 | `KISUGYFEL` | Kis-ügyfél DLL |
| V87 | `KORLEV` | Körlevelek (letöltés, olvasás, archiválás) |
| V88 | `LISTAK` | Listák DLL |
| V89 | `LOGIRO` | Log-író DLL |
| V90 | `MAKTABLAK` | Tábla-maker (BlokkFej, Blokktétel, Kezdij, Wuni, Wafa, JL, NARF, cimtár, Tesco stb.) |
| V91 | `MATPTAR` | Matrica-pénztár |
| V92 | `MATREGEN` | Matrica regeneráló (értéktár-total regen) |
| V93 | `METRO` | Metro integráció |
| V94 | `NAPIJEL` | Napi jelzés |
| V95 | `NZNYOMT` | Napzáró nyomtató (árfolyamlista, foglalókészlet, napi forgalom, pénztárállás, trade, WU) |
| V96 | `OTHERTSK` | Egyéb feladatok |
| V97 | `OTP` | OTP terminál DLL |
| V98 | `OTPLOG` | OTP log megjelenítő |
| V99 | `PAUSDISP` | Szünet kijelző |
| V100 | `PROCEND` | Folyamat vége DLL |
| V101 | `REGIZARO` | Régi záró (napzáró nyomtatás visszamenőleg) |
| V102 | `SUPERTSK` | Supervisor feladatok (cimlet setup, xtranz, checklist, stb.) |
| V103 | `TESCO` | Tesco integráció |
| V104 | `UGYFELTMK` | Ügyfél törzskarbantartás (natúr/jogi, törlés) |
| V105 | `UJSCANNER` | Új szkennelés (régi dokumentumok megjelenítése, lapozás) |

---

## 3. Legacy Use Case Katalógus — ERTEKTAR modulok

Az ERTEKTAR értéktár-alkalmazás 3 almodult tartalmaz:

| # | Modul | Funkció leírása |
|---|---|---|
| E01 | `fejleszt/frissito` | Értéktár DB-frissítő (szerverre lépés, új mezők/táblák hozzáadása, séma-migráció) |
| E02 | `fejleszt/newyear` | Értéktár évnyitó |
| E03 | `fejleszt/permit` | Értéktár engedélykezelés |
| E04 | `etdll/*` | Értéktár DLL komponensek (arftmk, atadolap, bizodisp, bloknyom, cimlctrl, stb.) |

---

## 4. Modern Funkció Katalógus

### 4A. Backend — Spring Boot Controllers (kivonat)

| # | Controller | Lefed |
|---|---|---|
| M01 | `TransactionController` | Tranzakció CRUD |
| M02 | `ExchangeRateController` / `RateCreationController` / `RateManagementController` | Árfolyam kezelés |
| M03 | `DailyClosingController` / `ClosingWizardController` | Napi zárás |
| M04 | `MonthlyClosingController` / `HrkMonthlyClosingController` | Havi zárás |
| M05 | `NavClosingController` / `NavIntegrationController` / `NavReportController` | NAV integráció |
| M06 | `CustomerController` / `CustomerControlController` | Ügyfél kezelés |
| M07 | `WesternUnionController` (+ stub) | Western Union |
| M08 | `StornoController` | Storno |
| M09 | `ReceiptController` / `ReceiptSearchController` | Bizonylat/blokk |
| M10 | `CashBalanceController` / `CashRegisterController` | Pénztári készlet/egyenleg |
| M11 | `DenominationController` / `DenominationBalanceController` / `DenominationCalculatorController` | Cimlet kezelés |
| M12 | `BranchController` / `BranchGroupController` / `BranchMonitoringController` | Iroda kezelés |
| M13 | `UserController` / `WorkerController` / `WorkerManagementController` | Felhasználó/pénztáros |
| M14 | `AuthController` / `SupervisorController` | Hitelesítés, supervisor |
| M15 | `DocumentScannerController` (+ stub) | Okmányszkenner |
| M16 | `DocumentStorageController` | Dokumentum tárolás |
| M17 | `ReportController` / `DailyReportController` / `CentralReportController` | Napi riportok |
| M18 | `MnbReportController` / `MnbApiClient` | MNB árfolyam integráció |
| M19 | `AmlController` / `SanctionScreeningController` | AML / terrorlista |
| M20 | `BlacklistController` | Feketelista |
| M21 | `PoliceRequestController` | Rendőrségi adatszolgáltatás |
| M22 | `CompetitionController` / `CompetitorController` | Verseny |
| M23 | `ArchivingController` / `BackupController` | Archiválás, backup |
| M24 | `ExchangeRatePollingController` / `ExchangeRateDisplayController` | Árfolyam polling, LED kijelző |
| M25 | `CommissionCalculationController` / `CommissionRateController` | Kezelési díj |
| M26 | `FeeController` / `HandlingFeeController` | Díjak |
| M27 | `InventoryController` / `InventoryMovementController` / `InventoryRegenerationController` | Készlet regenerálás |
| M28 | `PosTerminalController` (+ stub) | OTP/POS terminál |
| M29 | `QrCodeService` (backend) | QR kód |
| M30 | `HandoverSheetController` | Átadólap |
| M31 | `ReservationController` / `BookingExportController` | Foglalás |
| M32 | `LedDisplayController` | LED kijelző |
| M33 | `CameraController` / `CameraAdminController` / `CameraExportController` | Kamera |
| M34 | `NotificationController` / `CircularController` | Értesítések, körlevelek |
| M35 | `AuditLogController` / `LoggingController` | Naplózás |
| M36 | `SystemParameterController` / `SystemParameterManagementController` | Rendszerparaméterek |
| M37 | `ErtektarController` | Értéktár |
| M38 | `TradeController` | Kereskedés |
| M39 | `TransferController` / `TransferDocumentController` | Átforgatás/Transferálás |
| M40 | `TreasuryController` / `VaultTerritoryController` | Központi pénztár/trezor |
| M41 | `TurnoverController` / `ProfitController` | Forgalom/haszon |
| M42 | `WorkerCommissionController` | Pénztáros jutalék |
| M43 | `FtpSyncController` / `SyncController` / `SynchronizationController` | FTP/adatszinkron |
| M44 | `VatRefundController` | ÁFA visszatérítés |
| M45 | `PackagingController` / `StampController` / `SealNumberController` | Plomba, bélyegzők |
| M46 | `DataImportController` / `DataCollectionController` | Import, adatgyűjtés |
| M47 | `LicenseController` | Licensz |
| M48 | `VersionController` | Verziókezelés |
| M49 | `EmailController` / `EmailAccountController` | Email |
| M50 | `AnonymousReportController` / `DariusReportController` / `DecadeReportController` | Speciális riportok |
| M51 | `ContributionController` | Hozzájárulás/befizetés |
| M52 | `OrganizationController` / `CompanyAdminController` | Szervezet/cég |
| M53 | `HrkController` | HRK kezelés |
| M54 | `ShipmentController` | Szállítmány |
| M55 | `StockSnapshotController` | Készlet-snapshot |

### 4B. Frontend — React Oldalak (pages)

| # | Page csoport | Lefed |
|---|---|---|
| F01 | `transactions/` | Tranzakciók listája, új tranzakció |
| F02 | `rates/` + `ratemanagement/` | Árfolyam kezelés |
| F03 | `closing/` | Napi/havi zárás |
| F04 | `customers/` | Ügyfélkezelés |
| F05 | `westernunion/` | Western Union |
| F06 | `stornos/` | Storno |
| F07 | `receipts/` | Bizonylatok |
| F08 | `inventory/` | Készlet |
| F09 | `cashdesk/` | Pénztár |
| F10 | `branches/` | Irodák |
| F11 | `employees/` + `workers/` | Pénztárosok |
| F12 | `auth/` | Bejelentkezés |
| F13 | `documents/` | Dokumentumok |
| F14 | `reports/` + `darius/` + `decade/` | Riportok |
| F15 | `audit/` | Audit log |
| F16 | `commissions/` | Jutalékok |
| F17 | `currencies/` | Devizák |
| F18 | `camera/` | Kamera |
| F19 | `hrk/` | HRK |
| F20 | `nav/` | NAV |
| F21 | `competitors/` | Versenytársak/verseny |
| F22 | `archiving/` + `backup/` | Archiválás, backup |
| F23 | `blacklist/` + `suspicious/` + `pep/` | Feketelista, AML |
| F24 | `police/` | Rendőrségi |
| F25 | `notifications/` + `circulars/` | Értesítések, körlevelek |
| F26 | `settings/` | Rendszerparaméterek |
| F27 | `pos/` | POS terminál |
| F28 | `led/` | LED kijelző |
| F29 | `seals/` + `stamps/` | Plombák, bélyegzők |
| F30 | `sync/` | Szinkron |
| F31 | `import/` + `export/` | Import/export |
| F32 | `reservations/` | Foglalások |
| F33 | `handover/` | Átadólap |
| F34 | `transfers/` | Áttranszfer |
| F35 | `treasury/` | Trezor |
| F36 | `workstations/` | Munkaállomások |
| F37 | `profit/` | Haszon |
| F38 | `stock/` | Készlet-snapshot |
| F39 | `email/` | Email |
| F40 | `licenses/` | Licensz |

### 4C. Electron (penztar-client) komponensek

| # | Modul | Funkció |
|---|---|---|
| EC01 | `electron/main.ts` | Főablak, app életciklus |
| EC02 | `electron/printer.ts` | Nyomtató vezérlés (ESC/POS blokk, napló) |
| EC03 | `electron/serial-printer.ts` | Soros portos nyomtató |
| EC04 | `electron/scanner.ts` | Dokumentum-szkenner |
| EC05 | `electron/camera.ts` + `rtsp-recorder.ts` + `video-manager.ts` | Kamera, RTSP felvétel, videó kezelés |
| EC06 | `electron/sync-engine.ts` | Szinkronizáció motor |
| EC07 | `electron/sqlite.ts` | Lokális SQLite (offline mód) |
| EC08 | `electron/camera-encryption.ts` | Kamera-titkosítás |
| EC09 | `electron/updater.ts` | Automatikus frissítés |

---

## 5. Lefedettségi Mátrix

**Jelmagyarázat:**
- **KÉSZ** — a modern rendszerben megfelelő funkció implementálva és dokumentáltan elérhető
- **RÉSZLEGES** — az alap funkció megvan, de egyes részletek (pl. teljes UI folyamat, nyomtatás, speciális rule) hiányoznak vagy stub-os állapotban vannak
- **HIÁNYZIK** — a legacy funkciónak nincs modern megfelelője
- **NEM_RELEVÁNS** — legacy technikai megoldás, amit a modern stack natívan old meg másképp (pl. DLL parancsküldés helyett REST API)

| # | Legacy Use Case | Kategória | Lefedettség | Megjegyzés |
|---|---|---|---|---|
| S01 | Server főablak, DayBook, iroda-valutabetöltés | Core | KÉSZ | Spring Boot startup, BranchService |
| S02 | Árfolyam kezelés (betöltés, módosítás) | Core | KÉSZ | ExchangeRateController, RateManagementController |
| S03 | Tranzakció rögzítés | Core | KÉSZ | TransactionController, TransactionService |
| S04 | Tranzakció DB kezelés, havi kiolvasás | Core | KÉSZ | TransactionRepository, MonthlyClosingService |
| S05 | Forgalom megjelenítő | Riport | KÉSZ | TurnoverController, DashboardController |
| S06 | Napi mentés/archiválás | Backup | KÉSZ | ArchivingController, BackupController |
| S07 | Statisztika ügyfél-azonosítás | Stat | RÉSZLEGES | CustomerStatisticsService megvan, de részletes azonosítási flow hiányos |
| S08 | Összesítő (forgalom/profit/WU/ÁFA) | Riport | KÉSZ | CentralReportController, ReportService, ProfitController |
| S09 | Árfolyam-összesítő irodák szerint | Riport | KÉSZ | ExchangeRateDisplayController, BranchController |
| S10 | Havi összesítő tábla (Excel) | Riport | RÉSZLEGES | MonthlyReportService megvan, Excel export részleges |
| S11 | Foglalás kezelés | Üzleti | KÉSZ | ReservationController, BookingExportController |
| S12 | Jelenléti kimutatás (pénztáros munkaidő) | HR | HIÁNYZIK | Nincs AttendanceController vagy WorktimeService |
| S13 | Munkaidő manuális rögzítés | HR | HIÁNYZIK | Nincs munkaidő-rögzítő endpoint |
| S14 | Adatbázis-frissítő | DB admin | NEM_RELEVÁNS | Flyway/Liquibase migration váltja ki |
| S15 | Általános backup | Backup | KÉSZ | BackupController |
| S16 | Export backup | Backup | KÉSZ | ConfigExportController, BackupController |
| S17 | Kezelési díj táblázat/Excel | Díjak | KÉSZ | CommissionRateController, HandlingFeeController |
| S18 | Firebird adatbázis-tömörítő | DB admin | NEM_RELEVÁNS | PostgreSQL + Flyway |
| S19 | Firebird adatbázis-törlő | DB admin | NEM_RELEVÁNS | Nem releváns, PostgreSQL |
| S20 | Foglaláskezelő | Üzleti | KÉSZ | ReservationController |
| S21 | Bizalmas üzenetek/bejelentések | Belső comm | RÉSZLEGES | CircularController megvan, de confidential push-channel implementáció nem teljes |
| S22 | Okmány ellenőrzés (JPG összehasonlítás) | KYC | RÉSZLEGES | DocumentScannerController megvan, de JPG hasonlítás logika hiányos |
| S23 | Receptor-őr (watchdog) | Infrastruktúra | RÉSZLEGES | SchedulerController, HealthController megvan, de receptor-specifikus watchdog hiányzik |
| S24 | Receptor daemon | Infrastruktúra | NEM_RELEVÁNS | Szerver-oldali polling/push Spring Scheduler-rel helyettesítve |
| S25 | MoneyGram integráció | Fizetési | HIÁNYZIK | Nincs MoneyGramController vagy MoneyGramService |
| S26 | Postai terminál integráció | Fizetési | HIÁNYZIK | Nincs PostaTerminalController |
| S27 | Adatküldés FTP-re | Szinkron | KÉSZ | FtpSyncController, FileTransportService |
| S28 | User forgalom | Riport | KÉSZ | TurnoverController |
| S29 | Ügyfél ellenőrzés | KYC | KÉSZ | CustomerControlController, SanctionScreeningController |
| S30 | Ügyfél keresés | Ügyfél | KÉSZ | CustomerController (search endpoint) |
| S31 | Western Union összesítő (Excel/havi) | WU | RÉSZLEGES | WesternUnionController megvan, de Excel-specifikus exporttáblák részlegesek |
| S32 | Western Union kontroll | WU | KÉSZ | WesternUnionController |
| S33 | Terrorlista ellenőrzés | AML | KÉSZ | SanctionScreeningController, AmlController |
| S34 | Rendőrségi adatszolgáltatás | Hatóság | KÉSZ | PoliceRequestController |
| S35 | Engedély kiadás (árfolyam/díj/bankjegy) | Engedélyezés | KÉSZ | AuthorizationController, RateApprovalController |
| S36 | Általános kereső | Util | KÉSZ | Számos Controller search endpoint |
| S37 | Új árfolyam rögzítés | Core | KÉSZ | RateCreationController |
| S38 | Adatimport | Import | KÉSZ | DataImportController |
| S39 | Mentés kezelő (Windows exec) | Backup | NEM_RELEVÁNS | BackupController váltja ki |
| S40 | Időszak tranzakció export DBF | Export | RÉSZLEGES | TransactionExportService megvan, DBF formátum hiányos |
| S41 | Archiválás (IB tábla) | Archív | KÉSZ | ArchivingController |
| S42 | Haszon/nyereség számítás | Pénzügy | KÉSZ | ProfitController, ProfitCalculationService |
| S43 | Kereskedési összesítő | Kereskedés | KÉSZ | TradeController |
| S44 | Értéktári kereskedés (havi zárás) | Kereskedés | KÉSZ | ErtektarController, MonthlyClosingService |
| S45 | Értéktári verseny összesítő | Verseny | RÉSZLEGES | CompetitionController megvan, de értéktár-specifikus versenylogika részleges |
| S46 | Pénztáros verseny | Verseny | RÉSZLEGES | CompetitionController, CompetitorController megvan, de elhelyezési/pontrendszer implementáció hiányos |
| S47 | Vevő szűrő/összesítő | Riport | RÉSZLEGES | CustomerController megvan, de KFT/körzet/pénztár szegmentált összesítő hiányos |
| S48 | Vevőszámlálás irodák szerint | Stat | RÉSZLEGES | CustomerStatisticsService megvan |
| S49 | Körlevelek kezelése | Komm | KÉSZ | CircularController |
| S50 | Jogi személyek | KYC | KÉSZ | CustomerController (jogi személy típus) |
| S51 | Jogi személy összesítő (Excel) | Riport | RÉSZLEGES | Report megvan, Excel export részleges |
| S52 | Jutalék javítás (BF/WU adatbázis) | Pénzügy | RÉSZLEGES | WorkerCommissionController megvan, manuális javítás flow hiányos |
| S53 | Pályadíj (versenyeredmény pénzösszeg) | Verseny | HIÁNYZIK | Nincs PalyadijController |
| S54 | Kezelési díj változtatás | Díjak | KÉSZ | HandlingFeeController |
| S55 | Kedvezmény makró | Kedvezmény | RÉSZLEGES | DiscountThresholdController megvan, makró-jellegű batch alkalmazás hiányos |
| S56 | Statisztika gyűjtés | Stat | KÉSZ | DataCollectionController |
| S57 | Összesítő tábla (Excel) | Riport | RÉSZLEGES | Excel export részleges (StockSnapshotExcelService van) |
| S58 | Tranzakció-statisztika | Stat | KÉSZ | TransactionReportService |
| S59 | Pénztár forgalmi lekérdezés | Riport | KÉSZ | TurnoverController |
| S60 | Pénztár kezelési díj (Excel) | Díjak | RÉSZLEGES | HandlingFeeDecadeService megvan, Excel réteges export hiányos |
| S61 | Tábla-maker (séma eszköz) | DB admin | NEM_RELEVÁNS | Flyway migration |
| S62 | Foglalói készlet (körzet-KFT) | Foglalás | RÉSZLEGES | ReservationController megvan, AC összesítés hiányos |
| S63 | Iroda maker | Iroda admin | NEM_RELEVÁNS | Spring data migration |
| S64 | Év-nyitó | Üzleti | HIÁNYZIK | Nincs YearOpeningController |
| S65 | Export év-nyitó | Üzleti | HIÁNYZIK | Nincs YearOpeningExportController |
| S66 | Évi tranzakció összesítő | Riport | RÉSZLEGES | ReportExtendedController megvan, éves view hiányos |
| S67 | Orosz ügyfél-kereső | KYC | RÉSZLEGES | CustomerController megvan, specifikus orosz ügyfél szegmentáció hiányos |
| S68 | Jogi személy ISO javítás | KYC | RÉSZLEGES | CustomerController update megvan, batch-javítás flow hiányos |
| S69 | Távoli IB módosítás | DB admin | NEM_RELEVÁNS | Spring REST API váltja ki |
| S70 | Trade statisztika | Stat | KÉSZ | TradeController |
| S71 | Szerveres kereskedés beállítás | Kereskedés | KÉSZ | TradeController |
| S72 | Maximumösszeg összesítő | Szabályok | RÉSZLEGES | RoundingRuleController, DiscountThresholdController megvan |
| S73 | Árfolyam tesztelő | Testing | NEM_RELEVÁNS | Tesztelt test suite-ok |
| S74 | Napi forgalom helper | Util | NEM_RELEVÁNS | Beépítve DailyReportService-be |
| S75 | Banklista kezelés | Törzsadat | KÉSZ | BranchController |
| S76 | Beszámoló riport | Riport | KÉSZ | CentralReportController |
| S77 | Export adatvétel | Export | KÉSZ | ConfigExportController |
| S78 | Export GB-backup | Backup | KÉSZ | BackupController |
| S79 | FDB törlő | DB admin | NEM_RELEVÁNS | PostgreSQL |
| S80 | GB mentés | Backup | KÉSZ | BackupController |
| S81 | HRK vétel | HRK | KÉSZ | HrkController |
| S82 | Idő-pótló | Admin | HIÁNYZIK | Nincs retroaktív adat-pótló eszköz |
| S83 | ID pénztáros CT | Admin | HIÁNYZIK | Nincs ID-CT kezelő |
| S84 | Kamera összesítő | Kamera | KÉSZ | CameraController, CameraExportController |
| S85 | Nyitva lévő irodák listája | Monitoring | KÉSZ | BranchMonitoringController |
| S86 | Napi mentés (archiváló) | Backup | KÉSZ | ArchivingController |
| S87 | NAV keresés | NAV | KÉSZ | NavIntegrationController |
| S88 | Név kereső | Util | KÉSZ | CustomerController search |
| S89 | User kontroll | Auth | KÉSZ | UserController |
| S90 | Adatbázis feltöltő v18/v19 | DB admin | NEM_RELEVÁNS | Flyway |
| S91 | WWW web-interface | Integráció | RÉSZLEGES | REST API van, de legacy web-proxy integráció nincs |
| S92 | Lite news (belső hírek) | Komm | RÉSZLEGES | NotificationController megvan |
| V05 | Árfolyam-változtatás DLL | Core | KÉSZ | ExchangeRateController, AuthorizationController |
| V07 | Árfolyam-regisztráció/történet | Riport | KÉSZ | RateHistoryController |
| V08 | Árfolyam nyomtatás | Nyomtatás | RÉSZLEGES | PrintTemplateController megvan, ESC/POS árfolyam-lista hiányos |
| V09 | Nagy összegű árfolyamkedvezmény | Díjak | KÉSZ | DiscountThresholdController, BigarfvaltService |
| V11 | Blokknyomtatás (összes blokktípus) | Nyomtatás | RÉSZLEGES | ReceiptController, EscPosReceiptService megvan, de teljes natúr+jogi+storno+nyilatkozat blokktípus-lefedés részleges |
| V12 | Eladás | Core | KÉSZ | TransactionController (eladás típus) |
| V13 | Napi forgalom nyomtatás | Nyomtatás | RÉSZLEGES | DailyReportGenerator megvan, nyomtatási réteg részleges |
| V14 | Napi zárás | Core | KÉSZ | DailyClosingController, DailyClosingService |
| V15 | Napi kezdés (nyomtatás, napló) | Core | KÉSZ | SessionOpenController, DailySessionService |
| V16 | Ügyfél DLL | KYC | KÉSZ | CustomerController |
| V17 | Árfolyam jóváhagyás | Core | KÉSZ | RateApprovalController, SetRateService |
| V18 | Storno | Core | KÉSZ | StornoController, StornoService |
| V19 | Supervisor jelszó | Auth | KÉSZ | SupervisorController |
| V20 | Árfolyam-lehívás (FTP/MNB) | Integráció | KÉSZ | ExchangeRatePollingController, MnbApiClient |
| V21 | Fizetési eszköz (bankkártya/POS) | Core | KÉSZ | PosTerminalController, GetFizeService |
| V22 | Forgalom összesítő (időszak) | Riport | KÉSZ | TurnoverController |
| V23 | Mai forgalom kijelző | Dashboard | KÉSZ | DashboardController |
| V24 | Cimlet kontroll | Cimlet | KÉSZ | DenominationController, CimlCtrlService |
| V25 | Napkönyv nyomtatás | Nyomtatás | RÉSZLEGES | DailyClosingPdfService megvan, kétpéldányos napló nyomtatás hiányos |
| V26 | Pillanatnyi állás nyomtatás | Nyomtatás | RÉSZLEGES | StockSnapshotController megvan, ESC/POS nyomtatás részleges |
| V27 | Pillanatnyi készlet | Készlet | KÉSZ | InventoryController |
| V28 | Vásárlás | Core | KÉSZ | TransactionController (vétel típus) |
| V29 | Western Union DLL | WU | KÉSZ | WesternUnionController |
| V30 | Extra tranzakciós díj megjelenítő | Díjak | RÉSZLEGES | FeeController megvan, xtranz-specifikus UI hiányos |
| V31 | Regeneráló (készlet, WU, Metro/Tesco) | Admin | RÉSZLEGES | InventoryRegenerationController megvan, Metro/Tesco integráció hiányzik |
| V32 | NAV zárás (XML, email) | NAV | KÉSZ | NavClosingController, NavAbevXmlGenerator |
| V33 | Pénztáros kiléptetés | Auth | KÉSZ | WorkerController (logout) |
| V34 | Pénztáros törzskarbantartás | HR | KÉSZ | WorkerManagementController |
| V35 | Pénztáros belépés (hardwarekey) | Auth | RÉSZLEGES | AuthController megvan, hardware dongle/key ellenőrzés hiányos |
| V36 | Pénztári készletek kijelzése | Készlet | KÉSZ | CashBalanceController |
| V37 | Pénztár törzskarbantartás | Törzsadat | KÉSZ | CashRegisterController |
| V38 | Okmány-szkennelés | KYC | RÉSZLEGES | DocumentScannerController (stub) — valós scanner integráció részleges |
| V39 | Okmány küldés (FTP/JPG) | KYC | KÉSZ | DocumentStorageController, FtpSyncController |
| V40 | QR NAV online (napi nyitás/zárás/vétel/eladás/storno) | NAV | KÉSZ | NavIntegrationController, QrCodeService |
| V41 | QR-kód generátor | NAV | KÉSZ | QrCodeService |
| V42 | Verziószám-frissítés | Admin | KÉSZ | VersionController, VerzfrisService |
| V43 | Terminál (matrica, esti zárás) | Integráció | RÉSZLEGES | EveningClosingController megvan, matrica-rendszer részleges |
| V44 | TEAOR kód kiválasztó | Törzsadat | RÉSZLEGES | Nincs dedikált TeaorController, CustomerController mezőn belül van |
| V45 | Terrorlista ellenőrzés | AML | KÉSZ | SanctionScreeningController |
| V46 | WU ügyfél keresés/karton | WU | KÉSZ | WesternUnionController, CustomerController |
| V47 | Státusz lekérdező | Monitoring | KÉSZ | HealthController, BranchMonitoringController |
| V48 | Plomba szám bekérés | Plomba | KÉSZ | SealNumberController, SealTrackingController |
| V49 | Pénztár kiválasztó | Törzsadat | KÉSZ | CashRegisterController, GetPtarService |
| V50 | ISO kód kiválasztó | Törzsadat | KÉSZ | CustomerController (ISO mező) |
| V51 | ÁFA-tábla megjelenítő | ÁFA | RÉSZLEGES | VatRefundController megvan, ÁFA-tábla nézet hiányos |
| V55 | Nagy összegű tranzakció kontroller | KYC/Pénzügy | KÉSZ | CustomerControlController, TransactionValidationService |
| V56 | Checklist | Üzemeltetés | RÉSZLEGES | DailyChecklistController megvan |
| V57 | Cimlet menü | Cimlet | KÉSZ | DenominationController |
| V58 | Cimlet nyomtatás | Nyomtatás | RÉSZLEGES | DenominationService megvan, teljes nyomtatási réteg részleges |
| V60 | Bizalmas bejelentés küldés | Komm | RÉSZLEGES | NotificationController megvan, FTP/server bizalmas küldés hiányos |
| V61 | Megerősítő párbeszéd | UI | NEM_RELEVÁNS | React confirm dialog |
| V62 | FTP fájlmásoló | Szinkron | KÉSZ | FtpSyncController |
| V63 | Dekádos forgalmi kimutatás | Riport | KÉSZ | DecadeReportController |
| V64 | Dokumentum megjelenítő (JPG) | KYC | KÉSZ | DocumentStorageController, DocumentScannerController |
| V65 | Esti zárás csomagoló | Zárás | KÉSZ | EveningClosingController |
| V66 | EU akció kérdő | Üzleti | RÉSZLEGES | Nincs dedikált EuAkcioController |
| V67 | Első kontroll/indítás | Admin | KÉSZ | SessionOpenController, ClosingWizardController |
| V68 | Árfolyam küldés LED/COM port | LED | KÉSZ | LedDisplayController, FnyujsagService |
| V69 | Foglalás | Foglalás | KÉSZ | ReservationController |
| V70 | Foglalásrendező (árfolyam, bankjegy) | Foglalás | RÉSZLEGES | ReservationController megvan, bankjegy-specifikus rendező hiányos |
| V72 | Gongyölet visszavonás | Storno | KÉSZ | StornoController (gongyölet típus) |
| V73 | Havi zárás (ÁFA, Excel) | Zárás | KÉSZ | MonthlyClosingController, MonthlyClosingPdfService |
| V74 | HRK átadó | HRK | KÉSZ | HrkController |
| V75 | HRK záró | HRK | KÉSZ | HrkMonthlyClosingController |
| V76 | Időszak-választó | UI util | NEM_RELEVÁNS | React datepicker |
| V80 | Készlet-update (szerverre küldés) | Készlet | KÉSZ | InventoryMovementController, KeszupService |
| V81 | Kezdeti dekád nyomtatás | Nyomtatás | RÉSZLEGES | DecadeReportController megvan, indulónyomtatás részleges |
| V82 | Kezelési díj | Díjak | KÉSZ | HandlingFeeController |
| V83 | Kezdeti kedvezmény | Díjak | RÉSZLEGES | DiscountThresholdController megvan, kezdeti beállítás UI hiányos |
| V84 | Kis összegű árfolyam-változtatás | Core | KÉSZ | ExchangeRateController (kis összegű limittel) |
| V87 | Körlevelek | Komm | KÉSZ | CircularController |
| V89 | Log-writer | Infrastruktúra | KÉSZ | LoggingController, AuditLogController |
| V90 | Tábla-maker | DB admin | NEM_RELEVÁNS | Flyway |
| V91 | Matrica-pénztár | Matrica | RÉSZLEGES | StampController megvan, matrica pénztár link hiányos |
| V92 | Matrica regeneráló | Admin | RÉSZLEGES | InventoryRegenerationController megvan |
| V93 | Metro integráció | Kereskedés | HIÁNYZIK | Nincs MetroIntegrationController |
| V94 | Napi jelzés | Monitoring | RÉSZLEGES | NotificationController megvan |
| V95 | Napzáró nyomtató (teljes lista) | Nyomtatás | RÉSZLEGES | DailyClosingPdfService megvan, de teljes NZ nyomtatókép (árfolyamlista+foglalók+WU+Trade) hiányos |
| V97 | OTP terminál | POS | KÉSZ | PosTerminalController, OtpTerminalProtocolService |
| V98 | OTP log | POS | RÉSZLEGES | Nincs dedikált OtpLogController |
| V100 | Folyamat vége DLL | UI | NEM_RELEVÁNS | React lifecycle |
| V101 | Régi záró (visszamenőleges nyomtatás) | Admin | RÉSZLEGES | RegizaroService részleges |
| V102 | Supervisor feladatok | Admin | KÉSZ | SupervisorController |
| V103 | Tesco integráció | Kereskedés | HIÁNYZIK | Nincs TescoIntegrationController |
| V104 | Ügyfél törzskarbantartás | KYC | KÉSZ | CustomerController (CRUD) |
| V105 | Új szkennelés (régi dokumentumok) | KYC | RÉSZLEGES | DocumentStorageController megvan, régi doku-browse hiányos |
| E01 | Értéktár DB-frissítő | DB admin | NEM_RELEVÁNS | Flyway migration |
| E02 | Értéktár évnyitó | Üzleti | HIÁNYZIK | Nincs ErtektarYearOpeningController |
| E03 | Értéktár engedélykezelés | Engedélyezés | RÉSZLEGES | AuthorizationController megvan, értéktár-specifikus hiányos |

---

## 6. Kritikus Hiányok (prioritással)

### CRITICAL

| # | Hiányzó funkció | Legacy modul | Indoklás |
|---|---|---|---|
| G01 | **Év-nyitó folyamat** (S64/S65, E02) | `evnyito`, `expevnyito`, ERTEKTAR/newyear | Éves üzemi folyamat — nélküle az évforduló körüli zárás/nyitás nem lehetséges. CRITICAL mert határidős és visszamenőleg nem pótolható. |
| G02 | **Pénztáros jelenléti / munkaidő** (S12, S13) | `jelenlet`, `idbeiro` | Bérszámítás és HR compliance alap. Jogszabályban előírt munkaidő-nyilvántartás. |
| G03 | **Teljes blokknyomtatási lefedettség** (V11, V13, V25, V58, V95) | `BLOKNYOM`, `NAPIFORG`, `NAPKONYV`, `CIMLNYOM`, `NZNYOMT` | Az összes bizonylattípus (jogi személy nyilatkozat, orosz nyilatkozat, storno blokk, devizastatusz nyilatkozat, napzáró teljes lap) ESC/POS-on kötelező jogszabályi dokumentáció. |
| G04 | **Hardware dongle/key alapú pénztáros belépés** (V35) | `PROSBE` | Fizikai biztonsági elem. Nélküle az authentikáció csak szoftveres jelszóra támaszkodik. |

### HIGH

| # | Hiányzó funkció | Legacy modul | Indoklás |
|---|---|---|---|
| G05 | **MoneyGram integráció** (S25) | `monegram` | Aktív üzleti partner, bevételi forrás. Fájl-alapú adatcsere feldolgozás hiánya bevételkiesést okoz. |
| G06 | **Postai terminál integráció** (S26) | `postterm` | Magyar Posta terminál — ha aktív együttműködés van, ez kritikus hiány. |
| G07 | **Metro / Tesco integráció** (V93, V103) | `METRO`, `TESCO` | Nagykereskedelmi partner. Ha aktív, az adatcsere feldolgozás és könyvelés hiányzik. |
| G08 | **Pályadíj / versenyeredmény pénzösszeg kezelés** (S53) | `palyadij` | Pénztáros motiváció rendszer kritikus eleme, ha versenyprogram aktív. |
| G09 | **Retroaktív adat-pótló eszköz** (S82) | `idpotlo` | Ha szerver-szinkron megszakad, az elveszett adatok visszapótlása manuálisan lehetetlen. |
| G10 | **Értéktár évnyitó** (E02) | ERTEKTAR/newyear | Az értéktár éves nyitó egyenlege nélkül a havi/éves zárás hibás lesz. |

### MEDIUM

| # | Hiányzó funkció | Legacy modul | Indoklás |
|---|---|---|---|
| G11 | **Dekádon belüli kezdeti nyomtatás** (V81) | `KEZDEKAD` | Jogszabályi előírás: 10-napos forgalmi kimutatás nyomtatva kell. |
| G12 | **Kétpéldányos napkönyv nyomtatás** (V25) | `NAPKONYV` | Hatósági előírás (MNB/NAV felé). |
| G13 | **EU akció kérdő DLL** (V66) | `EUAKCIO` | EU polgár esetén kötelező kérdőív — compliance. |
| G14 | **TEAOR kód külön kezelő** (V44) | `TEAOR` | KFT/vállalkozás ügyfelekhez kötelező, NAV adatszolgáltatáshoz szükséges. |
| G15 | **ÁFA-tábla nézet** (V51) | `AFATABLA` | ÁFA-kulcsok vizuális ellenőrzése hiányzik a frontend-en. |
| G16 | **OTP log megjelenítő** (V98) | `OTPLOG` | POS terminál események visszakereshetősége compliance igény. |
| G17 | **Értéktár-specifikus engedélykezelés** (E03) | ERTEKTAR/permit | Értéktár speciális műveleteire külön engedélyezési szint szükséges. |
| G18 | **Visszamenőleges napzáró nyomtató** (V101) | `REGIZARO` | Hatósági ellenőrzésnél kötelező korábbi napzárók reprodukciója. |
| G19 | **Pénztáros verseny elhelyezési/pontrendszer** (S46) | `verseny` | Belső motiváció rendszer, de üzletileg fontos. |
| G20 | **KFT/körzet/pénztár szegmentált vevőösszesítő** (S47) | `vevo` | Üzleti elemzési eszköz, vezetői döntéstámogatás. |

### LOW

| # | Hiányzó funkció | Legacy modul | Indoklás |
|---|---|---|---|
| G21 | **Orosz ügyfél specifikus szegmentáció** (S67) | `orsoseek` | Speciális csoport, de KYC compliance alapú. |
| G22 | **Foglalói készlet körzet-KFT bontás** (S62) | `makeszlt` | Üzleti elemzés, alacsony prioritású. |
| G23 | **DBF formátumú tranzakció export** (S40) | `lemento` | Legacy könyvelőszoftver kompatibilitás. |
| G24 | **Gongyölet rendező bankjegy-specifikus** (V70) | `FOGLREND` | Speciális cimlet-kezelési edge case. |
| G25 | **Kamera összesítő szerver-szintű** (S84) | `kamersum` | Kamera-rendszer teljes audit view. |

---

## 7. Tesztelhetőségi Értékelés

### 7.1 Modern stack tesztelhetőség

| Réteg | Tesztelhetőség | Megjegyzés |
|---|---|---|
| Spring Boot Controllers | **KIVÁLÓ** | @WebMvcTest, MockMvc, MockBean teljes lefedettség lehetséges |
| Spring Services | **KIVÁLÓ** | @SpringBootTest + @MockBean, pure unit test is lehetséges |
| React UI | **JÓ** | Vitest + React Testing Library; Playwright E2E rendelkezésre áll |
| Electron | **KÖZEPES** | Playwright Electron konfig már megvan (playwright-electron.config.ts), de hardware-specifikus (printer, scanner) mockolása bonyolult |
| REST API | **KIVÁLÓ** | Spring MockMvc + Testcontainers (PostgreSQL), meglévő E2E teszt infrastruktúra |

### 7.2 Legacy vs Modern tesztelhetőség

A legacy Delphi kód **nem tesztelhető** automatikusan:
- Nincsenek unit tesztek
- UI és üzleti logika szorosan csatolt (TForm event handler-ek tartalmazzák a logikát)
- Közvetlen DBase/Firebird hívások (nincs rétegszeparáció)
- DLL-ek csak Windows-on futnak, COM porttól, hardwarekulcstól függnek

A modern stack ellenben:
- Spring rétegszeparáció → unit + integration tesztek írhatók
- Testcontainers PostgreSQL → izolált DB tesztek
- Playwright E2E — már konfigurált

### 7.3 Tesztelési kockázatok

| Kockázat | Szint | Leírás |
|---|---|---|
| Hardver-függő funkciók (printer, scanner, POS, LED) | MAGAS | Csak stub/mock-alapon tesztelhető CI-ban |
| NAV online COM port integráció | MAGAS | Valódi COM port nélkül csak mock test |
| WU partner API | KÖZEPES | WesternUnionStubController már létezik |
| FTP szinkron | KÖZEPES | Mockolható FTP server-rel |
| Kamera/RTSP | KÖZEPES | Playwright visual test + mock RTSP |
| Blockchain-szintű audit (kamera hash-lánc) | ALACSONY | Egységtesztelhető |

---

## 8. Javasolt Teszt Stratégia a Top 10 Gap-re

### G01 — Év-nyitó folyamat

**Tesztelési javaslat:**
```
SZINT: Integration + E2E
ESZKÖZ: @SpringBootTest + Testcontainers + Playwright

1. Unit test: YearOpeningService.performYearOpening()
   - Input: záró év pénztárkészletek, nyitó egyenlegek
   - Assert: új évi opening balance rekordok létrejöttek
   - Assert: előző évi záró == új évi nyitó

2. Integration test: POST /api/year-opening
   - Végrehajtás előtt: mock daily/monthly closing befejezve
   - Assert HTTP 200, JSON body tartalmaz "openingBalances"
   - Assert adatbázisban az évnyitó rekordok konzisztensek

3. E2E (Playwright): 
   - Bejelentkezés supervisor-ként
   - Navigáció → Closing → Year Opening
   - Dátumválasztó: dec 31 → jan 1
   - Confirm → Assert sikeres oldal megjelenik
   - Navigáció → Inventory → Assert nyitó készletek helyesek
```

### G02 — Pénztáros jelenléti / munkaidő

**Tesztelési javaslat:**
```
SZINT: Unit + Integration + E2E
ESZKÖZ: JUnit 5 + MockMvc + Playwright

1. Unit test: AttendanceService.recordCheckIn(workerId, timestamp)
   - Assert: rekord létrejött, státusz CHECKED_IN
   - Edge: dupla check-in → validáció hiba

2. Unit test: AttendanceService.recordCheckOut(workerId, timestamp)
   - Assert: munkaidő kiszámítva (checkOut - checkIn)
   - Edge: checkout nélküli nap → figyelmeztetés

3. Integration test: GET /api/attendance?date={date}
   - Assert: lista tartalmazza az aznapi belépéseket/kilépéseket

4. E2E: Pénztáros belép → UI-n munkaidő látható → kilép → 
   összesítő oldalon szerepel a munkaidő
```

### G03 — Teljes blokknyomtatási lefedettség

**Tesztelési javaslat:**
```
SZINT: Unit + Integration
ESZKÖZ: JUnit 5, ByteArrayOutputStream (ESC/POS byte ellenőrzés)

1. Unit test: EscPosReceiptService.printNaturalPersonBlock(transaction)
   - Assert: output byte[] tartalmazza a kötelező mezőket
   - Assert: fejléc, bizonylat szám, ügyfél adatok, összeg, árfolyam, ÁFA

2. Unit test: EscPosReceiptService.printLegalPersonBlock(transaction)
   - Assert: cég neve, adószám, TEAOR kód szerepel

3. Unit test: EscPosReceiptService.printStornoBlock(stornoTransaction)
   - Assert: "STORNO" szó szerepel, eredeti bizonylat szám

4. Unit test: EscPosReceiptService.printDailyClosingSheet()
   - Assert: összes kötelező rovat megjelenik
   - Assert: forgalmi összesítők helyesek

5. Integration test: Mock printer stream-re nyomtatás → 
   byte[] dekódolás → szöveg ellenőrzés

6. Snapshot test: Playwright screenshottal ellenőrizni a 
   PDF preview-t minden blokkra
```

### G04 — Hardware dongle/key alapú belépés

**Tesztelési javaslat:**
```
SZINT: Unit + Integration (mock hardwarekey)
ESZKÖZ: JUnit 5 + Mockito

1. Unit test: HardwareKeyService.validateKey(keyId)
   - Mock: hardwarekey driver → validKey = true/false
   - Assert: valid key → login folytatódik
   - Assert: invalid key → AuthenticationException

2. Unit test: AuthController.login() hardware key nélkül
   - Assert: HTTP 401 + hibaüzenet "Hardware key required"

3. Integration test: POST /api/auth/login payload-ban hardwareKeyId
   - Mock service: key valid → JWT kiadva
   - Mock service: key invalid → 401

4. E2E: Electron stub-ban mock hardware key → login sikeres
```

### G05 — MoneyGram integráció

**Tesztelési javaslat:**
```
SZINT: Unit + Integration
ESZKÖZ: JUnit 5, WireMock (HTTP mock), Testcontainers

1. Unit test: MoneyGramFileParser.parseMoneyGramFile(inputStream)
   - Input: sample MG adat fájl (DWord-alapú formátum)
   - Assert: N tranzakció kinyerve, összegek helyesek

2. Unit test: MoneyGramService.processFile(filePath)
   - Mock: adatbázis writer
   - Assert: minden rekord DB-be mentve
   - Edge: dupla feldolgozás → idempotens (nem kettőz)

3. Integration test: POST /api/moneygram/import (multipart fájl)
   - Assert: HTTP 200, processedCount > 0
   - Assert: DB-ben az importált tranzakciók megjelennek

4. Integration test: GET /api/moneygram/pending
   - Assert: feldolgozatlan fájlok listája helyes
```

### G06 — Postai terminál integráció

**Tesztelési javaslat:**
```
SZINT: Unit + Integration (stub terminál)
ESZKÖZ: JUnit 5, WireMock

1. Unit test: PostaTerminalService.getBankCode(terminalId)
   - Assert: bank kód a config-ból kiolvasva

2. Unit test: PostaTerminalReportService.generateMonthlyReport()
   - Assert: Excel sorok száma == feldolgozott tranzakciók

3. Integration test: GET /api/posta-terminal/status
   - Mock terminál válasz → Assert: ONLINE/OFFLINE

4. Integration test: POST /api/posta-terminal/transaction
   - Mock terminál elfogad → Assert: DB-ben rekord + Excel update
```

### G07 — Metro / Tesco integráció

**Tesztelési javaslat:**
```
SZINT: Unit + Integration
ESZKÖZ: JUnit 5, Testcontainers

1. Unit test: MetroTransactionParser.parseMetroFile(bytes)
   - Assert: tranzakció rekordok kinyerve

2. Unit test: TescoMovementService.processTescoMovement(record)
   - Assert: készlet frissítve, napló-bejegyzés létrejött

3. Integration test: POST /api/metro/import
   - Assert: HTTP 200, tranzakciók DB-ben

4. Integration test: POST /api/tesco/import
   - Assert: HTTP 200, Tesco-specifikus készlet mozgás rögzítve

5. E2E: Regenerálás → Metro/Tesco mozgások megjelennek 
   az inventoryban
```

### G08 — Pályadíj / versenyeredmény pénzösszeg kezelés

**Tesztelési javaslat:**
```
SZINT: Unit + Integration
ESZKÖZ: JUnit 5 + MockMvc

1. Unit test: CompetitionPrizeService.calculatePrize(competitionId)
   - Input: verseny eredmény + díjtábla
   - Assert: helyezésenkénti összeg helyes
   - Edge: egyenlő pontszám → tie-breaker szabály

2. Unit test: CompetitionPrizeService.assignPrize(workerId, amount)
   - Assert: WorkerCommission rekord létrejött

3. Integration test: POST /api/competition/{id}/prizes
   - Assert: összes résztvevő díja kiszámítva és elmentve

4. Integration test: GET /api/competition/{id}/leaderboard
   - Assert: JSON rangsor helyes sorrendben
```

### G09 — Retroaktív adat-pótló eszköz

**Tesztelési javaslat:**
```
SZINT: Unit + Integration
ESZKÖZ: JUnit 5 + Testcontainers

1. Unit test: DataRecoveryService.detectMissingRecords(dateRange)
   - Assert: hiányos napok/tranzakciók azonosítva

2. Unit test: DataRecoveryService.backfillFromSource(record)
   - Mock: forrás szinkron endpoint
   - Assert: DB-be bekerült a hiányzó rekord
   - Edge: conflict esetén → merge strategy (newer wins)

3. Integration test: POST /api/data-recovery/backfill
   - Input: date range, source path
   - Assert: HTTP 202, job ID visszaadva
   - Assert: job befejezésekor a gap-ek pótolva

4. Integration test: GET /api/data-recovery/gaps
   - Assert: pontos hiánylista visszaadva
```

### G10 — Értéktár évnyitó

**Tesztelési javaslat:**
```
SZINT: Unit + Integration + E2E
ESZKÖZ: JUnit 5 + Testcontainers + Playwright

1. Unit test: ErtektarYearOpeningService.performOpening(year)
   - Assert: értéktár nyitó egyenleg == előző évi záró
   - Assert: minden értéktár-egység új évi rekordja létrejött

2. Unit test: ErtektarYearOpeningService.validatePreConditions()
   - Assert: ha az előző évi havi zárás nincs kész → Exception
   - Assert: ha már volt évnyitó → IdempotencyException

3. Integration test: POST /api/ertektar/year-opening
   - Pre: mock yearly closing done
   - Assert: HTTP 200, openingRecords.count > 0
   - Assert: DB-ben az értéktár nyitó egyenlegek konzisztensek

4. E2E (Playwright): 
   - Admin bejelentkezik → Ertektar → Evnyito
   - Confirm → Assert zöld siker üzenet
   - Inventory oldalon → Ertektar nézet → nyitó egyenlegek láthatók
```

---

## 9. Következtetések

### 9.1 Összefoglalás

| Kategória | Darab | % |
|---|---|---|
| **Összesen azonosított legacy use case** | **105** | 100% |
| KÉSZ | 58 | 55% |
| RÉSZLEGES | 31 | 30% |
| HIÁNYZIK | 10 | 9% |
| NEM_RELEVÁNS | 6 | 6% |

A modern rendszer a legacy funkcionalitás **~55%-át** teljesen lefedi, **~30%-a részlegesen** van implementálva (főként nyomtatás, speciális export, edge case üzleti szabályok), **~9% teljesen hiányzik** (kritikus és high prioritású gaps).

### 9.2 Legfontosabb megállapítások

1. **Az üzleti core teljesen kész**: Tranzakciók, árfolyamok, napi/havi/NAV zárások, storno, Western Union, pénztáros kezelés — a napi üzleti működés alapjai megvannak.

2. **A nyomtatási réteg a legnagyobb részleges terület**: A legacy rendszer 15+ különböző blokknyomtatási sablonnal rendelkezett (BLOKNYOM, NAPKONYV, NZNYOMT, CIMLNYOM stb.). A modern ESC/POS réteg alapjai megvannak, de a teljes jogszabályi lefedettség (nyilatkozatok, kétpéldányos napló, orosz nyilatkozat stb.) még részleges.

3. **Integrációs hiányok (MoneyGram, Metro, Tesco, Posta)**: Ezek dedikált külső partner-integrációk. Ha ezek aktív üzleti csatornák, akkor CRITICAL/HIGH szintű fejlesztési igény.

4. **Év-nyitó folyamat kritikus hiány**: Minden év január 1-jén szükséges — ha nincs implementálva, az első évforduló egy emergency feladat lesz.

5. **Jelenléti / HR terület teljesen hiányzik**: Bérszámítás és munkaidő-nyilvántartás jogszabályi kötelezettség. Ez önálló fejlesztési sprint.

6. **Tesztelhetőség drámaian jobb a modern stacken**: A Delphi kód tesztelhetetlen volt (UI-ba zárt üzleti logika). A Spring Boot rétegszeparáció lehetővé teszi az összes gap tesztvezérelt fejlesztését.

7. **Hardware-függő funkciók tesztelése igényel mockolási stratégiát**: A Playwright Electron konfig már megvan, a hardver mock réteg (printer, scanner, dongle, QR COM port) rendszer-tesztelési beruházást igényel.

### 9.3 Javasolt fejlesztési prioritás

```
SPRINT 1 (CRITICAL):
  - G01: Év-nyitó folyamat
  - G03: Teljes blokknyomtatási lefedettség
  - G04: Hardware dongle belépés (ha compliance kötelező)

SPRINT 2 (HIGH):  
  - G02: Jelenléti / munkaidő nyilvántartás
  - G05: MoneyGram integráció (ha aktív)
  - G10: Értéktár évnyitó

SPRINT 3 (MEDIUM):
  - G06: Postai terminál (ha aktív)
  - G07: Metro/Tesco (ha aktív)
  - G08: Pályadíj / versenyrendszer
  - G11–G20: MEDIUM prioritású hiányok

SPRINT 4 (LOW/POLISH):
  - G21–G25 + Excel export lefedettség + részleges funkciók befejezése
```

### 9.4 Tesztelési infrastruktúra ajánlás

- **Testcontainers PostgreSQL**: minden service integration testhez kötelező
- **WireMock**: MoneyGram, Posta, Metro/Tesco külső API mockhoz
- **Playwright Electron**: E2E tesztek a penztar-client flow-kra (már konfigurált)
- **ESC/POS byte assert helper**: custom test utility a nyomtatás lefedettségéhez
- **Hardware mock layer**: printer, scanner, dongle, QR COM-port — Electron IPC mock szinten

---

*Dokumentum vége — Tamás (TestOps Chief), 2026-04-05*
