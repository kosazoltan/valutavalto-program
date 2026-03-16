# Monthly Closing Archive Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix MonthlyClosingService with: (1) a transaction-level archive table, (2) completeness check that all DailySessions are CLOSED, (3) Hungarian holiday awareness in getLastBusinessDay, (4) realized PnL calculation, and (5) a hard block if any DailySession in the month is OPEN.

**Architecture:** New Flyway migration V89 adds `archived_monthly_transaction` table. New `ArchivedMonthlyTransaction` entity. `MonthlyClosingService` gets pre-close guards and an enriched currency breakdown (realized PnL). `DailySessionRepository` gets a new query. No new controller endpoints required — the existing `performMonthlyClosing` API surface is preserved.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Context

- **Service:** `backend/src/main/java/hu/puzzleir/valuta/service/MonthlyClosingService.java`
- **Entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/MonthlyClosingSummary.java`
- **DailySession entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/DailySession.java` — has `status` (DailySessionStatus enum: OPEN / CLOSED)
- **DailySessionRepository:** `backend/src/main/java/hu/puzzleir/valuta/repository/DailySessionRepository.java` — has `findByDateRange(companyId, start, end)` and `findOpenSessionsByCompany(companyId)`
- **Migrations dir:** `backend/src/main/resources/db/migration/` — last file is V88
- **Tests dir:** `backend/src/test/java/hu/puzzleir/valuta/`

### Current bugs

1. **No archive copy** — legacy `NAPZAR.DLL HaviGyujtokbeMasolas` / `CopyTables()` copied each daily transaction row into monthly BF/BT tables. The modern service only writes a summary JSON, not individual transaction rows.
2. **No completeness check** — `performMonthlyClosing` does not verify that every working day in the month has a CLOSED DailySession.
3. **getLastBusinessDay only skips weekends** — Hungarian public holidays are not accounted for (lines 179-184 of the service).
4. **No realized PnL** — `CurrencyBreakdownEntry` has `unrealizedPnl` (stock × MNB − stock × WAC) but no `realizedPnl` (spread earned on actual buy/sell transactions).
5. **Open session not blocked** — `performMonthlyClosing` can run even if a DailySession for that month is still OPEN.

---

## Task 1: Flyway migration V89 — archived_monthly_transaction table

- [ ] Create file: `backend/src/main/resources/db/migration/V89__monthly_transaction_archive.sql`

```sql
-- V89: Monthly transaction archive (legacy CopyTables equivalent)
-- Each row is one transaction copied at the time of monthly closing.
CREATE TABLE IF NOT EXISTS archived_monthly_transaction (
    id                  BIGSERIAL PRIMARY KEY,
    monthly_closing_id  BIGINT       NOT NULL,   -- FK → monthly_closing_summary.id
    branch_id           UUID         NOT NULL,
    company_id          UUID         NOT NULL,
    original_tx_id      BIGINT,                  -- FK → transaction.id (nullable if tx deleted)
    transaction_date    DATE         NOT NULL,
    transaction_type    VARCHAR(30)  NOT NULL,    -- BUY / SELL / REVERSAL / etc.
    currency_code       VARCHAR(3)   NOT NULL,
    currency_amount     NUMERIC(18,2) NOT NULL,
    huf_amount          NUMERIC(18,2) NOT NULL,
    exchange_rate       NUMERIC(18,6),
    handling_fee        NUMERIC(18,2),
    customer_id         VARCHAR(50),
    worker_id           BIGINT,
    archived_at         TIMESTAMP    NOT NULL DEFAULT now(),
    year_month          VARCHAR(7)   NOT NULL     -- e.g. '2026-03'
);

CREATE INDEX idx_amt_closing     ON archived_monthly_transaction(monthly_closing_id);
CREATE INDEX idx_amt_branch_ym   ON archived_monthly_transaction(branch_id, year_month);
CREATE INDEX idx_amt_company     ON archived_monthly_transaction(company_id);
CREATE INDEX idx_amt_currency    ON archived_monthly_transaction(currency_code);
```

---

## Task 2: ArchivedMonthlyTransaction entity

- [ ] Create file: `backend/src/main/java/hu/puzzleir/valuta/entity/ArchivedMonthlyTransaction.java`

