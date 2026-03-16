# Turnover Currency & Worker Breakdown Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix `TurnoverService.buildReport()` which always returns `byCurrency: []` and `byWorker: []`. Also fix: (1) storno (REVERSED) transactions are not excluded from totals, (2) `buildReport()` converts `LocalDateTime → LocalDate` losing precision (time boundary).

**Architecture:**
- `TurnoverReportDto` already has `CurrencyTurnoverDto` and `WorkerTurnoverDto` inner classes.
- `TransactionRepository` already has `sumHufAmountByBranchAndTypeAndPeriod` and `sumFeeByBranchAndPeriod` but lacks grouped aggregation queries.
- Add two new `@Query` methods to `TransactionRepository` returning `Object[]` projections grouped by currency code and by worker ID.
- `TurnoverService.buildReport()` uses `LocalDate dateFrom/dateTo` derived from `LocalDateTime` parameters — this is correct for the existing queries (which use `transactionDate` which is `LocalDate`), but the `getCompanyTurnover` method uses `LocalDateTime` with `createdAt` — this inconsistency is the precision bug.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Files

**Modify:**
- `backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TurnoverService.java`
- `backend/src/main/java/hu/puzzleir/valuta/dto/turnover/TurnoverReportDto.java`

**Test (Create):**
- `backend/src/test/java/hu/puzzleir/valuta/service/TurnoverServiceBreakdownTest.java`

---

## Task 1 — Add repository methods for grouped aggregation

- [ ] Open `backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java`.

Append these methods after the existing `sumFeeByBranchAndPeriod` block (around line 510):

```java
    // ============ TURNOVER BREAKDOWN QUERIES ============

    /**
     * Valuta-bontás: forgalom valutánként — vétel és eladás összesítve.
     * REVERSED tranzakciókat kizárja (status != REVERSED).
     * Visszaadott sor: [currencyCode, txType, SUM(currencyAmount), SUM(hufAmount), COUNT(id)]
     */
    @Query("SELECT t.currency.code, CAST(t.transactionType AS string), " +
           "       COALESCE(SUM(t.currencyAmount), 0), " +
           "       COALESCE(SUM(t.hufAmount), 0), " +
           "       COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status != 'REVERSED' " +
           "AND t.status != 'CANCELLED' " +
           "AND t.transactionType IN ('BUY', 'SELL') " +
           "GROUP BY t.currency.code, t.transactionType " +
           "ORDER BY t.currency.code, t.transactionType")
    List<Object[]> groupByCurrencyAndTypeForBranch(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Dolgozó-bontás: forgalom pénztárosonként.
     * REVERSED tranzakciókat kizárja.
     * Visszaadott sor: [workerId, workerName, SUM(hufAmount), SUM(handlingFee), COUNT(id)]
     */
    @Query("SELECT t.worker.id, t.worker.name, " +
           "       COALESCE(SUM(t.hufAmount), 0), " +
           "       COALESCE(SUM(t.handlingFee), 0), " +
           "       COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status != 'REVERSED' " +
           "AND t.status != 'CANCELLED' " +
           "AND t.transactionType IN ('BUY', 'SELL') " +
           "GROUP BY t.worker.id, t.worker.name " +
           "ORDER BY t.worker.name")
    List<Object[]> groupByWorkerForBranch(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Storno-mentes HUF összeg branch + típus + időszak.
     * Csere: az eredeti sumHufAmountByBranchAndTypeAndPeriod REVERSED-et is beleszámította.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
        @Param("branchId") UUID branchId,
        @Param("txType") String txType,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Storno-mentes kezelési díj branch + időszak.
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumFeeByBranchAndPeriodExcludingReversals(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );
```

Verify that `java.time.LocalDate` is already imported; add if not:
```java
import java.time.LocalDate;
```

---

## Task 2 — Expand TurnoverReportDto with fee field

