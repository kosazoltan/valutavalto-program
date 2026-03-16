# Balance Cascade Fixes Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three cascade issues in `DailyBalanceService.getOpeningBalance()` and add reconciliation alerting: (1) Havi zárás nyitó egyenleg `DailyBalance` táblából keres, nem a `MonthlyClosingSummary`-ból, (2) Az iroda első napján 0-val nyit (lehet, hogy van `CurrencyStock.initialBalance`), (3) `calculateAllCurrenciesForDay()` egy valuta hibája az egész stream-et leállítja, (4) Nincs egyeztetés: számított záró vs. tényleges készlet eltérés alert.

**Architecture:** `getOpeningBalance()` három szintű fallback: (1) előző nap záró a `DailyBalance` táblából, (2) `MonthlyClosingSummary` entitásból, (3) `CurrencyStock.initialBalance` fallback. A `calculateAllCurrenciesForDay()` try-catch burkolattal fut, hibás valuták loggolva és átugorva. Egy új `DailyBalanceReconciliationService` végzi az egyeztetést és `Alert` entitásba írja az eltéréseket.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Priority & Context

- **Priority:** P2-MEDIUM
- **Érintett fájlok:**
  - `backend/src/main/java/hu/puzzleir/valuta/service/DailyBalanceService.java` (fő módosítás)
  - `backend/src/main/java/hu/puzzleir/valuta/repository/MonthlyClosingSummaryRepository.java` (meglévő)
  - `backend/src/main/java/hu/puzzleir/valuta/repository/CurrencyStockRepository.java` (meglévő)
  - `backend/src/main/java/hu/puzzleir/valuta/service/DailyBalanceReconciliationService.java` (ÚJ)
  - `backend/src/test/java/hu/puzzleir/valuta/service/DailyBalanceServiceTest.java` (bővítés)

---

## Task 1: Nyitó egyenleg javítása — MonthlyClosingSummary prioritás

### 1.1 A bug leírása

```java
// JELENLEGI getOpeningBalance() (DailyBalanceService.java:169-177):
// Ha az előző nap nincs, ez fut:
List<DailyBalance> monthlyClosing = dailyBalanceRepository.findMonthlyClosingBalance(
    branchId, currencyCode, previousMonthEnd.getYear(), previousMonthEnd.getMonthValue()
);
// ← Ez a DailyBalance táblából keres, nem a MonthlyClosingSummary-ból!
// Ha a havi zárás tábla más entitásban van (MonthlyClosingSummary), az soha nem kerül felhasználásra.
```

### 1.2 MonthlyClosingSummary entity ellenőrzése

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/entity/MonthlyClosingSummary.java`
- [ ] Azonosítsd a releváns mezőket (closingBalance, branchId, currencyCode, year, month):

```bash
grep -n "closingBalance\|branchId\|currencyCode\|closingYear\|closingMonth" \
  backend/src/main/java/hu/puzzleir/valuta/entity/MonthlyClosingSummary.java
```

- [ ] Ellenőrizd a `MonthlyClosingSummaryRepository`-t:

```bash
grep -n "findBy\|@Query" \
  backend/src/main/java/hu/puzzleir/valuta/repository/MonthlyClosingSummaryRepository.java
```

### 1.3 Szükséges repository metódus

- [ ] Ha nem létezik, add a `MonthlyClosingSummaryRepository`-hoz:

```java
/**
 * Havi zárás záró egyenlege adott iroda+valuta+hónap kombinációra.
 */
@Query("SELECT mcs.closingBalance FROM MonthlyClosingSummary mcs " +
       "WHERE mcs.branchId = :branchId " +
       "AND mcs.currencyCode = :currencyCode " +
       "AND mcs.closingYear = :year " +
       "AND mcs.closingMonth = :month " +
       "AND mcs.status = 'CLOSED'")