```java
package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "archived_monthly_transaction")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ArchivedMonthlyTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** FK to monthly_closing_summary */
    @Column(name = "monthly_closing_id", nullable = false)
    private Long monthlyClosingId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    /** Nullable — original transaction may be deleted (stornó) */
    @Column(name = "original_tx_id")
    private Long originalTxId;

    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    @Column(name = "transaction_type", nullable = false, length = 30)
    private String transactionType;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "currency_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal currencyAmount;

    @Column(name = "huf_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal hufAmount;

    @Column(name = "exchange_rate", precision = 18, scale = 6)
    private BigDecimal exchangeRate;

    @Column(name = "handling_fee", precision = 18, scale = 2)
    private BigDecimal handlingFee;

    @Column(name = "customer_id", length = 50)
    private String customerId;

    @Column(name = "worker_id")
    private Long workerId;

    @Column(name = "archived_at", nullable = false)
    @Builder.Default
    private LocalDateTime archivedAt = LocalDateTime.now();

    /** 'YYYY-MM' format */
    @Column(name = "year_month", nullable = false, length = 7)
    private String yearMonth;
}
```

- [ ] Create repository: `backend/src/main/java/hu/puzzleir/valuta/repository/ArchivedMonthlyTransactionRepository.java`

```java
package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ArchivedMonthlyTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ArchivedMonthlyTransactionRepository extends JpaRepository<ArchivedMonthlyTransaction, Long> {

    List<ArchivedMonthlyTransaction> findByMonthlyClosingId(Long monthlyClosingId);
    List<ArchivedMonthlyTransaction> findByBranchIdAndYearMonth(UUID branchId, String yearMonth);
    long countByBranchIdAndYearMonth(UUID branchId, String yearMonth);
}
```

---

## Task 3: Completeness check — all DailySessions for the month must be CLOSED

### 3a: Add query to DailySessionRepository

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/repository/DailySessionRepository.java`

Add the following two methods to the interface:

```java
/**
 * Returns all DailySessions for a branch in a given date range.
 * Used by MonthlyClosingService to check completeness.
 */
@Query("SELECT ds FROM DailySession ds " +
       "WHERE ds.branch.id = :branchId " +
       "AND ds.sessionDate BETWEEN :startDate AND :endDate " +
       "ORDER BY ds.sessionDate ASC")
List<DailySession> findByBranchAndDateRange(
    @Param("branchId") UUID branchId,
    @Param("startDate") LocalDate startDate,
    @Param("endDate") LocalDate endDate);

/**
 * Count OPEN sessions for a branch in a date range.
 * Returns > 0 if any day is still open → block monthly close.
 */
@Query("SELECT COUNT(ds) FROM DailySession ds " +
       "WHERE ds.branch.id = :branchId " +
       "AND ds.sessionDate BETWEEN :startDate AND :endDate " +
       "AND ds.status = 'OPEN'")
long countOpenSessionsInRange(
    @Param("branchId") UUID branchId,
    @Param("startDate") LocalDate startDate,
    @Param("endDate") LocalDate endDate);
```

### 3b: Add DailySessionRepository injection to MonthlyClosingService

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/service/MonthlyClosingService.java`

Add to constructor-injected fields:
```java
private final DailySessionRepository dailySessionRepository;
```

---

## Task 4: Hungarian holiday support in getLastBusinessDay

- [ ] Edit `MonthlyClosingService.java` — replace the existing `getLastBusinessDay` method.

### Hungarian public holidays (fixed + Easter-based)

Fixed holidays (year-independent):
- Jan 1, Mar 15, May 1, Aug 20, Oct 23, Nov 1, Dec 25, Dec 26

Easter-based (calculated per year — Gauss algorithm):
- Good Friday (Easter − 2 days)
- Easter Monday (Easter + 1 day)
- Whit Monday (Easter + 50 days)

```java
/**
 * Hónap utolsó munkanapjának meghatározása.
 * Figyelembe veszi a hétvégéket ÉS a magyar munkaszüneti napokat.
 *
 * Fixed ünnepek: jan.1, márc.15, máj.1, aug.20, okt.23, nov.1, dec.25, dec.26
 * Mozgó ünnepek: Nagypéntek, Húsvéthétfő, Pünkösdvasárnap (Easter + 50)
 */
private LocalDate getLastBusinessDay(LocalDate monthEnd) {
    LocalDate d = monthEnd;
    while (isHoliday(d)) {
        d = d.minusDays(1);
    }
    return d;
}

private boolean isHoliday(LocalDate date) {
    if (date.getDayOfWeek() == DayOfWeek.SATURDAY
            || date.getDayOfWeek() == DayOfWeek.SUNDAY) {
        return true;
    }
    int m = date.getMonthValue();
    int d = date.getDayOfMonth();
    // Fixed Hungarian public holidays
    if ((m == 1  && d == 1)  ||   // Újév
        (m == 3  && d == 15) ||   // Nemzeti ünnep
        (m == 5  && d == 1)  ||   // Munka ünnepe
        (m == 8  && d == 20) ||   // Államalapítás
        (m == 10 && d == 23) ||   // Forradalom ünnepe
        (m == 11 && d == 1)  ||   // Mindenszentek
        (m == 12 && d == 25) ||   // Karácsony
        (m == 12 && d == 26)) {   // Karácsony 2. napja
        return true;
    }
    // Easter-based holidays
    LocalDate easter = calculateEaster(date.getYear());
    return date.equals(easter.minusDays(2))   // Nagypéntek
        || date.equals(easter.plusDays(1))    // Húsvéthétfő
        || date.equals(easter.plusDays(50));  // Pünkösdvasárnap
}

/**
 * Húsvét vasárnap számítása (Anonymous Gregorian / Meeus/Jones/Butcher algoritmus).
 */
private LocalDate calculateEaster(int year) {
    int a = year % 19;
    int b = year / 100;
    int c = year % 100;
    int d = b / 4;
    int e = b % 4;
    int f = (b + 8) / 25;
    int g = (b - f + 1) / 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c / 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) / 451;
    int month  = (h + l - 7 * m + 114) / 31;
    int day    = ((h + l - 7 * m + 114) % 31) + 1;
    return LocalDate.of(year, month, day);
}
```