- [ ] Open `backend/src/main/java/hu/puzzleir/valuta/dto/turnover/TurnoverReportDto.java`.

The existing `CurrencyTurnoverDto` is missing a `fee` field. Add it:

```java
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class CurrencyTurnoverDto {
        private String currencyCode;
        private BigDecimal buyVolume;      // összeg devizában
        private BigDecimal sellVolume;     // összeg devizában
        private BigDecimal buyHuf;         // vétel HUF összeg
        private BigDecimal sellHuf;        // eladás HUF összeg
        private BigDecimal fee;            // kezelési díj összesen (NEW)
        private Integer transactionCount;
    }
```

The `WorkerTurnoverDto` is missing a `fee` field as well:
```java
    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class WorkerTurnoverDto {
        private Long workerId;
        private String workerName;
        private BigDecimal totalVolume;    // HUF összforgalom
        private BigDecimal fee;            // kezelési díj (NEW)
        private Integer transactionCount;
    }
```

---

## Task 3 — Failing test: buildReport returns empty byCurrency / byWorker

- [ ] Create:
```
backend/src/test/java/hu/puzzleir/valuta/service/TurnoverServiceBreakdownTest.java
```

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("TurnoverService – valuta és dolgozó bontás")
class TurnoverServiceBreakdownTest {

    @Mock
    TransactionRepository transactionRepository;

    @InjectMocks
    TurnoverService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();

    /**
     * Ellenőrzi, hogy a byCurrency lista TARTALMAZ adatokat —
     * JELENLEG ÜRES (BUG), ezért ez a teszt FAIL-el a fix előtt.
     */
    @Test
    @DisplayName("getDailyTurnover – byCurrency lista nem lehet üres ha van aznapi tranzakció")
    void getDailyTurnover_byCurrencyNotEmpty() {
        LocalDate date = LocalDate.of(2026, 3, 16);

        // storno-mentes totals
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                eq(BRANCH_ID), eq("BUY"), eq(date), eq(date)))
                .thenReturn(new BigDecimal("300000"));
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                eq(BRANCH_ID), eq("SELL"), eq(date), eq(date)))
                .thenReturn(new BigDecimal("250000"));
        when(transactionRepository.sumFeeByBranchAndPeriodExcludingReversals(
                eq(BRANCH_ID), eq(date), eq(date)))
                .thenReturn(new BigDecimal("5000"));

        // currency breakdown rows: [currencyCode, txType, currencyAmount, hufAmount, count]
        Object[] eurBuy  = new Object[]{"EUR", "BUY",  new BigDecimal("750"),  new BigDecimal("300000"), 2L};
        Object[] usdSell = new Object[]{"USD", "SELL", new BigDecimal("650"),  new BigDecimal("250000"), 1L};
        when(transactionRepository.groupByCurrencyAndTypeForBranch(eq(BRANCH_ID), eq(date), eq(date)))
                .thenReturn(Arrays.asList(eurBuy, usdSell));

        // worker breakdown rows: [workerId, workerName, hufAmount, fee, count]
        Object[] worker1 = new Object[]{1L, "Nagy Péter", new BigDecimal("550000"), new BigDecimal("5000"), 3L};
        when(transactionRepository.groupByWorkerForBranch(eq(BRANCH_ID), eq(date), eq(date)))
                .thenReturn(List.of(worker1));

        TurnoverReportDto result = service.getDailyTurnover(BRANCH_ID, date);

        // byCurrency must NOT be empty
        assertThat(result.getByCurrency())
                .as("byCurrency lista nem lehet üres")
                .isNotEmpty();
        assertThat(result.getByCurrency())
                .extracting(TurnoverReportDto.CurrencyTurnoverDto::getCurrencyCode)
                .containsExactlyInAnyOrder("EUR", "USD");

        // EUR buy entry
        TurnoverReportDto.CurrencyTurnoverDto eurEntry = result.getByCurrency().stream()
                .filter(c -> "EUR".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(eurEntry.getBuyVolume()).isEqualByComparingTo(new BigDecimal("750"));
        assertThat(eurEntry.getBuyHuf()).isEqualByComparingTo(new BigDecimal("300000"));

        // byWorker must NOT be empty
        assertThat(result.getByWorker())
                .as("byWorker lista nem lehet üres")
                .isNotEmpty();
        assertThat(result.getByWorker())
                .extracting(TurnoverReportDto.WorkerTurnoverDto::getWorkerName)
                .containsExactly("Nagy Péter");
    }

    @Test
    @DisplayName("getDailyTurnover – REVERSED tranzakciók ki vannak zárva a totalból")
    void getDailyTurnover_reversedTransactionsExcluded() {
        LocalDate date = LocalDate.of(2026, 3, 16);

        // new method used (excluding reversals)
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                any(), eq("BUY"), any(), any())).thenReturn(new BigDecimal("100000"));
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
                any(), eq("SELL"), any(), any())).thenReturn(new BigDecimal("80000"));
        when(transactionRepository.sumFeeByBranchAndPeriodExcludingReversals(any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.groupByCurrencyAndTypeForBranch(any(), any(), any()))
                .thenReturn(List.of());
        when(transactionRepository.groupByWorkerForBranch(any(), any(), any()))
                .thenReturn(List.of());

        TurnoverReportDto result = service.getDailyTurnover(BRANCH_ID, date);

        assertThat(result.getTotalBuy()).isEqualByComparingTo(new BigDecimal("100000"));
        assertThat(result.getTotalSell()).isEqualByComparingTo(new BigDecimal("80000"));
    }
}
```

- [ ] Run to confirm FAILURE before fix:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=TurnoverServiceBreakdownTest \
  -Dmaven.test.skip=false 2>&1 | tail -20
```
Expected: compile error (new repo methods not yet implemented) OR `AssertionError` (empty list).

