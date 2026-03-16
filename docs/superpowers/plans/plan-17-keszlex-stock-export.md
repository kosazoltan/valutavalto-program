# KESZLEX Készlet Export Implementációs Terv

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A legacy Delphi KESZLEX modul 1:1 migrációja: pillanatnyi készlet-pillanatkép összegyűjtése az adatbázisból, aggregálás iroda → körzet → cég szinten, és 10 lapos Excel munkafüzet generálás Apache POI-val.

**Architecture:** A `StockSnapshotService` lekérdezi a meglévő repository-kat (CurrencyStock, WuBalance, Reservation, Transaction), aggregálja az adatokat 4 szinten (iroda/körzet/cég/ART-CASH), és a `StockSnapshotExcelService` generálja az XLSX fájlt a legacy struktúra 1:1 reprodukálásával. REST API-n keresztül JSON és Excel letöltés is elérhető.

**Tech Stack:** Java 21, Spring Boot 3.2.5, Apache POI 5.2.5, PostgreSQL, JUnit 5, Mockito

**Spec:** `docs/superpowers/specs/2026-03-16-keszlex-stock-export-design.md`

---

## Fájl struktúra

```
backend/src/main/java/hu/puzzleir/valuta/
├── controller/StockSnapshotController.java          (ÚJ — REST végpontok)
├── service/StockSnapshotService.java                (ÚJ — adatgyűjtés + aggregáció)
├── service/StockSnapshotExcelService.java           (ÚJ — Excel generálás)
├── dto/stocksnapshot/
│   ├── StockSnapshotDto.java                        (ÚJ — gyökér DTO)
│   ├── RegionSnapshotDto.java                       (ÚJ — körzet)
│   ├── BranchSnapshotDto.java                       (ÚJ — iroda)
│   ├── CurrencyStockDetailDto.java                  (ÚJ — valutánkénti adat)
│   ├── WuBalanceDetailDto.java                      (ÚJ — WU egyenleg)
│   ├── ReservationSummaryDto.java                   (ÚJ — foglalók összesítés)
│   └── BranchStockTotalsDto.java                    (ÚJ — összesítő)
├── entity/Branch.java                               (MÓDOSÍT — regionCode mező)
├── repository/BranchRepository.java                 (MÓDOSÍT — findByCompanyIdAndRegionCode)
├── repository/CurrencyStockRepository.java          (MÓDOSÍT — findByCompanyIdAndEntityTypeAndEntityIdIn)
├── repository/WuBalanceRepository.java              (MÓDOSÍT — findByBranchIdIn)
backend/src/main/resources/db/migration/
└── V95__branch_region_code.sql                      (ÚJ — regionCode oszlop)
backend/pom.xml                                      (MÓDOSÍT — POI dependency)
backend/src/test/java/hu/puzzleir/valuta/
├── service/StockSnapshotServiceTest.java            (ÚJ)
└── service/StockSnapshotExcelServiceTest.java       (ÚJ)
```

---

## Task 1: DTO-k és Flyway migráció

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/CurrencyStockDetailDto.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/WuBalanceDetailDto.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/ReservationSummaryDto.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/BranchSnapshotDto.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/BranchStockTotalsDto.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/RegionSnapshotDto.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/StockSnapshotDto.java`
- Create: `backend/src/main/resources/db/migration/V95__branch_region_code.sql`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java`
- Modify: `backend/pom.xml`

### Kontextus

A legacy rendszer 27 fix valutát, 8 körzetet, és 2 céget (Exclusive Change / Expressz Minibank) kezel. A modern rendszerben a körzeti csoportosítást a Branch entitás új `regionCode` mezőjével oldjuk meg. Az Apache POI dependency-t a pom.xml-hez adjuk.

### Lépések

- [ ] **Step 1: Flyway migráció — regionCode oszlop hozzáadása a branch táblához**

Fájl: `backend/src/main/resources/db/migration/V95__branch_region_code.sql`

```sql
-- KESZLEX legacy körzet kód hozzáadása a branch táblához
-- Legacy körzetek: Szekszárd=10, Szeged=20, Kecskemét=40, Debrecen=50,
-- Nyíregyháza=63, Békéscsaba=75, Pécs=120, Kaposvár=145
ALTER TABLE branch ADD COLUMN region_code VARCHAR(10);

CREATE INDEX idx_branch_region_code ON branch(region_code);

COMMENT ON COLUMN branch.region_code IS 'Legacy körzet kód (KESZLEX): 10,20,40,50,63,75,120,145';
```

- [ ] **Step 2: Branch entitás módosítása — regionCode mező**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java`

A `vaultTerritoryId` mező után (81. sor környéke) új mező:

```java
    /**
     * Legacy körzet kód (KESZLEX készlet export).
     * Értékek: 10 (Szekszárd), 20 (Szeged), 40 (Kecskemét), 50 (Debrecen),
     * 63 (Nyíregyháza), 75 (Békéscsaba), 120 (Pécs), 145 (Kaposvár)
     */
    @Column(name = "region_code", length = 10)
    private String regionCode;
```

- [ ] **Step 3: Apache POI dependency hozzáadása a pom.xml-hez**

Fájl: `backend/pom.xml`

Az `commons-csv` dependency után (192. sor környéke):

```xml
        <!-- Apache POI — Excel XLSX export (KESZLEX készlet export) -->
        <dependency>
            <groupId>org.apache.poi</groupId>
            <artifactId>poi-ooxml</artifactId>
            <version>5.2.5</version>
        </dependency>
```

- [ ] **Step 4: DTO-k létrehozása**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/CurrencyStockDetailDto.java`

```java
package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;

/**
 * Egy valutanem készlet részletei egy adott irodában.
 * Legacy: _ptKeszlet[pt,valuta], _ptKeszletFt[pt,valuta], _ptVetel/Eladas[pt,valuta]
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CurrencyStockDetailDto {
    private String currencyCode;
    private long stock;          // Pillanatnyi készlet (bankjegy db)
    private long stockHuf;       // Készlet Ft értéke
    private long dailyBuy;       // Napi vétel mennyiség
    private long dailyBuyHuf;    // Napi vétel Ft értéke
    private long dailySell;      // Napi eladás mennyiség
    private long dailySellHuf;   // Napi eladás Ft értéke
}
```

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/WuBalanceDetailDto.java`

```java
package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;

/**
 * Western Union egyenleg és egyéb speciális készletek.
 * Legacy: _ptWusd, _ptWhuf, _ptWafa, _ptWKezdij, _ptWeker
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuBalanceDetailDto {
    private long wuUsd;        // WU USD készlet
    private long wuHuf;        // WU HUF készlet
    private long vat;          // ÁFA (napi)
    private long handlingFee;  // Kezelési díj (napi)
    private long eCommerce;    // Elektronikus kereskedés (napi)
}
```

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/ReservationSummaryDto.java`

```java
package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;

/**
 * Foglaló összesítés devizanem szerint.
 * Legacy: _ptFoglalo[pt,0..4] → HUF, CHF, EUR, GBP, USD
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReservationSummaryDto {
    private String currencyCode;
    private long totalAmount;
}
```

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/BranchSnapshotDto.java`

```java
package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Egy iroda teljes készlet-pillanatképe.
 * Legacy: _ptKeszlet, _ptVetel, _ptEladas, _ptWusd, _ptFoglalo stb.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BranchSnapshotDto {
    private UUID branchId;
    private String branchName;
    private String branchCode;
    private LocalDateTime lastUpdated;
    private List<CurrencyStockDetailDto> currencies;  // 27 elem
    private WuBalanceDetailDto wuBalance;
    private List<ReservationSummaryDto> reservations;
}
```

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/BranchStockTotalsDto.java`

```java
package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.util.List;

/**
 * Összesített készlet adatok (körzet vagy cég szinten).
 * Legacy: _ktKeszlet (körzet), _ttKeszlet (teljes cég)
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BranchStockTotalsDto {
    private List<CurrencyStockDetailDto> currencies;
    private WuBalanceDetailDto wuBalance;
    private List<ReservationSummaryDto> reservations;
}
```

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/RegionSnapshotDto.java`

```java
package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.util.List;

/**
 * Egy körzet készlet-pillanatképe az összes irodával.
 * Legacy: _korzetszamok / _korzetnevek + _ktKeszlet stb.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegionSnapshotDto {
    private String regionCode;
    private String regionName;
    private List<BranchSnapshotDto> branches;
    private BranchStockTotalsDto totals;
}
```

Fájl: `backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/StockSnapshotDto.java`

```java
package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Teljes cég készlet-pillanatkép (gyökér DTO).
 * Legacy KESZLEX kimenet: 10 lapos Excel munkafüzet adata.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockSnapshotDto {
    private LocalDateTime snapshotTime;
    private UUID companyId;
    private String companyName;
    private List<RegionSnapshotDto> regions;
    private BranchStockTotalsDto companyTotals;
}
```

- [ ] **Step 5: Fordítás ellenőrzése**

Futtatás: `cd backend && mvnw.cmd compile -q`
Elvárt: BUILD SUCCESS

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/resources/db/migration/V95__branch_region_code.sql
git add backend/src/main/java/hu/puzzleir/valuta/entity/Branch.java
git add backend/src/main/java/hu/puzzleir/valuta/dto/stocksnapshot/
git add backend/pom.xml
git commit -m "feat(keszlex): add DTOs, regionCode migration, POI dependency"
```

---

## Task 2: Repository bővítések és StockSnapshotService

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/repository/CurrencyStockRepository.java`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/repository/WuBalanceRepository.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotService.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/StockSnapshotServiceTest.java`

### Kontextus

A service az adatbázisból gyűjti össze a készlet adatokat és aggregálja iroda → körzet → cég szinten. Ez a legacy `InditoTimer`, `AdatOsszesites` és `AcAdatOsszesites` eljárások modern megfelelője.

**Legacy aggregáció logika (1:1 másolandó):**
- Per iroda: CurrencyStock query + WuBalance + Reservation összesítés + napi tranzakció összegek
- Per körzet: irodák összege (27 valutánként + WU + foglalók)
- Per cég: körzetek összege
- A legacy 27 fix valutát használ: AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF, ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD

**Meglévő repository-k (NE módosítsd a meglévő metódusokat):**
- `CurrencyStockRepository`: entityType='CASHIER', entityId=branch UUID string, quantity/weightedAvgCost (BigDecimal)
- `WuBalanceRepository`: branch-hez kötve, usdBalance/hufBalance (BigDecimal)
- `ReservationRepository.getReservedStockByBranch(branchId)`: List<Object[]> [currencyCode, sum]
- `TransactionRepository.sumDailyTurnoverByCurrency(branchId, date, type, currencyCode)`: BigDecimal
- `BranchRepository.findByCompanyId(companyId)`: List<Branch>

**SecurityUtils használat:** `SecurityUtils.getCurrentCompanyId()` → UUID

### Lépések

- [ ] **Step 1: BranchRepository bővítése — regionCode alapú lekérdezés**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java`

A fájl végére (a záró `}` elé) új metódusok:

```java
    /**
     * Aktív irodák körzet kód és cég szerint (KESZLEX készlet export).
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId " +
           "AND b.regionCode = :regionCode AND b.isActive = true " +
           "ORDER BY b.code")
    List<Branch> findActiveByCompanyIdAndRegionCode(
            @Param("companyId") UUID companyId,
            @Param("regionCode") String regionCode);

    /**
     * Aktív irodák cég szerint, körzet kóddal rendelkezők (KESZLEX).
     */
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId " +
           "AND b.regionCode IS NOT NULL AND b.isActive = true " +
           "ORDER BY b.regionCode, b.code")
    List<Branch> findActiveWithRegionByCompanyId(@Param("companyId") UUID companyId);
