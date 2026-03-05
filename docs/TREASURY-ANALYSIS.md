# Értéktári (Treasury) Rendszer — Legacy Elemzés és Új Rendszer Terv

**Dátum:** 2026-03-05
**Elemző:** Junior (koordinátor)
**Forrás:** ERTEKTAR\etdll\ (55 DLL), SZERVER\ujdll\ (35 DLL)

---

## 1. LEGACY RENDSZER ARCHITEKTÚRA

### Három szint:
```
┌─────────────────────────────────────────────┐
│                SZERVER (35 DLL)              │
│  Központi adatgyűjtő + összesítő            │
│  - Firebird DB (minden iroda adata)         │
│  - FTP szerver (pk file-ok fogadása)        │
│  - Összesítők: bankforg, keszletdisp, stb.  │
└─────────────────────┬───────────────────────┘
                      │ FTP + pk file-ok
┌─────────────────────┴───────────────────────┐
│              ÉRTÉKTÁR (55 DLL)               │
│  Értéktáros alkalmazás (ERTEKTAR.exe)        │
│  - Pénztárak készletének felügyelete         │
│  - Valuta szállítás (bank↔pénztár)          │
│  - Árfolyam kezelés, címletezés             │
│  - Napi/havi/dekád zárások                  │
└─────────────────────┬───────────────────────┘
                      │ pk file-ok + Firebird
┌─────────────────────┴───────────────────────┐
│              VALUTA KLIENS (100+ DLL)        │
│  Pénztáros alkalmazás (IBVALTO.exe)          │
│  - Eladás, vásárlás, konverzió              │
│  - Napzárás, címletezés                     │
│  - Bizonylat nyomtatás                      │
└─────────────────────────────────────────────┘
```

### Kommunikáció:
- **Pénztár → Értéktár:** pk file-ok (bináris, 737 byte/iroda, FTP-n feltöltve a szerverre)
- **Értéktár → Szerver:** Firebird DB közvetlen kapcsolat + FTP
- **Szerver → Pénztár:** Árfolyam letöltés (IRQ polling), körlevelek

### pk file formátum (PILLKESZ):
```
Byte [1]   = év
Byte [2]   = hónap
Byte [3]   = nap
Byte [4]   = óra
Byte [5]   = perc (>=100 → foglalóval, -100)
Byte [7..] = 27× valuta blokk:
  - 2 byte: devizanem kód (tömörített)
  - 4 byte: készlet
  - 4 byte: készlet Ft értékben
  - 4 byte: napi vétel
  - 4 byte: napi vétel Ft
  - 4 byte: napi eladás
  - 4 byte: napi eladás Ft
Utána: WU USD, WU HUF, ÁFA, kezelési díj, e-kereskedelem, foglaló
```

---

## 2. ÉRTÉKTÁRI MODULOK (55 DLL) — FONTOSSÁGI SORREND

### 🔴 KRITIKUS (az új rendszerben NINCS):

| Modul | Funkció | Leírás |
|-------|---------|--------|
| **penztarak** | Pénztárak összesítő nézet | 27 valuta × N pénztár mátrix, FTP-ről pk file letöltés, összesítés, grafikon |
| **keszup** | Készlet feltöltés/leszállítás | Bank → pénztár valuta szállítás, fedezetellenőrzés |
| **keszedit** | Készlet manuális szerkesztés | Kézi korrekciók (eltérés, leltár) |
| **ratectrl** | Árfolyam kontroll/letöltés | MNB + saját árfolyam, IRQ polling rendszer |
| **maktablak** | Árfolyam táblák | Nyomtatható/displayben megjelenítő árfolyamtábla |
| **napijel** | Napi jelentés | Pénztár→szerver napi forgalmi adatok |
| **atadvet** | Átadás/vétel | Pénztárak közti valuta mozgás (átadólap) |
| **korlev** | Körlevél | Központi utasítások a pénztáraknak |

### 🟡 FONTOS (részlegesen megvan):

| Modul | Funkció | Meglévő |
|-------|---------|---------|
| **ptarkesz** | Pénztári készlet | CashBalance (alap) |
| **pillkesz** | Pillanatnyi készlet | CashBalance lekérdezés |
| **cimlctrl** | Címletezés kontroll | DenominationBalance (alap) |
| **napzar** | Napzárás | ClosingWizard (9 lépés) |
| **napikezd** | Napi nyitás | DailySession |
| **storno** | Stornó | StornoApproval |
| **prosbe** | Bejelentkezés | Auth + JWT |
| **super** | Szupervízor jogok | Role + Permission (alap) |

### 🟢 MEGOLDOTT:

