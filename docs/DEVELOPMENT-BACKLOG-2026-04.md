# Valutaváltó — Priorizált Fejlesztési Backlog (2026-04-04)

> **Forrás:** 4 Delphi elemzés (`shared/reviews/`) — 645K Pascal sor, 1102 .pas, 200 modul átvizsgálva
> **Valódi lefedettség:** ~62% (nem 98% mint korábban hittük)
> **Hiányzó/részleges:** ~38% — elsősorban értéktár, MNB, elszámolás, haszonszámítás

---

## Sprint Terv — Összefoglaló

| Sprint | Fókusz | Becsült munka | Prioritás |
|--------|--------|---------------|-----------|
| **S1** | MNB háromszintű aggregáció + értéktár napi zárás | 50 ó | MUST |
| **S2** | Értéktár napi jelentés + napi könyv | 56 ó | MUST |
| **S3** | Tranzakció díj napi/havi bedolgozás + haszonszámítás | 54 ó | MUST |
| **S4** | Rendőrségi adatszolgáltatás + évnyitó/évfordítás + stornó | 56 ó | MUST |
| **S5** | Készlet feltöltő + értéktár átadólap + napi kezdés | 56 ó | MUST |
| **S6** | WU szerveri összesítő + jutalomszámítás | 44 ó | SHOULD |
| **S7** | Booking/könyvelési Excel export (3 modul) | 32 ó | SHOULD |
| **S8** | Verseny számítás + átlagárfolyam + pillanatnyi készlet | 44 ó | SHOULD |

**MUST összesen: ~272 óra (S1–S5)**
**SHOULD összesen: ~120 óra (S6–S8)**

---

## SPRINT 1 — MNB Compliance + Értéktár Zárás

### S1-01: MNB gyűjtő háromszintű aggregáció
- **Delphi forrás:** `ujdll/mnbgyujto/unit2.pas`
- **Java:** `MnbReportService.java` — kiegészítendő
- **Hiány:** pénztár→körzet→cég szintű aggregáció (ForgalomGyujtes, KorzetSumma, KftSumma, CegSumma)
- **Elfogadási kritérium:** MNB riport output egyezik a Delphi kimenettel tesztadatokon
- **Becsült munka:** 20 ó
- **Kockázat:** KRITIKUS — törvényi kötelezettség

### S1-02: Értéktár napi zárás teljes workflow
- **Delphi forrás:** `ERTEKTAR/etdll/napzar/unit2.pas` (1039 sor)
- **Java:** `ClosingWizardService.java`, `DailyClosingService.java`, `EveningClosingService.java`
- **Hiány:** 10+ copy-lépés (BFCopy, BTCopy, CIMTCopy, NarfCopy, WuniCopy, WzarCopy, EdatCopy, EkerCopy, KDatCopy, KezdijCopy, HaviGyujtokbeMasolas)
- **Elfogadási kritérium:** Minden copy-lépés lefut, havi gyűjtők konzisztensek
- **Becsült munka:** 30 ó
- **Kockázat:** KRITIKUS — adatintegritás

---

## SPRINT 2 — Értéktár Napi Működés

### S2-01: Értéktár napi jelentés teljes adat
- **Delphi forrás:** `ERTEKTAR/etdll/napijel/unit2.pas` (1557 sor)
- **Java:** `DailyReportService.java`, `ErtektarController.java`
- **Hiány:** 10+ valutanem árfolyam panelek, WU összesítő panel, címlet részletezés, DE/DU bontás, záró+forint+valuta összesítő, bizonylat X sorozat
- **Elfogadási kritérium:** Minden panel megjelenik, összegek egyeznek
- **Becsült munka:** 32 ó

### S2-02: Napi könyv teljes lista
- **Delphi forrás:** `ERTEKTAR/etdll/napkonyv/unit2.pas`
- **Java:** `DailyReportService.java`, `TransactionReportService.java`
- **Hiány:** Teljes napi tranzakció lista minden adattal
- **Elfogadási kritérium:** Kötelező napi dokumentum tartalom teljes
- **Becsült munka:** 24 ó

---

## SPRINT 3 — Elszámolás + Profit

### S3-01: Tranzakció díj napi/havi bedolgozás
- **Delphi forrás:** `ujdll/tranzakc/unit2.pas` (1659 sor)
- **Java:** `HandlingFeeService.java`, `CommissionCalculationService.java`, `TransactionService.java`
- **Hiány:** HAVIBEDOLGGOMBClick, NAPIBEDOLGGOMBClick logika, BEST/ALL/EAST/PANNON kategóriák, ElszamTablaControl, KonverzioForgalom
- **Elfogadási kritérium:** Napi/havi bedolgozás eredménye egyezik Delphi kimenettel
- **Becsült munka:** 30 ó
- **Kockázat:** MAGAS — pénztáros elszámolás alapja