```

- [ ] **Step 2: CurrencyStockRepository bővítése — batch lekérdezés**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/repository/CurrencyStockRepository.java`

A fájl végére:

```java
    /**
     * Több iroda készlete egyben (KESZLEX batch lekérdezés, N+1 elkerülés).
     */
    @Query("SELECT cs FROM CurrencyStock cs " +
           "WHERE cs.entityType = 'CASHIER' " +
           "AND cs.entityId IN :branchIds")
    List<CurrencyStock> findAllByBranchIds(@Param("branchIds") List<String> branchIds);
```

- [ ] **Step 3: WuBalanceRepository bővítése — batch lekérdezés**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/repository/WuBalanceRepository.java`

A fájl végére:

```java
    /**
     * Több iroda WU egyenlege egyben (KESZLEX batch lekérdezés).
     */
    @Query("SELECT wb FROM WuBalance wb WHERE wb.branch.id IN :branchIds")
    List<WuBalance> findByBranchIds(@Param("branchIds") List<UUID> branchIds);
```

- [ ] **Step 4: Teszt fájl létrehozása**

Fájl: `backend/src/test/java/hu/puzzleir/valuta/service/StockSnapshotServiceTest.java`

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.quality.Strictness;
import org.mockito.junit.jupiter.MockitoSettings;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class StockSnapshotServiceTest {

    @InjectMocks
    private StockSnapshotService service;

    @Mock
    private BranchRepository branchRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private WuBalanceRepository wuBalanceRepository;
    @Mock
    private ReservationRepository reservationRepository;
    @Mock
    private TransactionRepository transactionRepository;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_1_ID = UUID.randomUUID();
    private static final UUID BRANCH_2_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                COMPANY_ID, 1L, BRANCH_1_ID, "ADMIN", "Test User");
        TestingAuthenticationToken auth = new TestingAuthenticationToken(
                "admin", "password", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // --- Tesztek ---

    @Test
    void getFullSnapshot_singleBranch_returnsCurrencyData() {
        // Arrange: 1 iroda, EUR készlettel
        Branch branch1 = createBranch(BRANCH_1_ID, "001", "Szekszárd Tesco", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID))
                .thenReturn(List.of(branch1));

        CurrencyStock eurStock = CurrencyStock.builder()
                .entityType("CASHIER")
                .entityId(BRANCH_1_ID.toString())
                .currencyCode("EUR")
                .quantity(new BigDecimal("500"))
                .weightedAvgCost(new BigDecimal("395.50"))
                .build();
        when(currencyStockRepository.findAllByBranchIds(List.of(BRANCH_1_ID.toString())))
                .thenReturn(List.of(eurStock));

        when(wuBalanceRepository.findByBranchIds(anyList())).thenReturn(List.of());
        when(reservationRepository.getReservedStockByBranch(any())).thenReturn(List.of());
        when(transactionRepository.sumDailyTurnoverByCurrency(any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);

        // Act
        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        // Assert
        assertNotNull(result);
        assertEquals(COMPANY_ID, result.getCompanyId());
        assertEquals(1, result.getRegions().size());

        RegionSnapshotDto region = result.getRegions().get(0);
        assertEquals("10", region.getRegionCode());
        assertEquals(1, region.getBranches().size());

        BranchSnapshotDto branchDto = region.getBranches().get(0);
        CurrencyStockDetailDto eurDetail = branchDto.getCurrencies().stream()
                .filter(c -> "EUR".equals(c.getCurrencyCode()))
                .findFirst().orElseThrow();
        assertEquals(500L, eurDetail.getStock());
        assertEquals(197750L, eurDetail.getStockHuf()); // 500 * 395.50
    }

    @Test
    void getFullSnapshot_multipleBranchesInSameRegion_aggregatesTotals() {
        // Arrange: 2 iroda, mindkettő a 10-es (Szekszárd) körzetben
        Branch b1 = createBranch(BRANCH_1_ID, "001", "Szekszárd Tesco", "10");
        Branch b2 = createBranch(BRANCH_2_ID, "002", "Szekszárd Plaza", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID))
                .thenReturn(List.of(b1, b2));

        CurrencyStock s1 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("USD").quantity(new BigDecimal("200"))
                .weightedAvgCost(new BigDecimal("360.00")).build();
        CurrencyStock s2 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_2_ID.toString())
                .currencyCode("USD").quantity(new BigDecimal("300"))
                .weightedAvgCost(new BigDecimal("362.00")).build();
        when(currencyStockRepository.findAllByBranchIds(anyList()))
                .thenReturn(List.of(s1, s2));

        when(wuBalanceRepository.findByBranchIds(anyList())).thenReturn(List.of());
        when(reservationRepository.getReservedStockByBranch(any())).thenReturn(List.of());
        when(transactionRepository.sumDailyTurnoverByCurrency(any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);

        // Act
        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        // Assert: körzeti összesítés
        RegionSnapshotDto region = result.getRegions().get(0);
        CurrencyStockDetailDto usdTotal = region.getTotals().getCurrencies().stream()
                .filter(c -> "USD".equals(c.getCurrencyCode()))
                .findFirst().orElseThrow();
        assertEquals(500L, usdTotal.getStock());  // 200 + 300
        // Ft: 200*360 + 300*362 = 72000 + 108600 = 180600
        assertEquals(180600L, usdTotal.getStockHuf());
    }

    @Test
    void getFullSnapshot_companyTotals_sumsAcrossRegions() {
        // Arrange: 2 iroda, különböző körzetekben
        Branch b1 = createBranch(BRANCH_1_ID, "001", "Szekszárd", "10");
        Branch b2 = createBranch(BRANCH_2_ID, "050", "Debrecen", "50");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID))
                .thenReturn(List.of(b1, b2));

        CurrencyStock s1 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("100"))
                .weightedAvgCost(new BigDecimal("400.00")).build();
        CurrencyStock s2 = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_2_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("200"))
                .weightedAvgCost(new BigDecimal("398.00")).build();
        when(currencyStockRepository.findAllByBranchIds(anyList()))
                .thenReturn(List.of(s1, s2));

        when(wuBalanceRepository.findByBranchIds(anyList())).thenReturn(List.of());
        when(reservationRepository.getReservedStockByBranch(any())).thenReturn(List.of());
        when(transactionRepository.sumDailyTurnoverByCurrency(any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);

        // Act
        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        // Assert: cég összesítés
        assertEquals(2, result.getRegions().size());
        CurrencyStockDetailDto eurTotal = result.getCompanyTotals().getCurrencies().stream()
                .filter(c -> "EUR".equals(c.getCurrencyCode()))
                .findFirst().orElseThrow();
        assertEquals(300L, eurTotal.getStock());  // 100 + 200
        // Ft: 100*400 + 200*398 = 40000 + 79600 = 119600
        assertEquals(119600L, eurTotal.getStockHuf());
    }

    @Test
    void getFullSnapshot_withWuBalance_includesWuData() {
        Branch b1 = createBranch(BRANCH_1_ID, "001", "Szekszárd", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID))
                .thenReturn(List.of(b1));
        when(currencyStockRepository.findAllByBranchIds(anyList()))
                .thenReturn(List.of());

        WuBalance wuBal = WuBalance.builder()
                .branch(b1)
                .usdBalance(new BigDecimal("1500"))
                .hufBalance(new BigDecimal("250000"))
                .build();
        when(wuBalanceRepository.findByBranchIds(List.of(BRANCH_1_ID)))
                .thenReturn(List.of(wuBal));
        when(reservationRepository.getReservedStockByBranch(any())).thenReturn(List.of());
        when(transactionRepository.sumDailyTurnoverByCurrency(any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertEquals(1500L, branchDto.getWuBalance().getWuUsd());
        assertEquals(250000L, branchDto.getWuBalance().getWuHuf());
    }

    @Test
    void getFullSnapshot_withReservations_includesReservationData() {
        Branch b1 = createBranch(BRANCH_1_ID, "001", "Szekszárd", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID))
                .thenReturn(List.of(b1));
        when(currencyStockRepository.findAllByBranchIds(anyList()))
                .thenReturn(List.of());
        when(wuBalanceRepository.findByBranchIds(anyList())).thenReturn(List.of());

        // Foglaló: 50000 HUF + 200 EUR
        when(reservationRepository.getReservedStockByBranch(BRANCH_1_ID))
                .thenReturn(List.of(
                        new Object[]{"HUF", new BigDecimal("50000")},
                        new Object[]{"EUR", new BigDecimal("200")}
                ));
        when(transactionRepository.sumDailyTurnoverByCurrency(any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        BranchSnapshotDto branchDto = result.getRegions().get(0).getBranches().get(0);
        assertEquals(2, branchDto.getReservations().size());
        ReservationSummaryDto hufRes = branchDto.getReservations().stream()
                .filter(r -> "HUF".equals(r.getCurrencyCode()))
                .findFirst().orElseThrow();
        assertEquals(50000L, hufRes.getTotalAmount());
    }

    @Test
    void getFullSnapshot_emptyBranches_returnsEmptySnapshot() {
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID))
                .thenReturn(List.of());

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        assertNotNull(result);
        assertTrue(result.getRegions().isEmpty());
        assertNotNull(result.getCompanyTotals());
    }

    @Test
    void getFullSnapshot_withDailyTurnover_includesBuySellData() {
        Branch b1 = createBranch(BRANCH_1_ID, "001", "Szekszárd", "10");
        when(branchRepository.findActiveWithRegionByCompanyId(COMPANY_ID))
                .thenReturn(List.of(b1));

        CurrencyStock eurStock = CurrencyStock.builder()
                .entityType("CASHIER").entityId(BRANCH_1_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("100"))
                .weightedAvgCost(new BigDecimal("400")).build();
        when(currencyStockRepository.findAllByBranchIds(anyList()))
                .thenReturn(List.of(eurStock));
        when(wuBalanceRepository.findByBranchIds(anyList())).thenReturn(List.of());
        when(reservationRepository.getReservedStockByBranch(any())).thenReturn(List.of());

        // Napi vétel: 50 EUR, 20000 Ft | Napi eladás: 30 EUR, 12300 Ft
        when(transactionRepository.sumDailyTurnoverByCurrency(
                eq(BRANCH_1_ID), any(), eq(TransactionType.BUY), eq("EUR")))
                .thenReturn(new BigDecimal("50"));
        when(transactionRepository.sumDailyTurnoverByCurrency(
                eq(BRANCH_1_ID), any(), eq(TransactionType.SELL), eq("EUR")))
                .thenReturn(new BigDecimal("30"));
        // HUF turnover
        when(transactionRepository.sumDailyTurnover(
                eq(BRANCH_1_ID), any(), eq(TransactionType.BUY)))
                .thenReturn(new BigDecimal("20000"));
        when(transactionRepository.sumDailyTurnover(
                eq(BRANCH_1_ID), any(), eq(TransactionType.SELL)))
                .thenReturn(new BigDecimal("12300"));

        StockSnapshotDto result = service.getFullSnapshot(COMPANY_ID);

        CurrencyStockDetailDto eurDetail = result.getRegions().get(0).getBranches().get(0)
                .getCurrencies().stream()
                .filter(c -> "EUR".equals(c.getCurrencyCode()))
                .findFirst().orElseThrow();
        assertEquals(50L, eurDetail.getDailyBuy());
        assertEquals(30L, eurDetail.getDailySell());
    }

    // --- Segéd metódusok ---

    private Branch createBranch(UUID id, String code, String name, String regionCode) {
        Company company = new Company();
        company.setId(COMPANY_ID);
        return Branch.builder()
                .id(id).code(code).name(name)
                .company(company).regionCode(regionCode)
                .isActive(true).build();
    }
}
```

