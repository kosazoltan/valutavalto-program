---
type: analysis
scope: workspace-shared
version: 2026-07-19
format: structured-lookup
encoding: utf-8
description: "Delphi → Java RING-szintu Gap Matrix (Core-prioritas szerinti)"
load: on-demand
---

# Delphi → Java RING-szintű Gap Mátrix (Core-prioritás szerinti)
> Készítette: Tamás (TestOps Chief) | 2026-04-04 | v2 — Core-ból kifelé haladó elemzés
> Forrás: junior-core-analysis-2026-04-04.md + delphi-java-gap-analysis-2026-04-04.md + Java backend (1170 .java fájl)

---


---

## S1 GYORS_OSSZEFOGLALO

| Mutatók | Érték |
|---|---|
| Java backend controllerek | 122 db |
| Java service-ek | 175 db |
| Java entitások | 225 db |
| Delphi modulok vizsgálva | 200+ |
| P0 MAG lefedettség | ~74% (volt: ~62%) |
| P1 INNER RING lefedettség | ~61% |
| P2 OUTER RING lefedettség | ~45% |
| P3 PERIPHERY lefedettség | ~30% |
| Kritikus teljes gap (MUST) | ~202 óra |
| Ajánlott gap (SHOULD) | ~190 óra |

---


---

## S2 OLVASASI_UTMUTATO

**Prioritás-kódok:**
- **P0** = MAG — valutaváltás, értéktár, árfolyam. Enélkül nem fut a rendszer.
- **P1** = INNER RING — átadás/készletezés, ügyfélkezelés, bizonylat, szinkron
- **P2** = OUTER RING — értéktár↔bank, MNB riport, könyvelési export
- **P3** = PERIPHERY — szerver admin, verseny, western union, statisztikák

**Státusz-kódok:**
- `KÉSZ` = Java implementáció megfelel a Delphi logikának
- `RÉSZLEGES` = Java service létezik, de a Delphi teljes logika nincs lefedve
- `ELTÉRÉS` = Java implementáció van, de más algoritmussal vagy más szerkezettel
- `HIÁNYZIK` = Nincs Java megfelelő
- `NEM KELL` = Legacy-specifikus (Firebird backup, UI DLL stb.) — nem kell implementálni

**Kockázat-kódok:**
- 🔴 `KRITIKUS` = Adatvesztés vagy törvényi megfelelési kockázat
- 🟠 `MAGAS` = Pénzügyi pontossági kockázat
- 🟡 `KÖZEPES` = Működési zavar, de nem végzetes
- 🟢 `ALACSONY` = Kiegészítő funkció, halasztható

---


---

## S3 P0_MAG_VALUTAVALTAS_ERTEKTAR_ARFOLYAM

### P0.1 — Vétel (BUY) tranzakció — `VASARLAS/Unit2.pas`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P0.1.01 | Vételi tranzakció indítása | `FormActivate` → `AlapadatBeolvasas` → VTEMP nullázás, HARDWARE/PENZTAR/ARFOLYAM betöltés | `TransactionService.executeBuy()` | KÉSZ | 🟢 | Java REST-alapú flow, nincs VTEMP, DB-ből közvetlen betöltés |
| P0.1.02 | Devizanem kiválasztás és adatok betöltése | `DnemKeyDown` → árfolyam, készlet, deviza név | `ExchangeRateService.getCurrentRate()` | KÉSZ | 🟢 | REST hívással ekvivalens |
| P0.1.03 | Bankjegy összeg bevitel és soronkénti számítás | `BankjegyKeyDown` → `SorbeirasVtempbe` | `TransactionMultiLineService` | KÉSZ | 🟢 | Multi-line tranzakció támogatott |
| P0.1.04 | **Forint érték számítás — JPY speciális logika** | `_aktErtek = round((_aktArfolyam/100*_aktBankjegy)+0.001)` // JPY: `/10` | `TransactionCalculationService.calculateBuyHufAmount()` | **ELTÉRÉS** | 🔴 | Java NEM implementálja a JPY /10 és 1000-es egység logikát. `ExchangeRate.getBuyRateForAmount()` nincs JPY-specifikus ág. Kritikus! |
| P0.1.05 | **Kerekítési konstans (_rounder = 0.001)** | Delphi REAL típus lebegőpontos kerekítés + `_rounder` | `HungarianRounding.roundToFive()` | **ELTÉRÉS** | 🟠 | Java `BigDecimal` + `roundToFive()` van, de a `_rounder = 0.001` konstans nem implementált. Kis összegű tranzakcióknál ±1 Ft eltérés lehetséges. |
| P0.1.06 | Nettó/bruttó/kezelési díj/kerekítés számítás | `FizetendoDisplay` → `_netto`, `_origkezdij`, `_brutto = netto - kezelesidij`, `_fizetendo`, `_kerekites` | `HandlingFeeCalculator.calculateBuyGross()` + `HungarianRounding.roundToFive()` | KÉSZ | 🟢 | A teljes pipeline implementált |
| P0.1.07 | **Kezelési díj — NONE/PER_MILLE/BRACKET** | `GetKezelesidij`: `_realEzrelek=0` → nincs díj; `>0` → ezrelékes; `=-1` → sávos | `HandlingFeeService`: NONE/PER_MILLE/BRACKET enum | KÉSZ | 🟢 | Java teljesen lefedi a 3 módot |
| P0.1.08 | Kezelési díj max-limit (`_kezdijmax`) | `if dij > _kezdijmax then dij := _kezdijmax` | `HandlingFeeBracket` entity (max mező?) | **RÉSZLEGES** | 🟠 | `HandlingFeeBracket` entitás van, de `_kezdijmax` globális limit ellenőrzés nincs explicit implementálva — csak sávos maximum van |
| P0.1.09 | Konverzió kezelési díj = 0 | `if konverzio then kezelesidij := 0` | `TransactionConversionService` | **RÉSZLEGES** | 🟠 | `TransactionConversionService` létezik, de a díj=0 logika ellenőrizendő |
| P0.1.10 | Árfolyam kedvezmény (engedélyező kijelölés) | `ArfolyamotModosit` | `TransactionCalculationService.validateDiscount()` + `resolveBuyRate()` | KÉSZ | 🟢 | |
| P0.1.11 | Kezelési díj engedmény (fix díj felülírása) | `KezdijEngedmenyGomb` | `HandlingFeeService.getRemainingCustomFeeQuota()` | KÉSZ | 🟢 | |
| P0.1.12 | **SHK (Saját Hatáskörű Kedvezmény) — max 5/nap** | `HARDWARE.SAJATHATASKORU` számláló | `HandlingFeeService.getRemainingCustomFeeQuota()` + `DEFAULT_DAILY_CUSTOM_FEE_LIMIT=3` | **ELTÉRÉS** | 🟠 | Delphi max **5/nap**, Java max **3/nap**! Konstans eltérés. Napi zárásnál nullázandó. |
| P0.1.13 | Bizonylat szám generálás | `GetBizonylatSzam` → HARDWARE táblából sorszám | `ReceiptSequenceService.generateReceiptNumber()` | KÉSZ | 🟢 | |
| P0.1.14 | Blokk nyomtatás | `BlokkFejIro` + `BlokktetelIro` → `bloknyom.dll` | `ReceiptGeneratorService` + `EscPosReceiptService` | KÉSZ | 🟢 | |
| P0.1.15 | Bizonylat regisztrálás | `Bizregiszter` → INSERT INTO bizonylat | `TransactionRepository.save()` | KÉSZ | 🟢 | |
| P0.1.16 | **NAV XML generálás** | `MakeXml` → XML bizonylat | `NavIntegrationService` + `NavAbevXmlGenerator` | KÉSZ | 🟢 | |
| P0.1.17 | 300.000 Ft feletti ügyfél azonosítás kötelező | `if fizetendo > 300000 then azonositas_kotelezo` | `TransactionService: IDENTIFICATION_LIMIT = 300000` + `validateIdentification()` | KÉSZ | 🟢 | |
| P0.1.18 | **Kisügyfél lerendezés (szerverre küldés)** | `KisugyfelLerendezes` → RemoteDbase szerverre INSERT | `EveningClosingService` (adatcsomag szerverre) | RÉSZLEGES | 🟡 | Azonnali szerverre küldés helyett esti zárásnál küld csomag. Real-time szinkron hiányzik. |
| P0.1.19 | **Nagy összegű tranzakció kontrol (BIGCTRL.DLL)** | `BIGCTRL.DLL` hívás (ügyféltípus, ügyfélszám, fizetendő, konverzió, bizonylatszám) | Nincs dedikált BigCtrl service | **HIÁNYZIK** | 🔴 | AML folyamat van (`AmlService`), de a BIGCTRL.DLL-specifikus workflow (ügyféltípus + konverzió kombináció) nincs implementálva |
| P0.1.20 | QR kód generálás | `QrKodLerendezes` | `QrCodeService` | KÉSZ | 🟢 | |
| P0.1.21 | EUR érme konvertálás | `EurErmeKonvertalas` — speciális EU logika | Nincs dedikált EUR érme service | **HIÁNYZIK** | 🟠 | Niche eset, de EUR érmék esetén az eladási folyamat eltérő |
| P0.1.22 | POS terminál integráció | `GetPtParams` → HARDWARE.BKKS számláló | `PosTerminalService` + `OtpTerminalProtocolService` | KÉSZ | 🟢 | |
| P0.1.23 | Vásárlás előjelezés (bruttó = nettó - díj) | `_brutto := _netto - _kezelesidij` | `HandlingFeeCalculator.calculateBuyGross()` | KÉSZ | 🟢 | |
| P0.1.24 | Kerekítés könyvelése | `_kerekites := _fizetendo - _brutto` | `Transaction.roundingAmount` | KÉSZ | 🟢 | |
| P0.1.25 | Jogi személy kezelés | `RemoteJoviLerendezes` → JOGI tábla | `CustomerService` (jogi személy ág) | RÉSZLEGES | 🟡 | Jogi személy entitás van, de a JOGI tábla összes mezőjének leképezése ellenőrizendő |

**P0.1 Összesítés:** 25 elemből ~18 KÉSZ, ~5 RÉSZLEGES/ELTÉRÉS, ~2 HIÁNYZIK

---