| Modul | Funkció | Implementáció |
|-------|---------|---------------|
| logiro/logdisp | Naplózás | AuditLog entity + controller |
| wunion | Western Union | Transfer (CURRENCY type) |
| bloknyom | Bizonylat nyomtatás | QrCodeService (alap) |

---

## 3. SZERVER OLDAL (35 DLL) — KÖZPONTI LOGIKA

### 🔴 KRITIKUS szerver modulok:

| Modul | Funkció |
|-------|---------|
| **adatgyujto** | Pénztárak adatainak begyűjtése (pk file-ok feldolgozása) |
| **bankforg** | Bank forgalom összesítés (SUMBANKFORGALOM tábla) |
| **keszletdisp** | Központi készlet megjelenítés (CIMLETGYUJTO tábla) |
| **forgalomdisp** | Forgalom összesítés és kimutatás |
| **zarasctrl** | Zárás kontroll (pénztárak zárási állapota) |
| **tranzakc** | Tranzakció nyilvántartás (központi) |
| **dolgozok** | Dolgozó (pénztáros) kezelés |
| **mnbgyujto** | MNB adatgyűjtés és jelentés |
| **jutszamito** | Jutalék számítás |
| **jutszazalek** | Jutalék százalék beállítás |

### Szerver DB táblák (Firebird):
- **SUMBANKFORGALOM** — bank forgalom összesítő (valutanemenként felvett/befizetett KP)
- **CIMLETGYUJTO** — központi címlet nyilvántartás
- **ADATATADO** — paraméterek, irodák adatai
- **IDOSZAK** — vizsgált időszak (startDate, endDate)
- **TRANZAKCIO** — központi tranzakció log

---

## 4. ÚJ RENDSZER TERV (Spring Boot)

### Új entity-k szükségesek:

```java
// 1. Készlet mozgás (bank↔pénztár)
@Entity InventoryMovement {
    Long id
    Branch fromBranch / toBranch  // bank = speciális branch
    Currency currency
    BigDecimal amount
    MovementType type  // BANK_DEPOSIT, BANK_WITHDRAW, BRANCH_TRANSFER, CORRECTION, INITIAL_STOCK
    MovementStatus status  // PENDING, IN_TRANSIT, RECEIVED, CANCELLED
    Worker initiatedBy / receivedBy
    LocalDateTime createdAt / receivedAt
    String notes
    String referenceNumber  // szállítólevél szám
}

// 2. Központi készlet összesítő nézet
@Entity InventorySummary {
    Long id
    Branch branch
    Currency currency
    BigDecimal currentStock      // aktuális készlet
    BigDecimal dailyBuyTotal     // napi vétel összeg
    BigDecimal dailySellTotal    // napi eladás összeg
    BigDecimal dailyFeeTotal     // napi kezelési díj
    LocalDate summaryDate
    LocalTime lastUpdated
    // Ez egy materialized view jellegű tábla, ami a valós idejű állapotot tükrözi
}

// 3. Árfolyam forrás és letöltés
@Entity ExchangeRateSource {
    Long id
    String sourceName  // MNB, MANUAL, IMPORT
    String sourceUrl
    Integer pollingIntervalMinutes
    Boolean active
    LocalDateTime lastPolledAt
    String lastError
}

// 4. Napi jelentés (irodánként)
@Entity DailyReport {
    Long id
    Branch branch
    LocalDate reportDate
    Boolean submitted
    LocalDateTime submittedAt
    String reportData  // JSON vagy strukturált
    DailySession dailySession
}

// 5. Körlevél (központi utasítás)
@Entity Circular {
    Long id
    String title
    String content
    Worker createdBy
    LocalDateTime createdAt
    Boolean urgent
    // Many-to-many Branch-ekkel a kézbesítéshez
}
```

### Új service-ek:

```java
// 1. InventoryService — készlet mozgások kezelése
- requestStockFromBank(branchId, currencyId, amount)   // bank→pénztár kérés
- depositToBank(branchId, currencyId, amount)            // pénztár→bank befizetés
- transferBetweenBranches(fromBranchId, toBranchId, currencyId, amount)
- correctInventory(branchId, currencyId, newAmount, reason)
- getCurrentStock(branchId)                              // valós idejű készlet
- getStockMatrix()                                       // összes pénztár × összes valuta

// 2. ExchangeRatePollingService — árfolyam letöltés (IRQ megfelelő)
- @Scheduled(cron) pollMnbRates()
- pollExternalSource(sourceId)
- manualRateUpdate(currencyId, buyRate, sellRate)

// 3. DailyReportService — napi jelentés
- generateReport(branchId, date)
- submitReport(branchId, date)
- getSubmissionStatus()   // melyik iroda zárta le a napot

// 4. TreasuryDashboardService — összesítő (a szerver logikája)
- getCompanyWideSummary()        // összes iroda összesítve
- getBranchComparison()          // irodák összehasonlítása
- getBankFlowSummary(dateRange)  // bank forgalom
- getProfitAnalysis(dateRange)   // haszon elemzés
```