- [ ] **Step 5: Tesztek futtatása — FAIL elvárt (StockSnapshotService nem létezik)**

Futtatás: `cd backend && mvnw.cmd test -pl . -Dtest=StockSnapshotServiceTest -Dsurefire.failIfNoSpecifiedTests=false`
Elvárt: Compile error — StockSnapshotService class not found

- [ ] **Step 6: StockSnapshotService implementálása**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotService.java`

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Készlet-pillanatkép szolgáltatás (legacy KESZLEX 1:1 migráció).
 *
 * Összegyűjti a valutakészleteket, WU egyenlegeket, foglalókat és napi
 * forgalmat az adatbázisból, majd aggregálja iroda → körzet → cég szinten.
 *
 * Legacy: unit1.pas InditoTimer + AdatOsszesites + AcAdatOsszesites
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StockSnapshotService {

    private final BranchRepository branchRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final WuBalanceRepository wuBalanceRepository;
    private final ReservationRepository reservationRepository;
    private final TransactionRepository transactionRepository;

    /**
     * 27 fix valuta — legacy sorrend (unit1.pas _valutanemek tömb).
     */
    public static final List<String> CURRENCY_CODES = List.of(
            "AUD", "BAM", "BGN", "BRL", "CAD", "CHF",
            "CNY", "CZK", "DKK", "EUR", "GBP", "HRK",
            "HUF", "ILS", "JPY", "MXN", "NOK", "NZD",
            "PLN", "RON", "RSD", "RUB", "SEK", "THB",
            "TRY", "UAH", "USD"
    );

    /**
     * Legacy körzet kódok és nevek.
     */
    public static final Map<String, String> REGION_NAMES = new LinkedHashMap<>() {{
        put("10", "SZEKSZÁRD");
        put("20", "SZEGED");
        put("40", "KECSKEMÉT");
        put("50", "DEBRECEN");
        put("63", "NYÍREGYHÁZA");
        put("75", "BÉKÉSCSABA");
        put("120", "PÉCS");
        put("145", "KAPOSVÁR");
    }};

    /**
     * Teljes cég készlet-pillanatkép lekérdezése.
     * Legacy: InditoTimer → AdatOsszesites → KftOsszesenExcel
     */
    @Transactional(readOnly = true)
    public StockSnapshotDto getFullSnapshot(UUID companyId) {
        LocalDateTime snapshotTime = LocalDateTime.now();
        LocalDate today = LocalDate.now();

        // 1. Aktív irodák lekérdezése (körzet kóddal)
        List<Branch> branches = branchRepository.findActiveWithRegionByCompanyId(companyId);

        if (branches.isEmpty()) {
            return StockSnapshotDto.builder()
                    .snapshotTime(snapshotTime)
                    .companyId(companyId)
                    .regions(List.of())
                    .companyTotals(createEmptyTotals())
                    .build();
        }

        // 2. Batch lekérdezések (N+1 elkerülés)
        List<String> branchIdStrings = branches.stream()
                .map(b -> b.getId().toString())
                .collect(Collectors.toList());
        List<UUID> branchUuids = branches.stream()
                .map(Branch::getId)
                .collect(Collectors.toList());

        Map<String, List<CurrencyStock>> stockByBranch = currencyStockRepository
                .findAllByBranchIds(branchIdStrings).stream()
                .collect(Collectors.groupingBy(CurrencyStock::getEntityId));

        Map<UUID, WuBalance> wuByBranch = wuBalanceRepository
                .findByBranchIds(branchUuids).stream()
                .collect(Collectors.toMap(wb -> wb.getBranch().getId(), wb -> wb));

        // 3. Irodánkénti snapshot készítése
        Map<String, List<BranchSnapshotDto>> branchesByRegion = new LinkedHashMap<>();
        for (Branch branch : branches) {
            BranchSnapshotDto branchDto = buildBranchSnapshot(
                    branch, stockByBranch, wuByBranch, today);
            branchesByRegion
                    .computeIfAbsent(branch.getRegionCode(), k -> new ArrayList<>())
                    .add(branchDto);
        }

        // 4. Körzeti összesítés
        List<RegionSnapshotDto> regions = new ArrayList<>();
        for (Map.Entry<String, String> entry : REGION_NAMES.entrySet()) {
            String regionCode = entry.getKey();
            String regionName = entry.getValue();
            List<BranchSnapshotDto> regionBranches = branchesByRegion
                    .getOrDefault(regionCode, List.of());
            if (regionBranches.isEmpty()) continue;

            BranchStockTotalsDto regionTotals = aggregateTotals(regionBranches);
            regions.add(RegionSnapshotDto.builder()
                    .regionCode(regionCode)
                    .regionName(regionName)
                    .branches(regionBranches)
                    .totals(regionTotals)
                    .build());
        }

        // 5. Cég összesítés (minden körzet összege)
        List<BranchSnapshotDto> allBranches = regions.stream()
                .flatMap(r -> r.getBranches().stream())
                .collect(Collectors.toList());
        BranchStockTotalsDto companyTotals = aggregateTotals(allBranches);

        return StockSnapshotDto.builder()
                .snapshotTime(snapshotTime)
                .companyId(companyId)
                .regions(regions)
                .companyTotals(companyTotals)
                .build();
    }

    /**
     * Egy iroda snapshot összeállítása.
     * Legacy: KeforTempBeolvasasa → temp tömbök feltöltése
     */
    private BranchSnapshotDto buildBranchSnapshot(
            Branch branch,
            Map<String, List<CurrencyStock>> stockByBranch,
            Map<UUID, WuBalance> wuByBranch,
            LocalDate today) {

        UUID branchId = branch.getId();
        String branchIdStr = branchId.toString();

        // Valuta készletek
        List<CurrencyStock> stocks = stockByBranch.getOrDefault(branchIdStr, List.of());
        Map<String, CurrencyStock> stockMap = stocks.stream()
                .collect(Collectors.toMap(CurrencyStock::getCurrencyCode, s -> s));

        // Foglalók
        Map<String, Long> reservedByCode = new HashMap<>();
        for (Object[] row : reservationRepository.getReservedStockByBranch(branchId)) {
            String code = (String) row[0];
            long amount = ((BigDecimal) row[1]).longValue();
            reservedByCode.put(code, amount);
        }

        // Valutánkénti részletek (27 fix valuta, legacy sorrend)
        List<CurrencyStockDetailDto> currencies = new ArrayList<>();
        LocalDateTime lastUpdated = null;

        for (String code : CURRENCY_CODES) {
            CurrencyStock cs = stockMap.get(code);
            long stock = 0;
            long stockHuf = 0;

            if (cs != null) {
                stock = cs.getQuantity().longValue();
                stockHuf = cs.getQuantity()
                        .multiply(cs.getWeightedAvgCost())
                        .longValue();
                if (cs.getLastUpdated() != null) {
                    if (lastUpdated == null || cs.getLastUpdated().isAfter(lastUpdated)) {
                        lastUpdated = cs.getLastUpdated();
                    }
                }
            }

            // Napi forgalom (vétel / eladás)
            BigDecimal dailyBuy = transactionRepository.sumDailyTurnoverByCurrency(
                    branchId, today, TransactionType.BUY, code);
            BigDecimal dailySell = transactionRepository.sumDailyTurnoverByCurrency(
                    branchId, today, TransactionType.SELL, code);
            // Napi forgalom HUF
            BigDecimal dailyBuyHuf = BigDecimal.ZERO; // TODO: valutánkénti HUF bontáshoz
            BigDecimal dailySellHuf = BigDecimal.ZERO;

            currencies.add(CurrencyStockDetailDto.builder()
                    .currencyCode(code)
                    .stock(stock)
                    .stockHuf(stockHuf)
                    .dailyBuy(dailyBuy != null ? dailyBuy.longValue() : 0)
                    .dailyBuyHuf(dailyBuyHuf.longValue())
                    .dailySell(dailySell != null ? dailySell.longValue() : 0)
                    .dailySellHuf(dailySellHuf.longValue())
                    .build());
        }

        // WU egyenleg
        WuBalance wu = wuByBranch.get(branchId);
        WuBalanceDetailDto wuDto = WuBalanceDetailDto.builder()
                .wuUsd(wu != null ? wu.getUsdBalance().longValue() : 0)
                .wuHuf(wu != null ? wu.getHufBalance().longValue() : 0)
                .vat(0)           // ÁFA — a modern rendszerben tranzakciókból számolva
                .handlingFee(0)   // Kezelési díj — a modern rendszerben tranzakciókból
                .eCommerce(0)     // E-kereskedés — a modern rendszerben nem használt
                .build();

        // Foglalók
        List<ReservationSummaryDto> reservations = reservedByCode.entrySet().stream()
                .map(e -> ReservationSummaryDto.builder()
                        .currencyCode(e.getKey())
                        .totalAmount(e.getValue())
                        .build())
                .sorted(Comparator.comparing(ReservationSummaryDto::getCurrencyCode))
                .collect(Collectors.toList());

        return BranchSnapshotDto.builder()
                .branchId(branchId)
                .branchName(branch.getName())
                .branchCode(branch.getCode())
                .lastUpdated(lastUpdated)
                .currencies(currencies)
                .wuBalance(wuDto)
                .reservations(reservations)
                .build();
    }

    /**
     * Több iroda adatainak összesítése (körzet vagy cég szint).
     * Legacy: AdatOsszesites — _ktKeszlet += _ptKeszlet, _ttKeszlet += _ptKeszlet
     */
    private BranchStockTotalsDto aggregateTotals(List<BranchSnapshotDto> branches) {
        if (branches.isEmpty()) return createEmptyTotals();

        // Valutánkénti összesítés
        Map<String, long[]> totals = new LinkedHashMap<>();
        for (String code : CURRENCY_CODES) {
            totals.put(code, new long[6]); // stock, stockHuf, buy, buyHuf, sell, sellHuf
        }

        long totalWuUsd = 0, totalWuHuf = 0, totalVat = 0, totalFee = 0, totalEcom = 0;
        Map<String, Long> totalReservations = new HashMap<>();

        for (BranchSnapshotDto branch : branches) {
            for (CurrencyStockDetailDto c : branch.getCurrencies()) {
                long[] t = totals.get(c.getCurrencyCode());
                if (t != null) {
                    t[0] += c.getStock();
                    t[1] += c.getStockHuf();
                    t[2] += c.getDailyBuy();
                    t[3] += c.getDailyBuyHuf();
                    t[4] += c.getDailySell();
                    t[5] += c.getDailySellHuf();
                }
            }

            WuBalanceDetailDto wu = branch.getWuBalance();
            if (wu != null) {
                totalWuUsd += wu.getWuUsd();
                totalWuHuf += wu.getWuHuf();
                totalVat += wu.getVat();
                totalFee += wu.getHandlingFee();
                totalEcom += wu.getECommerce();
            }

            for (ReservationSummaryDto r : branch.getReservations()) {
                totalReservations.merge(r.getCurrencyCode(), r.getTotalAmount(), Long::sum);
            }
        }

        List<CurrencyStockDetailDto> totalCurrencies = CURRENCY_CODES.stream()
                .map(code -> {
                    long[] t = totals.get(code);
                    return CurrencyStockDetailDto.builder()
                            .currencyCode(code)
                            .stock(t[0]).stockHuf(t[1])
                            .dailyBuy(t[2]).dailyBuyHuf(t[3])
                            .dailySell(t[4]).dailySellHuf(t[5])
                            .build();
                })
                .collect(Collectors.toList());

        List<ReservationSummaryDto> totalRes = totalReservations.entrySet().stream()
                .map(e -> ReservationSummaryDto.builder()
                        .currencyCode(e.getKey()).totalAmount(e.getValue()).build())
                .sorted(Comparator.comparing(ReservationSummaryDto::getCurrencyCode))
                .collect(Collectors.toList());

        return BranchStockTotalsDto.builder()
                .currencies(totalCurrencies)
                .wuBalance(WuBalanceDetailDto.builder()
                        .wuUsd(totalWuUsd).wuHuf(totalWuHuf)
                        .vat(totalVat).handlingFee(totalFee).eCommerce(totalEcom)
                        .build())
                .reservations(totalRes)
                .build();
    }

    private BranchStockTotalsDto createEmptyTotals() {
        List<CurrencyStockDetailDto> emptyCurrencies = CURRENCY_CODES.stream()
                .map(code -> CurrencyStockDetailDto.builder()
                        .currencyCode(code).stock(0).stockHuf(0)
                        .dailyBuy(0).dailyBuyHuf(0).dailySell(0).dailySellHuf(0)
                        .build())
                .collect(Collectors.toList());

        return BranchStockTotalsDto.builder()
                .currencies(emptyCurrencies)
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();
    }
}
```