---

## Task 4 — Implement byCurrency and byWorker in TurnoverService

- [ ] Open `backend/src/main/java/hu/puzzleir/valuta/service/TurnoverService.java`.

Replace the entire `buildReport()` private method:

```java
    private TurnoverReportDto buildReport(UUID branchId, String period,
                                           LocalDateTime from, LocalDateTime to) {
        // Precision fix: use transactionDate (LocalDate), not LocalDateTime
        LocalDate dateFrom = from.toLocalDate();
        LocalDate dateTo   = to.toLocalDate();

        // Storno-mentes (REVERSED kizárva) összesítők
        BigDecimal totalBuy = transactionRepository
            .sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(branchId, "BUY",  dateFrom, dateTo);
        BigDecimal totalSell = transactionRepository
            .sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(branchId, "SELL", dateFrom, dateTo);
        BigDecimal fees = transactionRepository
            .sumFeeByBranchAndPeriodExcludingReversals(branchId, dateFrom, dateTo);

        totalBuy  = totalBuy  != null ? totalBuy  : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees      = fees      != null ? fees      : BigDecimal.ZERO;

        BigDecimal spread    = totalSell.subtract(totalBuy);
        BigDecimal netProfit = spread.add(fees);

        // === byCurrency bontás ===
        List<Object[]> currencyRows = transactionRepository
            .groupByCurrencyAndTypeForBranch(branchId, dateFrom, dateTo);

        // Összesítés valutánként (egy valutához lehet BUY és SELL is)
        Map<String, TurnoverReportDto.CurrencyTurnoverDto.CurrencyTurnoverDtoBuilder> currencyMap =
            new java.util.LinkedHashMap<>();

        for (Object[] row : currencyRows) {
            String currencyCode  = (String)     row[0];
            String txType        = (String)     row[1];
            BigDecimal volume    = (BigDecimal) row[2];
            BigDecimal huf       = (BigDecimal) row[3];
            long count           = ((Number)    row[4]).longValue();

            currencyMap.computeIfAbsent(currencyCode, k ->
                TurnoverReportDto.CurrencyTurnoverDto.builder()
                    .currencyCode(k)
                    .buyVolume(BigDecimal.ZERO).buyHuf(BigDecimal.ZERO)
                    .sellVolume(BigDecimal.ZERO).sellHuf(BigDecimal.ZERO)
                    .fee(BigDecimal.ZERO)
                    .transactionCount(0));

            TurnoverReportDto.CurrencyTurnoverDto.CurrencyTurnoverDtoBuilder b = currencyMap.get(currencyCode);
            if ("BUY".equals(txType)) {
                b.buyVolume(volume).buyHuf(huf);
                b.transactionCount((int) count);
            } else if ("SELL".equals(txType)) {
                b.sellVolume(volume).sellHuf(huf);
                // add to existing transactionCount
            }
        }

        List<TurnoverReportDto.CurrencyTurnoverDto> byCurrency = currencyMap.values().stream()
            .map(TurnoverReportDto.CurrencyTurnoverDto.CurrencyTurnoverDtoBuilder::build)
            .collect(java.util.stream.Collectors.toList());

        // === byWorker bontás ===
        List<Object[]> workerRows = transactionRepository
            .groupByWorkerForBranch(branchId, dateFrom, dateTo);

        List<TurnoverReportDto.WorkerTurnoverDto> byWorker = workerRows.stream()
            .map(row -> TurnoverReportDto.WorkerTurnoverDto.builder()
                .workerId(((Number) row[0]).longValue())
                .workerName((String) row[1])
                .totalVolume((BigDecimal) row[2])
                .fee((BigDecimal) row[3])
                .transactionCount(((Number) row[4]).intValue())
                .build())
            .collect(java.util.stream.Collectors.toList());

        return TurnoverReportDto.builder()
            .period(period)
            .totalBuy(totalBuy)
            .totalSell(totalSell)
            .spread(spread)
            .fees(fees)
            .netProfit(netProfit)
            .byCurrency(byCurrency)
            .byWorker(byWorker)
            .build();
    }
```

