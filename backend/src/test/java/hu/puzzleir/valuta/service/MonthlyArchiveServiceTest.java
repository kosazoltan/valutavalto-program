package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.FinancialRetentionProperties;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
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
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MonthlyArchiveService UNIT tesztek.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class MonthlyArchiveServiceTest {

    @InjectMocks
    private MonthlyArchiveService monthlyArchiveService;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ArchivedTransactionRepository archivedTransactionRepository;

    @Mock
    private AuditLogService auditLogService;

    @Mock
    private FinancialRetentionProperties financialRetentionProperties;

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

        when(financialRetentionProperties.getYears()).thenReturn(8);
        when(financialRetentionProperties.isHardDeleteEnabled()).thenReturn(false);
    }

    @Test
    @DisplayName("archiveMonth: sikeres archiválás")
    void testArchiveMonth_success() {
        YearMonth targetMonth = YearMonth.of(2024, 12);

        when(archivedTransactionRepository.countByMonthAndBranch(eq("2024-12"), eq(TEST_BRANCH_ID)))
            .thenReturn(0L);

        List<Transaction> transactions = createMockTransactions(targetMonth, 3);
        when(transactionRepository.findByBranchAndMonth(eq(TEST_BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(transactions);

        int result = monthlyArchiveService.archiveMonth(TEST_BRANCH_ID, targetMonth);

        assertThat(result).isEqualTo(3);
        verify(archivedTransactionRepository, times(3)).save(any(ArchivedTransaction.class));
        for (Transaction tx : transactions) {
            assertThat(tx.getStatus()).isEqualTo(TransactionStatus.ARCHIVED);
        }
    }

    @Test
    @DisplayName("archiveMonth: dupla archiválás → ValidationException")
    void testArchiveMonth_duplicate() {
        YearMonth targetMonth = YearMonth.of(2024, 11);

        when(archivedTransactionRepository.countByMonthAndBranch(eq("2024-11"), eq(TEST_BRANCH_ID)))
            .thenReturn(5L);

        assertThatThrownBy(() -> monthlyArchiveService.archiveMonth(TEST_BRANCH_ID, targetMonth))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("már archivált");
    }

    @Test
    @DisplayName("archiveMonth: üres hónap → 0 tranzakció, nincs hiba")
    void testArchiveMonth_emptyMonth() {
        YearMonth targetMonth = YearMonth.of(2024, 10);

        when(archivedTransactionRepository.countByMonthAndBranch(eq("2024-10"), eq(TEST_BRANCH_ID)))
            .thenReturn(0L);
        when(transactionRepository.findByBranchAndMonth(eq(TEST_BRANCH_ID), any(LocalDate.class), any(LocalDate.class)))
            .thenReturn(Collections.emptyList());

        int result = monthlyArchiveService.archiveMonth(TEST_BRANCH_ID, targetMonth);

        assertThat(result).isEqualTo(0);
        verify(archivedTransactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("isMonthArchived: archivált hónap → true")
    void testIsMonthArchived_true() {
        when(archivedTransactionRepository.countByMonthAndBranch(eq("2024-09"), eq(TEST_BRANCH_ID)))
            .thenReturn(10L);

        boolean result = monthlyArchiveService.isMonthArchived(TEST_BRANCH_ID, YearMonth.of(2024, 9));

        assertThat(result).isTrue();
    }

    @Test
    @DisplayName("isMonthArchived: nem archivált hónap → false")
    void testIsMonthArchived_false() {
        when(archivedTransactionRepository.countByMonthAndBranch(eq("2024-08"), eq(TEST_BRANCH_ID)))
            .thenReturn(0L);

        boolean result = monthlyArchiveService.isMonthArchived(TEST_BRANCH_ID, YearMonth.of(2024, 8));

        assertThat(result).isFalse();
    }

    // ============ HELPER ============

    private List<Transaction> createMockTransactions(YearMonth month, int count) {
        List<Transaction> transactions = new ArrayList<>();
        Company mockCompany = new Company();
        mockCompany.setId(TEST_COMPANY_ID);
        Branch mockBranch = new Branch();
        mockBranch.setId(TEST_BRANCH_ID);
        Worker mockWorker = Worker.builder().id(1L).code("TEST01").name("Test").build();

        for (int i = 1; i <= count; i++) {
            Transaction tx = new Transaction();
            tx.setCompany(mockCompany);
            tx.setBranch(mockBranch);
            tx.setWorker(mockWorker);
            tx.setTransactionDate(month.atDay(i));
            tx.setTransactionType(TransactionType.BUY);
            tx.setCurrencyAmount(new BigDecimal("100"));
            tx.setHufAmount(new BigDecimal("40000"));
            tx.setExchangeRate(new BigDecimal("400.00"));
            tx.setHandlingFee(BigDecimal.ZERO);
            tx.setStatus(TransactionStatus.COMPLETED);
            tx.setCreatedAt(LocalDateTime.of(month.atDay(i), LocalTime.of(10, 0)));
            transactions.add(tx);
        }
        return transactions;
    }
}