### S3-02: Haszonszámítás pontosság
- **Delphi forrás:** `SZERVER/fejleszt/haszon/unit1-5.pas`
- **Java:** `ProfitCalculationService.java`, `ProfitController.java`
- **Hiány:** Bizonylat-szintű árfolyam-különbözet, kedvezmény-korrekció, konverzió haszon, stornó hatása
- **Elfogadási kritérium:** Profit riport output egyezik
- **Becsült munka:** 24 ó

---

## SPRINT 4 — Törvényi + Éves Folytonosság

### S4-01: Rendőrségi adatszolgáltatás teljes
- **Delphi forrás:** `SZERVER/fejleszt/police/unit1-2.pas`
- **Java:** `PoliceRequestController.java`
- **Hiány:** Komplex kereső, Excel export, idő/összeg szűrő
- **Elfogadási kritérium:** Rendőrségi megkeresésre teljes adat előállítható
- **Becsült munka:** 20 ó
- **Kockázat:** KRITIKUS — törvényi

### S4-02: Évnyitó/évfordítás
- **Delphi forrás:** `SZERVER/fejleszt/evnyito/unit1.pas`, `newyear/unit1.pas`
- **Java:** `SessionOpenService.java`, `ClosingWizardService.java`, `ArchivingService.java`
- **Hiány:** Éves kezdőkészletek, archiválás workflow, éves táblák
- **Elfogadási kritérium:** Év végi zárás + új év nyitás hibátlan
- **Becsült munka:** 20 ó

### S4-03: Értéktár stornó teljes workflow
- **Delphi forrás:** `ERTEKTAR/etdll/storno/unit2.pas`, `VALUTA/STORNO/unit2.pas`
- **Java:** `StornoService.java`
- **Hiány:** Értéktári szintű stornó (nem csak pénztári)
- **Elfogadási kritérium:** Bizonylat visszavonás + készlet visszaállítás + könyvelés
- **Becsült munka:** 16 ó

---

## SPRINT 5 — Készletezés + Átadólap

### S5-01: Készlet feltöltő (értéktár→szerver)
- **Delphi forrás:** `ERTEKTAR/etdll/keszup/unit2.pas`
- **Java:** `VaultCollectionService.java`, `InventoryService.java`
- **Hiány:** Értéktár→szerver push workflow
- **Elfogadási kritérium:** Valós készletállapot szerveren
- **Becsült munka:** 16 ó

### S5-02: Értéktár átadólap teljes
- **Delphi forrás:** `ERTEKTAR/etdll/atadolap/unit2.pas` (64K)
- **Java:** `HandoverSheetService.java`, `TransferDocumentService.java`
- **Hiány:** Teljes értéktár verzió, plombaszám, szállító adatok, nyomtatás
- **Elfogadási kritérium:** Átadólap PDF egyezik Delphi kimenettel
- **Becsült munka:** 20 ó

### S5-03: Értéktár napi kezdés
- **Delphi forrás:** `ERTEKTAR/etdll/napikezd/unit2.pas`
- **Java:** `SessionOpenService.java`, `DailySessionService.java`
- **Hiány:** Készlet nyomtatás, nyitó rekord, értéktári inicializálás
- **Elfogadási kritérium:** Napi kezdés workflow teljes
- **Becsült munka:** 20 ó

---

## SPRINT 6 — WU + Jutalék (SHOULD)

### S6-01: Western Union szerveri összesítő
- **Delphi forrás:** `SZERVER/fejleszt/western/unit1.pas`, `westuni/unit1.pas`, `wucontrol/unit1.pas`
- **Java:** `WesternUnionService.java`, `CentralReportService.java`
- **Hiány:** Havi WU Excel (körzet+cég szint), WU kontrol
- **Becsült munka:** 20 ó

### S6-02: Jutalomszámítás komplex kalkuláció
- **Delphi forrás:** `ujdll/jutszamito/unit2.pas`, `ujdll/jutszazalek/unit2.pas`
- **Java:** `WorkerCommissionService.java`, `CommissionCalculationService.java`
- **Hiány:** By cashier/district, BEST/ALL/EAST/PANNON kategóriák, juttatás-mentes bizonylatok
- **Becsült munka:** 24 ó

---

## SPRINT 7 — Könyvelési Export (SHOULD)

### S7-01: Adásvétel Excel export
- **Delphi forrás:** `SZERVER/fejleszt/booking/advetexcel/unit1.pas`
- **Java:** `BookingExportService.java`
- **Hiány:** Teljes Delphi logika (korzet-szintű, multi-sheet)
- **Becsült munka:** 12 ó

### S7-02: Forgalom Excel export
- **Delphi forrás:** `SZERVER/fejleszt/booking/forgexel/unit1.pas`
- **Becsült munka:** 12 ó

