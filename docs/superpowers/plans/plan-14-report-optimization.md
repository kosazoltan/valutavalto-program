# Report Optimization Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four issues in `ReportService`: (1) `generateWorkerPerformanceReport` N+1 lekérdezés (naponta egyszer hívja a repo-t), (2) `generateHandlingFeeReport` hasonló N+1 probléma, (3) `generateMonthlyTurnoverReport` `"Iroda-" + UUID` prefix helyett valódi iroda nevet használ, (4) CSV export hozzáadása minden riport típushoz.

**Architecture:** Az N+1 optimalizációhoz új repository metódusokat hozunk létre `GROUP BY` aggregálással (JPQL `@Query`). A branch name fix a `MonthlyClosing` entitás joinját vagy egy BranchRepository lookup cache-t használ. A CSV export Apache Commons CSV-vel (`opencsv` / `commons-csv`) készül, egy dedikált `ReportExportService`-ben.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Priority & Context

- **Priority:** P3-LOW
- **Érintett fájlok:**
  - `backend/src/main/java/hu/puzzleir/valuta/service/ReportService.java` (fő módosítás)
  - `backend/src/main/java/hu/puzzleir/valuta/service/ReportExportService.java` (ÚJ)
  - `backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java` (új query)
  - `backend/src/main/java/hu/puzzleir/valuta/repository/MonthlyClosingRepository.java` (join query)
  - `backend/src/main/java/hu/puzzleir/valuta/controller/ReportController.java` (CSV endpoint)
  - `backend/src/test/java/hu/puzzleir/valuta/service/ReportServiceTest.java` (ÚJ)

---

## Task 1: N+1 optimalizálás — generateWorkerPerformanceReport

### 1.1 A bug leírása

```java
// JELENLEGI (ReportService.java:185-191) — N+1 DB hívás:
List<Transaction> transactions = new ArrayList<>();
LocalDate current = startDate;
while (!current.isAfter(endDate)) {
    transactions.addAll(transactionRepository.findByWorkerAndDate(workerId, current));  // ← N hívás!
    current = current.plusDays(1);
}
```

30 napos időszakra = 30 DB lekérdezés. Helyette egyetlen `WHERE transaction_date BETWEEN ? AND ?` lekérdezés.

### 1.2 Új repository metódus

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java`
- [ ] Add hozzá:

```java
/**
 * Pénztáros összes tranzakciója dátumtartományban (egyszeri lekérdezés).
 */
@Query("SELECT t FROM Transaction t " +
       "WHERE t.worker.id = :workerId " +
       "AND t.transactionDate BETWEEN :startDate AND :endDate " +
       "AND t.status != 'CANCELLED'")
