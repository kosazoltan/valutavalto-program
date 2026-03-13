package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
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
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * DailyBalanceService UNIT tesztek.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class DailyBalanceServiceTest {

    @InjectMocks
    private DailyBalanceService dailyBalanceService;

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private TransferRepository transferRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private CompanyRepository companyRepository;

    @Mock
    private AuditLogService auditLogService;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Common mock: Company
        Company mockCompany = new Company();
        mockCompany.setId(TEST_COMPANY_ID);
        when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(mockCompany));
    }

    @Test
    @DisplayName("getDailyBalances: üres nap → üres lista")
    void testGetDailyBalances_empty() {
        LocalDate today = LocalDate.of(2024, 6, 15);

        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_BRANCH_ID, today))
            .thenReturn(Collections.emptyList());

        List<DailyBalance> result = dailyBalanceService.getDailyBalances(TEST_BRANCH_ID, today);

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("getDailyBalances: van adat → visszaadja")
    void testGetDailyBalances_withData() {
        LocalDate today = LocalDate.of(2024, 6, 15);

        DailyBalance db = new DailyBalance();
        db.setBranchId(TEST_BRANCH_ID);
        db.setBalanceDate(today);
        db.setCurrencyCode("EUR");

        when(dailyBalanceRepository.findByBranchIdAndBalanceDate(TEST_BRANCH_ID, today))
            .thenReturn(List.of(db));

        List<DailyBalance> result = dailyBalanceService.getDailyBalances(TEST_BRANCH_ID, today);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCurrencyCode()).isEqualTo("EUR");
    }

    @Test
    @DisplayName("getMonthlyBalances: havi adatok lekérdezése")
    void testGetMonthlyBalances() {
        when(dailyBalanceRepository.findByBranchAndMonth(eq(TEST_BRANCH_ID), eq(2024), eq(6)))
            .thenReturn(Collections.emptyList());

        List<DailyBalance> result = dailyBalanceService.getMonthlyBalances(TEST_BRANCH_ID, 2024, 6);

        assertThat(result).isNotNull();
        verify(dailyBalanceRepository).findByBranchAndMonth(
            eq(TEST_BRANCH_ID), eq(2024), eq(6)
        );
    }

    @Test
    @DisplayName("closeDailyBalance: void return, no exception")
    void testCloseDailyBalance() {
        LocalDate today = LocalDate.of(2024, 6, 15);
        String currencyCode = "EUR";

        DailyBalance balance = new DailyBalance();
        balance.setBranchId(TEST_BRANCH_ID);
        balance.setBalanceDate(today);
        balance.setCurrencyCode(currencyCode);
        balance.setIsClosed(false);

        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(TEST_BRANCH_ID, today, currencyCode))
            .thenReturn(Optional.of(balance));

        assertThatNoException().isThrownBy(() ->
            dailyBalanceService.closeDailyBalance(TEST_BRANCH_ID, today, currencyCode)
        );
    }

    @Test
    @DisplayName("calculateDailyBalance: basic EUR calculation")
    void testCalculateDailyBalance() {
        LocalDate today = LocalDate.of(2024, 6, 15);
        String currencyCode = "EUR";

        // No existing balance
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(TEST_BRANCH_ID, today, currencyCode))
            .thenReturn(Optional.empty());

        // Previous day: no balance → opening = 0
        when(dailyBalanceRepository.findByBranchIdAndBalanceDateAndCurrencyCode(
            TEST_BRANCH_ID, today.minusDays(1), currencyCode))
            .thenReturn(Optional.empty());
        when(dailyBalanceRepository.findMonthlyClosingBalance(eq(TEST_BRANCH_ID), eq(currencyCode), anyInt(), anyInt()))
            .thenReturn(Collections.emptyList());

        // Daily turnover
        when(transactionRepository.sumDailyTurnover(eq(TEST_BRANCH_ID), eq(today), eq(TransactionType.BUY)))
            .thenReturn(new BigDecimal("2000.00"));
        when(transactionRepository.sumDailyTurnover(eq(TEST_BRANCH_ID), eq(today), eq(TransactionType.SELL)))
            .thenReturn(new BigDecimal("1500.00"));

        // Save mock
        when(dailyBalanceRepository.save(any(DailyBalance.class)))
            .thenAnswer(inv -> inv.getArgument(0));

        DailyBalance result = dailyBalanceService.calculateDailyBalance(TEST_BRANCH_ID, today, currencyCode);

        assertThat(result).isNotNull();
        assertThat(result.getCurrencyCode()).isEqualTo(currencyCode);
        verify(dailyBalanceRepository).save(any(DailyBalance.class));
    }
}