### S7-03: Készlet Excel export
- **Delphi forrás:** `SZERVER/fejleszt/booking/keszexcel/unit1.pas`
- **Becsült munka:** 8 ó

---

## SPRINT 8 — Verseny + Riportok (SHOULD)

### S8-01: Verseny számítás mélysége
- **Delphi forrás:** `SZERVER/fejleszt/verseny/unit1-5.pas`
- **Java:** `CompetitionService.java`, `WorkerCompetitionService.java`
- **Hiány:** Juttatás-mentes bizonylat, körzet verseny, HutoGb (gamification)
- **Becsült munka:** 20 ó

### S8-02: Átlagárfolyam pontos algoritmus
- **Delphi forrás:** `ujdll/atlagarf/unit2.pas`
- **Java:** `RateCalculationService.java`
- **Hiány:** Havi súlyozás pontos algoritmusa
- **Becsült munka:** 8 ó

### S8-03: Pillanatnyi készlet grafikon
- **Delphi forrás:** `ERTEKTAR/etdll/pillkesz/unit2.pas`
- **Java:** `StockSnapshotService.java`, `InventoryService.java`
- **Hiány:** Grafikon + real-time készlet értéktári szinten
- **Becsült munka:** 16 ó

---

## COULD — Halasztható Backlog

| ID | Modul | Munka | Megjegyzés |
|----|-------|-------|------------|
| C-01 | MoneyGram integráció | 40 ó | Csak ha aktív MG |
| C-02 | Havi WU tablók | 20 ó | Statisztikai |
| C-03 | Foglalás Excel FTP | 12 ó | Automatizálható |
| C-04 | Körzet összesítők teljes | 20 ó | Menedzsment riport |
| C-05 | FNYUJSAG (15+ helyszín LED) | 20 ó | Lokáció specifikus |
| C-06 | Jogi személy mélység | 12 ó | KFT edge case |
| C-07 | TRADE főmodul | 40 ó | Tőzsdei, ritkán |
| C-08 | IBVALTO főprogram maradvány | 60 ó | Már React-ban |
| C-09 | Helga lokális szerver | 60 ó | Részben SyncService |
| C-10 | Pénztáros elszámoltatás teljes | 16 ó | Beszam unit1-3 |

---

## Core Üzleti Képletek — Referencia

### Forintérték
```
forintÉrték = round((árfolyam / 100 × bankjegy) + 0.001)
JPY: forintÉrték = round(forintÉrték / 10)
```

### Kezelési díj
```
Mód 1: ezrelékes → díj = trunc(nettó × ezrelék / 1000), max = _kezdijmax
Mód 2: sávos (_realEzrelek = -1) → TRANZDIJTABLA lookup
Mód 3: konverzió → díj = 0
```

### Vétel vs. Eladás
```
Vétel:  bruttó = nettó − kezelési_díj
Eladás: bruttó = nettó + kezelési_díj
Fizetendő = 5_Ft_kerekítés(bruttó)
```

### SHK (Saját Hatáskörű Kedvezmény)
```
Max 5/nap/pénztáros — HARDWARE.SAJATHATASKORU mezőben
Napzárásnál nullázódik
```

### Ügyfél azonosítás
```
300.000 Ft felett → AML/KYC kötelező (Pmt. törvény)
UGYFEL.NAPIGONGYOLTFORINT — napi limit, zárásnál nullázódik
```

---

## Architekturális Különbségek

| Delphi (régi) | Java/React/Electron (új) |
|---------------|--------------------------|
| Firebird FDB, WIN1250 | PostgreSQL, UTF-8 |
| DLL plugin (stdcall) | REST API + Spring Service |
| FTP szinkron (plaintext) | HTTPS REST API |
| `REAL` (6 byte float) | `BigDecimal` |
| Timer-alapú async | `@Scheduled` + async service |
| Hardcoded FTP jelszó | Env var / secret manager |
| 27 fix devizanem tömb | DB-ből dinamikus (Currency entity) |

---

## Kapcsolódó Dokumentumok

| Dokumentum | Tartalom |
|---|---|
| `shared/reviews/junior-core-analysis-2026-04-04.md` | Core logika elemzés (476 sor) |
| `shared/reviews/delphi-full-analysis-2026-04-04.md` | Eszter teljes forráselemzés (577 sor) |
| `shared/reviews/delphi-java-gap-analysis-2026-04-04.md` | Tamás gap analízis (611 sor) |
| `shared/reviews/delphi-core-outward-analysis-2026-04-04.md` | Eszter ring modell elemzés (1400 sor) |

---

*Backlog: Junior (Csapatvezető) | 2026-04-04 | Forrás: 4 elemzés dokumentum + 645K Pascal sor*
