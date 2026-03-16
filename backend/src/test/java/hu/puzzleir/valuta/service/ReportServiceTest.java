package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.MonthlyClosing;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * ReportService UNIT tesztek — P2-14 N+1 fix + branch name fix.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class ReportServiceTest {

    @InjectMocks
    private ReportService reportService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private DailySessionRepository dailySessionRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private MonthlyClosingRepository monthlyClosingRepository;
    @Mock private BranchRepository branchRepository;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ============ TASK 1: Worker N+1 fix ============

    @Test
    @DisplayName("generateWorkerPerformanceReport: single date-range query használata (nem N+1)")
    void workerPerformance_usesSingleQuery_notNPlusOne() {
        LocalDate start = LocalDate.of(2024, 1, 1);
        LocalDate end = LocalDate.of(2024, 1, 31);
        Long workerId = 5L;

        Worker worker = new Worker();
        worker.setId(workerId);
        worker.setCode("P001");
        worker.setName("Teszt Pénztáros");

        when(workerRepository.findById(workerId)).thenReturn(Optional.of(worker));
        when(transactionRepository.findByWorkerIdAndTransactionDateBetween(workerId, start, end))
                .thenReturn(Collections.emptyList());

        reportService.generateWorkerPerformanceReport(workerId, start, end);

        // Egyetlen date-range query, nem napi ciklus
        verify(transactionRepository, times(1))
                .findByWorkerIdAndTransactionDateBetween(workerId, start, end);
        // A régi napi query nem hívódik meg
        verify(transactionRepository, never())
                .findByWorkerAndDate(anyLong(), any(LocalDate.class));
    }

    @Test
    @DisplayName("generateWorkerPerformanceReport: helyes összesítés tranzakciókból")
    void workerPerformance_correctAggregation() {
        LocalDate start = LocalDate.of(2024, 3, 1);
        LocalDate end = LocalDate.of(2024, 3, 31);
        Long workerId = 7L;

        Worker worker = new Worker();
        worker.setId(workerId);
        worker.setCode("P007");
        worker.setName("Kovács Pénztáros");

        Currency eur = new Currency();
        eur.setCode("EUR");

        Transaction buy1 = buildTransaction(TransactionType.BUY, new BigDecimal("100000"), eur);
        Transaction sell1 = buildTransaction(TransactionType.SELL, new BigDecimal("50000"), eur);

        when(workerRepository.findById(workerId)).thenReturn(Optional.of(worker));
        when(transactionRepository.findByWorkerIdAndTransactionDateBetween(workerId, start, end))
                .thenReturn(List.of(buy1, sell1));

        ReportService.WorkerPerformanceReport result =
                reportService.generateWorkerPerformanceReport(workerId, start, end);

        assertThat(result.getTotalTransactions()).isEqualTo(2);
        assertThat(result.getBuyTransactions()).isEqualTo(1);
        assertThat(result.getSellTransactions()).isEqualTo(1);
        assertThat(result.getTotalBuyHuf()).isEqualByComparingTo("100000");
        assertThat(result.getTotalSellHuf()).isEqualByComparingTo("50000");
        assertThat(result.getTotalTurnoverHuf()).isEqualByComparingTo("150000");
        assertThat(result.getWorkerCode()).isEqualTo("P007");
    }

    // ============ TASK 2: HandlingFee N+1 fix ============

    @Test
    @DisplayName("generateHandlingFeeReport: GROUP BY aggregált query használata (nem N+1)")
    void handlingFee_usesAggregateQuery_notNPlusOne() {
        LocalDate start = LocalDate.of(2024, 2, 1);
        LocalDate end = LocalDate.of(2024, 2, 29);

        when(transactionRepository.findHandlingFeeSummaryByBranchAndDateRange(TEST_BRANCH_ID, start, end))
                .thenReturn(Collections.emptyList());

        reportService.generateHandlingFeeReport(start, end);

        verify(transactionRepository, times(1))
                .findHandlingFeeSummaryByBranchAndDateRange(TEST_BRANCH_ID, start, end);
        // A régi napi query nem hívódik meg
        verify(transactionRepository, never())
                .findActiveByBranchAndDate(any(UUID.class), any(LocalDate.class));
    }

    @Test
    @DisplayName("generateHandlingFeeReport: helyes összesítés aggregate sorokból")
    void handlingFee_correctAggregation_fromRows() {
        LocalDate start = LocalDate.of(2024, 1, 1);
        LocalDate end = LocalDate.of(2024, 1, 31);

        // row: [transactionDate, currencyCode, SUM(handlingFee), COUNT(t)]
        Object[] rowEur = {LocalDate.of(2024, 1, 5), "EUR", new BigDecimal("500"), 3L};
        Object[] rowUsd = {LocalDate.of(2024, 1, 6), "USD", new BigDecimal("300"), 2L};
        Object[] rowEur2 = {LocalDate.of(2024, 1, 7), "EUR", new BigDecimal("200"), 1L};

        when(transactionRepository.findHandlingFeeSummaryByBranchAndDateRange(TEST_BRANCH_ID, start, end))
                .thenReturn(List.of(rowEur, rowUsd, rowEur2));

        ReportService.HandlingFeeReport result = reportService.generateHandlingFeeReport(start, end);

        assertThat(result.getTotalHandlingFees()).isEqualByComparingTo("1000");
        assertThat(result.getTransactionsWithFee()).isEqualTo(6);
        assertThat(result.getFeesByCurrency()).hasSize(2);

        Map<String, BigDecimal> feeMap = new java.util.LinkedHashMap<>();
        result.getFeesByCurrency().forEach(fd -> feeMap.put(fd.getCurrencyCode(), fd.getTotalFees()));
        assertThat(feeMap.get("EUR")).isEqualByComparingTo("700");
        assertThat(feeMap.get("USD")).isEqualByComparingTo("300");
    }

    // ============ TASK 3: Branch name fix ============

    @Test
    @DisplayName("generateMonthlyTurnoverReport: valódi iroda nevet mutat (nem UUID prefix)")
    void monthlyTurnover_realBranchName_notUuidPrefix() {
        UUID branchId = UUID.randomUUID();
        MonthlyClosing closing = buildMonthlyClosing(branchId);

        Branch branch = new Branch();
        branch.setId(branchId);
        branch.setName("Budapest I. kerület fiók");

        when(monthlyClosingRepository.findByCompanyIdAndClosingYearOrderByClosingMonthDesc(TEST_COMPANY_ID, 2024))
                .thenReturn(List.of(closing));
        when(branchRepository.findAllById(Set.of(branchId)))
                .thenReturn(List.of(branch));

        ReportService.MonthlyTurnoverReport result =
                reportService.generateMonthlyTurnoverReport(2024, 3);

        assertThat(result.getBranchData()).hasSize(1);
        String branchName = result.getBranchData().get(0).getBranchName();
        assertThat(branchName).isEqualTo("Budapest I. kerület fiók");
        assertThat(branchName).doesNotStartWith("Iroda-");
    }

    @Test
    @DisplayName("generateMonthlyTurnoverReport: ismeretlen branch esetén fallback UUID prefix")
    void monthlyTurnover_unknownBranch_fallbackPrefix() {
        UUID unknownBranchId = UUID.randomUUID();
        MonthlyClosing closing = buildMonthlyClosing(unknownBranchId);

        when(monthlyClosingRepository.findByCompanyIdAndClosingYearOrderByClosingMonthDesc(TEST_COMPANY_ID, 2024))
                .thenReturn(List.of(closing));
        // Nem találja az irodát
        when(branchRepository.findAllById(any()))
                .thenReturn(Collections.emptyList());

        ReportService.MonthlyTurnoverReport result =
                reportService.generateMonthlyTurnoverReport(2024, 3);

        assertThat(result.getBranchData()).hasSize(1);
        String branchName = result.getBranchData().get(0).getBranchName();
        assertThat(branchName).startsWith("Iroda-");
    }

    @Test
    @DisplayName("generateMonthlyTurnoverReport: branchRepository csak egyszer hívódik (nem ciklusonként)")
    void monthlyTurnover_branchRepository_calledOnce() {
        UUID branchId1 = UUID.randomUUID();
        UUID branchId2 = UUID.randomUUID();

        MonthlyClosing c1 = buildMonthlyClosing(branchId1);
        MonthlyClosing c2 = buildMonthlyClosing(branchId2);

        Branch b1 = new Branch();
        b1.setId(branchId1);
        b1.setName("Iroda 1");
        Branch b2 = new Branch();
        b2.setId(branchId2);
        b2.setName("Iroda 2");

        when(monthlyClosingRepository.findByCompanyIdAndClosingYearOrderByClosingMonthDesc(TEST_COMPANY_ID, 2024))
                .thenReturn(List.of(c1, c2));
        when(branchRepository.findAllById(any()))
                .thenReturn(List.of(b1, b2));

        reportService.generateMonthlyTurnoverReport(2024, 3);

        // Csak egy batch findAllById, nem 2 findById hívás
        verify(branchRepository, times(1)).findAllById(any());
        verify(branchRepository, never()).findById(any(UUID.class));
    }

    // ============ HELPER METHODS ============

    private Transaction buildTransaction(TransactionType type, BigDecimal hufAmount, Currency currency) {
        Transaction t = new Transaction();
        t.setTransactionType(type);
        t.setHufAmount(hufAmount);
        t.setCurrencyAmount(hufAmount.divide(BigDecimal.valueOf(400)));
        t.setCurrency(currency);
        t.setHandlingFee(BigDecimal.ZERO);
        t.setStatus(TransactionStatus.COMPLETED);
        return t;
    }

    private MonthlyClosing buildMonthlyClosing(UUID branchId) {
        MonthlyClosing mc = new MonthlyClosing();
        mc.setBranchId(branchId);
        mc.setClosingYear(2024);
        mc.setClosingMonth(3);
        mc.setTotalBuyHuf(new BigDecimal("1000000"));
        mc.setTotalSellHuf(new BigDecimal("1200000"));
        mc.setTotalHandlingFees(new BigDecimal("5000"));
        mc.setTotalTransactionCount(50);
        mc.setBuyCount(25);
        mc.setSellCount(25);
        mc.setReversalCount(0);
        mc.setStatus("CLOSED");
        return mc;
    }
}