### P0.2 — Eladás (SELL) tranzakció — `ELADAS/Unit2.pas`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P0.2.01 | Eladási tranzakció indítása | `TVetelForm` tükrözött struktúra | `TransactionService.executeSell()` | KÉSZ | 🟢 | |
| P0.2.02 | **Eladás előjelezés (bruttó = nettó + díj)** | `_brutto := _netto + _kezelesiDij` | `HandlingFeeCalculator.calculateSellGross()` | KÉSZ | 🟢 | |
| P0.2.03 | Eladás előjel bizonylaton | `_elojel := '-'` | `TransactionType.SELL` + Receipt generátor | KÉSZ | 🟢 | |
| P0.2.04 | Devizanem táblába írás (VTEMPD is) | `Dnem2Vtemp` → VTEMPD tábla | `TransactionLine` entitás | KÉSZ | 🟢 | Nincs különálló VTEMPD — a `TransactionLine` mindent tartalmaz |
| P0.2.05 | **Készlet limit figyelés eladásnál** | `Limitdisplay` → "NINCS ENNYI FORINT KÉSZLETÜNK" | `TransactionValidationService` (stock check) | KÉSZ | 🟢 | |
| P0.2.06 | Konverzió kezelés (kezelési díj = 0) | `if konverzio then kezdij := 0` | `TransactionConversionService` | RÉSZLEGES | 🟠 | `TransactionConversionService` létezik, de a díj=0 logika JavaBean-ben ellenőrizendő |
| P0.2.07 | Eladási árfolyam feloldás | `GetSellRate` + limit 1/2/3 tábla | `ExchangeRate.getSellRateForAmount()` | KÉSZ | 🟢 | Limit 1/2/3 teljes implementáció |
| P0.2.08 | **JPY eladási speciális** | JPY eladásnál is speciális 1000-es egység | `TransactionCalculationService.calculateSellHufAmount()` | **ELTÉRÉS** | 🔴 | Ugyanaz a JPY gap mint vételnél — nincs speciális /10 logika |
| P0.2.09 | Bizonylat és blokk nyomtatás | Ugyanaz mint vételnél | `ReceiptGeneratorService` + `EscPosReceiptService` | KÉSZ | 🟢 | |
| P0.2.10 | 300K azonosítás eladásnál is | `if fizetendo > 300000 then azonositas_kotelezo` | `TransactionService: IDENTIFICATION_LIMIT = 300000` | KÉSZ | 🟢 | |
| P0.2.11 | Napi ügyfél limit frissítés (`NAPIGONGYOLTFORINT`) | `UPDATE UGYFEL SET NAPIGONGYOLTFORINT=napigongyolt+fizetendo` | `CustomerControlService` / `AmlService` | RÉSZLEGES | 🟠 | `Customer` entitás a napi limit tracker mezőt nem látjuk — ellenőrizendő |
| P0.2.12 | `RemoteLerendezes` — nagyügyfél adatok szerverre | FTP-n XML/bináris csomag | `EveningClosingService` adatcsomag | RÉSZLEGES | 🟡 | Szinkronizáció esti zárásnál, nem real-time |

**P0.2 Összesítés:** 12 elemből ~8 KÉSZ, ~3 RÉSZLEGES/ELTÉRÉS, ~1 HIÁNYZIK (EUR érme — megosztva P0.1-gyel)

---

### P0.3 — Stornó — `STORNO/Unit2.pas`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P0.3.01 | Stornó tranzakció visszakeresés | Eredeti bizonylat sorszám alapján | `StornoService.checkStorno()` | KÉSZ | 🟢 | |
| P0.3.02 | **Sztornó napi limit (supervisor nélkül)** | Iroda szinten max 3/nap | `StornoService: DAILY_STORNO_LIMIT_BRANCH=3` | KÉSZ | 🟢 | |
| P0.3.03 | **Sztornó napi limit pénztáros szinten** | Max 2/nap pénztárosonként (Delphi) | `StornoService: DAILY_STORNO_LIMIT_CASHIER=2` | KÉSZ | 🟢 | |
| P0.3.04 | Sztornó jóváhagyás kérés | Supervisor jelszó ha limit felett | `StornoService` + `StornoApproval` entitás | KÉSZ | 🟢 | |
| P0.3.05 | Készlet visszaállítás stornónál | Eredeti tranzakció hatásának megfordítása | `TransactionReversalService` | KÉSZ | 🟢 | |
| P0.3.06 | **Stornó hatása profitszámításra** | `HaszonSzamitas` figyelembe veszi a stornót | `ProfitCalculationService` — stornók szűrése? | **RÉSZLEGES** | 🟠 | `ProfitCalculationService` `buildProfitReport()` szűri-e a stornókat? `Transaction.isActive()` flag ellenőrizendő |
| P0.3.07 | Stornó bizonylat nyomtatás | Külön stornó bizonylatszám, blokk | `ReceiptGeneratorService` + `StornoController` | KÉSZ | 🟢 | |
| P0.3.08 | Stornó értéktárban | ERTEKTAR/etdll/storno — külön workflow | `StornoService` (értéktár ág?) | **RÉSZLEGES** | 🟠 | Az értéktári stornó ugyanazon service-en megy vagy külön? Ellenőrizendő |

**P0.3 Összesítés:** 8 elemből ~5 KÉSZ, ~3 RÉSZLEGES

---

### P0.4 — Napi záras — `NAPZAR/Unit2.pas`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P0.4.01 | Lezárt nap ellenőrzés induláskor | `FormActivate` → HARDWARE lezárt nap check | `DailyClosingService` / `DailySessionService` | KÉSZ | 🟢 | |
| P0.4.02 | Napi forgalom összeszedés | `ForgalomBeolvasas` → napi tételek | `DailyClosingService.performInternalChecks()` | KÉSZ | 🟢 | |
| P0.4.03 | Devizánkénti nettó összesítés | `NapiForgalomSzamitas` → ARFOLYAM tábla alapján | `DailyReportService` | KÉSZ | 🟢 | |
| P0.4.04 | **Árfolyam archiválás** | INSERT INTO éves árfolyam tábla (dátum + devizanem + vétel/eladás/MNB) | `RateHistoryService` + `ArchivedMonthlyTransaction` | RÉSZLEGES | 🟠 | `RateHistory` entitás van, de az éves kumulatív archiválás (nem csak history) ellenőrizendő |
| P0.4.05 | **Ügyfél napi limit nullázás** | `UPDATE UGYFEL SET NAPIGONGYOLTFORINT=0` + `UPDATE JOGISZEMELY SET...` | Nincs explicit napi zárásnál ügyfél limit reset | **HIÁNYZIK** | 🔴 | A `CustomerService`-ben nincs `resetDailyLimits()` metódus amit a napi záras meghív — kritikus AML kockázat |
| P0.4.06 | **WU mozgás feldolgozás** | `WUMOZGAS` tábla feldolgozás napi zárásnál | `WesternUnionService` | RÉSZLEGES | 🟡 | WU service létezik, de a záráskori WU egyenleg feldolgozás ellenőrizendő |
| P0.4.07 | OTP lezárás | OTP POS terminál napi zárás | `OtpTerminalProtocolService` | KÉSZ | 🟢 | |
| P0.4.08 | HARDWARE lezárt nap frissítés | `UPDATE HARDWARE SET LEZARTNAPSZAMA=...` | `DailySessionService` (session closed) | KÉSZ | 🟢 | |
| P0.4.09 | Napi forgalom → éves forgalmi táblába | INSERT INTO `_cimfilenev` | `MonthlyArchiveService` | RÉSZLEGES | 🟡 | Havi archivált tranzakciók kezelve, de az éves forgalmi tábla (file-alapú) nincs |
| P0.4.10 | **Blokk fej/tétel archiválás** | INSERT INTO `BLOKKFEJ` éves, `BLOKKTETEL` éves | `EveningClosingService` (BFCopy, BTCopy) | **RÉSZLEGES** | 🔴 | Az esti zárásnál van BFCopy/BTCopy — de az értéktári esti zárásnál (`ClosingWizardService`) ez hiányzik! |
| P0.4.11 | Cimlet archiválás | INSERT INTO éves cimlet tábla | `DenominationBalanceService` | RÉSZLEGES | 🟡 | `DenominationBalance` entitás van, de az éves archiválás elkülönítve? |
| P0.4.12 | SHK számláló reset | `UPDATE HARDWARE SET SAJATHATASKORU=0` | `HandlingFeeService.getRemainingCustomFeeQuota()` | **HIÁNYZIK** | 🟠 | A napi zárásnál nincs explicit SHK reset — a quota DB-ből számol, de ha nem törlődik, limitszámítás hibás |
| P0.4.13 | 16 lépéses zárási varázsló (CIMLCTRL szekvencia) | 9 belső lépés + user lépések | `ClosingWizardService` + `ClosingWizardSteps` | KÉSZ | 🟢 | Teljes varázsló implementált |

**P0.4 Összesítés:** 13 elemből ~6 KÉSZ, ~5 RÉSZLEGES, ~2 HIÁNYZIK

---

### P0.5 — Árfolyamkészítés (Spreadsheet modul) — `SZERVER/fejleszt/arfolyam/verzio22`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P0.5.01 | Excel-szerű árfolyamtábla UI | `TMunkaForm` — rács, sorok=devizanemek, oszlopok=pénztárak | Frontend React (RateCreation page) | KÉSZ | 🟢 | |
| P0.5.02 | Cellánkénti képlet-szerkesztés | `FuggvenyKezelo` + `FuggvenyKijelzes` | `RateTemplateService` + `RateWorkgroupService` | RÉSZLEGES | 🟡 | Java sablon-alapú, nem valódi cellaszintű formula engine |
| P0.5.03 | **Árfolyam szétküldés irodákba** | `szetkuldogombClick` → `AdatSzetkuldes.showmodal` + `ArfdataIras.showmodal` | `RatePublishService.publishToGroup()` | KÉSZ | 🟢 | |
| P0.5.04 | Pénztárlista betöltés szétküldéshez | `PenztarListaTolto` | `BranchService` | KÉSZ | 🟢 | |
| P0.5.05 | Teljes tábla újraszámítás | `LapRegeneralo` | `RateCreationService` | KÉSZ | 🟢 | |
| P0.5.06 | **Csoportos árfolyammásolás (10 oszlop)** | `AdatMasolorutin` — 10 oszlop, soronként | `RateCreationService` | RÉSZLEGES | 🟡 | A Java csoportos publikálás API-n van, de az oszlop-másolás logika (10 csoport) ellenőrizendő |
| P0.5.07 | MNB árfolyam letöltés | `MnbApiClient` (ráépítve a Delphi MNBLEGYUJTO-ra) | `MnbApiClient` + `MnbExchangeRateService` | KÉSZ | 🟢 | |
| P0.5.08 | **Versenytárs árfolyam figyelés** | `everseny` + `verseny` modulok | `CompetitorRateRepository` + `CompetitorService` | RÉSZLEGES | 🟡 | Versenytárs entitás van, de a Delphi éves verseny-számítás mélysége nem implementált |
| P0.5.09 | Raiffeisen árfolyam lekérés | `RaiffeisenRateScheduler` | `RaiffeisenRateService` + `RaiffeisenRateScheduler` | KÉSZ | 🟢 | Java-specifikus kiegészítés |
| P0.5.10 | Rate jóváhagyási workflow | `rateperm` DLL | `RateApprovalService` + `RateApprovalController` | KÉSZ | 🟢 | |
| P0.5.11 | Árfolyam tábla nyomtatás | `tablomak` DLL | `PrintTemplateController` + `PrintTemplateService` | KÉSZ | 🟢 | |

**P0.5 Összesítés:** 11 elemből ~7 KÉSZ, ~4 RÉSZLEGES

---