### Új controller-ek:

```
GET  /api/v1/inventory/stock                    — összes iroda készlete
GET  /api/v1/inventory/stock/{branchId}         — egy iroda készlete
GET  /api/v1/inventory/matrix                   — pénztár × valuta mátrix
POST /api/v1/inventory/bank-withdraw             — bank→pénztár kérés
POST /api/v1/inventory/bank-deposit              — pénztár→bank befizetés
POST /api/v1/inventory/transfer                  — irodák közti szállítás
POST /api/v1/inventory/correction                — manuális korrekció
GET  /api/v1/inventory/movements                 — mozgás történet

GET  /api/v1/treasury/dashboard                  — központi összesítő
GET  /api/v1/treasury/bank-flow                  — bank forgalom
GET  /api/v1/treasury/profit                     — haszon elemzés
GET  /api/v1/treasury/submission-status           — irodák zárási állapota

GET  /api/v1/rates/poll                          — árfolyam frissítés trigger
GET  /api/v1/rates/sources                       — árfolyam források
POST /api/v1/rates/manual                        — manuális árfolyam bevitel

GET  /api/v1/reports/daily/{branchId}/{date}     — napi jelentés
POST /api/v1/reports/daily/{branchId}/submit     — jelentés beküldés

POST /api/v1/circulars                           — körlevél létrehozás
GET  /api/v1/circulars                           — körlevelek listázás
```

---

## 5. IMPLEMENTÁCIÓS SORREND (javasolt)

### Sprint 1: Készlet mozgások (KRITIKUS)
1. InventoryMovement entity + repository
2. InventoryService (bank↔pénztár)
3. InventoryController
4. Frontend: készlet táblázat nézet

### Sprint 2: Központi összesítő (SZERVER logika)
1. InventorySummary entity (materialized view)
2. TreasuryDashboardService
3. TreasuryController
4. Frontend: dashboard nézet (grafikonok)

### Sprint 3: Árfolyam rendszer (IRQ)
1. ExchangeRateSource entity
2. ExchangeRatePollingService (@Scheduled)
3. MNB árfolyam API integráció
4. Frontend: árfolyam kezelő panel

### Sprint 4: Napi jelentés + körlevél
1. DailyReport entity + service
2. Circular entity + service
3. Frontend: jelentés generálás + körlevél küldés

---

## 6. ADATÁRAMLÁS — ÚJ RENDSZER

```
┌─────────────────────────────────────────────┐
│     Spring Boot Backend (EGY ALKALMAZÁS)     │
│                                              │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │ Pénztáros   │  │ Értéktáros/Admin     │  │
│  │ Controller  │  │ Controller           │  │
│  │ (transaction│  │ (inventory, treasury │  │
│  │  buy/sell)  │  │  dashboard, reports) │  │
│  └──────┬──────┘  └──────────┬───────────┘  │
│         │                    │               │
│  ┌──────┴────────────────────┴───────────┐  │
│  │        Service Layer                   │  │
│  │  TransactionService                    │  │
│  │  InventoryService ← ÚJ                │  │
│  │  TreasuryDashboardService ← ÚJ        │  │
│  │  ExchangeRatePollingService ← ÚJ      │  │
│  │  DailyReportService ← ÚJ              │  │
│  └──────┬────────────────────────────────┘  │
│         │                                    │
│  ┌──────┴────────────────────────────────┐  │
│  │      Neon PostgreSQL (Frankfurt)       │  │
│  │  Minden adat EGY DB-ben               │  │
│  │  (nincs FTP, nincs pk file, nincs      │  │
│  │   Firebird — közvetlen SQL)            │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

### Legacy vs Új összehasonlítás:
| Aspektus | Legacy | Új |
|----------|--------|-----|
| Adatbázis | Firebird (helyi) + szerver | Neon PostgreSQL (felhő) |
| Kommunikáció | FTP + pk bináris fájlok | REST API + JSON |
| Készlet szinkron | Perces polling + file | Valós idejű DB query |
| Árfolyam | IRQ timer + FTP letöltés | @Scheduled + HTTP API |
| Szerver | Külön alkalmazás (35 DLL) | RÉSZE a Spring Boot-nak |
| Értéktár | Külön alkalmazás (55 DLL) | Admin/Treasury UI a React-ben |