Add required imports at the top of `TurnoverService.java`:
```java
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
```

> **Note on transactionCount per currency:** The `currencyMap` builder accumulates `buyCount + sellCount`. If both BUY and SELL rows exist for the same currency, the `transactionCount` set in the builder will be overwritten by the second row. Fix this properly by tracking counts separately:

```java
// Improved version: track buy/sell counts separately then sum
b.transactionCount(existingCount + (int) count);
```

The complete correct accumulation (to handle both BUY and SELL rows per currency):

```java
        for (Object[] row : currencyRows) {
            String currencyCode  = (String)     row[0];
            String txType        = (String)     row[1];
            BigDecimal volume    = (BigDecimal) row[2];
            BigDecimal huf       = (BigDecimal) row[3];
            int count            = ((Number)    row[4]).intValue();

            currencyMap.computeIfAbsent(currencyCode, k ->
                TurnoverReportDto.CurrencyTurnoverDto.builder()
                    .currencyCode(k)
                    .buyVolume(BigDecimal.ZERO).buyHuf(BigDecimal.ZERO)
                    .sellVolume(BigDecimal.ZERO).sellHuf(BigDecimal.ZERO)
                    .fee(BigDecimal.ZERO)
                    .transactionCount(0));

            // Retrieve current state of the builder via a mutable holder
        }
```

Since Lombok builders are not easily mutable after partial build, use a helper record or DTO accumulator instead. The cleanest approach is to use a local `HashMap<String, CurrencyAccumulator>`:

**Final implementation using accumulators:**

