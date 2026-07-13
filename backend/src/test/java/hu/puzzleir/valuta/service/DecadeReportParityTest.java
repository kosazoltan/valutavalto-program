package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.decade.DecadeReportDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.DecadeReport;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DecadeReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.jpa.repository.Query;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.lenient;

/**
 * P1-04/F-016 parity regresszió.
 * Spec-forrás: .hermes/dev-loop/decade-parity-matrix.md.
 */
@ExtendWith(MockitoExtension.class)
class DecadeReportParityTest {

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @InjectMocks private DecadeReportService service;
    @Mock private DecadeReportRepository decadeReportRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private DailyBalanceRepository dailyBalanceRepository;
    @Mock private MnbExchangeRateService mnbExchangeRateService;

    @ParameterizedTest(name = "D1/D2: dekád {1} -> {2}..{3}")
    @CsvSource({
            "2026, 1, 2026-01-01, 2026-01-10",
            "2026, 2, 2026-01-11, 2026-01-20",
            "2026, 3, 2026-01-21, 2026-01-31",
            "2026, 6, 2026-02-21, 2026-02-28",
            "2024, 6, 2024-02-21, 2024-02-29",
            "2026, 12, 2026-04-21, 2026-04-30",
            "2026, 36, 2026-12-21, 2026-12-31"
    })
    @DisplayName("A1 D1/D2: a dekádhatárok naptári nap szerint számolódnak")
    void a1_decadeBoundariesUseCalendarDays(int year, int decade,
                                             LocalDate expectedStart, LocalDate expectedEnd) {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(makeBranch(COMPANY_ID)));
        when(dailyBalanceRepository.findClosedDates(eq(COMPANY_ID), eq(BRANCH_ID), any(), any()))
                .thenAnswer(invocation -> List.of(invocation.getArgument(3, LocalDate.class)));
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(BRANCH_ID, year, decade))
                .thenReturn(Optional.empty());
        stubAggregates(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L);
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(eq(COMPANY_ID), eq(BRANCH_ID), any()))
                .thenReturn(List.of(makeHufBalance(expectedStart, BigDecimal.ZERO, BigDecimal.ZERO)));
        when(transactionRepository.findFinanciallyEffectiveByBranchAndDateRange(eq(BRANCH_ID), any(), any()))
                .thenReturn(Collections.emptyList());
        when(decadeReportRepository.save(any(DecadeReport.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            service.generateDecadeReport(BRANCH_ID, year, decade);
        }

        ArgumentCaptor<LocalDate> startCaptor = ArgumentCaptor.forClass(LocalDate.class);
        ArgumentCaptor<LocalDate> endCaptor = ArgumentCaptor.forClass(LocalDate.class);
        verify(dailyBalanceRepository).findClosedDates(
                eq(COMPANY_ID), eq(BRANCH_ID), startCaptor.capture(), endCaptor.capture());
        assertThat(startCaptor.getValue()).isEqualTo(expectedStart);
        assertThat(endCaptor.getValue()).isEqualTo(expectedEnd);
    }

    @ParameterizedTest
    @CsvSource({"0", "37"})
    @DisplayName("A2 D3: az 1-36 tartományon kívüli dekád elutasított")
    void a2_invalidDecadeIsRejected(int decade) {
        assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, decade))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("1-36");
        verifyNoInteractions(decadeReportRepository);
    }

    @Test
    @DisplayName("A3 D11: az üres dekád nullhelyett nulla aggregátumokat ad")
    void a3_emptyDecadeHasZeroAggregates() {
        stubForPeriod(LocalDate.of(2026, 1, 1), LocalDate.of(2026, 1, 10),
                BigDecimal.ZERO, BigDecimal.ZERO, Collections.emptyList(),
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L);

        DecadeReportDto dto = generate(2026, 1);

        assertThat(dto.getTotalBuyHuf()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(dto.getTotalSellHuf()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(dto.getTotalHandlingFee()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(dto.getTransactionCount()).isZero();
        assertThat(dto.getForintControlValid()).isTrue();
    }

    @Test
    @DisplayName("A4 D11: a repository aggregátumai torzítás nélkül kerülnek a riportba")
    void a4_repositoryAggregatesPassThroughUnchanged() {
        stubForPeriod(LocalDate.of(2026, 1, 1), LocalDate.of(2026, 1, 10),
                BigDecimal.ZERO, BigDecimal.ZERO, Collections.emptyList(),
                new BigDecimal("150000"), new BigDecimal("230000"), new BigDecimal("12000"), 7L);

        DecadeReportDto dto = generate(2026, 1);

        assertThat(dto.getTotalBuyHuf()).isEqualByComparingTo("150000");
        assertThat(dto.getTotalSellHuf()).isEqualByComparingTo("230000");
        assertThat(dto.getTotalHandlingFee()).isEqualByComparingTo("12000");
        assertThat(dto.getTransactionCount()).isEqualTo(7);
    }

    @Test
    @DisplayName("A5 D7/D8: csak a CARD forgalom különül el, a bizonylathatárok min/max szerintiek")
    void a5_cardTotalAndReceiptRangeAreSeparated() {
        List<Transaction> transactions = List.of(
                makeTransaction(TransactionType.SELL, "10000", BigDecimal.ZERO,
                        PaymentMethod.CASH, "B-2026-0005"),
                makeTransaction(TransactionType.SELL, "20000", BigDecimal.ZERO,
                        PaymentMethod.CASH, "B-2026-0001"),
                makeTransaction(TransactionType.SELL, "15000", BigDecimal.ZERO,
                        PaymentMethod.CARD, "B-2026-0003"));
        stubForPeriod(LocalDate.of(2026, 1, 1), LocalDate.of(2026, 1, 10),
                BigDecimal.ZERO, new BigDecimal("45000"), transactions,
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L);

        DecadeReportDto dto = generate(2026, 1);

        assertThat(dto.getCardPaymentTotal()).isEqualByComparingTo("15000");
        assertThat(dto.getFirstReceiptNumber()).isEqualTo("B-2026-0001");
        assertThat(dto.getLastReceiptNumber()).isEqualTo("B-2026-0005");
    }

    @Test
    @DisplayName("A6 D9: TRANSFER_IN bevétel, TRANSFER_OUT kiadás a forint kontrollban")
    void a6_transfersParticipateInForintControl() {
        // Modern szabály; a legacy ATADVET-kezelés a parity-mátrix szerint UNCLEAR.
        List<Transaction> transactions = List.of(
                makeTransaction(TransactionType.TRANSFER_IN, "50000", BigDecimal.ZERO,
                        PaymentMethod.CASH, "TI-1"),
                makeTransaction(TransactionType.TRANSFER_OUT, "30000", BigDecimal.ZERO,
                        PaymentMethod.CASH, "TO-1"));
        stubForPeriod(LocalDate.of(2026, 1, 1), LocalDate.of(2026, 1, 10),
                new BigDecimal("100000"), new BigDecimal("120000"), transactions,
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L);

        DecadeReportDto dto = generate(2026, 1);

        assertThat(dto.getForintTotalIncome()).isEqualByComparingTo("50000");
        assertThat(dto.getForintTotalExpense()).isEqualByComparingTo("30000");
        assertThat(dto.getForintControlValid()).isTrue();
    }

    @Test
    @DisplayName("A7 D10: a forint kontroll kizárólag financialEffective tranzakciókat kér")
    void a7_forintControlUsesFinanciallyEffectiveQuery() throws NoSuchMethodException {
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end = LocalDate.of(2026, 1, 10);
        stubForPeriod(start, end, BigDecimal.ZERO, BigDecimal.ZERO, Collections.emptyList(),
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L);

        generate(2026, 1);

        verify(transactionRepository)
                .findFinanciallyEffectiveByBranchAndDateRange(BRANCH_ID, start, end);
        verify(transactionRepository, never()).findByBranchId(any());
        assertFinancialEffectiveFilter("sumFeeByBranchAndPeriod",
                UUID.class, LocalDate.class, LocalDate.class);
        assertFinancialEffectiveFilter("countByBranchAndPeriod",
                UUID.class, LocalDate.class, LocalDate.class);
    }

    @Test
    @DisplayName("A8 D13: hét nap fallback után hiányzó MNB árfolyam fail-closed")
    void a8_mnbFallbackExhaustionIsRejected() {
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end = LocalDate.of(2026, 1, 10);
        stubForPeriod(start, end, BigDecimal.ZERO, BigDecimal.ZERO, Collections.emptyList(),
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L);
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(COMPANY_ID, BRANCH_ID, start))
                .thenReturn(List.of(
                        makeHufBalance(start, BigDecimal.ZERO, BigDecimal.ZERO),
                        makeBalance(start, "EUR", "100", "100")));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(COMPANY_ID, BRANCH_ID, end))
                .thenReturn(List.of(
                        makeHufBalance(end, BigDecimal.ZERO, BigDecimal.ZERO),
                        makeBalance(end, "EUR", "100", "100")));
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Collections.emptyMap());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, 1))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("MNB")
                    .hasMessageContaining("EUR");
        }
    }

    @Test
    @DisplayName("A9 D12: több valuta profitja aggregálódik, a HUF kimarad")
    void a9_multipleCurrenciesAreAggregatedAndHufIsExcluded() {
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end = LocalDate.of(2026, 1, 10);
        stubForPeriod(start, end, BigDecimal.ZERO, BigDecimal.ZERO, Collections.emptyList(),
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0L);
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(COMPANY_ID, BRANCH_ID, start))
                .thenReturn(List.of(
                        makeHufBalance(start, BigDecimal.ZERO, BigDecimal.ZERO),
                        makeBalance(start, "EUR", "1000", "1000"),
                        makeBalance(start, "USD", "500", "500")));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(COMPANY_ID, BRANCH_ID, end))
                .thenReturn(List.of(
                        makeHufBalance(end, BigDecimal.ZERO, BigDecimal.ZERO),
                        makeBalance(end, "EUR", "1000", "1000"),
                        makeBalance(end, "USD", "500", "500")));
        when(mnbExchangeRateService.getRatesForDate(start)).thenReturn(Map.of(
                "EUR", makeMnbRate("EUR", "380"), "USD", makeMnbRate("USD", "350")));
        when(mnbExchangeRateService.getRatesForDate(end)).thenReturn(Map.of(
                "EUR", makeMnbRate("EUR", "400"), "USD", makeMnbRate("USD", "350")));

        DecadeReportDto dto = generate(2026, 1);

        assertThat(dto.getLines()).hasSize(2);
        assertThat(dto.getLines()).extracting(line -> line.getCurrencyCode())
                .containsExactlyInAnyOrder("EUR", "USD")
                .doesNotContain("HUF");
        assertThat(dto.getLines()).filteredOn(line -> "EUR".equals(line.getCurrencyCode()))
                .singleElement().extracting(line -> line.getProfitHuf())
                .isEqualTo(new BigDecimal("20000.00"));
        assertThat(dto.getLines()).filteredOn(line -> "USD".equals(line.getCurrencyCode()))
                .singleElement().extracting(line -> line.getProfitHuf())
                .isEqualTo(new BigDecimal("0.00"));
        assertThat(dto.getDecadeProfitHuf()).isEqualByComparingTo("20000.00");
    }

    @Test
    @DisplayName("A10a D15: CLOSED riport nem regenerálható")
    void a10a_closedReportCannotBeRegenerated() {
        LocalDate start = LocalDate.of(2026, 1, 1);
        LocalDate end = LocalDate.of(2026, 1, 10);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(makeBranch(COMPANY_ID)));
        when(dailyBalanceRepository.findClosedDates(COMPANY_ID, BRANCH_ID, start, end))
                .thenReturn(List.of(end));
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(BRANCH_ID, 2026, 1))
                .thenReturn(Optional.of(DecadeReport.builder()
                        .branch(makeBranch(COMPANY_ID)).year(2026).decade(1)
                        .status(DecadeReport.DecadeReportStatus.CLOSED).build()));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, 1))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("már le van zárva");
        }
    }

    @Test
    @DisplayName("A10b D15: CLOSED riport nem zárható újra")
    void a10b_closedReportCannotBeClosedAgain() {
        UUID reportId = UUID.randomUUID();
        DecadeReport report = DecadeReport.builder()
                .id(reportId).branch(makeBranch(COMPANY_ID)).year(2026).decade(1)
                .status(DecadeReport.DecadeReportStatus.CLOSED).build();
        when(decadeReportRepository.findById(reportId)).thenReturn(Optional.of(report));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.closeDecade(reportId))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("már le van zárva");
        }
    }

    @Test
    @DisplayName("A11a D16: idegen cég irodájára nem generálható riport")
    void a11a_crossTenantGenerationIsRejected() {
        when(branchRepository.findById(BRANCH_ID))
                .thenReturn(Optional.of(makeBranch(UUID.randomUUID())));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.generateDecadeReport(BRANCH_ID, 2026, 1))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Nincs jogosultság");
        }
    }

    @Test
    @DisplayName("A11b D16: idegen cég riportja nem zárható le")
    void a11b_crossTenantCloseIsRejected() {
        UUID reportId = UUID.randomUUID();
        DecadeReport report = DecadeReport.builder()
                .id(reportId).branch(makeBranch(UUID.randomUUID())).year(2026).decade(1)
                .status(DecadeReport.DecadeReportStatus.DRAFT).build();
        when(decadeReportRepository.findById(reportId)).thenReturn(Optional.of(report));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.closeDecade(reportId))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Nincs jogosultság");
        }
    }

    private void stubForPeriod(LocalDate start, LocalDate end,
                               BigDecimal openingHuf, BigDecimal closingHuf,
                               List<Transaction> transactions,
                               BigDecimal totalBuy, BigDecimal totalSell,
                               BigDecimal totalFee, long transactionCount) {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(makeBranch(COMPANY_ID)));
        when(dailyBalanceRepository.findClosedDates(COMPANY_ID, BRANCH_ID, start, end))
                .thenReturn(List.of(end));
        when(decadeReportRepository.findByBranchIdAndYearAndDecade(BRANCH_ID, 2026, 1))
                .thenReturn(Optional.empty());
        stubAggregates(totalBuy, totalSell, totalFee, transactionCount);
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(COMPANY_ID, BRANCH_ID, start))
                .thenReturn(List.of(makeHufBalance(start, openingHuf, openingHuf)));
        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(COMPANY_ID, BRANCH_ID, end))
                .thenReturn(List.of(makeHufBalance(end, closingHuf, closingHuf)));
        lenient().when(transactionRepository.findFinanciallyEffectiveByBranchAndDateRange(BRANCH_ID, start, end))
                .thenReturn(transactions);
        lenient().when(decadeReportRepository.save(any(DecadeReport.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    private void stubAggregates(BigDecimal totalBuy, BigDecimal totalSell,
                                BigDecimal totalFee, long transactionCount) {
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
                eq(BRANCH_ID), eq("BUY"), any(), any())).thenReturn(totalBuy);
        when(transactionRepository.sumHufAmountByBranchAndTypeAndPeriod(
                eq(BRANCH_ID), eq("SELL"), any(), any())).thenReturn(totalSell);
        when(transactionRepository.sumFeeByBranchAndPeriod(eq(BRANCH_ID), any(), any()))
                .thenReturn(totalFee);
        when(transactionRepository.countByBranchAndPeriod(eq(BRANCH_ID), any(), any()))
                .thenReturn(transactionCount);
    }

    private void assertFinancialEffectiveFilter(String methodName, Class<?>... parameterTypes)
            throws NoSuchMethodException {
        Query query = TransactionRepository.class.getMethod(methodName, parameterTypes)
                .getAnnotation(Query.class);
        assertThat(query.value()).contains("t.financialEffective = true");
    }

    private DecadeReportDto generate(int year, int decade) {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            return service.generateDecadeReport(BRANCH_ID, year, decade);
        }
    }

    private Branch makeBranch(UUID companyId) {
        return Branch.builder()
                .id(BRANCH_ID)
                .company(Company.builder().id(companyId).build())
                .build();
    }

    private DailyBalance makeHufBalance(LocalDate date, BigDecimal opening, BigDecimal closing) {
        return DailyBalance.builder()
                .balanceDate(date).currencyCode("HUF")
                .openingBalance(opening).closingBalance(closing).build();
    }

    private DailyBalance makeBalance(LocalDate date, String currency,
                                     String opening, String closing) {
        return DailyBalance.builder()
                .balanceDate(date).currencyCode(currency)
                .openingBalance(new BigDecimal(opening))
                .closingBalance(new BigDecimal(closing)).build();
    }

    private MnbExchangeRateCache makeMnbRate(String currency, String ratePerUnit) {
        return MnbExchangeRateCache.builder()
                .currencyCode(currency).officialRate(new BigDecimal(ratePerUnit)).unit(1).build();
    }

    private Transaction makeTransaction(TransactionType type, String hufAmount,
                                        BigDecimal handlingFee, PaymentMethod paymentMethod,
                                        String receiptNumber) {
        return Transaction.builder()
                .transactionType(type)
                .hufAmount(new BigDecimal(hufAmount))
                .handlingFee(handlingFee)
                .paymentMethod(paymentMethod)
                .receiptNumber(receiptNumber)
                .build();
    }
}
