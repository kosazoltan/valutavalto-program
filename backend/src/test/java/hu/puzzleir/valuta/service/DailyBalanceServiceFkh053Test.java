package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.MonthlyClosingSummaryRepository;
import hu.puzzleir.valuta.repository.TransactionLineRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * FKH-053: past-date opening must not use live cash_balance; negative closing blocks.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DailyBalanceServiceFkh053Test {

    @InjectMocks
    private DailyBalanceService dailyBalanceService;

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;
    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private TransactionLineRepository transactionLineRepository;
    @Mock
    private TransferRepository transferRepository;
    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private CompanyRepository companyRepository;
    @Mock
    private AuditLogService auditLogService;
    @Mock
    private MonthlyClosingSummaryRepository monthlyClosingSummaryRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private CashBalanceRepository cashBalanceRepository;
    @Mock
    private BranchRepository branchRepository;
    @Mock
    private DenominationBalanceRepository denominationBalanceRepository;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final LocalDate TODAY = LocalDate.of(2026, 3, 16);
    private static final LocalDate PAST = LocalDate.of(2026, 3, 10);

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
                new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                        1L, COMPANY_ID, BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        Clock clock = Clock.fixed(Instant.parse("2026-03-16T12:00:00Z"), AmlEddService.BUSINESS_ZONE);
        try {
            ReflectionTestUtils.setField(dailyBalanceService, "clock", clock);
        } catch (IllegalArgumentException ignored) {
            // WU-1: clock field is added in WU-3
        }

        Company company = new Company();
        company.setId(COMPANY_ID);
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FKH-053 T3 (FR-2): past date without L1/L2 does not return live cash_balance")
    void t3_pastDate_doesNotUseLiveCashBalance() {
        when(dailyBalanceRepository.findClosingBalance(eq(COMPANY_ID), eq(BRANCH_ID), eq("EUR"), any(LocalDate.class)))
                .thenReturn(Optional.empty());
        when(monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(eq(BRANCH_ID), anyString()))
                .thenReturn(Optional.empty());
        CashBalance live = new CashBalance();
        live.setCurrentBalance(new BigDecimal("5000"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyCodeAndCompanyId(BRANCH_ID, "EUR", COMPANY_ID))
                .thenReturn(Optional.of(live));

        assertThatThrownBy(() -> dailyBalanceService.getOpeningBalance(BRANCH_ID, PAST, "EUR"))
                .isInstanceOf(ValidationException.class);
        verify(cashBalanceRepository, never())
                .findByBranchIdAndCurrencyCodeAndCompanyId(any(), any(), any());
    }

    @Test
    @DisplayName("FKH-053 T4 (NFR-3): today still falls back to cash_balance")
    void t4_today_usesCashBalance() {
        when(dailyBalanceRepository.findClosingBalance(eq(COMPANY_ID), eq(BRANCH_ID), eq("EUR"), any(LocalDate.class)))
                .thenReturn(Optional.empty());
        when(monthlyClosingSummaryRepository.findClosingByBranchAndYearMonth(eq(BRANCH_ID), anyString()))
                .thenReturn(Optional.empty());
        CashBalance live = new CashBalance();
        live.setCurrentBalance(new BigDecimal("5000"));
        when(cashBalanceRepository.findByBranchIdAndCurrencyCodeAndCompanyId(BRANCH_ID, "EUR", COMPANY_ID))
                .thenReturn(Optional.of(live));

        BigDecimal result = dailyBalanceService.getOpeningBalance(BRANCH_ID, TODAY, "EUR");
        assertThat(result).isEqualByComparingTo("5000");
    }

    @Test
    @DisplayName("FKH-053 T5: past date still uses previous-day closing (level 1)")
    void t5_pastDate_usesPreviousDay() {
        when(dailyBalanceRepository.findClosingBalance(
                eq(COMPANY_ID), eq(BRANCH_ID), eq("EUR"), eq(PAST.minusDays(1))))
                .thenReturn(Optional.of(new BigDecimal("1000.00")));

        BigDecimal result = dailyBalanceService.getOpeningBalance(BRANCH_ID, PAST, "EUR");
        assertThat(result).isEqualByComparingTo("1000.00");
        verifyNoInteractions(monthlyClosingSummaryRepository);
    }

    @Test
    @DisplayName("FKH-053 T6 (FR-3): negative closingBalance is not saved")
    void t6_negativeClosing_notSaved() {
        stubTurnover(TODAY, "EUR", new BigDecimal("100"), new BigDecimal("500"));

        assertThatThrownBy(() -> dailyBalanceService.calculateDailyBalance(BRANCH_ID, TODAY, "EUR"))
                .isInstanceOf(ValidationException.class);
        verify(dailyBalanceRepository, never()).save(any(DailyBalance.class));
    }

    @Test
    @DisplayName("FKH-053 T7 (FR-3): ValidationException from calculateDailyBalance propagates")
    void t7_validationException_propagatesFromCalculateAll() {
        hu.puzzleir.valuta.entity.Currency eur = new hu.puzzleir.valuta.entity.Currency();
        eur.setCode("EUR");
        when(currencyRepository.findActiveByCompany(COMPANY_ID)).thenReturn(List.of(eur));
        stubTurnover(TODAY, "EUR", new BigDecimal("100"), new BigDecimal("500"));

        assertThatThrownBy(() -> dailyBalanceService.calculateAllCurrenciesForDay(BRANCH_ID, TODAY))
                .isInstanceOf(ValidationException.class);
    }

    private void stubTurnover(LocalDate date, String ccy, BigDecimal opening, BigDecimal sales) {
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(
                eq(COMPANY_ID), eq(BRANCH_ID), eq(date), eq(ccy)))
                .thenReturn(Optional.empty());
        when(dailyBalanceRepository.findClosingBalance(eq(COMPANY_ID), eq(BRANCH_ID), eq(ccy), any(LocalDate.class)))
                .thenReturn(Optional.of(opening));
        when(transactionRepository.sumDailySingleLineTurnoverByCurrency(
                eq(BRANCH_ID), eq(date), eq(TransactionType.BUY), eq(ccy)))
                .thenReturn(BigDecimal.ZERO);
        when(transactionLineRepository.sumDailyLineTurnoverByCurrency(
                eq(BRANCH_ID), eq(date), eq(TransactionType.BUY), eq(ccy)))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumDailySingleLineTurnoverByCurrency(
                eq(BRANCH_ID), eq(date), eq(TransactionType.SELL), eq(ccy)))
                .thenReturn(sales);
        when(transactionLineRepository.sumDailyLineTurnoverByCurrency(
                eq(BRANCH_ID), eq(date), eq(TransactionType.SELL), eq(ccy)))
                .thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersInExcludingTh(eq(BRANCH_ID), eq(COMPANY_ID), eq(date), eq(ccy)))
                .thenReturn(BigDecimal.ZERO);
        when(transferRepository.sumTransfersOutExcludingTh(eq(BRANCH_ID), eq(COMPANY_ID), eq(date), eq(ccy)))
                .thenReturn(BigDecimal.ZERO);
    }
}