### P0.6 — Árfolyam entitás és számítás

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P0.6.01 | Alap vétel/eladás árfolyam | `ALAPVETEL`, `ALAPELADAS` | `ExchangeRate.baseBuyRate`, `baseSellRate` | KÉSZ | 🟢 | |
| P0.6.02 | **Limit 1/2/3 árfolyam-sávok** | `LIM1VETEL`, `LIM2VETEL`, `LIM3VETEL` + `LIMIT1`, `LIMIT2`, `LIMIT3` | `ExchangeRate.limit1BuyRate..limit3SellRate` + `getBuyRateForAmount()` | KÉSZ | 🟢 | Teljes implementáció |
| P0.6.03 | MNB elszámolási árfolyam | `ELSZAMOLASIARFOLYAM` | `ExchangeRate.officialRate` | KÉSZ | 🟢 | |
| P0.6.04 | **JPY 100 egységre adott árfolyam** | Az árfolyam 100 egységre szól, JPY 1000-re (speciális) | `ExchangeRate.baseBuyRate` — JPY-ra nincs megkülönböztetés | **ELTÉRÉS** | 🔴 | A Java `ExchangeRate` entitásban nincs `unitSize` mező vagy JPY-specifikus kezelés. Az árfolyam adatbázisban helyesen kell tárolni (**100-as egység**), de a JPY `/10` számítás hiányzik a `TransactionCalculationService`-ből |
| P0.6.05 | Árfolyam érvényességi idő | `DATUM`, `IDO` | `ExchangeRate.validDate`, `validTime` | KÉSZ | 🟢 | |
| P0.6.06 | Árfolyam archiválás (history) | Éves árfolyam tábla | `RateHistory` entitás | KÉSZ | 🟢 | |
| P0.6.07 | Eltérített árfolyam napló | `ARFOLYAMELTERITES` tábla | `RateDiscount` entitás + `RateApproval` | KÉSZ | 🟢 | |

**P0.6 Összesítés:** 7 elemből ~5 KÉSZ, ~0 RÉSZLEGES, ~2 ELTÉRÉS (JPY kritikus!)

---

### P0 ÖSSZESÍTŐ — KRITIKUS GAPEK

| Gap ID | Probléma | Érintett modulok | Kockázat | Becsült javítás |
|---|---|---|---|---|
| **GAP-P0-001** | **JPY /10 speciális logika hiányzik** | `TransactionCalculationService`, `ExchangeRate` entity | 🔴 KRITIKUS | 4 óra |
| **GAP-P0-002** | **`_rounder=0.001` kerekítési konstans hiányzik** | `TransactionCalculationService` | 🟠 MAGAS | 2 óra |
| **GAP-P0-003** | **SHK max 5/nap (Java: 3/nap) — konstans eltérés** | `HandlingFeeService` | 🟠 MAGAS | 1 óra |
| **GAP-P0-004** | **BIGCTRL.DLL workflow nincs implementálva** | `AmlService`, új `BigCtrlService`? | 🔴 KRITIKUS | 16 óra |
| **GAP-P0-005** | **Ügyfél napi limit reset napzárásnál hiányzik** | `DailyClosingService` → `CustomerService.resetDailyLimits()` | 🔴 KRITIKUS | 4 óra |
| **GAP-P0-006** | **SHK napi reset napzárásnál hiányzik** | `DailyClosingService` | 🟠 MAGAS | 2 óra |
| **GAP-P0-007** | **EUR érme konverzió nincs implementálva** | Új `EurCoinConversionService` | 🟠 MAGAS | 8 óra |
| **GAP-P0-008** | **Stornó hatása profitszámításra ellenőrizendő** | `ProfitCalculationService`, `Transaction.isActive()` | 🟠 MAGAS | 4 óra |
| **GAP-P0-009** | **Blokk fej/tétel éves archiválás hiányos** | `EveningClosingService` copy-lépések | 🔴 KRITIKUS | 8 óra |
| **GAP-P0-010** | **Kisügyfél real-time szinkron hiányzik** | `EveningClosingService` vs. real-time REST | 🟡 KÖZEPES | 12 óra |

**P0 kritikus gap összesítés: ~61 óra**

---


---

## S4 P1_INNER_RING_ATADAS_KESZLETEZES

### P1.1 — Értéktár Átadólap — `ERTEKTAR/etdll/atadolap` (64K)

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P1.1.01 | Átadólap struktúra (93 mező) | `_etData[]` tömb — értéktárszám, dátum, átadó/átvevő, pénzkészlet, tartozások, követelések, WU/ÁFA, banki be/kiszállítás, pénztári rendelések, körlevelek, szabad szöveg | `HandoverSheet` entitás | **RÉSZLEGES** | 🔴 | `HandoverSheet` entitás létezik, de csak egyszerű mezőkkel — a 93-mezős Delphi struktúra komplex részei (tartozások max 3 tétel, követelések max 3 tétel, banki be/kiszállítás max 4×4 mező) nincsenek részletesen implementálva |
| P1.1.02 | **Átadólap FTP szerverre küldés** | `FTPszerverbeBelep` → FTP-n XML csomag | `FtpSyncService` | RÉSZLEGES | 🟠 | `FtpSyncService` van, de az átadólap-specifikus FTP upload folyamat ellenőrizendő |
| P1.1.03 | Átadólap nyomtatás | Blokk nyomtató integráció | `HandoverSheetService.print()` | KÉSZ | 🟢 | |
| P1.1.04 | Átadólap DRAFT → PRINTED → COMPLETED workflow | Állapotgép | `HandoverSheetService` (DRAFT/PRINTED/COMPLETED) | KÉSZ | 🟢 | |
| P1.1.05 | Pénzkészlet egyezés/eltérés mező | `[5] Pénzkészlet: Egyezik`, `[6] Nem egyezik`, `[7] Eltérés` | `HandoverSheet` — van-e `denominationMatch` mező? | **HIÁNYZIK** | 🟠 | Az egyezési információ nincs implementálva az entitásban |
| P1.1.06 | Banki be/kiszállítás (max 4 tétel) | `[32-47]` és `[48-59]` mezők | Nincs `BankShipment` jellegű mező az átadólapon | **HIÁNYZIK** | 🔴 | A banki forgalom átadólapon való dokumentálása hiányzik — ez a bank↔értéktár mozgás alapbizonylata |

**P1.1 Összesítés:** 6 elemből ~2 KÉSZ, ~2 RÉSZLEGES, ~2 HIÁNYZIK

---

### P1.2 — Értéktár Átadás-vétel — `ERTEKTAR/etdll/atadvet` (138K)

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P1.2.01 | Értéktárközi devizamozgás | `TAtadvetForm` — értéktár→pénztár átadás | `VaultTransferService` | KÉSZ | 🟢 | |
| P1.2.02 | WAC (Weighted Average Cost) kezelés átadásnál | Kiadáskor aktuális WAC, átvételkor WAC frissítés | `VaultTransferService` — WAC logika | KÉSZ | 🟢 | |
| P1.2.03 | 5M HUF feletti supervisor threshold | `SUPERVISOR_THRESHOLD = 5000000` | `VaultTransferService.SUPERVISOR_THRESHOLD = 5000000` | KÉSZ | 🟢 | |
| P1.2.04 | **REQUESTED → IN_PROGRESS → COMPLETED → REJECTED állapotgép** | Kézzel kezelve | `VaultOperationStatus` enum | KÉSZ | 🟢 | |
| P1.2.05 | Átadás bizonylat generálás | Külön bizonylat (nem pénztári) | `TransferDocumentService` | KÉSZ | 🟢 | |
| P1.2.06 | **Értéktár stornó** | `ERTEKTAR/etdll/storno` — külön stornó workflow | `StornoService` (értéktár ág?) | **RÉSZLEGES** | 🟠 | Az értéktári stornó a pénztáritól eltérő munkafolyamat — ellenőrizni, hogy a `StornoService` kezeli-e az értéktári eseteket |
| P1.2.07 | Cimletszintű nyilvántartás átadásnál | Bankjegy típusonkénti darabszám × névérték | `DenominationBalance` + `DenominationCount` | KÉSZ | 🟢 | |

**P1.2 Összesítés:** 7 elemből ~5 KÉSZ, ~2 RÉSZLEGES

---

### P1.3 — Készletkezelés — `ERTEKTAR/etdll/keszup`, `keszedit`, `ptarkesz`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P1.3.01 | Készlet feltöltő (értéktár → szerver push) | `keszup` DLL → szerver oldali frissítés | `VaultCollectionService` | **RÉSZLEGES** | 🔴 | `VaultCollectionService` csak REQUESTED státuszra hoz létre rekordot — a szerver-oldali tényleges készlet push nincs implementálva |
| P1.3.02 | **Kézi készlet korrekció** | `keszedit` DLL — supervisor jóváhagyás + napló | `StockCorrectionService` | RÉSZLEGES | 🟠 | `StockCorrectionService` létezik, de a Delphi supervisor jóváhagyás + auditnapló mélység ellenőrizendő |
| P1.3.03 | Pénztárkészlet lekérés értéktárból | `ptarkesz` DLL — értéktári nézet a pénztárak készletéről | `StockSnapshotService` | KÉSZ | 🟢 | |
| P1.3.04 | **Pillanatnyi készlet + grafikon** | `pillkesz` DLL — real-time grafikonos készlet | `StockSnapshotService` | RÉSZLEGES | 🟡 | Service létezik, de grafikon adat (grafikon-ready aggregáció) ellenőrizendő |
| P1.3.05 | Pillanatnyi állapot összesítő | `pillall` DLL | `DashboardService` + `CashBalanceService` | KÉSZ | 🟢 | |
| P1.3.06 | Készlet regenerálás | `regen` DLL | `InventoryRegenerationService` | KÉSZ | 🟢 | |
| P1.3.07 | Készlet snapshot Excel | `makeszlt` + `excel` | `StockSnapshotExcelService` | RÉSZLEGES | 🟡 | Service létezik, de Delphi 3 Excel-sheet struktúra (körzet/szint) ellenőrizendő |
| P1.3.08 | **WAC (WAC = Weighted Average Cost)** | WAC számítás banki vásárlásnál | `WacService` | KÉSZ | 🟢 | Java-specifikus `WacService` |
| P1.3.09 | Anyagpénztár (MATPTAR) | `matptar` DLL — egyéb anyagok kezelése | `MaterialReceiptService` | KÉSZ | 🟢 | |

**P1.3 Összesítés:** 9 elemből ~5 KÉSZ, ~4 RÉSZLEGES

---

