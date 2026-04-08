---
type: registry
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Legacy SZERVER Modul Index"
load: on-demand
---

# Legacy SZERVER Modul Index
> Agent-optimalizált hivatkozás — keresés: `<!-- MODULE: név -->`
> Forrás: `Anti\SZERVER\_extracted\SZERVER\fejleszt\`
> Utolsó frissítés: 2026-04-05


---

## S1 SZERVER_ARCHITEKTURA_OSSZEFOGLALO

### Felépítés
- **Nyelv**: Delphi 7 (Object Pascal)
- **DB**: Firebird (InterBase) — `.FDB` fájlok, `C:\RECEPTOR\DATABASE\` könyvtár
- **Kommunikáció**: Fájl-alapú szinkronizáció (FTP, megosztott mappák) + DLL hívások
- **Struktúra**: Központi szerver app (`server\`) + ~95 DLL modul (`VALUTA\DLL\`, `ERTEKTAR\etdll\`)
- **Topológia**: 1 központi szerver → ~180 pénztár (iroda), 9 körzet (értéktár), 4 cégcsoport (B/P/E/Z)

### Központi Adatbázisok (Firebird)
| DB fájl | Tartalom |
|---------|----------|
| `RECEPTOR.FDB` | Rendszer törzsadatok (RENDSZER, IRODAK, ARFOLYAM, HIBAK) |
| `DAYBOOK.FDB` | Napi könyvek — `DAYB{ÉÉHO}` dinamikus táblák (pénztáranként 31 nap státusz) |
| `BLOKKFEJ.FDB` | Bizonylat fejlécek |
| `BLOKKTÉTEL.FDB` | Bizonylat tételek |
| `CIMTAR.FDB` | Címletkezelés tár |
| `MNB.FDB` | MNB árfolyam/kontroll adatok |
| `NARF*.FDB` | Napi árfolyam fájlok |

### Pénztár → Szerver Adatáramlás
1. Pénztár napzárásnál `.DAT` fájlokat generál (forgalom, címletek, WU, stb.)
2. FTP-n feltölti a szerverre (`C:\RECEPTOR\IRODA{xxx}\`)
3. Szerver `ADATLEGYUJTES` (unit29) importálja a Firebird DB-be
4. Szerver ellenőrzi (`TegnapControl`), hibákat jelent (`HIBAK` tábla)
5. Szerver generálja a jelentéseket, visszaküldi az árfolyamokat

### Devizanemek (fix 27 db + HUF)
```
AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF,
ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD
```

### Körzetek (Értéktárak)
```
1:Szekszárd, 2:Szeged, 3:Kecskemét, 4:Debrecen, 5:Nyíregyháza,
6:Békéscsaba, 7:Pécs, 8:Kaposvár, 9:Expressz
```

### Cégcsoportok
```
B=BEST, P=PANNON, E=EAST, Z=ZALOG
```

---


---

## S2 SZERVER_FEJLESZT_MODULOK

<!-- MODULE: server -->
### server/ (470K, 37 fájl) — Központi szerver alkalmazás
- `unit1.pas` (37K): **Fő form** — startup, rendszeradat beolvasás, iroda betöltés, valuta betöltés, DayBook kezelés, menü rendszer, AdatControl, TegnapControl
- `unit5.pas` (38K): **Import** — pénztári adatok importálása FTP-ről, bizonylat feldolgozás, Excel export
- `unit16.pas` (41K): **MNB Legyűjtő** — MNB árfolyam összesítés, iroda-szintű kontroll, eltérés keresés
- `unit29.pas` (77K): **ADATLEGYUJTES** — Forgalom/címlet/WU/bank/storno gyűjtés minden irodából, készlet-összesítés, TRB kontroll
- **Modern megfelelő**: `DailyClosingService`, `TransactionService`, `RateService`, `BranchService`
- **Gap**: DayBook dinamikus tábla rendszer (napi státusz tracking irodánként) nincs modern megfelelője

<!-- MODULE: arfolyam -->
### arfolyam/ (795K, 49 fájl) — Árfolyam kezelés
- Árfolyam TMK, árfolyam eltérítés, MNB árfolyam letöltés, verziók (v20-v22)
- **Modern megfelelő**: `RateService`, `RateController`, `ExchangeRateScheduler`
- **Gap**: MNB automatikus letöltés és napi árfolyam fájl generálás (NR*.DAT) — ellenőrizni kell

<!-- MODULE: booking -->
### booking/ (437K, 21 fájl) — Foglalás rendszer
- Foglalás bevételezés, kifizetés, visszafizetés, törlés, listázás
- **Modern megfelelő**: `ReservationService`, `ReservationController` ✅
- **Gap**: —

<!-- MODULE: beszam -->
### beszam/ (128K, 3 fájl) — Beszámolók / Jelentések
- Napi/havi/éves jelentések generálása, Excel export
- **Modern megfelelő**: `ReportService`, `NbReportGenerator`
- **Gap**: Specifikus Excel formátumok ellenőrzése

<!-- MODULE: ugyfelcontrol -->
### ugyfelcontrol/ (802K, 44 fájl) — Ügyfél kontroll
- Ügyfél tiltás, kockázat-kezelés, AML, szankciós lista
- **Modern megfelelő**: `CustomerService`, `AmlService`, `BlacklistService`
- **Gap**: Specifikus tiltási logika összehasonlítása

<!-- MODULE: recptor -->
### recptor/ (321K, 15 fájl) — Receptor (adatfogadó)
- `orecept/unit1.pas` (109K): Fő receptor — pénztári adat fogadás és feldolgozás
- **Modern megfelelő**: SyncEngine (Electron) + backend API
- **Gap**: —

<!-- MODULE: korlevel -->
### korlevel/ (115K, 9 fájl) — Körlevél rendszer
- Körlevél küldés irodáknak, nyugtázás
- **Modern megfelelő**: `CircularService`, `CircularController` ✅
- **Gap**: —

<!-- MODULE: makeszlt -->
### makeszlt/ (147K, 6 fájl) — Számla készítés
- Számlakészítés, bizonylat nyomtatás
- **Modern megfelelő**: `ReceiptGeneratorService`, `EscPosReceiptService`, `ReceiptPdfService`
- **Gap**: PDF formátum egyezés ellenőrzése

<!-- MODULE: permit -->
### permit/ (41K, 2 fájl) — Jogosultság kezelés
- Felhasználói jogok, engedélyek
- **Modern megfelelő**: `AuthService`, Spring Security RBAC
- **Gap**: —

<!-- MODULE: personal -->
### personal/ (68K, 3 fájl) — Személyzet
- Dolgozó nyilvántartás
- **Modern megfelelő**: `WorkerService`, `WorkerController`
- **Gap**: —

<!-- MODULE: haszon -->
### haszon/ (68K, 5 fájl) — Haszonszámítás
- Napi/havi haszon kalkuláció devizanemenként
- **Modern megfelelő**: `DecadeReportService`, `ProfitCalculationService`
- **Gap**: Haszonszámítási képletek egyezésének ellenőrzése

<!-- MODULE: uctrl -->
### uctrl/ (292K, 14 fájl) — Ügyfél kontroll (butított)
- Egyszerűsített ügyfélkezelés
- **Modern megfelelő**: `CustomerService`
- **Gap**: —

<!-- MODULE: helga -->
### helga/ (750K, 42 fájl) — Helga rendszer
- Valószínűleg egy specifikus alrendszer (HRK/monetáris)
- **Modern megfelelő**: Ellenőrizendő
- **Gap**: Tartalma ismeretlen — további elemzés szükséges

<!-- MODULE: terror -->
### terror/ (10K, 1 fájl) — Terror/szankciós lista
- Szankciós lista ellenőrzés (OFAC/EU)
- **Modern megfelelő**: `BlacklistService`, `AmlService`
- **Gap**: —

<!-- MODULE: police -->
### police/ (28K, 4 fájl) — Rendőrségi jelentés
- Gyanús tranzakciók bejelentése
- **Modern megfelelő**: `SuspiciousActivityService`
- **Gap**: Bejelentés formátum

<!-- MODULE: western -->
### western/ (43K, 1 fájl) — Western Union szerver
- WU forgalom központi kezelés
- **Modern megfelelő**: `WesternUnionService`, `WesternUnionController` ✅
- **Gap**: —

<!-- MODULE: postterm -->
### postterm/ (31K, 1 fájl) — POS terminál
- OTP/bankkártya terminál kezelés
- **Modern megfelelő**: `PosTerminalService`, `PosTerminalController` ✅
- **Gap**: —

<!-- MODULE: newyear / evnyito -->
### newyear/ (12K) + evnyito/ (6K) — Évnyitás
- Éves nyitás rutin, készlet átvitel
- **Modern megfelelő**: `YearOpeningService` ✅
- **Gap**: —

<!-- MODULE: foglalo -->
### foglalo/ (16K) — Foglalás (szerver oldal)
- Foglalás szerver logika
- **Modern megfelelő**: `ReservationService` ✅
- **Gap**: —

<!-- MODULE: tablomak -->
### tablomak/ (46K, 2 fájl) — Tábla generálás
- Összesítő táblázatok generálása
- **Modern megfelelő**: `ReportService`
- **Gap**: —

<!-- MODULE: verseny -->
### verseny/ (63K, 4 fájl) — Versenytárs figyelés
- Versenytárs árfolyamok
- **Modern megfelelő**: `CompetitorRateService` ✅
- **Gap**: —

<!-- MODULE: statiszt -->
### statiszt/ (21K, 2 fájl) — Statisztikák
- Forgalmi statisztikák
- **Modern megfelelő**: `ReportService`, `DataCollectionController`
- **Gap**: —

<!-- MODULE: jogiszemely -->
### jogiszemely/ (29K, 2 fájl) — Jogi személy kezelés
- Cégek ügyfélként
- **Modern megfelelő**: `CustomerService` (legal entity support)
- **Gap**: —

<!-- MODULE: jelenlet -->
### jelenlet/ (19K, 1 fájl) — Jelenlét nyilvántartás
- Dolgozó munkaóra
- **Modern megfelelő**: —
- **Gap**: ⚠️ HIÁNYZIK — dolgozó jelenlét/munkaóra tracking

<!-- MODULE: kezdij -->
### kezdij/ (33K, 2 fájl) — Kezelési díj
- Kezelési díj számítás és nyilvántartás
- **Modern megfelelő**: `HandlingFeeService` ✅
- **Gap**: —

<!-- MODULE: lemento -->
### lemento/ (33K, 2 fájl) — Adatmentés
- Adatbázis mentés
- **Modern megfelelő**: Backup script (Hetzner cron)
- **Gap**: —

<!-- MODULE: okmctrl -->
### okmctrl/ (13K, 1 fájl) — Okmány kontroll
- Személyi okmány ellenőrzés
- **Modern megfelelő**: `DocumentScanner` (Electron)
- **Gap**: —

<!-- MODULE: wuniforg -->
### wuniforg/ (9K, 1 fájl) — WU forgalom
- WU napi forgalom
- **Modern megfelelő**: `WesternUnionService`
- **Gap**: —

<!-- MODULE: summa / sumrate / sumtrade / sumtablo -->
### sum*/ — Összesítők
- Forgalom/árfolyam/kereskedelem összesítők
- **Modern megfelelő**: `DataCollectionService`, `ReportService`
- **Gap**: —

<!-- MODULE: frissdat -->
### frissdat/ (15K, 1 fájl) — Adatfrissítés
- Törzsadat frissítés az irodáknál
- **Modern megfelelő**: SyncEngine ✅
- **Gap**: —

---


---

## S3 VALUTA_DLL_MODULOK_PENZTAR_OLDAL
> Forrás: `Anti\SZERVER\_extracted\VALUTA\DLL\`

| DLL modul | Méret | Funkció | Modern megfelelő | Gap |
|-----------|-------|---------|-------------------|-----|
| ARFVALT | nagy | Árfolyam váltás | `TransactionService` | — |
| ELADAS | 134K | Eladás | `TransactionService.sell()` | — |
| VASARLAS | 102K | Vásárlás | `TransactionService.buy()` | — |
| STORNO | közepes | Sztornó | `StornoService` | — |
| NAPZAR | közepes | Napzárás | `DailyClosingService` | — |
| HAVIZAR | 57K | Havizárás | `MonthlyClosingService` | — |
| BLOKNYOM | 57K | Blokk nyomtatás | `EscPosReceiptService` | — |
| UGYFEL | 111K | Ügyfél kezelés | `CustomerService` | — |
| FOGLALO | 81K | Foglalás | `ReservationService` | — |
| WUNION | 89K | Western Union | `WesternUnionService` | — |
| OTP | 59K | OTP POS | `PosTerminalService` | — |
| NAVZARO | közepes | NAV zárás | `NavClosingService` | — |
| TERROR | közepes | Szankciós lista | `BlacklistService` | — |
| PILLKESZ | 64K | Pillanatkészlet | `StockService` | — |
| ATADOLAP | 63K | Átadólap | `HandoverSheetService` | — |
| ATADVET | 135K | Átad-átvétel | `HandoverService` | — |
| CIMLET | közepes | Címlet kezelés | `DenominationService` | — |
| METRO | 73K | Metro (bérelt pénzváltó) | — | ⚠️ Elavult? |
| TESCO | közepes | Tesco bérelt | — | ⚠️ Elavult? |
| DEKRUTIN | közepes | Dekádzárás | `DecadeReportService` | — |
| KORLEV | közepes | Körlevél | `CircularService` | — |
| PROSBE | közepes | Pénztáros belépés | `AuthService` | — |
| SUPER | közepes | Szupervízor | `AuthService` (ADMIN role) | — |
| GEPSETUP | 56K | Gép beállítás | Electron settings | — |
| NAPKONYV | közepes | Napi könyv | Napi kimutatás | — |
| KEZDIJ | közepes | Kezelési díj | `HandlingFeeService` | — |
| ESTIZAR | 91K | Esti zárás | `DailyClosingService` (step) | — |
| PTARKESZ | közepes | Pénztár készlet | `StockService` | — |


---

## S4 ERTEKTAR_DLL_MODULOK
> Forrás: `Anti\SZERVER\_extracted\ERTEKTAR\etdll\`

| DLL modul | Funkció | Modern megfelelő | Gap |
|-----------|---------|-------------------|-----|
| penztarak | Pénztárak kezelés (96K) | `BranchService` | — |
| atadvet | Átad-átvétel (85K) | `HandoverService` | — |
| pillkesz | Pillanatkészlet (64K) | `StockService` | — |
| estizar | Esti zárás (55K) | `DailyClosingService` | — |
| bloknyom | Bizonylat nyomtatás | `EscPosReceiptService` | — |
| napzar | Napzárás | `DailyClosingService` | — |
| havizar | Havi zárás | `MonthlyClosingService` | — |

---


---

## S5 TRADE_MODUL_ELEKTRONIKUS_KERESKEDES
> Forrás: `Anti\SZERVER\_extracted\VALUTA\TRADE\fejleszt\`
> Ez a telefon feltöltős, matricás, kupon rendszer — **ELAVULT, NEM IMPLEMENTÁLANDÓ**

---


---

## S6 AZONOSITOTT_GAP_EK_MODERN_RENDSZERBOL_HIANYZIK

| # | Gap | Legacy modul | Prioritás | Megjegyzés |
|---|-----|-------------|-----------|------------|
| SG-1 | DayBook rendszer (napi irodai státusz tracking) | `server/unit1.pas` | P2 | A modern rendszerben a `DailySession` entity ezt részben lefedi |
| SG-2 | Jelenlét nyilvántartás | `jelenlet/` | P2 | Dolgozó munkaóra/jelenlét — nincs modern megfelelő |
| SG-3 | MNB árfolyam automatikus letöltés | `arfolyam/` | P1 | Ellenőrizni: `ExchangeRateScheduler` lefedi-e |
| SG-4 | Haszon számítási képletek egyezése | `haszon/` | P1 | Pontos egyezés ellenőrzése szükséges |
| SG-5 | Helga alrendszer | `helga/` | P3 | Ismeretlen tartalom — további elemzés |
| SG-6 | Metro/Tesco bérelt pénzváltó | METRO, TESCO DLL | P3 | Elavult — Zoltánnal egyeztetni |
| SG-7 | Rendőrségi jelentés formátum | `police/` | P2 | `SuspiciousActivityService` — formátum ellenőrzés |
| SG-8 | Szerver→Pénztár fájl-alapú kommunikáció | Teljes szerver | — | Modern: REST API + SyncEngine ✅ |
