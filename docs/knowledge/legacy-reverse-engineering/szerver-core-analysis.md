---
type: analysis
scope: vault-creating
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Legacy SZERVER Core Analysis"
load: on-demand
---

# Legacy SZERVER Core Analysis
> Forrás: `Anti\SZERVER\_extracted\SZERVER\fejleszt\server\`
> 4 fő unit részletes elemzése


---

## S1 UNIT1PAS_37K_FO_SZERVER_FORM

### Fő Firebird táblák
| Tábla | DB | Tartalom |
|-------|-----|----------|
| RENDSZER | RECEPTOR.FDB | Rendszer config: AZONOSITO×3, VALTONEV×3, PAUSEPERC, BETUJEL×3, JELSZO, BANKFK1-9 |
| IRODAK | RECEPTOR.FDB | UZLET(int), CEGBETU, VAROS, BOLTNEV, STATUS, BANKKOD, ERTEKTAR(int), SUNDAYCLOSE, CLOSED |
| ARFOLYAM | RECEPTOR.FDB | VALUTANEM, VALUTANEV, VETELIARFOLYAM, ELADASIARFOLYAM, ELSZAMOLASIARFOLYAM |
| HIBAK | RECEPTOR.FDB | IRODA, IRODANEV, VALUTANEM, ELTERES |
| DAYB{ÉÉHO} | DAYBOOK.FDB | Dinamikus: PENZTAR(int), N1..N31 (char: ' '=nincs adat, 'X'=zárva/ünnep, '1'=beérkezett) |
| MNB | MNB.FDB | IRODASZAM, VALUTANEM, MEGJEGYZES, ZARO, SZAMITOTTZARO |

### Fő eljárások
| Eljárás | Funkció |
|---------|---------|
| `FormCreate` | Startup: RendszerAdatBeolvasas → ValutaBetolto → IrodaBetolto → DbkControl → StartIdozito |
| `RendszerAdatBeolvasas` | RENDSZER tábla olvasás → `_azonosito[]`, `_valtonev[]`, `_bankjel[]`, `_jelszo` |
| `ValutaBetolto` | ARFOLYAM tábla → `_dnem[]`, `_dnev[]`, `_varf[]`, `_earf[]`, `_elszarf[]` (27 deviza) |
| `IrodaBetolto` | IRODAK tábla → `_irodaszam[]`, `_vasarnap[]`, `_bezarva[]`, `_boltnev[]`, `_korzet[]` stb. |
| `DbkControl` | DayBook tábla létezés ellenőrzés → `MakeDayBook` + `FillDayBook` ha nem létezik |
| `MakeDayBook` | `CREATE TABLE DAYB{ÉÉHO} (PENZTAR INT, N1..N31 CHAR)` — dinamikus Firebird tábla |
| `FillDayBook` | Irodák betöltése DayBook-ba, ünnepnapok/vasárnapok 'X'-szel jelölve |
| `TegnapControl` | Ellenőrzi: bejött-e minden tegnapi zárás. Hiányzó pénztárak → `_missPenztar[]` |
| `AdatControl` | MNB összesítés → `MNBLegyujto` → HIBAK tábla feltöltése eltérésekkel |
| `MenuJob` | Fő menü: 14 pont (Rendszeradatok, ArfTMK, DataDisp, IrodaTMK, Import, Áttekintés, MNB, Átlagárf, Jutszám, ÁrfEltérítés, WU, Dolgozók, TranzDíj, JutSzorzó) |

### Menüpontok → Modern mapping
```
1: Rendszeradatok     → SystemParameterService
2: ArfolyamTmk        → RateController (CRUD)
3: GetDataDisp        → DataCollectionController
4: IrodaTMK           → BranchController (CRUD)
5: makeimportrutin    → SyncEngine (automatikus)
6: Attekintes         → ReportService (dashboard)
7: MnBListak          → NavReportController
8: Atlagarfolyam      → RateService.getAverageRates()
9: Jutszam            → CommissionService
10: ArfolyamElterites → RateService (rate override)
11: WuniWafaControl   → WesternUnionService
12: dolgozoinyilvantartas → WorkerController
13: tranzakciojelentes → TransactionService (reports)
14: jutalekszorzo     → CommissionService (multiplier)
```

### Ünnepnap logika
```
Január: 1
Március: 15
Május: 1
Augusztus: 20
Október: 23
November: 1
December: 25, 26
+ vasárnap ha SUNDAYCLOSE='X'
+ CLOSED='X' → egész hónapban zárva
```

### Címletek (14 db HUF)
```
20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1
```

---


---

## S2 UNIT5PAS_38K_IMPORT_MODUL_MAKEIMPORT

### Funkció
Pénztári napi adatok importálása FTP-ről letöltött fájlokból a központi Firebird DB-be.

### Firebird táblák
- SALLOMANY, SBANKFORG, BLOKKFEJ, BLOKKTÉTEL, CIMTAR, DAYBOOK, SUGYFELFORG, RECEPTOR

### Fő eljárások
- `ImportGo`: Fő import rutin — dátum kiválasztás → összes iroda feldolgozás
- Excel export támogatás (COM Automation → Excel97)
- Bizonylat (BLOKKFEJ/BLOKKTÉTEL) összesítés és import

### Modern megfelelő
SyncEngine (Electron → backend API) — teljesen kiváltva REST-tel

---


---

## S3 UNIT16PAS_41K_MNB_LEGYUJTO

### Funkció
MNB napi árfolyam adatok gyűjtése és ellenőrzése az összes irodából.

### Fő logika
1. Végigmegy az irodákon
2. Minden irodára lekéri a napi MNB-s adatokat
3. Összeveti a számított záróval (`SZAMITOTTZARO`) a tényleges záróval (`ZARO`)
4. Eltérést az MNB táblába írja `MEGJEGYZES` mezőbe
5. `AdatControl` meghívja → HIBAK tábla feltöltés

### Eltérés kezelés
- Ha `MEGJEGYZES <> 'OK'` és `STATUS <> 'X'` (nem zárva) → hiba
- Eltérés = `ZARO - SZAMITOTTZARO`
- A hibák irodánként és devizanemenként kerülnek naplózásra

### Modern megfelelő
`NavClosingDiscrepancyService.validateNavClosingAmount()` — részben lefedi

---


---

## S4 UNIT29PAS_77K_ADATLEGYUJTES_ADATGYUJTES

### Funkció
A legkomplexebb szerver modul — minden irodából összegyűjti a napi forgalmat, címleteket, WU tranzakciókat, bank forgalmat, és összesíti.

### Fő eljárások
| Eljárás | Funkció |
|---------|---------|
| `FormActivate` | Indítás → `INDITOTimer` |
| `ForgalomGyujtes` | Forgalom gyűjtés minden irodából |
| `CimletGyujtes` | Címlet gyűjtés |
| `WuniForgalomGyujtes` | Western Union forgalom |
| `BankGyujtes` | Bank forgalom gyűjtés |
| `Cimletosszesites` | Címlet összesítés körzetenként |
| `ForgalomOsszesites` | Forgalom összesítés |
| `WuniOsszesites` | WU összesítés |
| `InterPtControl` | Pénztárközi kontroll |
| `TRBControl` | TRB (tranzakciós bizonylat) kontroll |
| `ForgalomRutin` | Teljes forgalom feldolgozási rutin |
| `SendingRutin` | Adat visszaküldés pénztáraknak |
| `StornoRegisztracio` | Sztornó regisztráció |
| `WuniAfaBerogzites` | WU ÁFA rögzítés |
| `MetroForgalomGyujtes` | Metro bérelt pénzváltó forgalom |
| `TescoForgalomGyujtes` | Tesco bérelt pénzváltó forgalom |

### Forgalom változók struktúra
```
Per deviza (0..27):
  _uny/_uz: nyitó/záró
  _hny/_hz: HUF nyitó/záró
  _ubg/_ubp/_ubu: pénztárba beérkezett (gazdálkodásból/pénztárból/ügyfélből)
  _ukg/_ukp/_uku: pénztárból kimenő
  _any/_az: ÁFA nyitó/záró
  _hbg/_hbp/_hbu/_hkg/_hkp/_hku: HUF mozgások
  _abg/_abp/_akg/_akp/_aku: ÁFA mozgások

