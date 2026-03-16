# KESZLEX — Készlet Export Migráció Design Spec

## Összefoglaló

A legacy Delphi KESZLEX modul 1:1 migrációja modern Java/Spring Boot technológiára. A KESZLEX valós idejű készlet-pillanatképet gyűjt minden pénztárból, aggregálja iroda → körzet → cég szinten, és 10 lapos Excel munkafüzetet generál.

## Legacy rendszer

### Forrásfájlok
- `keszlex.dpr` — Delphi projekt, 3 form
- `unit1.pas` — Fő logika: bináris PK fájl parse, adataggregáció, Excel generálás orchestráció
- `unit2.pas` — ART-CASH Excel lap (kikommentezve, inaktív)
- `unit3.pas` — EXPRESSZ MINIBANK Excel lap (aktív, 27 valuta)

### Bináris PK fájl formátum (737 byte)
```
Byte 1:     év (2000+)
Byte 2:     hónap
Byte 3:     nap
Byte 4:     óra
Byte 5:     perc (+100 ha van foglaló)
Byte 6:     valutadarab (konstans 27)
Byte 7+:    27 × 26 byte valutaadat:
              2 byte: valutanem kód (kódolt, DnemDekod)
              4 byte: készlet (little-endian int32)
              4 byte: készlet Ft érték
              4 byte: napi vétel
              4 byte: vétel Ft
              4 byte: napi eladás
              4 byte: eladás Ft
Utána:      5 × 4 byte extra:
              WU USD, WU HUF, ÁFA, kezelési díj, e-kereskedés
```

### FOGLALO.DAT formátum
- Stringek XOR 255-tel kódolva
- Struktúra: pénztárdarab, majd per pénztár: ptszám, ptnév, körzet, foglalódarab, per foglaló: összeg(int32) + devizanem(string)

### Aggregációs hierarchia
- **Iroda** (`_pt*`): Pénztárak 1-150 (Exclusive Change)
- **Körzet** (`_kt*`): 8 körzet (Szekszárd=10, Szeged=20, Kecskemét=40, Debrecen=50, Nyíregyháza=63, Békéscsaba=75, Pécs=120, Kaposvár=145)
- **Cég** (`_tt*`): Exclusive Change összesen (minden körzet összege)
- **ART-CASH** (`_ac*`): Pénztárak >150, külön cég, index[0]=összesítés

### Excel struktúra (10 munkalap)
Minden körzeti lap azonos felépítésű:
- **Sorok 8-34:** 27 valuta készlet + Ft érték (per iroda 2 oszlop)
- **Sor 35:** ÖSSZESEN (összes valuta Ft értéke)
- **Sorok 38-43:** WU USD, WU HUF, ÁFA, Kezelési díj, E-kereskedés, Foglalók
- **Sor 47:** NAPI FORGALOM fejléc
- **Sorok 49-102:** Vétel/Eladás per valuta (2 sor per valuta: mennyiség + Ft érték szürkén)
- **Sor 103:** Forgalom összesen

Lapok:
1. SZEKSZÁRDI KÖRZET
2. SZEGEDI KÖRZET
3. KECSKEMÉTI KÖRZET
4. DEBRECENI KÖRZET
5. NYÍREGYHÁZI KÖRZET (sic)
6. BÉKÉSCSABAI KÖRZET (sic)
7. PÉCSI KÖRZET
8. KAPOSVÁRI KÖRZET
9. EXCLUSIVE CHANGE (körzetek mint oszlopok, összesen oszlop a 19-20.)
10. EXPRESSZ MINIBANK (ART-CASH irodák, unit3.pas logika)

## Modern implementáció

### Architektúra

```
StockSnapshotController (REST API)
    GET /api/stock-snapshot              → JSON teljes pillanatkép
    GET /api/stock-snapshot/excel        → XLSX letöltés
    GET /api/stock-snapshot/region/{code} → Körzet részletes adat
         │
StockSnapshotService (üzleti logika)
    ├── getFullSnapshot(companyId)
    ├── getRegionSnapshot(companyId, regionCode)
    └── aggregálás: branch → region → company
         │
    Adatforrások (meglévő repository-k):
    • CurrencyStockRepository
    • WuBalanceRepository
    • ReservationRepository
    • TransactionRepository (napi vétel/eladás)
    • BranchRepository
         │
StockSnapshotExcelService (Excel generálás, Apache POI)
    ├── generateFullWorkbook(snapshot)   → 10 lapos XLSX
    ├── writeRegionSheet(sheet, region)  → Körzeti lap
    ├── writeCompanySummarySheet(sheet)  → Cég összesítő
    └── writeExpressMinibank(sheet)      → ART-CASH lap
```