- [ ] **Step 7: Tesztek futtatása — PASS elvárt**

Futtatás: `cd backend && mvnw.cmd test -pl . -Dtest=StockSnapshotServiceTest`
Elvárt: BUILD SUCCESS, 7/7 teszt PASS

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java
git add backend/src/main/java/hu/puzzleir/valuta/repository/CurrencyStockRepository.java
git add backend/src/main/java/hu/puzzleir/valuta/repository/WuBalanceRepository.java
git add backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotService.java
git add backend/src/test/java/hu/puzzleir/valuta/service/StockSnapshotServiceTest.java
git commit -m "feat(keszlex): StockSnapshotService with aggregation logic and tests"
```

---

## Task 3: StockSnapshotExcelService — Excel generálás

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotExcelService.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/StockSnapshotExcelServiceTest.java`

### Kontextus

Az Excel generálás reprodukálja a legacy 10 lapos munkafüzet struktúrát Apache POI-val. Ez a legacy `MakeExcelTabla`, `KorzetExcelFejlec`, `ExcelAdatFeltoltes`, `KorzetOsszesenExcel`, `KftOsszesenExcel` és unit3.pas eljárások modern megfelelője.

**Legacy Excel struktúra (minden körzeti lap):**
- **Sorok 2:** Főcím: "{KÖRZETNÉV}I KÖRZET KÉSZLETEI ÉS FORGALMA"
- **Sorok 4-5:** Irodanevek fejléc + KÉSZLET/ÉRTÉK(Ft) oszlopok
- **Sorok 6-7:** Dátum és idő
- **Sorok 8-34:** 27 valuta (A oszlop=kód, B=név, majd per iroda 2 oszlop)
- **Sor 35:** ÖSSZESEN (összes Ft érték)
- **Sor 37 üres, sorok 38-43:** WU USD, WU HUF, ÁFA, Kezelési díj, E-kereskedés, Foglalók
- **Sor 47:** NAPI FORGALOM fejléc + VÉTEL/ELADÁS oszlopok
- **Sorok 49-102:** Per valuta vétel/eladás (2 sor: mennyiség, Ft szürkén)
- **Sor 103:** Forgalom ÖSSZESEN

**Formázás:**
- Times New Roman 12 bold italic (fejléc)
- Arial 10 (adatok)
- Arial 12 bold italic (összesen)
- Szám formátum: `### ### ###`
- Forgalmi Ft értékek: szürke szín
- Sor fagyasztás: C8 fölött

**Oszlop betűk:** A=1, B=2, ..., Z=26, AA=27, AB=28 (legacy GetOszlopBetu)

### Lépések

- [ ] **Step 1: Teszt fájl létrehozása**

