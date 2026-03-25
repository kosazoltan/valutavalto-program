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
 * ReportService UNIT tesztek — Facade delegálás tesztelése.
 *
 * A ReportService delegál a generátorokra (DailyReportGenerator,
 * MonthlyReportGenerator, NbReportGenerator), ezért azokat mock-oljuk.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class ReportServiceTest {

    @InjectMocks
    private ReportService reportService;

    @Mock private DailyReportGenerator dailyReportGenerator;
    @Mock private MonthlyReportGenerator monthlyReportGenerator;
    @Mock private NbReportGenerator nbReportGenerator;

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

    // ============ TASK 1: Worker N+1 fix — delegálás NbReportGenerator-ra ============

    @Test
    @DisplayName("generateWorkerPerformanceReport: delegál NbReportGenerator-ra")
    void workerPerformance_delegatesToNbReportGenerator() {
        LocalDate start = LocalDate.of(2024, 1, 1);
        LocalDate end = LocalDate.of(2024, 1, 31);
        Long workerId = 5L;

        ReportService.WorkerPerformanceReport expected = new ReportService.WorkerPerformanceReport();
        expected.setWorkerCode("P001");
        expected.setTotalTransactions(10);
        expected.setBuyTransactions(6);
        expected.setSellTransactions(4);
        expected.setTotalBuyHuf(new BigDecimal("600000"));
        expected.setTotalSellHuf(new BigDecimal("400000"));
        expected.setTotalTurnoverHuf(new BigDecimal("1000000"));

        when(nbReportGenerator.generateWorkerPerformanceReport(workerId, start, end))
                .thenReturn(expected);

        ReportService.WorkerPerformanceReport result =
                reportService.generateWorkerPerformanceReport(workerId, start, end);

        verify(nbReportGenerator, times(1))
                .generateWorkerPerformanceReport(workerId, start, end);
        assertThat(result.getTotalTransactions()).isEqualTo(10);
        assertThat(result.getBuyTransactions()).isEqualTo(6);
        assertThat(result.getSellTransactions()).isEqualTo(4);
        assertThat(result.getTotalBuyHuf()).isEqualByComparingTo("600000");
        assertThat(result.getTotalSellHuf()).isEqualByComparingTo("400000");
        assertThat(result.getTotalTurnoverHuf()).isEqualByComparingTo("1000000");
        assertThat(result.getWorkerCode()).isEqualTo("P001");
    }

    @Test
    @DisplayName("generateWorkerPerformanceReport: helyes összesítés visszaadva")
    void workerPerformance_correctAggregation() {
        LocalDate start = LocalDate.of(2024, 3, 1);
        LocalDate end = LocalDate.of(2024, 3, 31);
        Long workerId = 7L;

        ReportService.WorkerPerformanceReport expected = new ReportService.WorkerPerformanceReport();
        expected.setWorkerCode("P007");
        expected.setTotalTransactions(2);
        expected.setBuyTransactions(1);
        expected.setSellTransactions(1);
        expected.setTotalBuyHuf(new BigDecimal("100000"));
        expected.setTotalSellHuf(new BigDecimal("50000"));
        expected.setTotalTurnoverHuf(new BigDecimal("150000"));

        when(nbReportGenerator.generateWorkerPerformanceReport(workerId, start, end))
                .thenReturn(expected);

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

    // ============ TASK 2: HandlingFee N+1 fix — delegálás MonthlyReportGenerator-ra ============

    @Test
    @DisplayName("generateHandlingFeeReport: delegál MonthlyReportGenerator-ra")
    void handlingFee_delegatesToMonthlyReportGenerator() {
        LocalDate start = LocalDate.of(2024, 2, 1);
        LocalDate end = LocalDate.of(2024, 2, 29);

        ReportService.HandlingFeeReport expected = new ReportService.HandlingFeeReport();
        expected.setTotalHandlingFees(BigDecimal.ZERO);
        expected.setTransactionsWithFee(0);
        expected.setFeesByCurrency(Collections.emptyList());

        when(monthlyReportGenerator.generateHandlingFeeReport(start, end))
                .thenReturn(expected);

        reportService.generateHandlingFeeReport(start, end);

        verify(monthlyReportGenerator, times(1))
                .generateHandlingFeeReport(start, end);
    }

    @Test
    @DisplayName("generateHandlingFeeReport: helyes összesítés aggregate sorokból")
    void handlingFee_correctAggregation_fromRows() {
        LocalDate start = LocalDate.of(2024, 1, 1);
        LocalDate end = LocalDate.of(2024, 1, 31);

        ReportService.CurrencyFeeData eurFee = new ReportService.CurrencyFeeData();
        eurFee.setCurrencyCode("EUR");
        eurFee.setTotalFees(new BigDecimal("700"));
        ReportService.CurrencyFeeData usdFee = new ReportService.CurrencyFeeData();
        usdFee.setCurrencyCode("USD");
        usdFee.setTotalFees(new BigDecimal("300"));

        ReportService.HandlingFeeReport expected = new ReportService.HandlingFeeReport();
        expected.setTotalHandlingFees(new BigDecimal("1000"));
        expected.setTransactionsWithFee(6);
        expected.setFeesByCurrency(List.of(eurFee, usdFee));

        when(monthlyReportGenerator.generateHandlingFeeReport(start, end))
                .thenReturn(expected);

        ReportService.HandlingFeeReport result = reportService.generateHandlingFeeReport(start, end);

        assertThat(result.getTotalHandlingFees()).isEqualByComparingTo("1000");
        assertThat(result.getTransactionsWithFee()).isEqualTo(6);
        assertThat(result.getFeesByCurrency()).hasSize(2);

        Map<String, BigDecimal> feeMap = new java.util.LinkedHashMap<>();
        result.getFeesByCurrency().forEach(fd -> feeMap.put(fd.getCurrencyCode(), fd.getTotalFees()));
        assertThat(feeMap.get("EUR")).isEqualByComparingTo("700");
        assertThat(feeMap.get("USD")).isEqualByComparingTo("300");
    }

    // ============ TASK 3: Branch name fix — delegálás MonthlyReportGenerator-ra ============

    @Test
    @DisplayName("generateMonthlyTurnoverReport: valódi iroda nevet mutat (delegálás)")
    void monthlyTurnover_realBranchName_delegated() {
        ReportService.BranchMonthlyData branchData = new ReportService.BranchMonthlyData();
        branchData.setBranchName("Budapest I. kerület fiók");
        branchData.setBuyHuf(new BigDecimal("1000000"));
        branchData.setSellHuf(new BigDecimal("1200000"));

        ReportService.MonthlyTurnoverReport expected = new ReportService.MonthlyTurnoverReport();
        expected.setBranchData(List.of(branchData));
        expected.setYear(2024);
        expected.setMonth(3);

        when(monthlyReportGenerator.generateMonthlyTurnoverReport(2024, 3))
                .thenReturn(expected);

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
        ReportService.BranchMonthlyData branchData = new ReportService.BranchMonthlyData();
        branchData.setBranchName("Iroda-" + UUID.randomUUID().toString().substring(0, 8));

        ReportService.MonthlyTurnoverReport expected = new ReportService.MonthlyTurnoverReport();
        expected.setBranchData(List.of(branchData));
        expected.setYear(2024);
        expected.setMonth(3);

        when(monthlyReportGenerator.generateMonthlyTurnoverReport(2024, 3))
                .thenReturn(expected);

        ReportService.MonthlyTurnoverReport result =
                reportService.generateMonthlyTurnoverReport(2024, 3);

        assertThat(result.getBranchData()).hasSize(1);
        String branchName = result.getBranchData().get(0).getBranchName();
        assertThat(branchName).startsWith("Iroda-");
    }

    @Test
    @DisplayName("generateMonthlyTurnoverReport: MonthlyReportGenerator csak egyszer hívódik")
    void monthlyTurnover_generatorCalledOnce() {
        ReportService.MonthlyTurnoverReport expected = new ReportService.MonthlyTurnoverReport();
        expected.setBranchData(Collections.emptyList());

        when(monthlyReportGenerator.generateMonthlyTurnoverReport(2024, 3))
                .thenReturn(expected);

        reportService.generateMonthlyTurnoverReport(2024, 3);

        verify(monthlyReportGenerator, times(1)).generateMonthlyTurnoverReport(2024, 3);
    }
}