### P1.4 — Ügyfélkezelés — `SZERVER/fejleszt/ugyfelcontrol`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P1.4.01 | Ügyfél létrehozás | `ugyfcreat` DLL | `CustomerService.create()` | KÉSZ | 🟢 | |
| P1.4.02 | Ügyfél módosítás | `uctrl/mend` DLL | `CustomerService.update()` | KÉSZ | 🟢 | |
| P1.4.03 | Ügyfél keresés | `ugyfseek` DLL + `nevseek` DLL | `CustomerService.search()` | KÉSZ | 🟢 | |
| P1.4.04 | **Terror napló** | `terrornaplo` DLL — ENSZ terror lista egyeztetés + napló | `AmlService` (terror napló ág) | RÉSZLEGES | 🔴 | `AmlService` van, de a Delphi terrornapló részletes napló-struktúrája (esemény típus, forrás, kockázati szint) ellenőrizendő |
| P1.4.05 | **Évi maximum tranzakciók** | `evimax` DLL — éves határ figyelés | `AmlService` (threshold ág) | RÉSZLEGES | 🔴 | `AmlThreshold` entitás van, de az éves kumulatív tracking ellenőrizendő (nem csak napi) |
| P1.4.06 | Tiltások kezelés | `letilt` + `tiltasok` DLL | `BlacklistService` + `CustomerRestriction` | KÉSZ | 🟢 | |
| P1.4.07 | **Ügyfél adatgyűjtés** | `adatgyujto` DLL — rendszeres adatgyűjtés legyűjtéshez | `DataCollectionService` | RÉSZLEGES | 🟡 | Service létezik, de a Delphi hierarchikus adatgyűjtés (pénztár→körzet→cég) nem teljes |
| P1.4.08 | Excel export ügyfél adatokhoz | `excel` DLL + `makeexcel` DLL | `ReportExportService` | RÉSZLEGES | 🟡 | |
| P1.4.09 | Okmány display és kezelés | `okmdisp` DLL | `DocumentStorageService` | KÉSZ | 🟢 | |
| P1.4.10 | Személyes adatok keresés/töltés | `personal/kereso+perseek+tolto` | `CustomerService` + `DataImportService` | RÉSZLEGES | 🟡 | |
| P1.4.11 | **Napi ügyfél limit (`NAPIGONGYOLTFORINT`)** | `UGYFEL.NAPIGONGYOLTFORINT` — napi összesített HUF | `Customer` entitás — `dailyCumulativeHuf` mező? | **ELTÉRÉS** | 🔴 | Az entitásban nem látjuk a napi kumulatív limit mezőt. Ha nem létezik, az AML napi limit tracking teljes egészében hiányzik. |
| P1.4.12 | Jogi személy adatok | `jogiszemely` modul | `CustomerService` (jogi személy ág) | RÉSZLEGES | 🟡 | Jogi személy entitás van, de a részletesebb logika (KFT ügyfél edge case) ellenőrizendő |

**P1.4 Összesítés:** 12 elemből ~5 KÉSZ, ~6 RÉSZLEGES/ELTÉRÉS, ~1 HIÁNYZIK implicit

---

### P1.5 — Bizonylat rendszer

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P1.5.01 | Bizonylat megjelenítés és keresés | `BIZODISP` (48K) | `ReceiptSearchService` + `ReceiptController` | KÉSZ | 🟢 | |
| P1.5.02 | **Blokk/nyugta nyomtatás (POS)** | `BLOKNYOM` (58K) → `bloknyom.dll` | `EscPosReceiptService` | KÉSZ | 🟢 | |
| P1.5.03 | Nyugta lekérés | `GETNYUGT` (6K) | `ReceiptService` | KÉSZ | 🟢 | |
| P1.5.04 | **NAV XML bizonylat** | `MakeXml` → NAV kompatibilis XML | `NavAbevXmlGenerator` | KÉSZ | 🟢 | |
| P1.5.05 | QR kód bizonylaton | `QrKodLerendezes` | `QrCodeService` | KÉSZ | 🟢 | |
| P1.5.06 | **Bizonylat kötelező mezők (törvényi)** | ÁFA-mentesség, ügyfél adatok 300K+, iroda azonosító KÖTELEZŐ | `ReceiptGeneratorService` mezők | RÉSZLEGES | 🔴 | A `lessons-consolidated` megjegyzi: ReceiptPrint mezői jogszabályból jönnek. Ellenőrizni kell, hogy az összes törvényi mező kitöltött (pl. iroda azonosító, ÁFA megjegyzés) |
| P1.5.07 | Bizonylat sorszám szekvencia | `ReceiptSequenceService` | `ReceiptSequenceService` | KÉSZ | 🟢 | |
| P1.5.08 | PDF bizonylat generálás | Delphi: nyomtató DLL | `ReceiptPdfService` | KÉSZ | 🟢 | Java-specifikus kiegészítés |

**P1.5 Összesítés:** 8 elemből ~6 KÉSZ, ~2 RÉSZLEGES

---

### P1.6 — Szinkronizáció (helga/frissdat)

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P1.6.01 | Irodák közti adatszinkron | `frissdat` + `helga/locserver` | `SynchronizationService` + `SyncService` | RÉSZLEGES | 🔴 | A HELGA lokális szerver 37 form — koordinátor, pénztárak közötti szinkron. Java `SynchronizationService` + `SyncInboundController` részlegesen fedi |
| P1.6.02 | **Bejövő szinkron esemény feldolgozás** | FTP-alapú bináris csomag kezelés | `SyncInboundEventService` | RÉSZLEGES | 🟠 | JSON REST, nem bináris FTP csomag — architektúra különbség elfogadható, de az összes eseménytípus lefedve? |
| P1.6.03 | Kimenő szinkron outbox | `SZERVER/fejleszt/senddata` | `SyncOutboxEvent` entitás + `OutboxSyncWorkerService` | KÉSZ | 🟢 | |
| P1.6.04 | **Esti bináris csomag (ESTIZAR)** | PutByte/PutWord/PutInteger/PutString → FTP port 21100 | `EveningClosingService` (JSON REST) | RÉSZLEGES | 🟡 | Az architektúra különbség (bináris FTP → JSON REST) tudatos döntés, de az összes adat átmegy-e? |
| P1.6.05 | FTP szinkron | `FTPszerverbeBelep` + `COPY2FTP` DLL | `FtpSyncService` | KÉSZ | 🟢 | |
| P1.6.06 | Iroda tábla másoló | `irtmk` DLL | `SyncService` | RÉSZLEGES | 🟡 | |
| P1.6.07 | Neon replikáció (PostgreSQL) | N/A Delphi — Java-specifikus | `NeonReplicationService` | KÉSZ | 🟢 | Java-specifikus kiegészítés (cloud DB replikáció) |

**P1.6 Összesítés:** 7 elemből ~3 KÉSZ, ~4 RÉSZLEGES

---

### P1 ÖSSZESÍTŐ — KRITIKUS GAPEK

| Gap ID | Probléma | Érintett modulok | Kockázat | Becsült javítás |
|---|---|---|---|---|
| **GAP-P1-001** | **Átadólap 93 mező nem teljes (banki be/kiszállítás hiányzik)** | `HandoverSheet` entitás kibővítés | 🔴 KRITIKUS | 20 óra |
| **GAP-P1-002** | **Ügyfél napi limit (`NAPIGONGYOLTFORINT`) entitás mezője** | `Customer` entitás + `AmlService` | 🔴 KRITIKUS | 8 óra |
| **GAP-P1-003** | **Készlet feltöltő szerver push hiányzik** | `VaultCollectionService` → szerver push | 🔴 KRITIKUS | 16 óra |
| **GAP-P1-004** | **Terror napló részletesség** | `AmlService` terror napló szekció | 🔴 KRITIKUS | 10 óra |
| **GAP-P1-005** | **HELGA lokális szerver komplex workflow (~60 óra)** | `SynchronizationService` mélységű kibővítés | 🔴 KRITIKUS | 60 óra |
| **GAP-P1-006** | **Bizonylat törvényi mezők teljesség** | `ReceiptGeneratorService` audit | 🔴 KRITIKUS | 4 óra |
| **GAP-P1-007** | **Évi maximum tranzakció tracking** | `AmlService` + éves kumulatív lekérdezés | 🟠 MAGAS | 8 óra |

**P1 kritikus gap összesítés: ~126 óra**

---


---

## S5 P2_OUTER_RING_ERTEKTARBANK_MNB_KONYVELES

### P2.1 — Értéktár↔Bank tranzakciók — `ERTEKTAR/etdll/matptar` + `SZERVER/ujdll/bankforg`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P2.1.01 | **Bank → értéktár valuta vétel (BUY)** | Valuta betöltés bankból → készlet nő, HUF csökken | `VaultBankTransactionService.createTransaction(BUY)` | KÉSZ | 🟢 | |
| P2.1.02 | **Értéktár → bank valuta eladás (SELL)** | Valuta kiszállítás bankba → készlet csökken, HUF nő | `VaultBankTransactionService.createTransaction(SELL)` | KÉSZ | 🟢 | |
| P2.1.03 | WAC frissítés banki vásárlásnál | BUY: WAC = árfolyam | `WacService` | KÉSZ | 🟢 | |
| P2.1.04 | **Bank forgalom DLL (`ujdll/bankforg`)** | Banki mozgások összesítése (körzet, cég szint) | `VaultBankTransactionService` | RÉSZLEGES | 🟠 | Tranzakció-szintű kezelés van, de a körzet és cég szintű aggregáció ellenőrizendő |
| P2.1.05 | Banki utalás szállítás (SZALLITAS) | `ShipmentRequest` — banki szállítás igénylés | `ShipmentService` + `ShipmentRequest` entitás | KÉSZ | 🟢 | |
| P2.1.06 | Átlagárfolyam számítás (banki szint) | `ujdll/atlagarf` DLL — súlyozott átlag, time-weighted | `RateCalculationService` | RÉSZLEGES | 🟠 | `RateCalculationService` létezik, de az exact Delphi time-weighted átlagszámítás (havi súlyozás módja) ellenőrizendő |

**P2.1 Összesítés:** 6 elemből ~4 KÉSZ, ~2 RÉSZLEGES

---

### P2.2 — MNB adatszolgáltatás — `SZERVER/ujdll/mnbgyujto`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P2.2.01 | **Napi MNB riport generálás** | `MnbReportService.generateDailyReport()` | `MnbReportService.generateDailyReport()` | KÉSZ | 🟢 | |
| P2.2.02 | **Háromszintű aggregáció: pénztár→körzet→cég** | `ForgalomGyujtes`, `KorzetSumma`, `KftSumma`, `CegSumma` | `MnbReportService` — iroda szintű, de körzet/KFT szint? | **RÉSZLEGES** | 🔴 | A Java `MnbReportService` iroda szintű aggregációt végez, de a Delphi háromszintű (pénztár→körzet→cég) aggregáció nem implementált. MNB riport pontossága kérdéses. |
| P2.2.03 | F és U bizonylat feldolgozás | `FBizonylatFeldolgozo`, `UBizonylatFeldolgozo` | `MnbReportService` | **RÉSZLEGES** | 🔴 | F (fizikai) és U (utalás?) bizonylattípus megkülönböztetés nem implementált |
| P2.2.04 | Nyitó/záró/forgalom minden valutanemhez | `NyitoKeszlet`, `ZaroKeszlet` tracking | `MnbReport` + `MnbReportLine` entitások | KÉSZ | 🟢 | |
| P2.2.05 | **MNB bejelentés DLL** | `ujdll/bejelentes` — MNB-nek XML küldés | `MnbApiClient` | RÉSZLEGES | 🟠 | API kliens van, de a teljes bejelentési workflow (retry, státusz tracking) ellenőrizendő |
| P2.2.06 | Heti/havi MNB riport | Delphi-ban napi + havi aggregálás | `MnbReportService.generatePeriodReport()` | KÉSZ | 🟢 | |