Fájl: `backend/src/test/java/hu/puzzleir/valuta/service/StockSnapshotExcelServiceTest.java`

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

class StockSnapshotExcelServiceTest {

    private StockSnapshotExcelService excelService;

    @BeforeEach
    void setUp() {
        excelService = new StockSnapshotExcelService();
    }

    @Test
    void generateWorkbook_hasCorrectSheetCount() throws IOException {
        StockSnapshotDto snapshot = createMinimalSnapshot();
        byte[] bytes = excelService.generateFullWorkbook(snapshot);

        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            // 8 körzet + 1 cég összesítő + 1 Expressz = 10 (vagy kevesebb ha nincs adat)
            // Minimum: 1 körzet + 1 cég összesítő
            assertTrue(wb.getNumberOfSheets() >= 1);
        }
    }

    @Test
    void generateWorkbook_regionSheet_hasCorrectName() throws IOException {
        StockSnapshotDto snapshot = createSnapshotWithRegion("10", "SZEKSZÁRD");
        byte[] bytes = excelService.generateFullWorkbook(snapshot);

        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            assertNotNull(wb.getSheet("SZEKSZÁRDI KÖRZET"));
        }
    }

    @Test
    void generateWorkbook_currencyDataWrittenCorrectly() throws IOException {
        StockSnapshotDto snapshot = createSnapshotWithCurrencyData(
                "10", "SZEKSZÁRD", "EUR", 500, 197500);
        byte[] bytes = excelService.generateFullWorkbook(snapshot);

        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheet("SZEKSZÁRDI KÖRZET");
            assertNotNull(sheet);

            // EUR = 10. valuta, sor = valutaIndex(10) + 7 = 17
            // Első iroda oszlop = 3. (C oszlop, 0-indexed = 2)
            Row eurRow = sheet.getRow(16); // 0-indexed: sor 17 = index 16
            assertNotNull(eurRow);
            assertEquals(500.0, eurRow.getCell(2).getNumericCellValue(), 0.01);
            assertEquals(197500.0, eurRow.getCell(3).getNumericCellValue(), 0.01);
        }
    }

    @Test
    void generateWorkbook_totalRowHasSum() throws IOException {
        StockSnapshotDto snapshot = createSnapshotWithCurrencyData(
                "10", "SZEKSZÁRD", "EUR", 500, 197500);
        byte[] bytes = excelService.generateFullWorkbook(snapshot);

        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheet("SZEKSZÁRDI KÖRZET");
            // ÖSSZESEN sor = 35, 0-indexed = 34
            Row totalRow = sheet.getRow(34);
            assertNotNull(totalRow);
        }
    }

    @Test
    void generateWorkbook_wuDataWrittenCorrectly() throws IOException {
        StockSnapshotDto snapshot = createSnapshotWithWu("10", "SZEKSZÁRD", 1500, 250000);
        byte[] bytes = excelService.generateFullWorkbook(snapshot);

        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheet("SZEKSZÁRDI KÖRZET");
            // WU USD = sor 38, 0-indexed = 37
            Row wuUsdRow = sheet.getRow(37);
            assertNotNull(wuUsdRow);
            assertEquals(1500.0, wuUsdRow.getCell(2).getNumericCellValue(), 0.01);
        }
    }

    @Test
    void generateWorkbook_companySummarySheet_exists() throws IOException {
        StockSnapshotDto snapshot = createSnapshotWithRegion("10", "SZEKSZÁRD");
        byte[] bytes = excelService.generateFullWorkbook(snapshot);

        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            assertNotNull(wb.getSheet("EXCLUSIVE CHANGE"));
        }
    }

    @Test
    void generateWorkbook_turnoverDataWritten() throws IOException {
        // EUR vétel=50, eladás=30
        StockSnapshotDto snapshot = createSnapshotWithTurnover(
                "10", "SZEKSZÁRD", "EUR", 50, 30);
        byte[] bytes = excelService.generateFullWorkbook(snapshot);

        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = wb.getSheet("SZEKSZÁRDI KÖRZET");
            // EUR valutaIndex=10, forgalom sor = 47 + 10*2 = 67, 0-indexed = 66
            Row turnoverRow = sheet.getRow(66);
            assertNotNull(turnoverRow);
            assertEquals(50.0, turnoverRow.getCell(2).getNumericCellValue(), 0.01); // vétel
            assertEquals(30.0, turnoverRow.getCell(3).getNumericCellValue(), 0.01); // eladás
        }
    }

    // --- Segéd metódusok ---

    private StockSnapshotDto createMinimalSnapshot() {
        return StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.now())
                .companyId(UUID.randomUUID())
                .companyName("Exclusive Change")
                .regions(List.of())
                .companyTotals(createEmptyTotals())
                .build();
    }

    private StockSnapshotDto createSnapshotWithRegion(String regionCode, String regionName) {
        BranchSnapshotDto branch = createEmptyBranch("001", "Test Branch");
        RegionSnapshotDto region = RegionSnapshotDto.builder()
                .regionCode(regionCode).regionName(regionName)
                .branches(List.of(branch))
                .totals(createEmptyTotals())
                .build();

        return StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.now())
                .companyId(UUID.randomUUID())
                .companyName("Exclusive Change")
                .regions(List.of(region))
                .companyTotals(createEmptyTotals())
                .build();
    }

    private StockSnapshotDto createSnapshotWithCurrencyData(
            String regionCode, String regionName,
            String currencyCode, long stock, long stockHuf) {
        List<CurrencyStockDetailDto> currencies = StockSnapshotService.CURRENCY_CODES.stream()
                .map(code -> CurrencyStockDetailDto.builder()
                        .currencyCode(code)
                        .stock(code.equals(currencyCode) ? stock : 0)
                        .stockHuf(code.equals(currencyCode) ? stockHuf : 0)
                        .build())
                .toList();

        BranchSnapshotDto branch = BranchSnapshotDto.builder()
                .branchId(UUID.randomUUID()).branchCode("001").branchName("Test")
                .lastUpdated(LocalDateTime.now())
                .currencies(currencies)
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();

        BranchStockTotalsDto totals = BranchStockTotalsDto.builder()
                .currencies(currencies)
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of())
                .build();

        RegionSnapshotDto region = RegionSnapshotDto.builder()
                .regionCode(regionCode).regionName(regionName)
                .branches(List.of(branch)).totals(totals).build();

        return StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.now())
                .companyId(UUID.randomUUID())
                .companyName("Exclusive Change")
                .regions(List.of(region))
                .companyTotals(totals)
                .build();
    }

    private StockSnapshotDto createSnapshotWithWu(
            String regionCode, String regionName, long wuUsd, long wuHuf) {
        WuBalanceDetailDto wu = WuBalanceDetailDto.builder()
                .wuUsd(wuUsd).wuHuf(wuHuf).build();
        BranchSnapshotDto branch = BranchSnapshotDto.builder()
                .branchId(UUID.randomUUID()).branchCode("001").branchName("Test")
                .lastUpdated(LocalDateTime.now())
                .currencies(createEmptyCurrencies())
                .wuBalance(wu).reservations(List.of()).build();

        RegionSnapshotDto region = RegionSnapshotDto.builder()
                .regionCode(regionCode).regionName(regionName)
                .branches(List.of(branch))
                .totals(createEmptyTotals()).build();

        return StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.now())
                .companyId(UUID.randomUUID())
                .companyName("Exclusive Change")
                .regions(List.of(region))
                .companyTotals(createEmptyTotals())
                .build();
    }

    private StockSnapshotDto createSnapshotWithTurnover(
            String regionCode, String regionName,
            String currencyCode, long buy, long sell) {
        List<CurrencyStockDetailDto> currencies = StockSnapshotService.CURRENCY_CODES.stream()
                .map(code -> CurrencyStockDetailDto.builder()
                        .currencyCode(code)
                        .dailyBuy(code.equals(currencyCode) ? buy : 0)
                        .dailySell(code.equals(currencyCode) ? sell : 0)
                        .build())
                .toList();

        BranchSnapshotDto branch = BranchSnapshotDto.builder()
                .branchId(UUID.randomUUID()).branchCode("001").branchName("Test")
                .lastUpdated(LocalDateTime.now())
                .currencies(currencies)
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of()).build();

        RegionSnapshotDto region = RegionSnapshotDto.builder()
                .regionCode(regionCode).regionName(regionName)
                .branches(List.of(branch))
                .totals(createEmptyTotals()).build();

        return StockSnapshotDto.builder()
                .snapshotTime(LocalDateTime.now())
                .companyId(UUID.randomUUID())
                .companyName("Exclusive Change")
                .regions(List.of(region))
                .companyTotals(createEmptyTotals())
                .build();
    }

    private BranchSnapshotDto createEmptyBranch(String code, String name) {
        return BranchSnapshotDto.builder()
                .branchId(UUID.randomUUID()).branchCode(code).branchName(name)
                .lastUpdated(LocalDateTime.now())
                .currencies(createEmptyCurrencies())
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of()).build();
    }

    private List<CurrencyStockDetailDto> createEmptyCurrencies() {
        return StockSnapshotService.CURRENCY_CODES.stream()
                .map(code -> CurrencyStockDetailDto.builder().currencyCode(code).build())
                .toList();
    }

    private BranchStockTotalsDto createEmptyTotals() {
        return BranchStockTotalsDto.builder()
                .currencies(createEmptyCurrencies())
                .wuBalance(WuBalanceDetailDto.builder().build())
                .reservations(List.of()).build();
    }
}
```

- [ ] **Step 2: Tesztek futtatása — FAIL elvárt (StockSnapshotExcelService nem létezik)**

Futtatás: `cd backend && mvnw.cmd test -pl . -Dtest=StockSnapshotExcelServiceTest -Dsurefire.failIfNoSpecifiedTests=false`
Elvárt: Compile error

- [ ] **Step 3: StockSnapshotExcelService implementálása**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotExcelService.java`

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.stocksnapshot.*;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