Per körzet (0..2) + összesítés:
  _kuny/_kuz, _khny/_khz stb.

Összesítés:
  _sumvett/_sumeladott/_sumvettertek/_sumeladottertek
```

### Modern megfelelő
- `DataCollectionService` — részben
- `DailyClosingService` — a napzárás logika
- `StockService` — készlet számítás
- `TransactionService` — forgalom kezelés

### Gap elemzés
A modern rendszer REST API-n keresztül valós időben dolgozik, nem batch feldolgozással. A fő logika (forgalom összesítés, készlet számítás) implementálva van, de a körzetenként összesítés és a specifikus batch adatgyűjtés nem 1:1 felel meg — a modern rendszer query-kkel oldja meg, nem gyűjtéssel.

---


---

## S5 OSSZEFOGLALO_SZERVERMODERN_MAPPING_MATRIX

| Legacy szerver funkció | Modern service | Státusz |
|------------------------|---------------|---------|
| Rendszer config kezelés | `SystemParameterService` | ✅ |
| Iroda/pénztár nyilvántartás | `BranchService` | ✅ |
| Árfolyam nyilvántartás | `RateService` | ✅ |
| Napi könyv (DayBook) | `DailySession` entity | ⚠️ Részleges |
| Pénztári import (FTP) | SyncEngine (REST) | ✅ Kiváltva |
| MNB legyűjtő/kontroll | `NavClosingService` + `NavReportService` | ✅ |
| Adatgyűjtés (batch) | Real-time REST API | ✅ Kiváltva |
| Forgalom összesítés | `DataCollectionService` + query | ✅ |
| Címlet összesítés | `DenominationService` | ✅ |
| WU összesítés | `WesternUnionService` | ✅ |
| Bank forgalom | `BankTransactionService` | ✅ |
| Sztornó regisztráció | `StornoService` | ✅ |
| Hibák kezelés | `AuditLogService` | ✅ |
| Pénztárközi kontroll | `HandoverService` | ✅ |
| TRB kontroll | `TransactionService` | ✅ |
| Menürendszer | React SPA routing | ✅ |