### DTO-k

```java
// Főstruktúra
StockSnapshotDto {
    LocalDateTime snapshotTime;
    UUID companyId;
    String companyName;
    List<RegionSnapshotDto> regions;
    BranchStockTotalsDto companyTotals;
}

RegionSnapshotDto {
    String regionCode;
    String regionName;
    List<BranchSnapshotDto> branches;
    BranchStockTotalsDto regionTotals;
}

BranchSnapshotDto {
    UUID branchId;
    String branchName;
    String branchCode;
    LocalDateTime lastUpdated;
    List<CurrencyStockDetailDto> currencies;  // 27 elem
    WuBalanceDetailDto wuBalance;
    List<ReservationSummaryDto> reservations;
}

CurrencyStockDetailDto {
    String currencyCode;
    long stock;
    long stockHuf;
    long dailyBuy;
    long dailyBuyHuf;
    long dailySell;
    long dailySellHuf;
}

WuBalanceDetailDto {
    long wuUsd;
    long wuHuf;
    long vat;           // ÁFA
    long handlingFee;   // kezelési díj
    long eCommerce;     // e-kereskedés
}

ReservationSummaryDto {
    String currencyCode;  // HUF, CHF, EUR, GBP, USD
    long totalAmount;
}

// Összesítőhöz
BranchStockTotalsDto {
    List<CurrencyStockDetailDto> currencies;
    WuBalanceDetailDto wuBalance;
    List<ReservationSummaryDto> reservations;
}
```

### Körzet-kezelés

A `Branch` entitásnak jelenleg nincs `regionCode` mezője. Két lehetőség:
1. Flyway migráció: `ALTER TABLE branch ADD COLUMN region_code VARCHAR(10)` + adatfeltöltés
2. A `parentBranch` hierarchia használata

**Választás: 1. opció** — explicit `regionCode` mező, mert:
- A legacy rendszerben ez egy egyértelmű koncepció (8 fix körzet)
- A `parentBranch` más célú (szervezeti hierarchia)
- Egyszerűbb query-k: `WHERE region_code = ?`

### Excel generálás részletei (Apache POI)

Legacy formázás 1:1 reprodukálása:
- **Betűtípusok:** Times New Roman 12 bold italic (fejléc), Arial 10 (adatok), Arial 12 bold italic (összesen)
- **Igazítás:** Középre (HorizontalAlignment.CENTER)
- **Cellák összenyitása:** Fejléc cellák, ÖSSZESEN sorok, WU cellák (2-2 oszlop)
- **Szám formátum:** `### ### ###`
- **Forgalmi Ft értékek:** Szürke betűszín (clGray)
- **Sor fagyasztás:** C8 cella fölött/balra
- **27 valuta fix sorrend:** AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF, ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD
- **Oszlop helper:** A-Z egyszerű, utána AA, AB... (GetOszlopBetu logika)

### Fájlok

```
backend/src/main/java/hu/puzzleir/valuta/
├── controller/StockSnapshotController.java
├── service/StockSnapshotService.java
├── service/StockSnapshotExcelService.java
├── dto/stocksnapshot/
│   ├── StockSnapshotDto.java
│   ├── RegionSnapshotDto.java
│   ├── BranchSnapshotDto.java
│   ├── CurrencyStockDetailDto.java
│   ├── WuBalanceDetailDto.java
│   ├── ReservationSummaryDto.java
│   └── BranchStockTotalsDto.java
└── ...
backend/src/main/resources/db/migration/
└── V95__branch_region_code.sql
backend/src/test/java/hu/puzzleir/valuta/
├── service/StockSnapshotServiceTest.java
└── service/StockSnapshotExcelServiceTest.java
```

### Dependency
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.2.5</version>
</dependency>
```

### Tesztelés
- **StockSnapshotServiceTest:** Aggregáció helyessége (branch → region → company), üres adatok kezelése, multi-tenant szűrés
- **StockSnapshotExcelServiceTest:** Excel cellaértékek, lap nevek, formázás, összesítő képletek

### Biztonsági követelmények
- `@PreAuthorize("hasAnyRole('ADMIN','MANAGER')")` a controller-en
- Minden query `companyId` szűréssel
- A `SecurityUtils.getCurrentCompanyId()` használata

## Nem implementálandó
- FTP letöltés (az adatok már az adatbázisban vannak)
- Bináris PK fájl parse (legacy formátum, nem szükséges)
- FOGLALO.DAT parse (a `Reservation` entitás már tartalmazza)
- unit2.pas ART-CASH logika (kikommentezve a legacy-ben is)
- `irodak.dat` / `acirodak.dat` kezelés (a `Branch` entitás tartalmazza)