**P2.2 Összesítés:** 6 elemből ~3 KÉSZ, ~3 RÉSZLEGES

---

### P2.3 — Értéktár Napi Zárás — `ERTEKTAR/etdll/napzar` (1039+ sor)

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P2.3.01 | `BFCopy` — bankforgalom másolás | Banki mozgások másolása az értéktári összesítőbe | `EveningClosingService` | RÉSZLEGES | 🔴 | |
| P2.3.02 | `BTCopy` — banktétel másolás | Banki tételek archiválás | `EveningClosingService` | RÉSZLEGES | 🔴 | |
| P2.3.03 | `CIMTCopy` — cimlet tábla másolás | Cimlet egyenleg snapshot archiválás | `DenominationBalanceService` | RÉSZLEGES | 🟠 | |
| P2.3.04 | `NarfCopy` — névleges árfolyam másolás | Napi névleges árfolyamok archív | `RateHistoryService` | RÉSZLEGES | 🟠 | |
| P2.3.05 | `WuniCopy` — WU összesítő másolás | Western Union napi összesítő archiválás | `WesternUnionService` | RÉSZLEGES | 🟡 | |
| P2.3.06 | `WzarCopy` — WU záró másolás | WU záró egyenleg | `WesternUnionService` | RÉSZLEGES | 🟡 | |
| P2.3.07 | `EdatCopy` — dátum másolás | Zárás dátum metaadat | `EveningClosingService` | RÉSZLEGES | 🟡 | |
| P2.3.08 | `EkerCopy` — értékkamat másolás | Értékkamat archív | Nincs dedikált service | **HIÁNYZIK** | 🟠 | |
| P2.3.09 | `KDatCopy` — kötelező adatok másolás | Kötelező nyilvántartási adatok archiválás | Részben `EveningClosingService` | **RÉSZLEGES** | 🟠 | |
| P2.3.10 | `KezdijCopy` — kezelési díj másolás | Kezelési díj összesítő archiválás | `HandlingFeeDecadeService` | RÉSZLEGES | 🟠 | |
| P2.3.11 | `HaviGyujtokbeMasolas` — havi gyűjtőkbe másolás | Napi adatok havi aggregátumba emelése | `MonthlyArchiveService` | RÉSZLEGES | 🟠 | |
| P2.3.12 | Értéktár esti záras összesítés | `estizar` DLL | `EveningClosingService` | KÉSZ | 🟢 | |
| P2.3.13 | Értéktár napi jelzés | `napijel` DLL (1557+ sor, 10+ panel) | `DailyReportService` + `ErtektarController` | **RÉSZLEGES** | 🔴 | A `napijel` 1557+ soros, rendkívül komplex (10+ árfolyam panel, WU, cimlet, napi DE/DU bontás). A Java `DailyReportService` lényegesen kevesebb adatot jelenít meg. |
| P2.3.14 | Értéktár napi kezdés | `napikezd` DLL — készlet nyomtatás, nyitó rekord | `SessionOpenService` | RÉSZLEGES | 🟠 | |

**P2.3 Összesítés:** 14 elemből ~2 KÉSZ, ~10 RÉSZLEGES, ~2 HIÁNYZIK

---

### P2.4 — Értéktár Napi Könyv + Havi Zárás

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P2.4.01 | **Napi könyv — teljes nap összes tranzakciója** | `napkonyv` DLL — lista minden tranzakcióról | `DailyReportService` + `TransactionReportService` | RÉSZLEGES | 🔴 | Tranzakció lista kérdezhető, de a Delphi `napkonyv` formázott lista (cimlet bontás, devizánként részletezve) nem implementált |
| P2.4.02 | Havi zárás (értéktár) | `havizar` DLL | `MonthlyClosingService` + `HrkMonthlyClosingService` | RÉSZLEGES | 🟠 | |
| P2.4.03 | Havi összesítő tablo | `havitablo` modul | `MonthlyReportService` | RÉSZLEGES | 🟡 | |
| P2.4.04 | **Évfordítás** | `newyear` DLL + `evnyito` modul | `ArchivingService` | RÉSZLEGES | 🔴 | Az évfordítás kritikus: régi rekordok archiválás, új nyitó készletek, sorszám reset — a `ArchivingService` ellenőrizendő |

**P2.4 Összesítés:** 4 elemből ~0 KÉSZ, ~4 RÉSZLEGES

---

### P2.5 — Könyvelési Export — `SZERVER/fejleszt/booking`

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P2.5.01 | **Adásvétel Excel export** | `booking/advetexcel` — könyvelési Excel | `BookingExportService.exportDailyBooking()` | RÉSZLEGES | 🟠 | Java CSV-t exportál (UTF-8 BOM), de Delphi Excel (több sheet, körzet-szintű) |
| P2.5.02 | Forgalom Excel export | `booking/forgexel` | `BookingExportService` | RÉSZLEGES | 🟠 | |
| P2.5.03 | Készlet Excel export | `booking/keszexcel` | `StockSnapshotExcelService` | RÉSZLEGES | 🟡 | |
| P2.5.04 | **Körzet-szintű összesítő könyvelési export** | Körzet + cég szintű aggregáció | `CentralReportService` | RÉSZLEGES | 🟠 | A `CentralReportService` létezik, de a Delphi körzet-szintű multi-sheet Excel struktúra nem implementált |
| P2.5.05 | Haszonszámítás (profit) | `haszon/unit1-5` — bizonylat-szintű árfolyam-különbözet | `ProfitCalculationService` | RÉSZLEGES | 🟠 | Service létezik, de kedvezmény-korrekció és stornó hatás ellenőrizendő |

**P2.5 Összesítés:** 5 elemből ~0 KÉSZ, ~5 RÉSZLEGES

---

### P2.6 — Tranzakció Díj napi/havi bedolgozás — `SZERVER/ujdll/tranzakc` (1659+ sor)

| # | Delphi funkció | Delphi implementáció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P2.6.01 | Napi bedolgozás | `NAPIBEDOLGGOMBClick` | `HandlingFeeDecadeService` | RÉSZLEGES | 🔴 | |
| P2.6.02 | Havi bedolgozás | `HAVIBEDOLGGOMBClick` | `MonthlyReportService` | RÉSZLEGES | 🔴 | |
| P2.6.03 | Elszámolás tábla kontrol | `ElszamTablaControl` | Nincs dedikált service | **HIÁNYZIK** | 🔴 | |
| P2.6.04 | Forgalom gyűjtés | `ForgalomGyujtes` | `TurnoverService` | RÉSZLEGES | 🟠 | |
| P2.6.05 | Konverzió forgalom | `KonverzioForgalom` | `TransactionConversionService` | RÉSZLEGES | 🟠 | |
| P2.6.06 | Eladás forgalom | `EladasForgalom` | `TurnoverService` | RÉSZLEGES | 🟠 | |
| P2.6.07 | **BEST/ALL/EAST/PANNON kategória szortírozás** | Körzetszintű kategória besorolás | Nincs implementálva | **HIÁNYZIK** | 🔴 | Ez a kategória-rendszer az EBC-specifikus üzleti logika — pénztáros elszámolás alapja |
| P2.6.08 | Árfolyam különbözet alapú elszámolás | `Getelszarfarfolyam` | `ProfitCalculationService` | RÉSZLEGES | 🟠 | |

**P2.6 Összesítés:** 8 elemből ~0 KÉSZ, ~5 RÉSZLEGES, ~3 HIÁNYZIK

---

### P2 ÖSSZESÍTŐ — KRITIKUS GAPEK

| Gap ID | Probléma | Érintett modulok | Kockázat | Becsült javítás |
|---|---|---|---|---|
| **GAP-P2-001** | **MNB háromszintű aggregáció hiányzik** | `MnbReportService` | 🔴 KRITIKUS | 20 óra |
| **GAP-P2-002** | **Értéktár napi zárás 10 copy-lépés nem implementált** | `EveningClosingService` / `DailyClosingService` | 🔴 KRITIKUS | 30 óra |
| **GAP-P2-003** | **Értéktár napi jelentes 10+ panel hiányos** | `DailyReportService` / `ErtektarController` | 🔴 KRITIKUS | 32 óra |
| **GAP-P2-004** | **BEST/ALL/EAST/PANNON kategória szortírozás hiányzik** | `CommissionCalculationService` | 🔴 KRITIKUS | 16 óra |
| **GAP-P2-005** | **Elszámolás tábla kontrol hiányzik** | Új `AccountingReconciliationService` | 🔴 KRITIKUS | 12 óra |
| **GAP-P2-006** | **Évfordítás workflow ellenőrizendő** | `ArchivingService` | 🔴 KRITIKUS | 20 óra |
| **GAP-P2-007** | **Könyvelési export: CSV vs. multi-sheet Excel** | `BookingExportService` | 🟠 MAGAS | 12 óra |

**P2 kritikus gap összesítés: ~142 óra**

---


---

## S6 P3_PERIPHERY_SZERVER_ADMIN

### P3.1 — Szerver Admin funkciók

