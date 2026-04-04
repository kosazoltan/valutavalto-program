package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.MonthlyReportFullDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class MonthlyReportServiceTest {

    @Mock private ReportService reportService;
    @Mock private BranchRepository branchRepository;
    @Mock private DailyBalanceRepository dailyBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private DailySubledgerSnapshotRepository subledgerSnapshotRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private MnbExchangeRateService mnbExchangeRateService;
    @Mock private TransferRepository transferRepository;

    @InjectMocks
    private MonthlyReportService service;

    private static final UUID BRANCH_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private Branch testBranch;
    private Company testCompany;

    @BeforeEach
    void setUp() {
        testCompany = new Company();
        testCompany.setTaxNumber("32313332-2-02");

        testBranch = new Branch();
        testBranch.setId(BRANCH_ID);
        testBranch.setCode("101");
        testBranch.setName("Test Iroda");
        testBranch.setAddress("7621 Pecs, Kiraly u. 10.");
        testBranch.setCompany(testCompany);
    }

    @Test
    @DisplayName("generateFullReport: alap adatok helyesek")
    void generateFullReport_basicFields() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(testBranch));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchAndMonth(eq(BRANCH_ID), eq(2026), eq(3)))
                .thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(eq(BRANCH_ID), any()))
                .thenReturn(List.of());
        when(transactionRepository.findActiveByBranchAndDateRange(eq(BRANCH_ID), any(), any()))
                .thenReturn(List.of());
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(BRANCH_ID)))
                .thenReturn(List.of());
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                any(), any(), any(), any())).thenReturn(Optional.empty());
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateBetweenAndSubledgerTypeAndCurrencyCode(
                any(), any(), any(), any(), any())).thenReturn(List.of());
        when(transferRepository.sumTransfersIn(any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersOut(any(), any(), any())).thenReturn(BigDecimal.ZERO);

        MonthlyReportFullDto result = service.generateFullReport(BRANCH_ID, "2026-03");

        assertThat(result.getYearMonth()).isEqualTo("2026-03");
        assertThat(result.getBranchCode()).isEqualTo("101");
        assertThat(result.getBranchName()).isEqualTo("Test Iroda");
        assertThat(result.getBranchAddress()).isEqualTo("7621 Pecs, Kiraly u. 10.");
        assertThat(result.getTaxId()).isEqualTo("32313332-2-02");
    }

    @Test
    @DisplayName("generateFullReport: handling fee subledger aggregalas")
    void generateFullReport_handlingFeeFromSubledger() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(testBranch));
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchAndMonth(eq(BRANCH_ID), anyInt(), anyInt()))
                .thenReturn(List.of());
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(eq(BRANCH_ID), any()))
                .thenReturn(List.of());
        when(transactionRepository.findActiveByBranchAndDateRange(eq(BRANCH_ID), any(), any()))
                .thenReturn(List.of());
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(exchangeRateRepository.findActiveByDateAndBranch(any(), eq(BRANCH_ID)))
                .thenReturn(List.of());
        when(transferRepository.sumTransfersIn(any(), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersOut(any(), any(), any())).thenReturn(BigDecimal.ZERO);

        // Handling fee opening (march 1)
        DailySubledgerSnapshot hfOpening = DailySubledgerSnapshot.builder()
                .branchId(BRANCH_ID).snapshotDate(LocalDate.of(2026, 3, 1))
                .subledgerType("HANDLING_FEE").currencyCode("HUF")
                .openingBalance(new BigDecimal("50000")).closingBalance(new BigDecimal("55000"))
                .income(new BigDecimal("10000")).expense(new BigDecimal("5000"))
                .build();
        DailySubledgerSnapshot hfClosing = DailySubledgerSnapshot.builder()
                .branchId(BRANCH_ID).snapshotDate(LocalDate.of(2026, 3, 31))
                .subledgerType("HANDLING_FEE").currencyCode("HUF")
                .openingBalance(new BigDecimal("80000")).closingBalance(new BigDecimal("90000"))
                .income(new BigDecimal("15000")).expense(new BigDecimal("5000"))
                .build();

        // Opening query
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                BRANCH_ID, LocalDate.of(2026, 3, 1), "HANDLING_FEE", "HUF"))
                .thenReturn(Optional.of(hfOpening));
        // Closing query
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                BRANCH_ID, LocalDate.of(2026, 3, 31), "HANDLING_FEE", "HUF"))
                .thenReturn(Optional.of(hfClosing));
        // Range query for sum
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateBetweenAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), any(), eq("HANDLING_FEE"), eq("HUF")))
                .thenReturn(List.of(hfOpening, hfClosing));

        // Other subledgers return empty by default
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), argThat(t -> !"HANDLING_FEE".equals(t)), any()))
                .thenReturn(Optional.empty());
        when(subledgerSnapshotRepository.findByBranchIdAndSnapshotDateBetweenAndSubledgerTypeAndCurrencyCode(
                eq(BRANCH_ID), any(), any(), argThat(t -> !"HANDLING_FEE".equals(t)), any()))
                .thenReturn(List.of());

        MonthlyReportFullDto result = service.generateFullReport(BRANCH_ID, "2026-03");

        assertThat(result.getHandlingFeeOpening()).isEqualByComparingTo("50000");
        assertThat(result.getHandlingFeeBalance()).isEqualByComparingTo("90000");
        assertThat(result.getHandlingFeeIncome()).isEqualByComparingTo("25000"); // 10000 + 15000
        assertThat(result.getHandlingFeeExpense()).isEqualByComparingTo("10000"); // 5000 + 5000
    }

    @Test
    @DisplayName("generateFullReport: branch not found -> ResourceNotFoundException")
    void generateFullReport_branchNotFound() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.generateFullReport(BRANCH_ID, "2026-03"))
                .isInstanceOf(hu.puzzleir.valuta.exception.ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("getLastBusinessDay: hetvege es unnepnap atlepese")
    void getLastBusinessDay_skipsWeekendsAndHolidays() {
        // 2026-12-31 = csutortok, de 12-25 cs, 12-26 p unnep
        // 2026-08-20 (csutortok) = unnepnap → 08-19 szerdara ugrik
        LocalDate aug31 = LocalDate.of(2026, 8, 31); // hetfo
        LocalDate result = service.getLastBusinessDay(aug31);
        assertThat(result).isEqualTo(aug31); // Aug 31 = Monday, not holiday

        // Aug 20 is Allamalapitas (Thursday)
        LocalDate aug20 = LocalDate.of(2026, 8, 20);
        LocalDate resultAug20 = service.getLastBusinessDay(aug20);
        assertThat(resultAug20).isEqualTo(LocalDate.of(2026, 8, 19)); // Wednesday

        // Dec 26, 2026 = Saturday → also holiday → Dec 25 = Friday also holiday → Dec 24 = Thursday
        LocalDate dec26 = LocalDate.of(2026, 12, 26);
        LocalDate resultDec = service.getLastBusinessDay(dec26);
        assertThat(resultDec).isEqualTo(LocalDate.of(2026, 12, 24));
    }

    @Test
    @DisplayName("getLastBusinessDay: hetvege atlepese")
    void getLastBusinessDay_skipsWeekend() {
        // 2026-03-29 = vasarnap → 03-27 pentek
        LocalDate march29 = LocalDate.of(2026, 3, 29);
        LocalDate result = service.getLastBusinessDay(march29);
        assertThat(result).isEqualTo(LocalDate.of(2026, 3, 27));
    }
}