---

## Task 5: Realized PnL in currency breakdown

- [ ] Edit `MonthlyClosingService.java`

### 5a: Extend CurrencyBreakdownEntry inner class

Add to the inner class after `unrealizedPnl`:
```java
// --- Realizált eredmény ---
BigDecimal realizedPnl = BigDecimal.ZERO;
// Képlet: Σ(sellHuf) − Σ(sellAmount × weightedAvgCostAtSale)
// Egyszerűsített: sellHuf − buyHuf (a spread az irodán marad)
// Pontosabb: buyHuf és sellHuf különbsége (mivel buyHuf=mi vettük, sellHuf=mi adtuk el)
// realizedPnl = totalSellHuf − (totalSellAmount × WAC)

public BigDecimal getRealizedPnl() { return realizedPnl; }
```

### 5b: Populate realizedPnl in buildCurrencyBreakdown

After the existing unrealizedPnl calculation block, add:

```java
// Realizált eredmény számítás
// Képlet: sellHuf − (sellAmount × weightedAvgCost)
// = a valuta eladásából bevett HUF − az eladott valuta WAC-alapú könyv szerinti értéke
if (entry.sellAmount.compareTo(BigDecimal.ZERO) > 0 && stock != null
        && stock.getWeightedAvgCost() != null
        && stock.getWeightedAvgCost().compareTo(BigDecimal.ZERO) > 0) {
    BigDecimal costOfGoodsSold = entry.sellAmount
        .multiply(stock.getWeightedAvgCost())
        .setScale(2, RoundingMode.HALF_UP);
    entry.realizedPnl = entry.sellHuf
        .subtract(costOfGoodsSold)
        .setScale(2, RoundingMode.HALF_UP);
}
```

---

## Task 6: Block monthly close if any DailySession in that month is OPEN

- [ ] Edit `MonthlyClosingService.performMonthlyClosing()` — add the following guard AFTER the jövőbeli hónap check and BEFORE the duplicate check:

```java
// 3. Nyitott napok ellenőrzés (BLOCK ha van OPEN DailySession a hónapban)
long openSessions = dailySessionRepository.countOpenSessionsInRange(
        branchId, monthStart, monthEnd);
if (openSessions > 0) {
    throw new ValidationException(
        "Havi zárás nem lehetséges: " + openSessions +
        " napra még nincs elvégezve a napi zárás! (" + yearMonth + ")");
}

// 4. Teljességi ellenőrzés — minden munkanapnak legyen CLOSED session
// (Opcionálisan warning-ként is lehet kezelni ha az iroda nem minden nap nyitva van)
List<DailySession> sessions = dailySessionRepository.findByBranchAndDateRange(
        branchId, monthStart, monthEnd);
boolean hasAnySessions = !sessions.isEmpty();
if (!hasAnySessions) {
    log.warn("Havi zárás: nem találhatók napi sessionök: branch={}, yearMonth={}",
            branchId, yearMonth);
    // Nem blokkoljuk — lehet, hogy az iroda az adott hónapban nem volt nyitva
}
```

---

## Task 7: Archive transactions at monthly closing time

- [ ] Inject `ArchivedMonthlyTransactionRepository` into `MonthlyClosingService`
- [ ] In `performMonthlyClosing`, after saving `summary`, call `archiveTransactions(saved, branchId, transactions, yearMonth)`