| # | Delphi modul | Funkció | Java megfelelő | Státusz | Kockázat | Gap leírás |
|---|---|---|---|---|---|---|
| P3.1.01 | `helga/locserver` (37 form) | Helyi szerver koordinátor | `SynchronizationService` | RÉSZLEGES | 🔴 | ~60 óra fejlesztés |
| P3.1.02 | `recptor` | Receptor (pénztár kliens kezelő) | `CashRegisterService` + `WorkstationService` | RÉSZLEGES | 🟠 | ~30 óra |
| P3.1.03 | `police/unit1-2` | Rendőrségi adatszolgáltatás | `PoliceRequestController` | RÉSZLEGES | 🔴 | ~20 óra |
| P3.1.04 | `newyear` | Évnyitó | `ArchivingService` | RÉSZLEGES | 🔴 | ~20 óra |
| P3.1.05 | `summa/unit1-2` | Összefoglaló összesítők | `TurnoverService` + `ProfitCalculationService` | RÉSZLEGES | 🟠 | ~24 óra |
| P3.1.06 | `verseny/unit1-5` | Verseny számítás | `CompetitionService` + `WorkerCompetitionService` | RÉSZLEGES | 🟡 | ~20 óra |
| P3.1.07 | `jutszamito` + `jutszazalek` | Jutalékszámítás | `WorkerCommissionService` + `CommissionCalculationService` | RÉSZLEGES | 🟠 | ~24 óra (BEST/ALL/EAST/PANNON kiegészítéssel ~36 óra) |
| P3.1.08 | `western/unit1` | WU szerveri összesítő | `WesternUnionService` + `CentralReportService` | RÉSZLEGES | 🟡 | ~20 óra |
| P3.1.09 | `sumwuafa` + `wuafatranz` | WU + ÁFA összesítő | `WesternUnionService` + `VatRefundService` | RÉSZLEGES | 🟡 | ~16 óra |
| P3.1.10 | `statiszt` | Statisztika (ügyfél-azonosítás) | `CustomerControlService` + `AmlService` | RÉSZLEGES | 🟡 | ~12 óra |
| P3.1.11 | `haszon/unit1-5` | Haszonszámítás teljes | `ProfitCalculationService` | RÉSZLEGES | 🟠 | ~24 óra |
| P3.1.12 | `archival/unit1` | Éves archiválás | `ArchivingService` | RÉSZLEGES | 🟠 | ~8 óra |
| P3.1.13 | `evnyito/unit1` | Évnyitó (éves kezdőkészletek) | `SessionOpenService` | RÉSZLEGES | 🔴 | ~16 óra |
| P3.1.14 | `ptforg/unit1-4` | Pénztár forgalom összesítő | `TurnoverService` + `ReportService` | RÉSZLEGES | 🟡 | ~20 óra |
| P3.1.15 | `monegram` | MoneyGram integráció | **NINCS** | **HIÁNYZIK** | 🟡 | ~40 óra (csak ha aktív MG integráció van) |
| P3.1.16 | `lemento/unit1-2` | Lementő (adat mentés) | `BackupService` | RÉSZLEGES | 🟡 | ~8 óra |
| P3.1.17 | `foglalo/unit1` | Foglalás összesítő | `ReservationService` | RÉSZLEGES | 🟡 | ~12 óra |
| P3.1.18 | `ugyfelcontrol` | Ügyfélcontrol főmodul | `AmlService` + `CustomerControlService` + `BlacklistService` | RÉSZLEGES | 🟠 | ~30 óra |
| P3.1.19 | `bejelentes` | MNB bejelentés workflow | `MnbReportService` | RÉSZLEGES | 🟠 | ~8 óra |
| P3.1.20 | `mnbgyujto/mnbhibak` | MNB gyűjtő DLL komplex | `MnbReportService` | RÉSZLEGES | 🔴 | ~20 óra |
| P3.1.21 | `zarasctrl` | Zárás kontroler DLL | `DailyClosingService` + `ClosingWizardService` | RÉSZLEGES | 🟠 | ~16 óra |
| P3.1.22 | `beerkezes` + `beerkctrl` | Beerkezés DLL (napkezdés) | `SessionOpenService` + `DailySessionService` | RÉSZLEGES | 🟠 | ~12 óra |
| P3.1.23 | `dbookctrl` | DayBook kontrol | `DailySessionService` | RÉSZLEGES | 🟡 | ~8 óra |
| P3.1.24 | `frissdat` | Adatfrissítés pénztárak között | `SyncService` | RÉSZLEGES | 🟠 | ~10 óra |
| P3.1.25 | `tranzdb/unit1` | Tranzakció DB lekérdező | `TransactionController` | KÉSZ | 🟢 | |
| P3.1.26 | `korlevel/zsuzsa` | Körlevél (évnyitó) | `CircularService` | RÉSZLEGES | 🟡 | ~8 óra |
| P3.1.27 | `litenews` | Értesítő küldés | `NotificationService` | KÉSZ | 🟢 | |
| P3.1.28 | `napiment` | Napi mentés scheduler | `SchedulerService` + `BackupService` | KÉSZ | 🟢 | |
| P3.1.29 | `tiltcopy` | Tiltólista propagálás | `BlacklistService` | KÉSZ | 🟢 | |
| P3.1.30 | `terror/maketerrlist` | Terror lista generátor | `SanctionScreeningService` | KÉSZ | 🟢 | |
| P3.1.31 | `palyadij` | Pályázati díj kezelés | `ContributionService` | RÉSZLEGES | 🟡 | ~6 óra |
| P3.1.32 | `uctrl/regeneral` | Ügyfélcontrol regenerálás | `InventoryRegenerationService` | KÉSZ | 🟢 | |
| P3.1.33 | `uctrl/svisor` | Supervisor modul | `SupervisorService` | KÉSZ | 🟢 | |
| P3.1.34 | `hrkvetel` | HRK vétel | `HrkService` | KÉSZ | 🟢 | |
| P3.1.35 | `idbeiro` | Azonosítás beíró | `DocumentStorageService` + `CustomerService` | RÉSZLEGES | 🟡 | ~8 óra |
| P3.1.36 | `jelenlet` | Jelenlét | `WorkerAttendance` entitás | KÉSZ | 🟢 | |
| P3.1.37 | `okmctrl` | Okmány ellenőrzés | `DocumentScannerService` | RÉSZLEGES | 🟡 | ~8 óra |

### P3.2 — SZERVER Ujdll — Teljesen kész modulok

| Delphi modul | Java megfelelő | Státusz |
|---|---|---|
| `arftmk` | `RateCreationService` | KÉSZ |
| `datadisp` | `DashboardService` | KÉSZ |
| `dolgozok` | `WorkerService` | KÉSZ |
| `forgalomdisp` | `LedDisplayService` | KÉSZ |
| `getdisp` | `DashboardService` | KÉSZ |
| `getuzlet` | `BranchService` | KÉSZ |
| `hovalasz` | `SyncService` | KÉSZ |
| `hrkserver` | `HrkService` | KÉSZ |
| `idoszak` | `ReportService` | KÉSZ |
| `keszletdisp` | `InventoryService` | KÉSZ |
| `kezdtranzdisp` | `DashboardService` | KÉSZ |
| `stornodisp` | `StornoService` | KÉSZ |
| `trbdisp` | `CashBalanceService` | KÉSZ |
| `userbelep` | `AuthController` | KÉSZ |
| `wunidisp` | `WesternUnionService` | KÉSZ |

### P3.3 — SZERVER Ujdll — Részleges modulok

| Delphi modul | Java megfelelő | Státusz | Becsült munka |
|---|---|---|---|
| `atlagarf` | `RateCalculationService` | RÉSZLEGES | 8 óra |
| `bankforg` | `VaultBankTransactionService` | RÉSZLEGES | 10 óra |
| `import` | `DataImportService` | RÉSZLEGES | 6 óra |
| `irtmk` | `SyncService` | RÉSZLEGES | 6 óra |
| `jutszamito` | `WorkerCommissionService` | RÉSZLEGES | 24 óra |
| `jutszazalek` | `CommissionRateService` | RÉSZLEGES | 12 óra |
| `kezdij` | `HandlingFeeService` | RÉSZLEGES | 10 óra |
| `mnbgyujto` | `MnbReportService` | RÉSZLEGES | 20 óra |
| `mnbhibak` | `MnbReportService` | RÉSZLEGES | 6 óra |
| `ptarkozott` | `PackagingService` + `StampService` | RÉSZLEGES | 8 óra |
| `sumwuafa` | `WesternUnionService` + `VatRefundService` | RÉSZLEGES | 16 óra |
| `tranzakc` | `TransactionService` + `TransactionReportService` | RÉSZLEGES | 30 óra |
| `western` | `WesternUnionService` | RÉSZLEGES | 12 óra |
| `wuafatranz` | `WesternUnionService` + `VatRefundService` | RÉSZLEGES | 12 óra |
| `zarasctrl` | `DailyClosingService` + `ClosingWizardService` | RÉSZLEGES | 16 óra |

### P3.4 — ERTEKTAR Fejleszt modulok

| Delphi modul | Java megfelelő | Státusz | Gap leírás |
|---|---|---|---|
| `frissito` | `VersionController` + `FtpSyncService` | KÉSZ | |
| `newyear` | `ArchivingService` | RÉSZLEGES | 8 óra |
| `permit` | `PermissionController` | KÉSZ | |

### P3.5 — VALUTA Delta modulok

| Delphi modul | Java megfelelő | Státusz | Gap leírás |
|---|---|---|---|
| `QRGENER` | `QrCodeService` | KÉSZ | |
| `QRDEPUTY` | `AuthorizationController` | RÉSZLEGES | 6 óra |
| `SCANNING` / `UJSCANNER` | `DocumentScannerService` | KÉSZ | |
| `SENDOKMANY` / `DOCDISP` | `DocumentStorageService` | KÉSZ | |
| `TEAOR` | `CustomerService` | RÉSZLEGES | 4 óra |
| **`METRO`** | **NINCS** | **HIÁNYZIK** | ~8 óra |
| **`TESCO`** | **NINCS** | **HIÁNYZIK** | ~8 óra |
| `PAUSDISP` | `CashDeskBreakService` | KÉSZ | |
| `GETSTATUS` | `BranchMonitoringService` | KÉSZ | |
| `GETWCEG` / `GETWUGYF` | `WesternUnionService` | KÉSZ | |
| `OTHERTSK` | `SchedulerService` | KÉSZ | |
| `XTRANZ` | `TransactionService` | RÉSZLEGES | 8 óra |
| **`FNYUJSAG` (15+ helyszín)** | `ExchangeRateDisplayService` + `LedDisplayService` | RÉSZLEGES | ~20 óra |
| `COPY2FTP` | `FtpSyncService` | KÉSZ | |
| `PROCEND` | `SchedulerService` | KÉSZ | |
| **`VALUTA/TRADE/fejleszt`** | `TradeController` + `TradeService` | RÉSZLEGES | ~40 óra |
| **`IBVALTO/unit1`** | Frontend + Backend | RÉSZLEGES | ~60 óra |

### P3.6 — NEM KELL (WONT)

| Delphi modul | Miért nem kell |
|---|---|
| `gbakall`, `fdbtomorito`, `fdbtorlo` | Firebird backup → PostgreSQL + pgdump váltotta ki |
| `remaltib` | Fejlesztői DB böngésző |
| `uctrl/butitott` | Fejlesztői debug mód |
| `recptor/orecept` | Már lefutott migráció |
| `GONGBACK` | UI hangvisszajelző |
| `pictload` | UI képbetöltő |
| `quitform` | UI kilépő form |
| `_arfteszt` | Fejlesztői árfolyam teszt |
| `unpacker` | Firebird-specifikus csomagkezelő |
| `kdchange` | Egyszeri migráció |
| `confident` | Legacy bizalmas adatok (integrálva) |

---


---

## S7 TELJES_GAP_OSSZESITO_TABLAZAT

### P0 — MAG kritikus gapek (összesen)

