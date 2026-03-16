package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

/**
 * ReportExportService UNIT tesztek — P2-14 CSV export.
 */
class ReportExportServiceTest {

    private ReportExportService exportService;

    @BeforeEach
    void setUp() {
        exportService = new ReportExportService();
    }

    // ============ BOM ============

    @Test
    @DisplayName("getBom: UTF-8 BOM bytes helyes értékek")
    void bom_correctBytes() {
        byte[] bom = exportService.getBom();
        assertThat(bom).hasSize(3);
        assertThat(bom[0]).isEqualTo((byte) 0xEF);
        assertThat(bom[1]).isEqualTo((byte) 0xBB);
        assertThat(bom[2]).isEqualTo((byte) 0xBF);
    }

    // ============ WorkerPerformance CSV ============

    @Test
    @DisplayName("exportWorkerPerformanceCsv: fejléc és adat sorok megjelennek")
    void workerCsv_containsHeaderAndData() {
        ReportService.WorkerPerformanceReport report = ReportService.WorkerPerformanceReport.builder()
                .workerId(1L)
                .workerCode("P001")
                .workerName("Teszt Pénztáros")
                .startDate(LocalDate.of(2024, 1, 1))
                .endDate(LocalDate.of(2024, 1, 31))
                .generatedAt(LocalDateTime.now())
                .totalTransactions(10)
                .buyTransactions(6)
                .sellTransactions(4)
                .reversalCount(0)
                .totalBuyHuf(new BigDecimal("600000"))
                .totalSellHuf(new BigDecimal("400000"))
                .totalTurnoverHuf(new BigDecimal("1000000"))
                .averageTransactionValue(new BigDecimal("100000"))
                .build();

        String csv = exportService.exportWorkerPerformanceCsv(report);

        assertThat(csv).contains("Pénztáros kód");
        assertThat(csv).contains("Pénztáros név");
        assertThat(csv).contains("P001");
        assertThat(csv).contains("Teszt Pénztáros");
        assertThat(csv).contains("600000");
        assertThat(csv).contains("1000000");
    }

    // ============ HandlingFee CSV ============

    @Test
    @DisplayName("exportHandlingFeeCsv: valuta sorok és összesítő sor megjelennek")
    void handlingFeeCsv_containsCurrencyRowsAndTotal() {
        ReportService.HandlingFeeReport report = ReportService.HandlingFeeReport.builder()
                .startDate(LocalDate.of(2024, 1, 1))
                .endDate(LocalDate.of(2024, 1, 31))
                .generatedAt(LocalDateTime.now())
                .totalHandlingFees(new BigDecimal("1500"))
                .transactionsWithFee(5)
                .feesByCurrency(List.of(
                        new ReportService.CurrencyFeeData("EUR", new BigDecimal("1000")),
                        new ReportService.CurrencyFeeData("USD", new BigDecimal("500"))
                ))
                .build();

        String csv = exportService.exportHandlingFeeCsv(report);

        assertThat(csv).contains("Valuta");
        assertThat(csv).contains("EUR");
        assertThat(csv).contains("1000");
        assertThat(csv).contains("USD");
        assertThat(csv).contains("500");
        assertThat(csv).contains("ÖSSZESEN");
        assertThat(csv).contains("1500");
    }

    // ============ MonthlyTurnover CSV ============

    @Test
    @DisplayName("exportMonthlyTurnoverCsv: valódi iroda név jelenik meg, nem UUID prefix")
    void monthlyTurnoverCsv_realBranchName() {
        UUID branchId = UUID.randomUUID();
        ReportService.BranchMonthlyData bd = ReportService.BranchMonthlyData.builder()
                .branchId(branchId)
                .branchName("Debrecen Főfiók")
                .transactionCount(100)
                .buyCount(60)
                .sellCount(40)
                .reversalCount(2)
                .buyHuf(new BigDecimal("5000000"))
                .sellHuf(new BigDecimal("6000000"))
                .netResult(new BigDecimal("1000000"))
                .handlingFees(new BigDecimal("10000"))
                .finalized(true)
                .build();

        ReportService.MonthlyTurnoverReport report = ReportService.MonthlyTurnoverReport.builder()
                .year(2024)
                .month(3)
                .generatedAt(LocalDateTime.now())
                .branchCount(1)
                .totalTransactions(100)
                .branchData(List.of(bd))
                .build();

        String csv = exportService.exportMonthlyTurnoverCsv(report);

        assertThat(csv).contains("Iroda neve");
        assertThat(csv).contains("Debrecen Főfiók");
        assertThat(csv).doesNotContain("Iroda-" + branchId.toString().substring(0, 8));
        assertThat(csv).contains("Igen");
    }

    // ============ PeriodReport CSV ============

    @Test
    @DisplayName("exportPeriodReportCsv: fejléc és napi összesítő sorok megjelennek")
    void periodCsv_containsHeaderAndRows() {
        ReportService.DailySummary ds = ReportService.DailySummary.builder()
                .date(LocalDate.of(2024, 1, 15))
                .branchName("Pest Fiók")
                .transactionCount(20)
                .buyTurnover(new BigDecimal("200000"))
                .sellTurnover(new BigDecimal("180000"))
                .netTurnover(new BigDecimal("-20000"))
                .handlingFees(new BigDecimal("2000"))
                .build();

        ReportService.PeriodReport report = ReportService.PeriodReport.builder()
                .startDate(LocalDate.of(2024, 1, 1))
                .endDate(LocalDate.of(2024, 1, 31))
                .generatedAt(LocalDateTime.now())
                .totalDays(1)
                .dailySummaries(List.of(ds))
                .build();

        String csv = exportService.exportPeriodReportCsv(report);

        assertThat(csv).contains("Dátum");
        assertThat(csv).contains("2024-01-15");
        assertThat(csv).contains("Pest Fiók");
        assertThat(csv).contains("200000");
    }
}