List<Transaction> findByWorkerAndDateRange(
    @Param("workerId") Long workerId,
    @Param("startDate") LocalDate startDate,
    @Param("endDate") LocalDate endDate
);
```

### 1.3 TDD

- [ ] Hozd létre: `backend/src/test/java/hu/puzzleir/valuta/service/ReportServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class ReportServiceTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private DailySessionRepository dailySessionRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private MonthlyClosingRepository monthlyClosingRepository;

    @InjectMocks private ReportService reportService;

    // ============ TASK 1: N+1 FIX ============

    @Test
    @DisplayName("generateWorkerPerformanceReport: egyetlen DB hívás dátumtartományra")
    void workerPerformance_singleQuery_notNPlus1() {
        Worker worker = Worker.builder().id(1L).code("P001").name("Nagy Béla").build();
        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(transactionRepository.findByWorkerAndDateRange(eq(1L), any(), any()))
            .thenReturn(buildSampleTransactions());

        LocalDate start = LocalDate.of(2026, 3, 1);
        LocalDate end   = LocalDate.of(2026, 3, 31);

        reportService.generateWorkerPerformanceReport(1L, start, end);

        // Csak EGYSZER hívódik a repository (nem 31-szer)
        verify(transactionRepository, times(1))
            .findByWorkerAndDateRange(eq(1L), eq(start), eq(end));
        verify(transactionRepository, never())
            .findByWorkerAndDate(any(), any());  // régi metódus NEM hívódik
    }

    @Test
    @DisplayName("generateWorkerPerformanceReport: helyes összesítést ad")
    void workerPerformance_correctAggregation() {
        Worker worker = Worker.builder().id(1L).code("P001").name("Nagy Béla").build();
        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));

        List<Transaction> txs = List.of(
            buildBuyTx(new BigDecimal("100000")),
            buildSellTx(new BigDecimal("80000")),
            buildSellTx(new BigDecimal("60000"))
        );
        when(transactionRepository.findByWorkerAndDateRange(any(), any(), any()))
            .thenReturn(txs);

        WorkerPerformanceReport report = reportService.generateWorkerPerformanceReport(
            1L, LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31));

        assertThat(report.getTotalTransactions()).isEqualTo(3);
        assertThat(report.getTotalBuyHuf()).isEqualByComparingTo(new BigDecimal("100000"));
        assertThat(report.getTotalSellHuf()).isEqualByComparingTo(new BigDecimal("140000"));
    }
}
```

### 1.4 Fix implementálása

- [ ] Nyisd meg: `ReportService.java` → `generateWorkerPerformanceReport()`
- [ ] Cseréld le a while-loop-os lekérdezést:

```java
public WorkerPerformanceReport generateWorkerPerformanceReport(Long workerId, LocalDate startDate, LocalDate endDate) {
    Worker worker = workerRepository.findById(workerId)
            .orElseThrow(() -> new RuntimeException("Pénztáros nem található"));

    // OPTIMALIZÁLT: egyetlen lekérdezés dátumtartományra (nem N+1 loop)
    List<Transaction> transactions = transactionRepository
        .findByWorkerAndDateRange(workerId, startDate, endDate);

    // ... többi logika változatlan ...
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=ReportServiceTest#workerPerformance*` → ZÖLD

---

## Task 2: N+1 optimalizálás — generateHandlingFeeReport

### 2.1 A meglévő helyzet feltérképezése

- [ ] Keresd meg a `generateHandlingFeeReport` metódust `ReportService.java`-ban, vagy a `ReportExtendedService.java`-ban:

```bash
grep -n "HandlingFeeReport\|handlingFee.*loop\|while.*current\|for.*date" \
  backend/src/main/java/hu/puzzleir/valuta/service/ReportExtendedService.java
```

- [ ] Ha a metódus `ReportExtendedService`-ben van, ugyanolyan mintát alkalmazz.

### 2.2 Általános minta (ahol a handling fee loop van)

Ha a kód így néz ki:
```java
// LOOP-os minta (N+1):
for (LocalDate d = startDate; !d.isAfter(endDate); d = d.plusDays(1)) {
    List<Transaction> daily = transactionRepository.findByBranchAndDate(branchId, d);
    // handling fee összesítés...
}
```

### 2.3 Új repository metódus

- [ ] Add a `TransactionRepository`-hoz:

```java
/**
 * Handling fee összesítés valutánként és napokra GROUP BY-val.
 * Eredmény: [transactionDate, currencyCode, sum(handlingFee), count(*)]
 */
@Query("SELECT t.transactionDate, t.currency.code, SUM(t.handlingFee), COUNT(t) " +
       "FROM Transaction t " +
       "WHERE t.branch.id = :branchId " +
       "AND t.transactionDate BETWEEN :startDate AND :endDate " +
       "AND t.active = true " +
       "GROUP BY t.transactionDate, t.currency.code " +
       "ORDER BY t.transactionDate ASC, t.currency.code ASC")
List<Object[]> findHandlingFeeSummaryByBranchAndDateRange(
    @Param("branchId") UUID branchId,
    @Param("startDate") LocalDate startDate,
    @Param("endDate") LocalDate endDate
);

/**
 * Dolgozó handling fee összesítés GROUP BY napok szerint.
 */
@Query("SELECT t.transactionDate, SUM(t.handlingFee), COUNT(t) " +
       "FROM Transaction t " +
       "WHERE t.worker.id = :workerId " +
       "AND t.transactionDate BETWEEN :startDate AND :endDate " +
       "AND t.active = true " +
       "GROUP BY t.transactionDate " +
       "ORDER BY t.transactionDate ASC")
List<Object[]> findHandlingFeeSummaryByWorkerAndDateRange(
    @Param("workerId") Long workerId,
    @Param("startDate") LocalDate startDate,
    @Param("endDate") LocalDate endDate
);
```

### 2.4 TDD

```java
@Test
@DisplayName("generateHandlingFeeReport: GROUP BY query-t hív, nem naponta")
void handlingFeeReport_usesGroupByQuery() {
    mockSecurityContext();
    when(transactionRepository.findHandlingFeeSummaryByBranchAndDateRange(any(), any(), any()))
        .thenReturn(List.of(
            new Object[]{ LocalDate.of(2026,3,1), "EUR", new BigDecimal("500"), 5L },
            new Object[]{ LocalDate.of(2026,3,1), "USD", new BigDecimal("300"), 3L }
        ));

    // Metódus hívása (adaptáld a tényleges szignatúrához)
    // reportService.generateHandlingFeeReport(startDate, endDate);

    verify(transactionRepository, times(1))
        .findHandlingFeeSummaryByBranchAndDateRange(any(), any(), any());
    // NEM hívja naponta a findByBranchAndDate-et
    verify(transactionRepository, never()).findByBranchAndDate(any(), any());
}
```

### 2.5 Fix

- [ ] A handling fee riport generáló metódusban cseréld ki a napokra bontott loopot az aggregált query eredményének feldolgozásával:

```java
// A GROUP BY eredmény feldolgozása:
List<Object[]> rows = transactionRepository
    .findHandlingFeeSummaryByBranchAndDateRange(branchId, startDate, endDate);

Map<LocalDate, Map<String, BigDecimal>> dailyFeesByCurrency = new LinkedHashMap<>();
for (Object[] row : rows) {
    LocalDate date    = (LocalDate) row[0];
    String currency   = (String) row[1];
    BigDecimal fee    = (BigDecimal) row[2];
    // Long count     = (Long) row[3];  // ha szükséges

    dailyFeesByCurrency
        .computeIfAbsent(date, k -> new LinkedHashMap<>())
        .put(currency, fee);
}
```

---

## Task 3: Branch name fix — generateMonthlyTurnoverReport

### 3.1 A bug leírása

```java
// JELENLEGI (ReportService.java:361):
.branchName("Iroda-" + closing.getBranchId().toString().substring(0,8))
```

Ehelyett az iroda nevét kell megjeleníteni.

### 3.2 Fix — Option A: BranchRepository lookup (egyszerű)

- [ ] Add a `BranchRepository`-t a `ReportService` függőségei közé
- [ ] Módosítsd a `generateMonthlyTurnoverReport()` metódust:

```java
// A closings loop elején egyszer töltsd be az iroda neveket:
Map<UUID, String> branchNames = new HashMap<>();
for (MonthlyClosing closing : closings) {
    branchNames.computeIfAbsent(closing.getBranchId(), id ->
        branchRepository.findById(id)
            .map(Branch::getName)
            .orElse("Ismeretlen iroda (" + id.toString().substring(0, 8) + ")")
    );
}

// Majd a branchData buildernél:
branchData.add(BranchMonthlyData.builder()
    .branchId(closing.getBranchId())
    .branchName(branchNames.get(closing.getBranchId()))  // ← FIX
    // ... többi mező ...
    .build());
```

### 3.3 Fix — Option B: JOIN query (hatékonyabb)

- [ ] Add a `MonthlyClosingRepository`-hoz egy JOIN query-t:

```java
@Query("SELECT mc, b.name FROM MonthlyClosing mc " +
       "LEFT JOIN Branch b ON b.id = mc.branchId " +
       "WHERE mc.companyId = :companyId " +
       "AND mc.closingYear = :year AND mc.closingMonth = :month")
List<Object[]> findByCompanyAndYearMonthWithBranchName(
    @Param("companyId") UUID companyId,
    @Param("year") Integer year,
    @Param("month") Integer month
);
```

**Ajánlott: Option A** — egyszerűbb, a branchRepository.findById()-ra már van cache JPA szinten, és az irodák száma általában alacsony (max 20-30).

### 3.4 TDD

```java
@Test
@DisplayName("generateMonthlyTurnoverReport: valódi iroda nevet ad vissza, nem UUID prefixet")
void monthlyTurnover_realBranchName() {
    mockSecurityContext();
    UUID branchId = UUID.fromString("550e8400-e29b-41d4-a716-446655440000");
    Branch branch = Branch.builder().id(branchId).name("Keleti pályaudvar iroda").build();

    MonthlyClosing closing = MonthlyClosing.builder()
        .branchId(branchId)
        .closingYear(2026).closingMonth(3)
        .totalBuyHuf(new BigDecimal("1000000"))
        .totalSellHuf(new BigDecimal("1100000"))
        .totalHandlingFees(new BigDecimal("50000"))
        .totalTransactionCount(100)
        .buyCount(60).sellCount(40).reversalCount(0)
        .status("CLOSED")
        .build();

    when(monthlyClosingRepository.findByCompanyIdAndClosingYearOrderByClosingMonthDesc(any(), eq(2026)))
        .thenReturn(List.of(closing));
    when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

    MonthlyTurnoverReport report = reportService.generateMonthlyTurnoverReport(2026, 3);

    assertThat(report.getBranchData()).hasSize(1);
    assertThat(report.getBranchData().get(0).getBranchName())
        .isEqualTo("Keleti pályaudvar iroda");  // nem "Iroda-550e8400"
    assertThat(report.getBranchData().get(0).getBranchName())
        .doesNotStartWith("Iroda-");
}
```

---

## Task 4: CSV export hozzáadása

### 4.1 Függőség ellenőrzés

- [ ] Ellenőrizd a `backend/pom.xml`-ben, hogy van-e Apache Commons CSV függőség:

```xml
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-csv</artifactId>
    <version>1.10.0</version>
</dependency>
```

Ha hiányzik, add hozzá a pom.xml-hez.

### 4.2 ReportExportService létrehozása

- [ ] Hozd létre: `backend/src/main/java/hu/puzzleir/valuta/service/ReportExportService.java`

```java
package hu.puzzleir.valuta.service;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.StringWriter;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;

/**
 * Riport CSV export szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReportExportService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter DATETIME_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * Dolgozói teljesítmény riport → CSV.
     */
    public String exportWorkerPerformanceCsv(ReportService.WorkerPerformanceReport report) {
        StringWriter sw = new StringWriter();
        CSVFormat format = CSVFormat.DEFAULT.builder()
            .setHeader("Pénztáros kód", "Pénztáros neve", "Időszak kezdete", "Időszak vége",
                       "Összes tranzakció", "Vétel db", "Eladás db", "Sztornó db",
                       "Vétel HUF", "Eladás HUF", "Forgalom HUF", "Átlag tranzakció HUF",
                       "Generálás ideje")
            .build();

        try (CSVPrinter printer = new CSVPrinter(sw, format)) {
            printer.printRecord(
                report.getWorkerCode(),
                report.getWorkerName(),
                report.getStartDate().format(DATE_FMT),
                report.getEndDate().format(DATE_FMT),
                report.getTotalTransactions(),
                report.getBuyTransactions(),
                report.getSellTransactions(),
                report.getReversalCount(),
                report.getTotalBuyHuf(),
                report.getTotalSellHuf(),
                report.getTotalTurnoverHuf(),
                report.getAverageTransactionValue(),
                report.getGeneratedAt().format(DATETIME_FMT)
            );
        } catch (IOException e) {
            throw new RuntimeException("CSV export hiba: " + e.getMessage(), e);
        }

        return sw.toString();
    }

    /**
     * Havi forgalmi riport → CSV (iroda sorok).
     */
    public String exportMonthlyTurnoverCsv(ReportService.MonthlyTurnoverReport report) {
        StringWriter sw = new StringWriter();
        CSVFormat format = CSVFormat.DEFAULT.builder()
            .setHeader("Iroda neve", "Tranzakciók", "Vétel db", "Eladás db", "Sztornó db",
                       "Vétel HUF", "Eladás HUF", "Nettó eredmény HUF",
                       "Kezelési díj HUF", "Lezárva")
            .build();

        try (CSVPrinter printer = new CSVPrinter(sw, format)) {
            // Fejléc sor kommentként
            printer.printComment("Havi forgalmi kimutatás: " + report.getYear() + "/" + report.getMonth());

            for (ReportService.BranchMonthlyData branch : report.getBranchData()) {
                printer.printRecord(
                    branch.getBranchName(),
                    branch.getTransactionCount(),
                    branch.getBuyCount(),
                    branch.getSellCount(),
                    branch.getReversalCount(),
                    branch.getBuyHuf(),
                    branch.getSellHuf(),
                    branch.getNetResult(),
                    branch.getHandlingFees(),
                    branch.isFinalized() ? "Igen" : "Nem"
                );
            }

            // Összesítő sor
            printer.printRecord(
                "ÖSSZESEN",
                report.getTotalTransactions(),
                report.getTotalBuyCount(),
                report.getTotalSellCount(),
                report.getTotalReversals(),
                report.getTotalBuyHuf(),
                report.getTotalSellHuf(),
                report.getNetTurnoverHuf(),
                report.getTotalHandlingFees(),
                ""
            );
        } catch (IOException e) {
            throw new RuntimeException("CSV export hiba: " + e.getMessage(), e);
        }

        return sw.toString();
    }

    /**
     * Napi záró riport → CSV.
     */
    public String exportDailyClosingCsv(ReportService.DailyClosingReport report) {
        StringWriter sw = new StringWriter();
        CSVFormat format = CSVFormat.DEFAULT.builder()
            .setHeader("Valuta", "Vétel összeg", "Eladás összeg",
                       "Vétel HUF", "Eladás HUF", "Tranzakciók")
            .build();

        try (CSVPrinter printer = new CSVPrinter(sw, format)) {
            printer.printComment("Napi záró: " + report.getReportDate().format(DATE_FMT));

            for (ReportService.CurrencyTurnover ct : report.getCurrencyTurnovers()) {
                printer.printRecord(
                    ct.getCurrencyCode(),
                    ct.getBoughtAmount(),
                    ct.getSoldAmount(),
                    ct.getBoughtHuf(),
                    ct.getSoldHuf(),
                    ct.getTransactionCount()
                );
            }
        } catch (IOException e) {
            throw new RuntimeException("CSV export hiba: " + e.getMessage(), e);
        }

        return sw.toString();
    }
}
```

### 4.3 Controller endpoint

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/controller/ReportController.java`
- [ ] Add hozzá a CSV export endpointokat:

```java
@Autowired
private ReportExportService reportExportService;

/**
 * Dolgozói teljesítmény riport CSV export.
 */
@GetMapping("/worker-performance/{workerId}/csv")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
public ResponseEntity<byte[]> exportWorkerPerformanceCsv(
        @PathVariable Long workerId,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {

    ReportService.WorkerPerformanceReport report =
        reportService.generateWorkerPerformanceReport(workerId, startDate, endDate);
    String csv = reportExportService.exportWorkerPerformanceCsv(report);

    String filename = "worker_performance_" + workerId + "_" + startDate + "_" + endDate + ".csv";
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
        .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
        .body(csv.getBytes(java.nio.charset.StandardCharsets.UTF_8));
}

/**
 * Havi forgalmi riport CSV export.
 */
@GetMapping("/monthly-turnover/csv")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
public ResponseEntity<byte[]> exportMonthlyTurnoverCsv(
        @RequestParam Integer year,
        @RequestParam Integer month) {

    ReportService.MonthlyTurnoverReport report =
        reportService.generateMonthlyTurnoverReport(year, month);
    String csv = reportExportService.exportMonthlyTurnoverCsv(report);

    String filename = "monthly_turnover_" + year + "_" + String.format("%02d", month) + ".csv";
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
        .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
        .body(csv.getBytes(java.nio.charset.StandardCharsets.UTF_8));
}

/**
 * Napi záró riport CSV export.
 */
@GetMapping("/daily-closing/csv")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR', 'CASHIER')")
public ResponseEntity<byte[]> exportDailyClosingCsv(
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {

    ReportService.DailyClosingReport report =
        reportService.generateDailyClosingReport(date);
    String csv = reportExportService.exportDailyClosingCsv(report);

    String filename = "daily_closing_" + date + ".csv";
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
        .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
        .body(csv.getBytes(java.nio.charset.StandardCharsets.UTF_8));
}
```

### 4.4 TDD a CSV exporthoz

```java
// ReportServiceTest.java-ban:
@Mock private ReportExportService reportExportService;

@Test
@DisplayName("exportWorkerPerformanceCsv: CSV tartalmazza a pénztáros nevét és összesítőket")
void exportWorkerPerformanceCsv_containsHeaderAndData() {
    ReportService.WorkerPerformanceReport report = ReportService.WorkerPerformanceReport.builder()
        .workerId(1L).workerCode("P001").workerName("Nagy Béla")
        .startDate(LocalDate.of(2026, 3, 1)).endDate(LocalDate.of(2026, 3, 31))
        .generatedAt(LocalDateTime.now())
        .totalTransactions(50).buyTransactions(30).sellTransactions(20).reversalCount(0)
        .totalBuyHuf(new BigDecimal("5000000"))
        .totalSellHuf(new BigDecimal("4500000"))
        .totalTurnoverHuf(new BigDecimal("9500000"))
        .averageTransactionValue(new BigDecimal("190000"))
        .build();

    ReportExportService exportService = new ReportExportService();
    String csv = exportService.exportWorkerPerformanceCsv(report);

    assertThat(csv).contains("Nagy Béla");
    assertThat(csv).contains("P001");
    assertThat(csv).contains("5000000");
    assertThat(csv).contains("Pénztáros neve");  // fejléc
}

@Test
@DisplayName("exportMonthlyTurnoverCsv: iroda neve szerepel, nem UUID prefix")
void exportMonthlyTurnoverCsv_branchNameNotUuid() {
    ReportService.MonthlyTurnoverReport report = ReportService.MonthlyTurnoverReport.builder()
        .year(2026).month(3).generatedAt(LocalDateTime.now())
        .branchData(List.of(
            ReportService.BranchMonthlyData.builder()
                .branchName("Keleti pályaudvar iroda")
                .transactionCount(100).buyCount(60).sellCount(40).reversalCount(0)
                .buyHuf(new BigDecimal("1000000")).sellHuf(new BigDecimal("1100000"))
                .netResult(new BigDecimal("100000")).handlingFees(new BigDecimal("50000"))
                .finalized(true).build()
        ))
        .totalTransactions(100).totalBuyCount(60).totalSellCount(40).totalReversals(0)
        .totalBuyHuf(new BigDecimal("1000000")).totalSellHuf(new BigDecimal("1100000"))
        .netTurnoverHuf(new BigDecimal("100000")).totalHandlingFees(new BigDecimal("50000"))
        .build();

    ReportExportService exportService = new ReportExportService();
    String csv = exportService.exportMonthlyTurnoverCsv(report);

    assertThat(csv).contains("Keleti pályaudvar iroda");
    assertThat(csv).doesNotContain("Iroda-");
}
```

---

## Futtatandó parancsok

```bash
# Új függőség letöltése
cd backend && ./mvnw dependency:resolve

# Riport tesztek
cd backend && ./mvnw test -Dtest=ReportServiceTest

# CSV export tesztek
cd backend && ./mvnw test -Dtest=ReportExportServiceTest

# Teljes build
cd backend && ./mvnw clean verify -DskipITs

# Kézi tesztelés: CSV letöltés
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/reports/monthly-turnover/csv?year=2026&month=3" \
  -o monthly_report.csv
```

---

## Commit üzenetek

```
perf(report): optimize generateWorkerPerformanceReport — single query instead of N+1

perf(report): optimize generateHandlingFeeReport — use GROUP BY aggregate query

fix(report): resolve real branch name in generateMonthlyTurnoverReport

feat(report): add CSV export for all report types via ReportExportService

feat(report): add /csv endpoints to ReportController with proper Content-Disposition

test(report): add ReportServiceTest for N+1 fix and branch name

test(report): add ReportExportServiceTest for CSV output correctness
```

---

## Megjegyzések

### BOM (UTF-8 BOM) Excel kompatibilitás

Ha a CSV-t Excelben is megnyitják, érdemes BOM-ot (byte order mark) hozzáadni, mert az Excel UTF-8 BOM nélkül nem mindig ismeri fel az ékezetes karaktereket:

```java
// ResponseEntity buildernél:
byte[] csvBytes = csv.getBytes(java.nio.charset.StandardCharsets.UTF_8);
byte[] bom = { (byte) 0xEF, (byte) 0xBB, (byte) 0xBF };
byte[] withBom = new byte[bom.length + csvBytes.length];
System.arraycopy(bom, 0, withBom, 0, bom.length);
System.arraycopy(csvBytes, 0, withBom, bom.length, csvBytes.length);
return ResponseEntity.ok()
    .header(...)
    .body(withBom);
```

### Teljesítmény benchmark

30 napos worker performance riportnál a várható javulás:
- **Előtte:** 30 × ~5ms = ~150ms DB idő
- **Utána:** 1 × ~15ms = ~15ms DB idő (10× gyorsabb)