| Gap ID | Delphi funkció | Java megfelelő | Státusz | Kockázat | Becsült munka |
|---|---|---|---|---|---|
| GAP-P0-001 | JPY /10 speciális logika | `TransactionCalculationService` | HIÁNYZIK | 🔴 | 4 óra |
| GAP-P0-002 | `_rounder=0.001` kerekítési konstans | `TransactionCalculationService` | ELTÉRÉS | 🟠 | 2 óra |
| GAP-P0-003 | SHK max 5/nap (Java: 3/nap) | `HandlingFeeService` | ELTÉRÉS | 🟠 | 1 óra |
| GAP-P0-004 | BIGCTRL.DLL workflow | Új `BigCtrlService` | HIÁNYZIK | 🔴 | 16 óra |
| GAP-P0-005 | Ügyfél napi limit reset napzárásnál | `DailyClosingService.resetDailyLimits()` | HIÁNYZIK | 🔴 | 4 óra |
| GAP-P0-006 | SHK napi reset napzárásnál | `DailyClosingService` | HIÁNYZIK | 🟠 | 2 óra |
| GAP-P0-007 | EUR érme konverzió | Új `EurCoinConversionService` | HIÁNYZIK | 🟠 | 8 óra |
| GAP-P0-008 | Stornó hatása profitszámításra | `ProfitCalculationService` audit | RÉSZLEGES | 🟠 | 4 óra |
| GAP-P0-009 | Blokk fej/tétel éves archiválás | `EveningClosingService` copy | RÉSZLEGES | 🔴 | 8 óra |
| GAP-P0-010 | Kisügyfél real-time szinkron | `EveningClosingService` | RÉSZLEGES | 🟡 | 12 óra |
| GAP-P0-011 | Kezelési díj max-limit (`_kezdijmax`) | `HandlingFeeService` | RÉSZLEGES | 🟠 | 3 óra |
| GAP-P0-012 | Konverzió díj=0 explicit verifikáció | `TransactionConversionService` | RÉSZLEGES | 🟠 | 2 óra |

**P0 részösszeg: ~66 óra**

---

### P1 — INNER RING kritikus gapek (összesen)

| Gap ID | Delphi funkció | Java megfelelő | Státusz | Kockázat | Becsült munka |
|---|---|---|---|---|---|
| GAP-P1-001 | Átadólap 93 mező — banki be/kiszállítás hiányzik | `HandoverSheet` entitás kibővítés | HIÁNYZIK | 🔴 | 20 óra |
| GAP-P1-002 | Ügyfél napi limit (`NAPIGONGYOLTFORINT`) mező | `Customer` entitás + `AmlService` | ELTÉRÉS | 🔴 | 8 óra |
| GAP-P1-003 | Készlet feltöltő szerver push | `VaultCollectionService` | RÉSZLEGES | 🔴 | 16 óra |
| GAP-P1-004 | Terror napló részletesség | `AmlService` | RÉSZLEGES | 🔴 | 10 óra |
| GAP-P1-005 | HELGA lokális szerver workflow | `SynchronizationService` | RÉSZLEGES | 🔴 | 60 óra |
| GAP-P1-006 | Bizonylat törvényi mezők | `ReceiptGeneratorService` | RÉSZLEGES | 🔴 | 4 óra |
| GAP-P1-007 | Évi maximum tranzakció tracking | `AmlService` | RÉSZLEGES | 🟠 | 8 óra |
| GAP-P1-008 | Jogi személy lerendezés részletesség | `CustomerService` | RÉSZLEGES | 🟡 | 12 óra |
| GAP-P1-009 | Értéktár stornó külön workflow | `StornoService` (értéktár ág) | RÉSZLEGES | 🟠 | 16 óra |
| GAP-P1-010 | Esti bináris csomag összes adat | `EveningClosingService` | RÉSZLEGES | 🟡 | 10 óra |

**P1 részösszeg: ~164 óra**

---

### P2 — OUTER RING kritikus gapek (összesen)

| Gap ID | Delphi funkció | Java megfelelő | Státusz | Kockázat | Becsült munka |
|---|---|---|---|---|---|
| GAP-P2-001 | MNB háromszintű aggregáció | `MnbReportService` | RÉSZLEGES | 🔴 | 20 óra |
| GAP-P2-002 | Értéktár napi zárás 10 copy-lépés | `EveningClosingService` | RÉSZLEGES | 🔴 | 30 óra |
| GAP-P2-003 | Értéktár napi jelentes 10+ panel | `DailyReportService` | RÉSZLEGES | 🔴 | 32 óra |
| GAP-P2-004 | BEST/ALL/EAST/PANNON kategória | `CommissionCalculationService` | HIÁNYZIK | 🔴 | 16 óra |
| GAP-P2-005 | Elszámolás tábla kontrol | Új `AccountingReconciliationService` | HIÁNYZIK | 🔴 | 12 óra |
| GAP-P2-006 | Évfordítás workflow | `ArchivingService` | RÉSZLEGES | 🔴 | 20 óra |
| GAP-P2-007 | CSV vs. multi-sheet Excel könyvelés | `BookingExportService` | RÉSZLEGES | 🟠 | 12 óra |
| GAP-P2-008 | Tranzakció díj napi/havi bedolgozás | `HandlingFeeDecadeService` | RÉSZLEGES | 🔴 | 30 óra |
| GAP-P2-009 | Átlagárfolyam time-weighted algoritmus | `RateCalculationService` | RÉSZLEGES | 🟠 | 8 óra |
| GAP-P2-010 | F és U bizonylat MNB megkülönböztetés | `MnbReportService` | RÉSZLEGES | 🔴 | 8 óra |
| GAP-P2-011 | Haszonszámítás kedvezmény-korrekció + stornó | `ProfitCalculationService` | RÉSZLEGES | 🟠 | 24 óra |
| GAP-P2-012 | Értéktár napi könyv formázott lista | `DailyReportService` | RÉSZLEGES | 🔴 | 24 óra |

**P2 részösszeg: ~236 óra**

---

### P3 — PERIPHERY gapek (MUST/SHOULD)

| Gap ID | Delphi funkció | Java megfelelő | Státusz | Kockázat | Becsült munka |
|---|---|---|---|---|---|
| GAP-P3-001 | HELGA szerver (részben P1-ben) | `SynchronizationService` | RÉSZLEGES | 🔴 | 60 óra |
| GAP-P3-002 | Rendőrségi adatszolgáltatás | `PoliceRequestController` | RÉSZLEGES | 🔴 | 20 óra |
| GAP-P3-003 | Verseny számítás komplex | `CompetitionService` | RÉSZLEGES | 🟡 | 20 óra |
| GAP-P3-004 | Jutalékszámítás + BEST/ALL/EAST | `CommissionCalculationService` | RÉSZLEGES | 🟠 | 36 óra |
| GAP-P3-005 | WU szerveri összesítő havi | `WesternUnionService` | RÉSZLEGES | 🟡 | 20 óra |
| GAP-P3-006 | Receptor (pénztár kliens kezelő) | `CashRegisterService` | RÉSZLEGES | 🟠 | 30 óra |
| GAP-P3-007 | MoneyGram integráció | NINCS | HIÁNYZIK | 🟡 | 40 óra |
| GAP-P3-008 | METRO helyszín-specifikus | NINCS | HIÁNYZIK | 🟡 | 8 óra |
| GAP-P3-009 | TESCO helyszín-specifikus | NINCS | HIÁNYZIK | 🟡 | 8 óra |
| GAP-P3-010 | FNYUJSAG 15+ helyszín | `ExchangeRateDisplayService` | RÉSZLEGES | 🟡 | 20 óra |
| GAP-P3-011 | TRADE főmodul (VALUTA/TRADE) | `TradeController` | RÉSZLEGES | 🟡 | 40 óra |
| GAP-P3-012 | IBVALTO főprogram | Frontend + Backend | RÉSZLEGES | 🟡 | 60 óra |

**P3 részösszeg: ~362 óra (MUST rész: ~120 óra)**

---


---

## S8 PRIORITALT_GAPEK_MASTER_LISTA_TOP_25

| Rang | Gap ID | Probléma | Prioritás | Kockázat | Becsült munka |
|---|---|---|---|---|---|
| 1 | GAP-P0-001 | **JPY /10 speciális logika — pénzügyi hiba** | P0 | 🔴 | 4 óra |
| 2 | GAP-P0-005 | **Ügyfél napi limit reset napzárásnál — AML kockázat** | P0 | 🔴 | 4 óra |
| 3 | GAP-P0-004 | **BIGCTRL.DLL large-amount workflow hiányzik** | P0 | 🔴 | 16 óra |
| 4 | GAP-P1-002 | **`NAPIGONGYOLTFORINT` — ügyfél napi limit tracking** | P1 | 🔴 | 8 óra |
| 5 | GAP-P1-006 | **Bizonylat törvényi mezők — NAV/jogszabályi compliance** | P1 | 🔴 | 4 óra |
| 6 | GAP-P2-001 | **MNB háromszintű aggregáció — törvényi kötelezettség** | P2 | 🔴 | 20 óra |
| 7 | GAP-P2-010 | **F/U bizonylat megkülönböztetés MNB-nek** | P2 | 🔴 | 8 óra |
| 8 | GAP-P1-001 | **Átadólap banki be/kiszállítás hiányzik** | P1 | 🔴 | 20 óra |
| 9 | GAP-P2-002 | **Értéktár napi zárás 10 copy-lépés** | P2 | 🔴 | 30 óra |
| 10 | GAP-P1-003 | **Készlet feltöltő szerver push** | P1 | 🔴 | 16 óra |
| 11 | GAP-P2-012 | **Értéktár napi könyv — kötelező napi dokumentum** | P2 | 🔴 | 24 óra |
| 12 | GAP-P2-008 | **Tranzakció díj napi/havi bedolgozás** | P2 | 🔴 | 30 óra |
| 13 | GAP-P2-004 | **BEST/ALL/EAST/PANNON kategória szortírozás** | P2 | 🔴 | 16 óra |
| 14 | GAP-P1-004 | **Terror napló részletesség** | P1 | 🔴 | 10 óra |
| 15 | GAP-P3-002 | **Rendőrségi adatszolgáltatás** | P3 | 🔴 | 20 óra |
| 16 | GAP-P2-006 | **Évfordítás workflow** | P2 | 🔴 | 20 óra |
| 17 | GAP-P2-003 | **Értéktár napi jelentes 10+ panel** | P2 | 🔴 | 32 óra |
| 18 | GAP-P2-005 | **Elszámolás tábla kontrol** | P2 | 🔴 | 12 óra |
| 19 | GAP-P1-005 | **HELGA lokális szerver workflow** | P1 | 🔴 | 60 óra |
| 20 | GAP-P0-009 | **Blokk fej/tétel éves archiválás** | P0 | 🔴 | 8 óra |
| 21 | GAP-P2-011 | **Haszonszámítás kedvezmény-korrekció** | P2 | 🟠 | 24 óra |
| 22 | GAP-P0-003 | **SHK max 5/nap — konstans eltérés** | P0 | 🟠 | 1 óra |
| 23 | GAP-P0-002 | **_rounder=0.001 kerekítési konstans** | P0 | 🟠 | 2 óra |
| 24 | GAP-P1-007 | **Évi maximum tranzakció tracking** | P1 | 🟠 | 8 óra |
| 25 | GAP-P2-009 | **Átlagárfolyam time-weighted** | P2 | 🟠 | 8 óra |

---


---

## S9 OSSZESITETT_MUNKABECSLES_RING_SZINT_SZERINT