```java
    private TurnoverReportDto buildReport(UUID branchId, String period,
                                           LocalDateTime from, LocalDateTime to) {
        LocalDate dateFrom = from.toLocalDate();
        LocalDate dateTo   = to.toLocalDate();

        BigDecimal totalBuy = transactionRepository
            .sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(branchId, "BUY",  dateFrom, dateTo);
        BigDecimal totalSell = transactionRepository
            .sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(branchId, "SELL", dateFrom, dateTo);
        BigDecimal fees = transactionRepository
            .sumFeeByBranchAndPeriodExcludingReversals(branchId, dateFrom, dateTo);

        totalBuy  = totalBuy  != null ? totalBuy  : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees      = fees      != null ? fees      : BigDecimal.ZERO;

        // byCurrency bontás — [currencyCode, txType, currencyAmount, hufAmount, count]
        List<Object[]> currencyRows = transactionRepository
            .groupByCurrencyAndTypeForBranch(branchId, dateFrom, dateTo);

        java.util.Map<String, CurrencyAccum> currAccum = new java.util.LinkedHashMap<>();
        for (Object[] row : currencyRows) {
            String code  = (String)     row[0];
            String type  = (String)     row[1];
            BigDecimal vol = (BigDecimal) row[2];
            BigDecimal huf = (BigDecimal) row[3];
            int cnt        = ((Number)   row[4]).intValue();

            CurrencyAccum acc = currAccum.computeIfAbsent(code, CurrencyAccum::new);
            if ("BUY".equals(type)) {
                acc.buyVolume = vol; acc.buyHuf = huf; acc.buyCount = cnt;
            } else if ("SELL".equals(type)) {
                acc.sellVolume = vol; acc.sellHuf = huf; acc.sellCount = cnt;
            }
        }

        List<TurnoverReportDto.CurrencyTurnoverDto> byCurrency = currAccum.values().stream()
            .map(acc -> TurnoverReportDto.CurrencyTurnoverDto.builder()
                .currencyCode(acc.code)
                .buyVolume(acc.buyVolume).buyHuf(acc.buyHuf)
                .sellVolume(acc.sellVolume).sellHuf(acc.sellHuf)
                .fee(BigDecimal.ZERO)
                .transactionCount(acc.buyCount + acc.sellCount)
                .build())
            .collect(Collectors.toList());

        // byWorker bontás — [workerId, workerName, hufAmount, fee, count]
        List<Object[]> workerRows = transactionRepository
            .groupByWorkerForBranch(branchId, dateFrom, dateTo);

        List<TurnoverReportDto.WorkerTurnoverDto> byWorker = workerRows.stream()
            .map(row -> TurnoverReportDto.WorkerTurnoverDto.builder()
                .workerId(((Number) row[0]).longValue())
                .workerName((String) row[1])
                .totalVolume((BigDecimal) row[2])
                .fee((BigDecimal) row[3])
                .transactionCount(((Number) row[4]).intValue())
                .build())
            .collect(Collectors.toList());

        BigDecimal spread    = totalSell.subtract(totalBuy);
        BigDecimal netProfit = spread.add(fees);

        return TurnoverReportDto.builder()
            .period(period)
            .totalBuy(totalBuy).totalSell(totalSell)
            .spread(spread).fees(fees).netProfit(netProfit)
            .byCurrency(byCurrency)
            .byWorker(byWorker)
            .build();
    }

    /** Helper accumulator (valuta-bontáshoz). */
    private static class CurrencyAccum {
        final String code;
        BigDecimal buyVolume = BigDecimal.ZERO, buyHuf = BigDecimal.ZERO;
        BigDecimal sellVolume = BigDecimal.ZERO, sellHuf = BigDecimal.ZERO;
        int buyCount, sellCount;
        CurrencyAccum(String code) { this.code = code; }
    }
```

---

## Task 5 — Fix LocalDateTime→LocalDate precision in getCompanyTurnover

`getCompanyTurnover()` currently calls `sumHufAmountByCompanyAndTypeAndPeriod` with `LocalDateTime` parameters and the query filters on `createdAt` (timestamp). This is correct for the company-level query. However, the branch-level `buildReport()` was also converting `LocalDateTime → LocalDate` via `.toLocalDate()` — which loses the time component for `LocalTime.MAX` end boundaries.