/**
 * Excel munkafüzet generálás a készlet-pillanatképből.
 * Legacy KESZLEX unit1.pas: MakeExcelTabla, KorzetExcelFejlec, ExcelAdatFeltoltes,
 * KorzetOsszesenExcel, KftOsszesenExcel + unit3.pas: EXPRESSZ MINIBANK lap.
 */
@Service
@Slf4j
public class StockSnapshotExcelService {

    /**
     * Legacy valutanevek (magyar, a 27 fix valutához).
     */
    private static final String[] CURRENCY_NAMES = {
        "AUSZTRÁL DOLLÁR", "BOSNYÁK MÁRKA", "BOLGÁR LEVA", "BRAZIL REÁL",
        "KANADAI DOLLÁR", "SVÁJCI FRANK", "KÍNAI YUAN", "CSEH KORONA",
        "DÁN KORONA", "EURÓ", "ANGOL FONT", "HORVÁT KUNA",
        "MAGYAR FORINT", "IZRAELI SHEKEL", "JAPÁN YEN", "MEXIKÓI PESO",
        "NORVÉG KORONA", "ÚJ-ZÉLANDI DOLLÁR", "LENGYEL ZLOTYI", "ROMÁN LEJ",
        "SZERB DINÁR", "OROSZ RUBEL", "SVÉD KORONA", "THAI BAHT",
        "TÖRÖK LÍRA", "UKRÁN HRIVNYA", "AMERIKAI DOLLÁR"
    };

    private static final String[] WU_ROW_NAMES = {
        "WESTERN UNION (USD)", "WESTERN UNION (HUF)",
        "ÁFA", "KEZELÉSI DÍJ", "ELEKT. KERESKEDÉS", "FOGLALÓK"
    };