| Ring | MUST | SHOULD | COULD | Összesen |
|---|---|---|---|---|
| P0 — MAG | 66 óra | 0 óra | 0 óra | **66 óra** |
| P1 — INNER | 126 óra | 38 óra | 0 óra | **164 óra** |
| P2 — OUTER | 202 óra | 34 óra | 0 óra | **236 óra** |
| P3 — PERIPHERY | 120 óra | 130 óra | 112 óra | **362 óra** |
| **Összesen** | **514 óra** | **202 óra** | **112 óra** | **828 óra** |

> **MUST részösszeg (kritikus + törvényi):** ~514 óra  
> **2 tapasztalt Java fejlesztő, 2 hetes sprint = ~40 óra/dev = 80 óra/sprint**  
> **MUST teljesítési idő: ~6-7 sprint (12-14 hét)**

---


---

## S10 SPRINT_TERVEZESI_JAVASLAT

```
Sprint 1 (P0 MAG gyors fix):
  - GAP-P0-001: JPY /10 logika (4 óra)
  - GAP-P0-002: _rounder=0.001 (2 óra)
  - GAP-P0-003: SHK 5/nap fix (1 óra)
  - GAP-P0-005: Ügyfél napi limit reset napzárásnál (4 óra)
  - GAP-P0-006: SHK reset napzárásnál (2 óra)
  - GAP-P0-011: Kezelési díj max-limit (_kezdijmax) (3 óra)
  - GAP-P0-012: Konverzió díj=0 verifikáció (2 óra)
  - GAP-P1-006: Bizonylat törvényi mezők audit (4 óra)
  Összesen: ~22 óra — Sprint 1 befejezésre

Sprint 2 (P1 AML + Compliance):
  - GAP-P1-002: NAPIGONGYOLTFORINT mező (8 óra)
  - GAP-P1-004: Terror napló részletesség (10 óra)
  - GAP-P1-007: Évi maximum tracking (8 óra)
  - GAP-P0-004: BIGCTRL.DLL workflow (16 óra)
  Összesen: ~42 óra

Sprint 3 (P2 MNB + Értéktár):
  - GAP-P2-001: MNB háromszintű aggregáció (20 óra)
  - GAP-P2-010: F/U bizonylat MNB (8 óra)
  - GAP-P0-009: Blokk fej/tétel éves archiválás (8 óra)
  Összesen: ~36 óra

Sprint 4-5 (P2 Értéktár zárás + napkönyv):
  - GAP-P2-002: Értéktár napi zárás 10 copy-lépés (30 óra)
  - GAP-P2-012: Értéktár napi könyv (24 óra)
  Összesen: ~54 óra

Sprint 6 (P2 Tranzakció díj + elszámolás):
  - GAP-P2-008: Tranzakció díj napi/havi bedolgozás (30 óra)
  - GAP-P2-005: Elszámolás tábla kontrol (12 óra)
  Összesen: ~42 óra

Sprint 7 (P1 Átadólap + Készlet):
  - GAP-P1-001: Átadólap banki mezők (20 óra)
  - GAP-P1-003: Készlet feltöltő szerver push (16 óra)
  Összesen: ~36 óra

Sprint 8-9 (P2 Jelentes + Évfordítás + Haszon):
  - GAP-P2-003: Értéktár napi jelentes (32 óra)
  - GAP-P2-006: Évfordítás workflow (20 óra)
  - GAP-P2-011: Haszonszámítás korrekció (24 óra)
  Összesen: ~76 óra

Sprint 10-11 (P3 MUST):
  - GAP-P3-002: Rendőrségi adatszolgáltatás (20 óra)
  - GAP-P2-004: BEST/ALL/EAST/PANNON (16 óra)
  - GAP-P3-004: Jutalékszámítás komplex (36 óra)
  Összesen: ~72 óra

Sprint 12-14+ (P1 HELGA + P3 SHOULD):
  - GAP-P1-005: HELGA lokális szerver (60 óra)
  - P3 SHOULD kategória...
```

---


---

## S11 TECHNIKAI_AJANLASOK

### 1. JPY Speciális Kezelés (AZONNALI)

```java
// TransactionCalculationService.java — HIÁNYZÓ logika
public BigDecimal calculateBuyHufAmount(BigDecimal currencyAmount, ExchangeRate rate, ...) {
    BigDecimal hufAmount = currencyAmount.multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
    
    // DELPHI EKVIVALENS: JPY speciális 1000-es egység (Delphi: /10 az eredményen)
    // Delphi: _aktArfolyam / 100 * _aktBankjegy → ha JPY: / 10
    // Feltétel: a JPY árfolyam 100-as egységben tárolva a DB-ben
    String currencyCode = rate.getCurrency().getCode();
    if ("JPY".equals(currencyCode)) {
        hufAmount = hufAmount.divide(BigDecimal.TEN, 0, RoundingMode.HALF_UP);
    }
    
    return hufAmount;
}
```

### 2. Ügyfél Napi Limit Reset (AZONNALI)

```java
// DailyClosingService.java — HIÁNYZÓ metódus
@Transactional
public void resetDailyCustomerLimits(UUID branchId, LocalDate date) {
    // Delphi: UPDATE UGYFEL SET NAPIGONGYOLTFORINT=0
    // Delphi: UPDATE JOGISZEMELY SET NAPIGONGYOLTFORINT=0
    customerRepository.resetDailyLimitsForBranch(branchId);
    log.info("Napi ügyfél limitek nullázva: branch={}, date={}", branchId, date);
}
```

### 3. SHK Limit Eltérés (AZONNALI)

```java
// HandlingFeeService.java — konstans fix
// Delphi: max 5/nap
// Java jelenleg: DEFAULT_DAILY_CUSTOM_FEE_LIMIT = 3 → javítandó 5-re
// VAGY: konfigurálható system parameter-ből (jobb megoldás)
private int getDailyCustomFeeLimit() {
    return systemParameterService.getIntValue("DAILY_CUSTOM_FEE_LIMIT", 5); // default 5, nem 3!
}
```

### 4. Adattípus irányelvek (minden pénzügyi számítás)

```java
// TILOS: double/float pénzügyi számításoknál
// KÖTELEZŐ: BigDecimal precision=15, scale=4 (árfolyam), scale=2 (HUF összeg)
// Delphi REAL (6 byte float) → Java BigDecimal

// Kerekítés:
// - HUF összeg: HALF_UP, 0 tizedes
// - Árfolyam: HALF_UP, 4 tizedes  
// - Kezelési díj: HALF_DOWN (Delphi: trunc = RoundingMode.DOWN)
BigDecimal fee = netto.multiply(ezrelek)
    .divide(new BigDecimal("1000"), 0, RoundingMode.DOWN); // trunc = DOWN
```

### 5. MNB Háromszintű Aggregáció — Minta

```java
// MnbReportService.java — hiányzó szintek
// Delphi: ForgalomGyujtes → KorzetSumma → KftSumma → CegSumma
public MnbAggregatedReport generateCompanyReport(UUID companyId, LocalDate date) {
    // 1. szint: pénztáranként
    List<BranchReport> branchReports = branches.stream()
        .map(b -> generateBranchReport(b, date))
        .collect(toList());
    
    // 2. szint: körzetenkénti aggregáció (BranchGroup → körzet)
    Map<UUID, KorzetReport> korzetMap = aggregateByKorzet(branchReports);
    
    // 3. szint: cég szintű aggregáció
    CegReport cegReport = aggregateToCompany(korzetMap.values());
    
    return new MnbAggregatedReport(branchReports, korzetMap, cegReport);
}
```

---


---

## S12 KOCKAZATI_MATRIX

| Terület | Valószínűség | Hatás | Prioritás |
|---|---|---|---|
| JPY tranzakció pénzügyi hiba | MAGAS | KRITIKUS | 🔴 Azonnali |
| MNB riport pontatlanság | MAGAS | KRITIKUS | 🔴 Azonnali |
| AML napi limit reset hiánya | KÖZEPES | KRITIKUS | 🔴 Azonnali |
| BIGCTRL large-amount workflow | KÖZEPES | KRITIKUS | 🔴 Sprint 2 |
| Bizonylat törvényi mezők | MAGAS | MAGAS | 🔴 Sprint 1 |
| Értéktár zárás adatvesztés | KÖZEPES | KRITIKUS | 🔴 Sprint 4-5 |
| Tranzakció díj bedolgozás eltérés | MAGAS | MAGAS | 🟠 Sprint 6 |
| Haszonszámítás pontossága | KÖZEPES | MAGAS | 🟠 Sprint 8 |
| Évfordítás hibás nyitó | ALACSONY | KRITIKUS | 🔴 Sprint 8 |
| Rendőrségi adatszolgáltatás | ALACSONY | KRITIKUS | 🔴 Sprint 10 |
| MoneyGram hiánya (ha aktív) | ISMERETLEN | KÖZEPES | 🟡 COULD |

---


---

## S13 STATISZTIKAI_OSSZEFOGLALO

| Rendszer | Elemzett | KÉSZ | RÉSZLEGES | ELTÉRÉS | HIÁNYZIK | NEM KELL | Lefedettség |
|---|---|---|---|---|---|---|---|
| P0 MAG (vétel/eladás/stornó/napzár/arfolyam) | 74 | 42 | 22 | 5 | 5 | 0 | ~64% |
| P1 INNER (átadás/készlet/ügyfél/bizonylat/szinkron) | 48 | 19 | 24 | 2 | 3 | 0 | ~50% |
| P2 OUTER (értéktár zárás/MNB/könyvelés/díj) | 39 | 5 | 28 | 0 | 6 | 0 | ~24% |
| P3 PERIPHERY (szerver admin/WU/verseny/egyéb) | 105 | 35 | 53 | 0 | 6 | 11 | ~47% |
| **ÖSSZESEN** | **266** | **101 (38%)** | **127 (48%)** | **7 (3%)** | **20 (7%)** | **11 (4%)** | **~52% teljes** |

> **Valódi lefedettség (KÉSZ=1.0, RÉSZLEGES=0.5, ELTÉRÉS=0.3):**  
> = (101×1.0 + 127×0.5 + 7×0.3) / 255 = (101 + 63.5 + 2.1) / 255 = **~65%**

> **Korábbi elemzés szerint 62% — ez az érték a P0 MAG részletesebb vizsgálata alapján pontosabb (KÉSZ kategóriák megerősítve a Java forráskódból).**

---


---

## S14 OSSZEFOGLALAS_EGY_MONDATBAN

**A Java backend a Delphi rendszer ~65%-át fedi le; a legkritikusabb azonnali javítandók (P0): JPY /10 kalkuláció (`TransactionCalculationService`), ügyfél napi AML limit reset napzárásnál (`DailyClosingService`), SHK konstans 5→3 eltérés (`HandlingFeeService`); a legnagyobb P1-P2 gapek: HELGA szerver (~60 óra), értéktár napi zárás copy-lépések (~30 óra), MNB háromszintű aggregáció (~20 óra), tranzakció díj bedolgozás (~30 óra) — összesen ~514 óra MUST fejlesztés szükséges a production-ready állapothoz.**

---
*Gap Analízis v2 (Core-prioritás): Tamás (TestOps Chief) | 2026-04-04 | Forrás: Java 1170 .java + Delphi 645K Pascal sor*