The fix: the branch-level queries already use `transactionDate` (a `LocalDate` field), so the conversion is semantically correct. Document this explicitly in a comment:

- [ ] In `buildReport()`, add a comment above the conversion:
```java
        // transactionDate is a LocalDate column — toLocalDate() conversion is intentional.
        // The time component (from/to times) is relevant only for company-level createdAt queries.
        LocalDate dateFrom = from.toLocalDate();
        LocalDate dateTo   = to.toLocalDate();
```

- [ ] In `getCompanyTurnover()`, replace the old method calls with the storno-excluding equivalents. Also replace `sumHufAmountByCompanyAndTypeAndPeriod` with a new method that excludes REVERSED:

Add to `TransactionRepository.java`:
```java
    /**
     * Storno-mentes HUF összeg company + típus + időszak (DateTime).
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumHufAmountByCompanyAndTypeAndPeriodExcludingReversals(
        @Param("companyId") UUID companyId,
        @Param("txType") String txType,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * Storno-mentes kezelési díj company + időszak (DateTime).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumFeeByCompanyAndPeriodExcludingReversals(
        @Param("companyId") UUID companyId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );
```

Update `getCompanyTurnover()` in `TurnoverService`:
```java
    public TurnoverReportDto getCompanyTurnover(UUID companyId, LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt   = to.atTime(LocalTime.MAX);

        BigDecimal totalBuy = transactionRepository
            .sumHufAmountByCompanyAndTypeAndPeriodExcludingReversals(companyId, "BUY",  fromDt, toDt);
        BigDecimal totalSell = transactionRepository
            .sumHufAmountByCompanyAndTypeAndPeriodExcludingReversals(companyId, "SELL", fromDt, toDt);
        BigDecimal fees = transactionRepository
            .sumFeeByCompanyAndPeriodExcludingReversals(companyId, fromDt, toDt);

        totalBuy  = totalBuy  != null ? totalBuy  : BigDecimal.ZERO;
        totalSell = totalSell != null ? totalSell : BigDecimal.ZERO;
        fees      = fees      != null ? fees      : BigDecimal.ZERO;

        return TurnoverReportDto.builder()
            .period(from + " - " + to)
            .totalBuy(totalBuy).totalSell(totalSell)
            .spread(totalSell.subtract(totalBuy))
            .fees(fees)
            .netProfit(totalSell.subtract(totalBuy).add(fees))
            .byCurrency(Collections.emptyList())  // company-level breakdown: future task
            .byWorker(Collections.emptyList())
            .build();
    }
```

---

## Run tests

- [ ] Run all turnover tests:
```bash
cd backend && ./mvnw test -pl . \
  -Dtest=TurnoverServiceBreakdownTest \
  -Dmaven.test.skip=false 2>&1 | tail -20
```
Expected: `Tests run: 2, Failures: 0, Errors: 0`.

- [ ] Run full suite to check regressions:
```bash
cd backend && ./mvnw test 2>&1 | tail -30
```

---

## Commit

```bash
git add \
  backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java \
  backend/src/main/java/hu/puzzleir/valuta/service/TurnoverService.java \
  backend/src/main/java/hu/puzzleir/valuta/dto/turnover/TurnoverReportDto.java \
  backend/src/test/java/hu/puzzleir/valuta/service/TurnoverServiceBreakdownTest.java

git commit -m "$(cat <<'EOF'
fix(turnover): implement byCurrency/byWorker breakdowns + exclude REVERSED transactions

- groupByCurrencyAndTypeForBranch and groupByWorkerForBranch JPQL queries added to TransactionRepository
- buildReport() now populates byCurrency and byWorker lists
- All totals now use REVERSED/CANCELLED-excluding queries
- getCompanyTurnover() updated to match
- TDD: TurnoverServiceBreakdownTest added

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```
