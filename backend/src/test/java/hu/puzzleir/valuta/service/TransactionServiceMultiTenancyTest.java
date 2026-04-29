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
import org.springframework.security.core.context.SecurityContext;
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

    private SecurityContext savedContext;

    @BeforeEach
    void setUp() {
        // Mentsuk az eredetit, hogy NE szivárogjanak ki teszt-context-ek
        savedContext = SecurityContextHolder.getContext();
        // Mock SecurityContext: KOSA worker, BR035 branch, companyId
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
        SecurityContextHolder.clearContext();
        if (savedContext != null) {
            SecurityContextHolder.setContext(savedContext);
        }
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
                PageRequest.of(0, 10)
            )
        )
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("branchId KÖTELEZŐ")
        .hasMessageContaining("B17");

        // Repository hívás SOHA NEM történik
        verify(transactionRepository, never()).findWithFilters(any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("B17: searchTransactions valid branchId → repository hívva companyId+branchId-vel")
    void searchTransactionsWithValidBranchIdPropagatesParams() {
        // Given: valid branchId
        Page<Transaction> emptyPage = new PageImpl<>(Collections.emptyList());
        when(transactionRepository.findWithFilters(eq(COMPANY_ID), eq(BRANCH_BR035), any(), any(), any(), any()))
            .thenReturn(emptyPage);

        // When
        Page<Transaction> result = transactionService.searchTransactions(
            BRANCH_BR035,
            LocalDate.now().minusDays(7),
            LocalDate.now(),
            TransactionType.BUY,
            PageRequest.of(0, 10)
        );

        // Then: repository pontosan a saját company+branch szűrővel hívva
        assertThat(result).isNotNull();
        verify(transactionRepository).findWithFilters(
            eq(COMPANY_ID),
            eq(BRANCH_BR035),
            eq(LocalDate.now().minusDays(7)),
            eq(LocalDate.now()),
            eq(TransactionType.BUY),
            any()
        );
    }
}