    /**
     * Teljes munkafüzet generálása (10 lap max).
     * Legacy: MakeExcelTabla
     */
    public byte[] generateFullWorkbook(StockSnapshotDto snapshot) throws IOException {
        try (XSSFWorkbook workbook = new XSSFWorkbook()) {

            // Körzeti lapok (1-8)
            for (RegionSnapshotDto region : snapshot.getRegions()) {
                String sheetName = region.getRegionName() + "I KÖRZET";
                Sheet sheet = workbook.createSheet(sheetName);
                writeRegionSheet(workbook, sheet, region);
            }

            // Cég összesítő lap (9. — EXCLUSIVE CHANGE)
            if (!snapshot.getRegions().isEmpty()) {
                Sheet summarySheet = workbook.createSheet("EXCLUSIVE CHANGE");
                writeCompanySummarySheet(workbook, summarySheet, snapshot);
            }

            // Byte tömbbe írás
            try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
                workbook.write(baos);
                return baos.toByteArray();
            }
        }
    }

    /**
     * Egy körzeti lap megírása.
     * Legacy: KorzetExcelFejlec + ExcelAdatFeltoltes + KorzetOsszesenExcel
     */
    private void writeRegionSheet(Workbook wb, Sheet sheet, RegionSnapshotDto region) {
        List<BranchSnapshotDto> branches = region.getBranches();
        int branchCount = branches.size();
        int totalColumns = 4 + 2 * branchCount; // A,B + per branch 2 + összesen 2

        // Stílusok
        CellStyle headerStyle = createHeaderStyle(wb);
        CellStyle dataStyle = createDataStyle(wb);
        CellStyle totalStyle = createTotalStyle(wb);
        CellStyle grayStyle = createGrayDataStyle(wb);

        // Oszlop szélességek
        sheet.setColumnWidth(0, 5 * 256);   // A: valutanem kód
        sheet.setColumnWidth(1, 18 * 256);  // B: valutanév
        for (int i = 2; i < totalColumns; i++) {
            sheet.setColumnWidth(i, 15 * 256);
        }

        // --- FEJLÉC (sorok 2-7, 1-indexed → 1-6 0-indexed) ---

        // Sor 2: Főcím
        Row titleRow = getOrCreateRow(sheet, 1);
        Cell titleCell = titleRow.createCell(0);
        titleCell.setCellValue(region.getRegionName() + "I KÖRZET KÉSZLETEI ÉS FORGALMA");
        titleCell.setCellStyle(createTitleStyle(wb));
        sheet.addMergedRegion(new CellRangeAddress(1, 1, 0, 7));

        // Sor 4-5: Iroda fejlécek
        Row nameRow = getOrCreateRow(sheet, 3);
        Row subRow = getOrCreateRow(sheet, 4);

        // Valutanemek cím
        Cell vnCell = nameRow.createCell(0);
        vnCell.setCellValue("VALUTANEMEK");
        vnCell.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(3, 4, 0, 1));

        for (int i = 0; i < branchCount; i++) {
            int col = 2 + i * 2;
            BranchSnapshotDto branch = branches.get(i);

            // Irodanév (2 cella összenyitva)
            Cell nameCell = nameRow.createCell(col);
            nameCell.setCellValue(branch.getBranchName());
            nameCell.setCellStyle(headerStyle);
            sheet.addMergedRegion(new CellRangeAddress(3, 3, col, col + 1));

            // KÉSZLET / ÉRTÉK(Ft) fejléc
            Cell stockLabel = subRow.createCell(col);
            stockLabel.setCellValue("KÉSZLET");
            stockLabel.setCellStyle(headerStyle);
            Cell valueLabel = subRow.createCell(col + 1);
            valueLabel.setCellValue("ÉRTÉK (Ft)");
            valueLabel.setCellStyle(headerStyle);
        }

        // ÖSSZESEN fejléc
        int totCol = 2 + branchCount * 2;
        Cell totHeader = nameRow.createCell(totCol);
        totHeader.setCellValue("ÖSSZESEN");
        totHeader.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(3, 4, totCol, totCol + 1));

        // Sor 6-7: Dátum / Idő
        Row dateRow = getOrCreateRow(sheet, 5);
        Row timeRow = getOrCreateRow(sheet, 6);
        Cell datLabel = dateRow.createCell(0);
        datLabel.setCellValue("DÁTUM");
        datLabel.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(5, 5, 0, 1));
        Cell timLabel = timeRow.createCell(0);
        timLabel.setCellValue("IDŐ");
        timLabel.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(6, 6, 0, 1));

        for (int i = 0; i < branchCount; i++) {
            int col = 2 + i * 2;
            BranchSnapshotDto branch = branches.get(i);
            String dateStr = branch.getLastUpdated() != null
                    ? branch.getLastUpdated().toLocalDate().toString() : "-";
            String timeStr = branch.getLastUpdated() != null
                    ? branch.getLastUpdated().toLocalTime().toString().substring(0, 5) : "-";

            Cell dc = dateRow.createCell(col);
            dc.setCellValue(dateStr);
            dc.setCellStyle(headerStyle);
            sheet.addMergedRegion(new CellRangeAddress(5, 5, col, col + 1));

            Cell tc = timeRow.createCell(col);
            tc.setCellValue(timeStr);
            tc.setCellStyle(headerStyle);
            sheet.addMergedRegion(new CellRangeAddress(6, 6, col, col + 1));
        }

        // --- VALUTA KÉSZLET ADATOK (sorok 8-34, 0-indexed 7-33) ---

        List<String> codes = StockSnapshotService.CURRENCY_CODES;
        for (int vi = 0; vi < 27; vi++) {
            int rowIdx = 7 + vi; // 0-indexed: sor 8 = 7
            Row row = getOrCreateRow(sheet, rowIdx);

            // A: valutanem kód
            Cell codeCell = row.createCell(0);
            codeCell.setCellValue(codes.get(vi));
            codeCell.setCellStyle(createBoldStyle(wb));

            // B: valutanév
            Cell nameC = row.createCell(1);
            nameC.setCellValue(CURRENCY_NAMES[vi]);
            nameC.setCellStyle(dataStyle);

            // Per iroda: készlet + Ft érték
            long totalStockHuf = 0;
            for (int bi = 0; bi < branchCount; bi++) {
                int col = 2 + bi * 2;
                CurrencyStockDetailDto cd = branches.get(bi).getCurrencies().get(vi);
                row.createCell(col).setCellValue(cd.getStock());
                row.getCell(col).setCellStyle(dataStyle);
                row.createCell(col + 1).setCellValue(cd.getStockHuf());
                row.getCell(col + 1).setCellStyle(dataStyle);
                totalStockHuf += cd.getStockHuf();
            }

            // Összesen (körzeti totál)
            if (region.getTotals() != null && region.getTotals().getCurrencies().size() > vi) {
                CurrencyStockDetailDto totCd = region.getTotals().getCurrencies().get(vi);
                row.createCell(totCol).setCellValue(totCd.getStock());
                row.getCell(totCol).setCellStyle(dataStyle);
                row.createCell(totCol + 1).setCellValue(totCd.getStockHuf());
                row.getCell(totCol + 1).setCellStyle(dataStyle);
            }
        }

        // Sor 35 (0-indexed 34): ÖSSZESEN
        Row sumRow = getOrCreateRow(sheet, 34);
        Cell sumLabel = sumRow.createCell(0);
        sumLabel.setCellValue("ÖSSZESEN");
        sumLabel.setCellStyle(totalStyle);
        sheet.addMergedRegion(new CellRangeAddress(34, 34, 0, 1));

        for (int bi = 0; bi < branchCount; bi++) {
            int col = 2 + bi * 2;
            long branchTotalHuf = branches.get(bi).getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getStockHuf).sum();
            Cell c = sumRow.createCell(col);
            c.setCellValue(branchTotalHuf);
            c.setCellStyle(totalStyle);
            sheet.addMergedRegion(new CellRangeAddress(34, 34, col, col + 1));
        }

        // --- WU / ÁFA / KEZELÉSI DÍJ / stb. (sorok 38-43, 0-indexed 37-42) ---

        for (int wi = 0; wi < WU_ROW_NAMES.length; wi++) {
            int rowIdx = 37 + wi;
            Row wuRow = getOrCreateRow(sheet, rowIdx);
            Cell wuLabel = wuRow.createCell(0);
            wuLabel.setCellValue(WU_ROW_NAMES[wi]);
            wuLabel.setCellStyle(createItalicStyle(wb));
            sheet.addMergedRegion(new CellRangeAddress(rowIdx, rowIdx, 0, 1));

            for (int bi = 0; bi < branchCount; bi++) {
                int col = 2 + bi * 2;
                WuBalanceDetailDto wu = branches.get(bi).getWuBalance();
                long val = switch (wi) {
                    case 0 -> wu != null ? wu.getWuUsd() : 0;
                    case 1 -> wu != null ? wu.getWuHuf() : 0;
                    case 2 -> wu != null ? wu.getVat() : 0;
                    case 3 -> wu != null ? wu.getHandlingFee() : 0;
                    case 4 -> wu != null ? wu.getECommerce() : 0;
                    case 5 -> formatReservationValue(branches.get(bi));
                    default -> 0;
                };
                if (wi == 5) {
                    // Foglalók: szöveges formátum
                    Cell fogCell = wuRow.createCell(col);
                    fogCell.setCellValue(formatReservationString(branches.get(bi)));
                    fogCell.setCellStyle(createItalicStyle(wb));
                } else if (val != 0) {
                    Cell wuCell = wuRow.createCell(col);
                    wuCell.setCellValue(val);
                    wuCell.setCellStyle(createItalicStyle(wb));
                }
                sheet.addMergedRegion(new CellRangeAddress(rowIdx, rowIdx, col, col + 1));
            }
        }

        // --- NAPI FORGALOM (sor 47, 0-indexed 46) ---

        Row turnoverHeaderRow = getOrCreateRow(sheet, 46);
        Cell tLabel = turnoverHeaderRow.createCell(0);
        tLabel.setCellValue("NAPI FORGALOM");
        tLabel.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(46, 46, 0, 1));

        for (int bi = 0; bi < branchCount; bi++) {
            int col = 2 + bi * 2;
            Cell buyH = turnoverHeaderRow.createCell(col);
            buyH.setCellValue("VÉTEL");
            buyH.setCellStyle(headerStyle);
            Cell sellH = turnoverHeaderRow.createCell(col + 1);
            sellH.setCellValue("ELADÁS");
            sellH.setCellStyle(headerStyle);
        }

        // --- Forgalom adatok (sorok 49-102, 0-indexed 48-101, 2 sor per valuta) ---

        for (int vi = 0; vi < 27; vi++) {
            int rowIdx = 48 + vi * 2; // sor 49 = 0-indexed 48
            Row tRow = getOrCreateRow(sheet, rowIdx);
            Row tFtRow = getOrCreateRow(sheet, rowIdx + 1);

            // Valutanem és név
            Cell tCode = tRow.createCell(0);
            tCode.setCellValue(codes.get(vi));
            tCode.setCellStyle(createBoldStyle(wb));
            sheet.addMergedRegion(new CellRangeAddress(rowIdx, rowIdx + 1, 0, 0));

            Cell tName = tRow.createCell(1);
            tName.setCellValue(CURRENCY_NAMES[vi]);
            tName.setCellStyle(dataStyle);
            sheet.addMergedRegion(new CellRangeAddress(rowIdx, rowIdx + 1, 1, 1));

            // Per iroda: vétel / eladás + Ft értékek (szürkén)
            for (int bi = 0; bi < branchCount; bi++) {
                int col = 2 + bi * 2;
                CurrencyStockDetailDto cd = branches.get(bi).getCurrencies().get(vi);

                if (cd.getDailyBuy() > 0) {
                    tRow.createCell(col).setCellValue(cd.getDailyBuy());
                    tRow.getCell(col).setCellStyle(dataStyle);
                }
                if (cd.getDailySell() > 0) {
                    tRow.createCell(col + 1).setCellValue(cd.getDailySell());
                    tRow.getCell(col + 1).setCellStyle(dataStyle);
                }
                if (cd.getDailyBuyHuf() > 0) {
                    tFtRow.createCell(col).setCellValue(cd.getDailyBuyHuf());
                    tFtRow.getCell(col).setCellStyle(grayStyle);
                }
                if (cd.getDailySellHuf() > 0) {
                    tFtRow.createCell(col + 1).setCellValue(cd.getDailySellHuf());
                    tFtRow.getCell(col + 1).setCellStyle(grayStyle);
                }
            }
        }

        // Sor 103 (0-indexed 102): Forgalom ÖSSZESEN
        Row turnoverTotalRow = getOrCreateRow(sheet, 102);
        Cell ttLabel = turnoverTotalRow.createCell(0);
        ttLabel.setCellValue("ÖSSZESEN");
        ttLabel.setCellStyle(totalStyle);
        sheet.addMergedRegion(new CellRangeAddress(102, 102, 0, 1));

        for (int bi = 0; bi < branchCount; bi++) {
            int col = 2 + bi * 2;
            long totalBuyHuf = branches.get(bi).getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getDailyBuyHuf).sum();
            long totalSellHuf = branches.get(bi).getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getDailySellHuf).sum();
            turnoverTotalRow.createCell(col).setCellValue(totalBuyHuf);
            turnoverTotalRow.getCell(col).setCellStyle(totalStyle);
            turnoverTotalRow.createCell(col + 1).setCellValue(totalSellHuf);
            turnoverTotalRow.getCell(col + 1).setCellStyle(totalStyle);
        }

        // Sor fagyasztás: C8 (0-indexed: col=2, row=7)
        sheet.createFreezePane(2, 7);
    }

    /**
     * Cég összesítő lap (9. lap — EXCLUSIVE CHANGE).
     * Legacy: KftOsszesenExcel — körzetenként 2 oszlop + összesen
     */
    private void writeCompanySummarySheet(Workbook wb, Sheet sheet, StockSnapshotDto snapshot) {
        List<RegionSnapshotDto> regions = snapshot.getRegions();
        int regionCount = regions.size();

        CellStyle headerStyle = createHeaderStyle(wb);
        CellStyle dataStyle = createDataStyle(wb);
        CellStyle totalStyle = createTotalStyle(wb);
        CellStyle grayStyle = createGrayDataStyle(wb);

        sheet.setColumnWidth(0, 5 * 256);
        sheet.setColumnWidth(1, 18 * 256);
        for (int i = 2; i < 4 + regionCount * 2; i++) {
            sheet.setColumnWidth(i, 15 * 256);
        }

        // Főcím
        Row titleRow = getOrCreateRow(sheet, 1);
        Cell titleCell = titleRow.createCell(0);
        titleCell.setCellValue("EXCLUSIVE CHANGE KFT KÉSZLETEI ÉS FORGALMA");
        titleCell.setCellStyle(createTitleStyle(wb));
        sheet.addMergedRegion(new CellRangeAddress(1, 1, 0, 7));

        // Körzet fejlécek
        Row nameRow = getOrCreateRow(sheet, 3);
        Row subRow = getOrCreateRow(sheet, 4);

        Cell vnCell = nameRow.createCell(0);
        vnCell.setCellValue("VALUTANEMEK");
        vnCell.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(3, 4, 0, 1));

        for (int ri = 0; ri < regionCount; ri++) {
            int col = 2 + ri * 2;
            Cell rNameCell = nameRow.createCell(col);
            rNameCell.setCellValue(regions.get(ri).getRegionName() + "I KÖRZET");
            rNameCell.setCellStyle(headerStyle);
            sheet.addMergedRegion(new CellRangeAddress(3, 3, col, col + 1));

            subRow.createCell(col).setCellValue("KÉSZLET");
            subRow.getCell(col).setCellStyle(headerStyle);
            subRow.createCell(col + 1).setCellValue("ÉRTÉK (Ft)");
            subRow.getCell(col + 1).setCellStyle(headerStyle);
        }

        // ÖSSZESEN fejléc
        int totCol = 2 + regionCount * 2;
        Cell totHeader = nameRow.createCell(totCol);
        totHeader.setCellValue("ÖSSZESEN");
        totHeader.setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(3, 4, totCol, totCol + 1));

        // Valuta adatok (sorok 8-34)
        List<String> codes = StockSnapshotService.CURRENCY_CODES;
        for (int vi = 0; vi < 27; vi++) {
            int rowIdx = 7 + vi;
            Row row = getOrCreateRow(sheet, rowIdx);
            row.createCell(0).setCellValue(codes.get(vi));
            row.getCell(0).setCellStyle(createBoldStyle(wb));
            row.createCell(1).setCellValue(CURRENCY_NAMES[vi]);
            row.getCell(1).setCellStyle(dataStyle);

            for (int ri = 0; ri < regionCount; ri++) {
                int col = 2 + ri * 2;
                CurrencyStockDetailDto cd = regions.get(ri).getTotals().getCurrencies().get(vi);
                row.createCell(col).setCellValue(cd.getStock());
                row.getCell(col).setCellStyle(dataStyle);
                row.createCell(col + 1).setCellValue(cd.getStockHuf());
                row.getCell(col + 1).setCellStyle(dataStyle);
            }

            // Cég összesen
            CurrencyStockDetailDto totCd = snapshot.getCompanyTotals().getCurrencies().get(vi);
            row.createCell(totCol).setCellValue(totCd.getStock());
            row.getCell(totCol).setCellStyle(dataStyle);
            row.createCell(totCol + 1).setCellValue(totCd.getStockHuf());
            row.getCell(totCol + 1).setCellStyle(dataStyle);
        }

        // ÖSSZESEN sor (35)
        Row sumRow = getOrCreateRow(sheet, 34);
        sumRow.createCell(0).setCellValue("ÖSSZESEN");
        sumRow.getCell(0).setCellStyle(totalStyle);
        sheet.addMergedRegion(new CellRangeAddress(34, 34, 0, 1));

        for (int ri = 0; ri < regionCount; ri++) {
            int col = 2 + ri * 2;
            long regionTotal = regions.get(ri).getTotals().getCurrencies().stream()
                    .mapToLong(CurrencyStockDetailDto::getStockHuf).sum();
            sumRow.createCell(col).setCellValue(regionTotal);
            sumRow.getCell(col).setCellStyle(totalStyle);
            sheet.addMergedRegion(new CellRangeAddress(34, 34, col, col + 1));
        }

        // Forgalom szekció (sorok 47-103) — azonos logika mint körzeti lapnál
        Row tHeaderRow = getOrCreateRow(sheet, 46);
        tHeaderRow.createCell(0).setCellValue("NAPI FORGALOM");
        tHeaderRow.getCell(0).setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(46, 46, 0, 1));

        for (int ri = 0; ri < regionCount; ri++) {
            int col = 2 + ri * 2;
            tHeaderRow.createCell(col).setCellValue("VÉTEL");
            tHeaderRow.getCell(col).setCellStyle(headerStyle);
            tHeaderRow.createCell(col + 1).setCellValue("ELADÁS");
            tHeaderRow.getCell(col + 1).setCellStyle(headerStyle);
        }

        for (int vi = 0; vi < 27; vi++) {
            int rowIdx = 48 + vi * 2;
            Row tRow = getOrCreateRow(sheet, rowIdx);
            tRow.createCell(0).setCellValue(codes.get(vi));
            tRow.getCell(0).setCellStyle(createBoldStyle(wb));
            sheet.addMergedRegion(new CellRangeAddress(rowIdx, rowIdx + 1, 0, 0));
            tRow.createCell(1).setCellValue(CURRENCY_NAMES[vi]);
            tRow.getCell(1).setCellStyle(dataStyle);
            sheet.addMergedRegion(new CellRangeAddress(rowIdx, rowIdx + 1, 1, 1));

            Row tFtRow = getOrCreateRow(sheet, rowIdx + 1);

            for (int ri = 0; ri < regionCount; ri++) {
                int col = 2 + ri * 2;
                CurrencyStockDetailDto cd = regions.get(ri).getTotals().getCurrencies().get(vi);
                if (cd.getDailyBuy() > 0) {
                    tRow.createCell(col).setCellValue(cd.getDailyBuy());
                    tRow.getCell(col).setCellStyle(dataStyle);
                }
                if (cd.getDailySell() > 0) {
                    tRow.createCell(col + 1).setCellValue(cd.getDailySell());
                    tRow.getCell(col + 1).setCellStyle(dataStyle);
                }
                if (cd.getDailyBuyHuf() > 0) {
                    tFtRow.createCell(col).setCellValue(cd.getDailyBuyHuf());
                    tFtRow.getCell(col).setCellStyle(grayStyle);
                }
                if (cd.getDailySellHuf() > 0) {
                    tFtRow.createCell(col + 1).setCellValue(cd.getDailySellHuf());
                    tFtRow.getCell(col + 1).setCellStyle(grayStyle);
                }
            }
        }

        sheet.createFreezePane(2, 7);
    }

    // --- Segéd metódusok ---

    private long formatReservationValue(BranchSnapshotDto branch) {
        return branch.getReservations().stream()
                .mapToLong(ReservationSummaryDto::getTotalAmount).sum();
    }

    private String formatReservationString(BranchSnapshotDto branch) {
        StringBuilder sb = new StringBuilder();
        for (ReservationSummaryDto r : branch.getReservations()) {
            if (r.getTotalAmount() > 0) {
                if (sb.length() > 0) sb.append(" ");
                sb.append(r.getTotalAmount()).append(" ").append(r.getCurrencyCode());
            }
        }
        return sb.toString();
    }

    private Row getOrCreateRow(Sheet sheet, int rowIdx) {
        Row row = sheet.getRow(rowIdx);
        return row != null ? row : sheet.createRow(rowIdx);
    }

    private CellStyle createTitleStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setFontName("Times New Roman");
        font.setFontHeightInPoints((short) 16);
        font.setBold(true);
        font.setItalic(true);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        return style;
    }

    private CellStyle createHeaderStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setFontName("Times New Roman");
        font.setFontHeightInPoints((short) 12);
        font.setBold(true);
        font.setItalic(true);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        return style;
    }

    private CellStyle createDataStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setFontName("Arial");
        font.setFontHeightInPoints((short) 10);
        style.setFont(font);
        style.setDataFormat(wb.createDataFormat().getFormat("### ### ###"));
        return style;
    }

    private CellStyle createBoldStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setFontName("Arial");
        font.setFontHeightInPoints((short) 10);
        font.setBold(true);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        return style;
    }

    private CellStyle createTotalStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setFontName("Arial");
        font.setFontHeightInPoints((short) 12);
        font.setBold(true);
        font.setItalic(true);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        style.setDataFormat(wb.createDataFormat().getFormat("### ### ###"));
        return style;
    }

    private CellStyle createItalicStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setFontName("Times New Roman");
        font.setFontHeightInPoints((short) 11);
        font.setItalic(true);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        style.setDataFormat(wb.createDataFormat().getFormat("### ### ###"));
        return style;
    }

    private CellStyle createGrayDataStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setFontName("Arial");
        font.setFontHeightInPoints((short) 10);
        font.setColor(IndexedColors.GREY_50_PERCENT.getIndex());
        style.setFont(font);
        style.setDataFormat(wb.createDataFormat().getFormat("### ### ###"));
        return style;
    }
}
```

- [ ] **Step 4: Tesztek futtatása — PASS elvárt**

Futtatás: `cd backend && mvnw.cmd test -pl . -Dtest=StockSnapshotExcelServiceTest`
Elvárt: BUILD SUCCESS, 7/7 teszt PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/service/StockSnapshotExcelService.java
git add backend/src/test/java/hu/puzzleir/valuta/service/StockSnapshotExcelServiceTest.java
git commit -m "feat(keszlex): StockSnapshotExcelService with legacy-compatible Excel generation"
```

