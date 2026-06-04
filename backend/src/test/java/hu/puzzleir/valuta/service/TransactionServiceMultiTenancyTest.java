package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.util.Collections;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * 2026-04-29 v2.3.25 (B17 multi-tenant hardening):
 * Defenzív tesztek a `searchTransactions` cross-branch adatszivárgás megelőzéséhez.
 *
 * Audit-jegyzet: D:\valutavalto-vault\sessions\2026-04-29-full-program-audit.md (B17)
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class TransactionServiceMultiTenancyTest {
    @Mock private TransactionValidationService transactionValidationService;
    @Mock private PmtComplianceValidator pmtComplianceValidator;
    @Mock private WacService wacService;

    @InjectMocks
    private TransactionService transactionService;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CompanyRepository companyRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private WorkerRepository workerRepository;

    @Mock
    private CashBalanceRepository cashBalanceRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @Mock
    private TransactionMapper transactionMapper;

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_BR035 = UUID.fromString("22222222-2222-2222-2222-222222222222");

    /**
     * 2026-04-29 v2.3.26 (Sourcery PR #290 P2 #2 follow-up):
     * Tisztább SecurityContext kezelés: minden teszt SAJÁT context-tel indul,
     * `clearContext()` a végén garantálja az izolációt. NEM próbálunk visszaállítani
     * "elöző" context-et (ami félrevezető — `getContext()` mutable instance).
     */
    @BeforeEach
    void setUp() {
        // Friss SecurityContext minden teszt-hez (NEM reuse mutable instance)
        SecurityContextHolder.clearContext();
        Authentication auth = new TestingAuthenticationToken("kosa", null);
        auth.setAuthenticated(true);
        var details = mock(hu.puzzleir.valuta.security.WorkerAuthenticationDetails.class);
        when(details.getCompanyId()).thenReturn(COMPANY_ID);
        when(details.getBranchId()).thenReturn(BRANCH_BR035);
        ((TestingAuthenticationToken) auth).setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDown() {
        // Minden teszt után tisztítunk — NEM szivárogtatás más tesztekbe
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("B17: searchTransactions branchId=null → IllegalArgumentException (defenzív hardening)")
    void searchTransactionsWithNullBranchIdThrows() {
        // Given: branchId=null (potenciális IDOR forrás)
        assertThatThrownBy(() ->
            transactionService.searchTransactions(
                null,  // branchId KIHAGYVA — ennek FAIL-elnie kell
                LocalDate.now().minusDays(7),
                LocalDate.now(),
                TransactionType.BUY,
                false,
                PageRequest.of(0, 10)
            )
        )
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("branchId KÖTELEZŐ")
        .hasMessageContaining("B17");

        // Repository hívás SOHA NEM történik
        verify(transactionRepository, never()).findWithFilters(any(), any(), any(), any(), any(), anyBoolean(), any());
    }

    @Test
    @DisplayName("B17: searchTransactions valid branchId → repository hívva companyId+branchId-vel")
    void searchTransactionsWithValidBranchIdPropagatesParams() {
        // 2026-04-29 v2.3.26 (Sourcery PR #290 P2 #1 follow-up):
        // LocalDate értékek extract változókba — NEM többszöri LocalDate.now()
        // hívás (test-stabilitás clock-szempontból + olvashatóság).
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(7);

        Page<Transaction> emptyPage = new PageImpl<>(Collections.emptyList());
        when(transactionRepository.findWithFilters(eq(COMPANY_ID), eq(BRANCH_BR035), any(), any(), any(), anyBoolean(), any()))
            .thenReturn(emptyPage);

        // When
        Page<Transaction> result = transactionService.searchTransactions(
            BRANCH_BR035,
            startDate,
            endDate,
            TransactionType.BUY,
            false,
            PageRequest.of(0, 10)
        );

        // Then: repository pontosan a saját company+branch szűrővel hívva
        assertThat(result).isNotNull();
        verify(transactionRepository).findWithFilters(
            eq(COMPANY_ID),
            eq(BRANCH_BR035),
            eq(startDate),
            eq(endDate),
            eq(TransactionType.BUY),
            eq(false),
            any()
        );
    }

    @Test
    @DisplayName("v2.3.26 Codex P1 follow-up: findCompanyWideWithFilters NEM tartalmaz branchId param-ot")
    void findCompanyWideWithFiltersUsesCompanyIdOnly() {
        // Given: company-wide statistics query (pl. /customers/top, /customers/frequent)
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(30);

        Page<Transaction> emptyPage = new PageImpl<>(Collections.emptyList());
        when(transactionRepository.findCompanyWideWithFilters(eq(COMPANY_ID), any(), any(), any(), any()))
            .thenReturn(emptyPage);

        // When: a repository közvetlen hívása (CustomerStatisticsService pattern)
        Page<Transaction> result = transactionRepository.findCompanyWideWithFilters(
            COMPANY_ID, startDate, endDate, null, PageRequest.of(0, 100)
        );

        // Then: a metódus aláírása NEM tartalmaz branchId paramot
        assertThat(result).isNotNull();
        verify(transactionRepository).findCompanyWideWithFilters(
            eq(COMPANY_ID),
            eq(startDate),
            eq(endDate),
            isNull(),
            any()
        );
        // Defenzív: a branch-scoped findWithFilters NEM hívódik
        verify(transactionRepository, never()).findWithFilters(any(), any(), any(), any(), any(), anyBoolean(), any());
    }
}