```java
/**
 * Tranzakció archiválás — CopyTables() legacy megfelelője.
 * Minden tranzakciót átmásol az archived_monthly_transaction táblába.
 */
private void archiveTransactions(MonthlyClosingSummary summary,
                                  UUID branchId,
                                  List<Transaction> transactions,
                                  String yearMonth) {
    UUID companyId = summary.getBranch().getCompany().getId();
    List<ArchivedMonthlyTransaction> archives = transactions.stream()
        .map(t -> ArchivedMonthlyTransaction.builder()
            .monthlyClosingId(summary.getId())
            .branchId(branchId)
            .companyId(companyId)
            .originalTxId(t.getId())
            .transactionDate(t.getTransactionDate() != null
                ? t.getTransactionDate().toLocalDate() : null)
            .transactionType(t.getTransactionType() != null
                ? t.getTransactionType().name() : "UNKNOWN")
            .currencyCode(t.getCurrency() != null ? t.getCurrency().getCode() : "UNKNOWN")
            .currencyAmount(t.getCurrencyAmount() != null ? t.getCurrencyAmount() : BigDecimal.ZERO)
            .hufAmount(t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO)
            .exchangeRate(t.getExchangeRate())
            .handlingFee(t.getHandlingFee())
            .customerId(t.getCustomerId())
            .workerId(t.getWorker() != null ? t.getWorker().getId() : null)
            .archivedAt(LocalDateTime.now())
            .yearMonth(yearMonth)
            .build())
        .toList();
    archivedMonthlyTransactionRepository.saveAll(archives);
    log.info("Archivált tranzakciók: {}, yearMonth={}", archives.size(), yearMonth);
}
```

---

## TDD Steps

### Test file location
`backend/src/test/java/hu/puzzleir/valuta/service/MonthlyClosingServiceTest.java`

### Test cases (in order)

- [ ] **T1: Block on OPEN session** — `performMonthlyClosing` throws `ValidationException` when `countOpenSessionsInRange` returns > 0
- [ ] **T2: Pass when all sessions CLOSED** — `performMonthlyClosing` proceeds normally when `countOpenSessionsInRange` returns 0
- [ ] **T3: getLastBusinessDay — weekend** — Dec 31 2022 (Saturday) → Dec 30
- [ ] **T4: getLastBusinessDay — Dec 26** — Dec 31 2023 (Sunday) → Dec 29 (Dec 26 is holiday)
- [ ] **T5: calculateEaster** — 2025: April 20, 2026: April 5
- [ ] **T6: isHoliday — Aug 20** — returns true
- [ ] **T7: isHoliday — Good Friday 2025** — April 18, 2025 returns true
- [ ] **T8: realizedPnl populated** — when sellHuf=400, sellAmount=1.0, WAC=350 → realizedPnl=50
- [ ] **T9: archiveTransactions count** — after close, `archivedMonthlyTransactionRepository.countByBranchIdAndYearMonth` equals transaction list size

```java
// Example test skeleton
@ExtendWith(MockitoExtension.class)
class MonthlyClosingServiceTest {

    @Mock TransactionRepository transactionRepository;
    @Mock MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;
    @Mock BranchRepository branchRepository;
    @Mock WorkerRepository workerRepository;
    @Mock ObjectMapper objectMapper;
    @Mock MnbExchangeRateService mnbExchangeRateService;
    @Mock CurrencyStockRepository currencyStockRepository;
    @Mock DailySessionRepository dailySessionRepository;
    @Mock ArchivedMonthlyTransactionRepository archivedMonthlyTransactionRepository;

    @InjectMocks MonthlyClosingService service;

    @Test
    void performMonthlyClosing_throwsWhenOpenSession() {
        UUID branchId = UUID.randomUUID();
        when(dailySessionRepository.countOpenSessionsInRange(
                eq(branchId), any(), any())).thenReturn(2L);
        assertThrows(ValidationException.class,
            () -> service.performMonthlyClosing(branchId, "2026-02"));
    }
}
```

---

## Test commands

```bash
cd backend
./mvnw test -pl . -Dtest=MonthlyClosingServiceTest -q
```

Full suite:
```bash
./mvnw test -q
```

---

## Commit message

```
feat(monthly-closing): archive transactions, Hungarian holidays, open-session block, realized PnL

- V89 migration: archived_monthly_transaction table
- ArchivedMonthlyTransaction entity + repository
- performMonthlyClosing blocks if any DailySession is OPEN
- getLastBusinessDay: Hungarian public holidays + Easter calculation
- CurrencyBreakdownEntry: realizedPnl = sellHuf - (sellAmount * WAC)
- archiveTransactions: copies all month transactions at close time

Fixes: legacy CopyTables gap, holiday-blind last-business-day, missing realized PnL
```