Optional<BigDecimal> findClosingBalance(
    @Param("branchId") UUID branchId,
    @Param("currencyCode") String currencyCode,
    @Param("year") int year,
    @Param("month") int month
);
```

> **Megjegyzés:** Az `MonthlyClosingSummary` entitás mezőneveit (`closingBalance`, `closingYear`, `closingMonth`, `status`) a tényleges entitáshoz kell igazítani — futtatás előtt ellenőrizd.

### 1.4 TDD

- [ ] Nyisd meg: `backend/src/test/java/hu/puzzleir/valuta/service/DailyBalanceServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class DailyBalanceServiceTest {

    @Mock private DailyBalanceRepository dailyBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;

    @InjectMocks private DailyBalanceService dailyBalanceService;

    private static final UUID BRANCH_ID  = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    // ============ TASK 1: MONTHLY CLOSING SUMMARY PRIORITÁS ============

    @Test
    @DisplayName("getOpeningBalance: előző nap nincs → MonthlyClosingSummary-ból veszi a nyitót")
    void getOpeningBalance_usesMonthlyClosingSummary_notDailyBalance() {
        mockSecurityContext(COMPANY_ID, BRANCH_ID);
        mockCompany();

        LocalDate date = LocalDate.of(2026, 3, 1); // hónap eleje

        // Előző nap (2026-02-28) nincs a DailyBalance-ban
        when(dailyBalanceRepository.findClosingBalance(BRANCH_ID, "EUR",
            LocalDate.of(2026, 2, 28))).thenReturn(Optional.empty());

        // DailyBalance findMonthlyClosingBalance NEM adja vissza (ellenőrzés, hogy nem hívják)
        // MonthlyClosingSummary visszaadja a februári záró egyenleget
        when(monthlyClosingSummaryRepository.findClosingBalance(
            BRANCH_ID, "EUR", 2026, 2))
            .thenReturn(Optional.of(new BigDecimal("5000.0000")));

        mockCurrencies("EUR");
        mockZeroTransactions(BRANCH_ID, date, "EUR");
        when(dailyBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        DailyBalance result = dailyBalanceService.calculateDailyBalance(BRANCH_ID, date, "EUR");

        assertThat(result.getOpeningBalance()).isEqualByComparingTo(new BigDecimal("5000.0000"));

        // FONTOS: NEM a dailyBalanceRepository.findMonthlyClosingBalance hívódott
        verify(dailyBalanceRepository, never()).findMonthlyClosingBalance(any(), any(), anyInt(), anyInt());
        // HANEM a MonthlyClosingSummaryRepository
        verify(monthlyClosingSummaryRepository).findClosingBalance(BRANCH_ID, "EUR", 2026, 2);
    }

    @Test
    @DisplayName("getOpeningBalance: előző nap záró megvan → MonthlyClosingSummary NEM kell")
    void getOpeningBalance_previousDayExists_skipsMonthlySummary() {
        mockSecurityContext(COMPANY_ID, BRANCH_ID);
        mockCompany();

        LocalDate date = LocalDate.of(2026, 3, 15);

        when(dailyBalanceRepository.findClosingBalance(BRANCH_ID, "EUR",
            LocalDate.of(2026, 3, 14)))
            .thenReturn(Optional.of(new BigDecimal("3000.0000")));

        mockCurrencies("EUR");
        mockZeroTransactions(BRANCH_ID, date, "EUR");
        when(dailyBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        DailyBalance result = dailyBalanceService.calculateDailyBalance(BRANCH_ID, date, "EUR");

        assertThat(result.getOpeningBalance()).isEqualByComparingTo(new BigDecimal("3000.0000"));
        verify(monthlyClosingSummaryRepository, never()).findClosingBalance(any(), any(), anyInt(), anyInt());
    }
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DailyBalanceServiceTest#getOpeningBalance*` → PIROS

### 1.5 Fix implementálása

- [ ] Nyisd meg: `DailyBalanceService.java`
- [ ] Add hozzá a `MonthlyClosingSummaryRepository` és `CurrencyStockRepository` függőségeket
- [ ] Cseréld le a `getOpeningBalance()` metódust:

```java
/**
 * Nyitó készlet számítása — háromszintű fallback.
 *
 * 1. szint: Előző nap záró egyenlege (DailyBalance tábla)
 * 2. szint: Előző hónap havi záró összefoglaló (MonthlyClosingSummary)
 * 3. szint: Kezdeti készlet beállítás (CurrencyStock.initialBalance)
 * 4. szint: 0 (ha semmi sem elérhető — első nap, nincs beállítás)
 */
private BigDecimal getOpeningBalance(UUID branchId, LocalDate date, String currencyCode) {
    // === 1. SZINT: Előző nap záró ===
    LocalDate previousDay = date.minusDays(1);
    Optional<BigDecimal> previousDayClosing = dailyBalanceRepository
        .findClosingBalance(branchId, currencyCode, previousDay);

    if (previousDayClosing.isPresent()) {
        log.debug("Nyitó egyenleg forrása: előző nap záró. branchId={}, currency={}, date={}",
            branchId, currencyCode, date);
        return previousDayClosing.get();
    }

    // === 2. SZINT: Előző hónap havi záró ===
    LocalDate previousMonthEnd = date.minusMonths(1).withDayOfMonth(
        date.minusMonths(1).lengthOfMonth()
    );
    Optional<BigDecimal> monthlyClosingBalance = monthlyClosingSummaryRepository
        .findClosingBalance(
            branchId, currencyCode,
            previousMonthEnd.getYear(), previousMonthEnd.getMonthValue()
        );

    if (monthlyClosingBalance.isPresent()) {
        log.debug("Nyitó egyenleg forrása: MonthlyClosingSummary. branchId={}, currency={}, date={}",
            branchId, currencyCode, date);
        return monthlyClosingBalance.get();
    }

    // === 3. SZINT: CurrencyStock.initialBalance ===
    Optional<BigDecimal> initialBalance = currencyStockRepository
        .findInitialBalanceByBranchAndCurrency(branchId, currencyCode);

    if (initialBalance.isPresent()) {
        log.info("Nyitó egyenleg forrása: CurrencyStock.initialBalance (első nap). " +
            "branchId={}, currency={}, date={}", branchId, currencyCode, date);
        return initialBalance.get();
    }

    // === 4. SZINT: 0 (semmi sem elérhető) ===
    log.warn("Nincs nyitó egyenleg forrás: branchId={}, currency={}, date={} → nyitó=0",
        branchId, currencyCode, date);
    return BigDecimal.ZERO;
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DailyBalanceServiceTest` → ZÖLD

---

## Task 2: CurrencyStock initialBalance fallback

### 2.1 CurrencyStockRepository metódus

- [ ] Ellenőrizd a `CurrencyStock` entitás mezőneveit:

```bash
grep -n "initialBalance\|openingBalance\|branchId\|currencyCode" \
  backend/src/main/java/hu/puzzleir/valuta/entity/CurrencyStock.java
```

- [ ] Ha szükséges, add a `CurrencyStockRepository`-hoz:

```java
/**
 * Iroda+valuta kezdeti egyenleg lekérdezése (első nap fallback).
 */
@Query("SELECT cs.initialBalance FROM CurrencyStock cs " +
       "WHERE cs.branch.id = :branchId " +
       "AND cs.currency.code = :currencyCode " +
       "AND cs.initialBalance IS NOT NULL")
Optional<BigDecimal> findInitialBalanceByBranchAndCurrency(
    @Param("branchId") UUID branchId,
    @Param("currencyCode") String currencyCode
);
```

> **Megjegyzés:** Az `initialBalance` mező nevét a tényleges `CurrencyStock.java`-ban kell ellenőrizni. A seed migráció (`V83__seed_cash_registers_and_stocks.sql`) tartalmazza az inicializálási értékeket.

### 2.2 TDD

```java
@Test
@DisplayName("getOpeningBalance: nincs előző nap, nincs havi zárás → CurrencyStock.initialBalance")
void getOpeningBalance_fallsBackToCurrencyStock() {
    mockSecurityContext(COMPANY_ID, BRANCH_ID);
    mockCompany();

    LocalDate date = LocalDate.of(2026, 1, 1); // iroda nyitónapja

    // Nincs előző nap
    when(dailyBalanceRepository.findClosingBalance(BRANCH_ID, "EUR",
        LocalDate.of(2025, 12, 31))).thenReturn(Optional.empty());

    // Nincs havi zárás (december)
    when(monthlyClosingSummaryRepository.findClosingBalance(
        BRANCH_ID, "EUR", 2025, 12)).thenReturn(Optional.empty());

    // Van CurrencyStock initialBalance
    when(currencyStockRepository.findInitialBalanceByBranchAndCurrency(BRANCH_ID, "EUR"))
        .thenReturn(Optional.of(new BigDecimal("10000.0000")));

    mockCurrencies("EUR");
    mockZeroTransactions(BRANCH_ID, date, "EUR");
    when(dailyBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    DailyBalance result = dailyBalanceService.calculateDailyBalance(BRANCH_ID, date, "EUR");

    assertThat(result.getOpeningBalance()).isEqualByComparingTo(new BigDecimal("10000.0000"));
}

@Test
@DisplayName("getOpeningBalance: minden forrás hiányzik → nyitó=0, nem dob hibát")
void getOpeningBalance_allSourcesMissing_returnsZero() {
    mockSecurityContext(COMPANY_ID, BRANCH_ID);
    mockCompany();

    LocalDate date = LocalDate.of(2026, 3, 1);

    when(dailyBalanceRepository.findClosingBalance(any(), any(), any()))
        .thenReturn(Optional.empty());
    when(monthlyClosingSummaryRepository.findClosingBalance(any(), any(), anyInt(), anyInt()))
        .thenReturn(Optional.empty());
    when(currencyStockRepository.findInitialBalanceByBranchAndCurrency(any(), any()))
        .thenReturn(Optional.empty());

    mockCurrencies("EUR");
    mockZeroTransactions(BRANCH_ID, date, "EUR");
    when(dailyBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    DailyBalance result = dailyBalanceService.calculateDailyBalance(BRANCH_ID, date, "EUR");

    assertThat(result.getOpeningBalance()).isEqualByComparingTo(BigDecimal.ZERO);
}
```

---

## Task 3: calculateAllCurrenciesForDay — per-valuta hibaizolálás

### 3.1 A bug leírása

```java
// JELENLEGI (DailyBalanceService.java:143-147):
return currencies.stream()
    .map(currency -> calculateDailyBalance(branchId, date, currency.getCode()))
    .collect(Collectors.toList());
// ← Ha az EUR számítás közben RuntimeException dob, az USD stb. sem fut le!
```

### 3.2 TDD

```java
@Test
@DisplayName("calculateAllCurrenciesForDay: egy valuta hibája nem állítja le a többit")
void calculateAllCurrenciesForDay_oneFailure_othersStillProcess() {
    mockSecurityContext(COMPANY_ID, BRANCH_ID);
    mockCompany();

    LocalDate date = LocalDate.of(2026, 3, 16);

    // EUR, USD, GBP aktív valuták
    List<Currency> currencies = List.of(
        buildCurrency("EUR", 1L),
        buildCurrency("USD", 2L),
        buildCurrency("GBP", 3L)
    );
    when(currencyRepository.findActiveByCompany(COMPANY_ID)).thenReturn(currencies);

    // EUR rendben lefut
    mockZeroTransactions(BRANCH_ID, date, "EUR");
    when(dailyBalanceRepository.findClosingBalance(BRANCH_ID, "EUR", date.minusDays(1)))
        .thenReturn(Optional.empty());
    when(monthlyClosingSummaryRepository.findClosingBalance(any(), eq("EUR"), anyInt(), anyInt()))
        .thenReturn(Optional.empty());
    when(currencyStockRepository.findInitialBalanceByBranchAndCurrency(any(), eq("EUR")))
        .thenReturn(Optional.empty());

    // USD RuntimeException-t dob (pl. adatbázis hiba)
    when(transactionRepository.sumDailyTurnoverByCurrency(BRANCH_ID, date, TransactionType.BUY, "USD"))
        .thenThrow(new RuntimeException("Adatbázis hiba USD-nél"));

    // GBP rendben lefut
    mockZeroTransactions(BRANCH_ID, date, "GBP");
    when(dailyBalanceRepository.findClosingBalance(BRANCH_ID, "GBP", date.minusDays(1)))
        .thenReturn(Optional.empty());
    when(monthlyClosingSummaryRepository.findClosingBalance(any(), eq("GBP"), anyInt(), anyInt()))
        .thenReturn(Optional.empty());
    when(currencyStockRepository.findInitialBalanceByBranchAndCurrency(any(), eq("GBP")))
        .thenReturn(Optional.empty());

    when(dailyBalanceRepository
        .findByBranchIdAndBalanceDateAndCurrencyCode(any(), any(), any()))
        .thenReturn(Optional.empty());
    when(dailyBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    // Nem dob kivételt
    List<DailyBalance> results = assertDoesNotThrow(() ->
        dailyBalanceService.calculateAllCurrenciesForDay(BRANCH_ID, date));

    // EUR és GBP feldolgozásra került, USD kimaradt (hiba miatt)
    assertThat(results).hasSize(2);
    assertThat(results.stream().map(DailyBalance::getCurrencyCode).collect(Collectors.toList()))
        .containsExactlyInAnyOrder("EUR", "GBP");
}
```

### 3.3 Fix implementálása

- [ ] Nyisd meg: `DailyBalanceService.java` → `calculateAllCurrenciesForDay()`
- [ ] Cseréld le:

```java
/**
 * Összes valuta napi mérlege — hibatoleráns implementáció.
 * Egy valuta feldolgozási hibája nem akadályozza meg a többit.
 */
public List<DailyBalance> calculateAllCurrenciesForDay(UUID branchId, LocalDate date) {
    log.info("Összes valuta napi mérlege: branchId={}, date={}", branchId, date);

    List<Currency> currencies = currencyRepository.findActiveByCompany(
        SecurityUtils.getCurrentCompanyId());

    List<DailyBalance> results = new ArrayList<>();
    List<String> failedCurrencies = new ArrayList<>();

    for (Currency currency : currencies) {
        try {
            DailyBalance balance = calculateDailyBalance(branchId, date, currency.getCode());
            results.add(balance);
        } catch (Exception e) {
            // ÚJ: Elnyeljük az egyes valuta hibákat — a többi folytatódik
            failedCurrencies.add(currency.getCode());
            log.error("Napi mérleg számítási hiba: branchId={}, date={}, currency={}, hiba={}",
                branchId, date, currency.getCode(), e.getMessage(), e);
        }
    }

    if (!failedCurrencies.isEmpty()) {
        log.warn("Sikertelen valuta számítások: {} (összesen {} valutából {})",
            String.join(", ", failedCurrencies),
            currencies.size(), failedCurrencies.size());

        // Audit log bejegyzés a részleges hibáról
        try {
            auditLogService.log(
                "DAILY_BALANCE_PARTIAL_FAILURE",
                String.format("Napi mérleg részleges hiba %s napon: sikertelen valuták: %s",
                    date, String.join(", ", failedCurrencies)),
                branchId.toString()
            );
        } catch (Exception auditEx) {
            log.warn("Audit log írás sikertelen: {}", auditEx.getMessage());
        }
    }

    return results;
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=DailyBalanceServiceTest#calculateAllCurrenciesForDay*` → ZÖLD

---

## Task 4: Egyeztetés — számított záró vs. tényleges készlet

### 4.1 DailyBalanceReconciliationService létrehozása

- [ ] Hozd létre: `backend/src/main/java/hu/puzzleir/valuta/service/DailyBalanceReconciliationService.java`

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Napi mérleg egyeztetési szolgáltatás.
 *
 * Összehasonlítja a számított záró egyenleget (DailyBalance.closingBalance)
 * a tényleges kassza egyenleggel (CashBalance.currentBalance).
 *
 * Eltérés esetén audit logba írja és alert-et generál.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DailyBalanceReconciliationService {

    private final DailyBalanceRepository dailyBalanceRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final AuditLogService auditLogService;

    /** Eltérés tolerancia: ennél kisebb eltérés nem generál alertet (kerekítési hiba). */
    private static final BigDecimal TOLERANCE = new BigDecimal("0.01");

    /**
     * Egyeztetés egy iroda összes valutájára adott napra.
     *
     * @return Azok a ReconciliationAlert objektumok, amelyek eltérést találtak
     */
    @Transactional(readOnly = true)
    public List<ReconciliationAlert> reconcile(UUID branchId, LocalDate date) {
        log.info("Napi mérleg egyeztetés: branchId={}, date={}", branchId, date);

        // Számított záró egyenlegek (DailyBalance)
        List<DailyBalance> calculatedBalances = dailyBalanceRepository
            .findByBranchIdAndBalanceDate(branchId, date);

        // Tényleges kassza egyenlegek (CashBalance)
        List<CashBalance> actualBalances = cashBalanceRepository.findByBranchId(branchId);

        // Kulcs: currency code → tényleges egyenleg
        Map<String, BigDecimal> actualMap = actualBalances.stream()
            .collect(Collectors.toMap(
                cb -> cb.getCurrency().getCode(),
                CashBalance::getCurrentBalance
            ));

        List<ReconciliationAlert> alerts = new ArrayList<>();

        for (DailyBalance daily : calculatedBalances) {
            String currCode = daily.getCurrencyCode();
            BigDecimal calculated = daily.getClosingBalance();

            if (calculated == null) {
                log.debug("Nincs záró egyenleg {}/{}: kihagyva", branchId, currCode);
                continue;
            }

            BigDecimal actual = actualMap.getOrDefault(currCode, null);
            if (actual == null) {
                log.warn("Nincs CashBalance rekord: branchId={}, currency={}", branchId, currCode);
                continue;
            }

            BigDecimal difference = calculated.subtract(actual).abs();

            if (difference.compareTo(TOLERANCE) > 0) {
                ReconciliationAlert alert = ReconciliationAlert.builder()
                    .branchId(branchId)
                    .currencyCode(currCode)
                    .date(date)
                    .calculatedBalance(calculated)
                    .actualBalance(actual)
                    .difference(calculated.subtract(actual)) // előjeles különbség
                    .build();

                alerts.add(alert);

                log.warn("EGYEZTETÉSI ELTÉRÉS: branchId={}, valuta={}, dátum={}, " +
                    "számított={}, tényleges={}, eltérés={}",
                    branchId, currCode, date,
                    calculated.setScale(4, RoundingMode.HALF_UP),
                    actual.setScale(4, RoundingMode.HALF_UP),
                    calculated.subtract(actual).setScale(4, RoundingMode.HALF_UP));

                // Audit log
                auditLogService.log(
                    "BALANCE_RECONCILIATION_MISMATCH",
                    String.format("Egyeztetési eltérés %s/%s %s napon: " +
                        "számított=%s, tényleges=%s, eltérés=%s",
                        branchId, currCode, date, calculated, actual,
                        calculated.subtract(actual)),
                    branchId.toString()
                );
            }
        }

        if (alerts.isEmpty()) {
            log.info("Egyeztetés OK: nincs eltérés. branchId={}, date={}", branchId, date);
        } else {
            log.warn("Egyeztetés ELTÉRÉS TALÁLVA: {} valuta. branchId={}, date={}",
                alerts.size(), branchId, date);
        }

        return alerts;
    }

    /**
     * Egyeztetési eredmény DTO.
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ReconciliationAlert {
        private UUID branchId;
        private String currencyCode;
        private LocalDate date;
        private BigDecimal calculatedBalance;
        private BigDecimal actualBalance;
        private BigDecimal difference;  // pozitív: számított > tényleges, negatív: fordítva

        public boolean isOverage() {
            return difference != null && difference.compareTo(BigDecimal.ZERO) > 0;
        }

        public boolean isShortage() {
            return difference != null && difference.compareTo(BigDecimal.ZERO) < 0;
        }
    }
}
```

### 4.2 Repository metódus hozzáadása

- [ ] Add a `DailyBalanceRepository`-hoz (ha nem létezik):

```java
List<DailyBalance> findByBranchIdAndBalanceDate(UUID branchId, LocalDate date);
```

### 4.3 Integráció a napi zárásba

- [ ] Nyisd meg: `DailyBalanceService.java`
- [ ] Add hozzá a `DailyBalanceReconciliationService` függőséget
- [ ] Hívd meg az egyeztetést a `calculateAllCurrenciesForDay()` végén (opcionálisan):

```java
// calculateAllCurrenciesForDay() végén (eltérés figyelmeztetés, de nem blokkoló):
try {
    List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
        reconciliationService.reconcile(branchId, date);
    if (!alerts.isEmpty()) {
        log.warn("Napi mérleg egyeztetés: {} eltérés találva {} napon: {}",
            alerts.size(), date,
            alerts.stream().map(a -> a.getCurrencyCode() + ":" + a.getDifference())
                .collect(Collectors.joining(", ")));
    }
} catch (Exception e) {
    log.warn("Egyeztetési hiba (nem blokkoló): {}", e.getMessage());
}
```

### 4.4 TDD az egyeztetéshez

```java
// DailyBalanceServiceTest.java
@Mock private DailyBalanceReconciliationService reconciliationService;

@Test
@DisplayName("reconcile: eltérés esetén ReconciliationAlert-et ad vissza")
void reconcile_mismatch_returnsAlert() {
    UUID branchId = UUID.randomUUID();
    LocalDate date = LocalDate.of(2026, 3, 16);

    DailyBalance daily = DailyBalance.builder()
        .branchId(branchId).balanceDate(date).currencyCode("EUR")
        .closingBalance(new BigDecimal("5000.0000")).build();

    CashBalance actual = CashBalance.builder()
        .currentBalance(new BigDecimal("4950.0000"))
        .currency(Currency.builder().code("EUR").build())
        .branch(Branch.builder().id(branchId).build())
        .build();

    when(dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, date))
        .thenReturn(List.of(daily));
    when(cashBalanceRepository.findByBranchId(branchId))
        .thenReturn(List.of(actual));
    doNothing().when(auditLogService).log(any(), any(), any());

    DailyBalanceReconciliationService reconcSvc = new DailyBalanceReconciliationService(
        dailyBalanceRepository, cashBalanceRepository, auditLogService);

    List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
        reconcSvc.reconcile(branchId, date);

    assertThat(alerts).hasSize(1);
    assertThat(alerts.get(0).getCurrencyCode()).isEqualTo("EUR");
    assertThat(alerts.get(0).getDifference()).isEqualByComparingTo(new BigDecimal("50.0000"));
    assertThat(alerts.get(0).isOverage()).isTrue();
}

@Test
@DisplayName("reconcile: egyezés esetén üres lista (tolerancián belül)")
void reconcile_withinTolerance_noAlert() {
    UUID branchId = UUID.randomUUID();
    LocalDate date = LocalDate.of(2026, 3, 16);

    DailyBalance daily = DailyBalance.builder()
        .branchId(branchId).balanceDate(date).currencyCode("EUR")
        .closingBalance(new BigDecimal("5000.0050")).build();  // 0.005 különbség — tolerancián belül

    CashBalance actual = CashBalance.builder()
        .currentBalance(new BigDecimal("5000.0000"))
        .currency(Currency.builder().code("EUR").build())
        .branch(Branch.builder().id(branchId).build())
        .build();

    when(dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, date))
        .thenReturn(List.of(daily));
    when(cashBalanceRepository.findByBranchId(branchId))
        .thenReturn(List.of(actual));

    DailyBalanceReconciliationService reconcSvc = new DailyBalanceReconciliationService(
        dailyBalanceRepository, cashBalanceRepository, auditLogService);

    List<DailyBalanceReconciliationService.ReconciliationAlert> alerts =
        reconcSvc.reconcile(branchId, date);

    assertThat(alerts).isEmpty();
}
```

---

## Segédmetódusok a teszthez

```java
// DailyBalanceServiceTest.java — helper-ek
private void mockSecurityContext(UUID companyId, UUID branchId) {
    WorkerAuthenticationDetails details = mock(WorkerAuthenticationDetails.class);
    when(details.getCompanyId()).thenReturn(companyId);
    when(details.getBranchId()).thenReturn(branchId);
    TestingAuthenticationToken auth = new TestingAuthenticationToken("worker", null);
    auth.setDetails(details);
    SecurityContextHolder.getContext().setAuthentication(auth);
}

private void mockCompany() {
    Company company = Company.builder().id(COMPANY_ID).build();
    when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
}

private void mockCurrencies(String... codes) {
    List<Currency> currencies = Arrays.stream(codes)
        .map(c -> buildCurrency(c, (long) c.hashCode()))
        .collect(Collectors.toList());
    when(currencyRepository.findActiveByCompany(COMPANY_ID)).thenReturn(currencies);
}

private void mockZeroTransactions(UUID branchId, LocalDate date, String currCode) {
    when(transactionRepository.sumDailyTurnoverByCurrency(branchId, date, TransactionType.BUY, currCode))
        .thenReturn(BigDecimal.ZERO);
    when(transactionRepository.sumDailyTurnoverByCurrency(branchId, date, TransactionType.SELL, currCode))
        .thenReturn(BigDecimal.ZERO);
    when(transferRepository.sumTransfersIn(branchId, date, currCode)).thenReturn(BigDecimal.ZERO);
    when(transferRepository.sumTransfersOut(branchId, date, currCode)).thenReturn(BigDecimal.ZERO);
    when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currCode))
        .thenReturn(Optional.empty());
}

private Currency buildCurrency(String code, Long id) {
    return Currency.builder().id(id).code(code).name(code).build();
}
```

---

## Futtatandó parancsok

```bash
# DailyBalance tesztek
cd backend && ./mvnw test -Dtest=DailyBalanceServiceTest

# Reconciliation tesztek
cd backend && ./mvnw test -Dtest=DailyBalanceReconciliationServiceTest

# Teljes build
cd backend && ./mvnw clean verify -DskipITs
```

---

## Commit üzenetek

```
fix(balance): getOpeningBalance uses MonthlyClosingSummary instead of DailyBalance table

feat(balance): fallback to CurrencyStock.initialBalance for first-ever day at branch

fix(balance): isolate per-currency errors in calculateAllCurrenciesForDay with try-catch

feat(balance): add DailyBalanceReconciliationService with computed vs actual stock alerting

test(balance): extend DailyBalanceServiceTest for three-level opening balance fallback

test(balance): add DailyBalanceReconciliationServiceTest for mismatch detection
```

---

## Megjegyzések az éles bevezetéshez

### Visszafelé kompatibilitás

A `getOpeningBalance()` változás visszafelé kompatibilis — a sorrend megváltozott ugyan (DailyBalance → MonthlyClosingSummary → CurrencyStock → 0), de a végeredmény ugyanolyan lesz azokban az esetekben ahol az előző nap záró elérhető a DailyBalance táblában.

### Egyeztetési alert kezelése

A `ReconciliationAlert` jelenleg csak `AuditLog`-ba és Log-ba kerül. Ha az adminisztrátornak email értesítés is kell eltérés esetén, a `NotificationService`-t kell hívni (ha létezik):

```java
// Opcionális email értesítés (ha NotificationService elérhető):
if (difference.abs().compareTo(new BigDecimal("10000")) > 0) {
    // 10 000+ Ft eltérés → email
    notificationService.sendReconciliationAlert(alert);
}
```

### CurrencyStock.initialBalance ellenőrzés

Az éles adatbázisban ellenőrizni kell, hogy az `initial_balance` értékek helyesek-e a `currency_stock` táblában. A `V83__seed_cash_registers_and_stocks.sql` migráció tartalmaz seed adatokat — ezek pontossága meghatározza az első-napi nyitó egyenlegek helyességét.