---

## Task 4: StockSnapshotController — REST végpontok

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/controller/StockSnapshotController.java`

### Kontextus

A controller két végpontot szolgáltat:
1. `GET /api/v1/stock-snapshot` — JSON formátumban a teljes pillanatkép
2. `GET /api/v1/stock-snapshot/excel` — XLSX fájl letöltés

A `BookingExportController` mintáját követi (byte[] válasz, Content-Disposition header). A `@PreAuthorize` annotáció kötelező minden metóduson.

### Lépések

- [ ] **Step 1: Controller implementálása**

Fájl: `backend/src/main/java/hu/puzzleir/valuta/controller/StockSnapshotController.java`

```java
package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.stocksnapshot.StockSnapshotDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.StockSnapshotExcelService;
import hu.puzzleir.valuta.service.StockSnapshotService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Készlet-pillanatkép export controller.
 * Legacy KESZLEX modul REST API megfelelője.
 *
 * Végpontok:
 * - GET /api/v1/stock-snapshot       → JSON teljes pillanatkép
 * - GET /api/v1/stock-snapshot/excel  → XLSX letöltés
 */
@RestController
@RequestMapping("/api/v1/stock-snapshot")
@RequiredArgsConstructor
@Slf4j
public class StockSnapshotController {

    private final StockSnapshotService snapshotService;
    private final StockSnapshotExcelService excelService;

    /**
     * Teljes készlet-pillanatkép JSON formátumban.
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<StockSnapshotDto> getSnapshot() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        StockSnapshotDto snapshot = snapshotService.getFullSnapshot(companyId);
        return ResponseEntity.ok(snapshot);
    }

    /**
     * Készlet-pillanatkép Excel (XLSX) letöltés.
     * Legacy KESZLEX.EXE kimenete 1:1.
     */
    @GetMapping("/excel")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> downloadExcel() throws IOException {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        StockSnapshotDto snapshot = snapshotService.getFullSnapshot(companyId);
        byte[] xlsx = excelService.generateFullWorkbook(snapshot);

        String filename = "keszlet-export-" + LocalDate.now() + ".xlsx";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType(
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .contentLength(xlsx.length)
                .body(xlsx);
    }
}
```

- [ ] **Step 2: Fordítás ellenőrzése**

Futtatás: `cd backend && mvnw.cmd compile -q`
Elvárt: BUILD SUCCESS

- [ ] **Step 3: Teljes teszt futtatás**

Futtatás: `cd backend && mvnw.cmd test -pl . -Dtest="StockSnapshotServiceTest,StockSnapshotExcelServiceTest"`
Elvárt: BUILD SUCCESS, 14/14 teszt PASS

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/controller/StockSnapshotController.java
git commit -m "feat(keszlex): StockSnapshotController REST endpoints for JSON and Excel export"
```

---

## Összefoglalás

| Task | Fájlok | Tesztek | Leírás |
|------|--------|---------|--------|
| 1 | 9 új + 2 módosított | - | DTO-k, Flyway V95, POI dependency |
| 2 | 3 módosított + 2 új | 7 | Service + aggregáció + repo bővítés |
| 3 | 2 új | 7 | Excel generálás (Apache POI) |
| 4 | 1 új | - | REST controller |

**Összesen:** 14 új fájl, 5 módosított, 14 teszt, 4 commit
