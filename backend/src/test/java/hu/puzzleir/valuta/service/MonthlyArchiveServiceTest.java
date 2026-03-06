package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
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
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MonthlyArchiveService UNIT tesztek — Mockito.
 *
 * archiveMonth() metódus tesztelése:
 * - Sikeres archiválás
 * - Dupla archiválás védelem
 * - Üres hónap kezelés
 * - Státusz frissítés ellenőrzés
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

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();
    private static final UUID TEST_USER_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        // SecurityContext beállítása a multi-tenant metódusokhoz
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ============ SIKERES ARCHIVÁLÁS ============

    @Test
    @DisplayName("archiveMonth: sikeres archiválás — tranzakciók ARCHIVED státuszba kerülnek")
    void testArchiveMonth_success() {
        // GIVEN
        YearMonth targetMonth = YearMonth.of(2024, 12);
        
        // Mock: NEM archivált még ez a hónap
        when(archivedTransactionRepository.existsByArchiveMonthAndCompanyId(
            eq("2024-12"), eq(TEST_COMPANY_ID)
        )).thenReturn(false);
        
        // Mock: 3 tranzakció a hónapban
        List<Transaction> transactions = createMockTransactions(targetMonth, 3);
        when(transactionRepository.findByTransactionDateBetweenAndStatusAndCompanyId(
            any(LocalDate.class), any(LocalDate.class), eq(TransactionStatus.COMPLETED), eq(TEST_COMPANY_ID)
        )).thenReturn(transactions);
        
        // WHEN
        monthlyArchiveService.archiveMonth(targetMonth);
        
        // THEN
        // 1. ArchivedTransaction mentés történt (3x)
        verify(archivedTransactionRepository, times(3)).save(any(ArchivedTransaction.class));
        
        // 2. Minden tranzakció státusza ARCHIVED-re változott
        for (Transaction tx : transactions) {
            assertThat(tx.getStatus()).isEqualTo(TransactionStatus.ARCHIVED);
        }
        verify(transactionRepository, times(3)).save(any(Transaction.class));
        
        // 3. Audit log írás történt
        verify(auditLogService, times(1)).log(
            eq("MONTHLY_ARCHIVE"),
            contains("2024-12"),
            anyString()
        );
    }

    // ============ DUPLA ARCHIVÁLÁS VÉDELEM ============

    @Test
    @DisplayName("archiveMonth: dupla archiválás ugyanarra a hónapra → ValidationException")
    void testArchiveMonth_duplicate() {
        // GIVEN
        YearMonth targetMonth = YearMonth.of(2024, 11);
        
        // Mock: MÁR archivált ez a hónap
        when(archivedTransactionRepository.existsByArchiveMonthAndCompanyId(
            eq("2024-11"), eq(TEST_COMPANY_ID)
        )).thenReturn(true);
        
        // WHEN + THEN
        assertThatThrownBy(() -> monthlyArchiveService.archiveMonth(targetMonth))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("már archivált")
            .hasMessageContaining("2024-11");
        
        // NEM szabad mentés történjen
        verify(archivedTransactionRepository, never()).save(any());
        verify(transactionRepository, never()).save(any());
    }

    // ============ ÜRES HÓNAP KEZELÉS ============

    @Test
    @DisplayName("archiveMonth: üres hónap (0 tranzakció) → ne dobjon hibát, de audit log legyen")
    void testArchiveMonth_emptyMonth() {
        // GIVEN
        YearMonth targetMonth = YearMonth.of(2024, 10);
        
        // Mock: NEM archivált még
        when(archivedTransactionRepository.existsByArchiveMonthAndCompanyId(
            eq("2024-10"), eq(TEST_COMPANY_ID)
        )).thenReturn(false);
        
        // Mock: NINCS tranzakció a hónapban
        when(transactionRepository.findByTransactionDateBetweenAndStatusAndCompanyId(
            any(LocalDate.class), any(LocalDate.class), eq(TransactionStatus.COMPLETED), eq(TEST_COMPANY_ID)
        )).thenReturn(Collections.emptyList());
        
        // WHEN
        monthlyArchiveService.archiveMonth(targetMonth);
        
        // THEN
        // 1. NEM történt mentés (0 tranzakció)
        verify(archivedTransactionRepository, never()).save(any());
        verify(transactionRepository, never()).save(any());
        
        // 2. De audit log ÍRÓDOTT (0 tranzakció archiválva)
        verify(auditLogService, times(1)).log(
            eq("MONTHLY_ARCHIVE"),
            contains("2024-10"),
            contains("0 tranzakció")
        );
    }

    // ============ TÖBBVÁLLALATÚ KÖRNYEZET ============

    @Test
    @DisplayName("archiveMonth: multi-tenant — csak a saját cég tranzakciói archiválódnak")
    void testArchiveMonth_multiTenant() {
        // GIVEN
        YearMonth targetMonth = YearMonth.of(2024, 9);
        
        UUID otherCompanyId = UUID.randomUUID();
        
        // Mock: NEM archivált
        when(archivedTransactionRepository.existsByArchiveMonthAndCompanyId(
            eq("2024-09"), eq(TEST_COMPANY_ID)
        )).thenReturn(false);
        
        // Mock: 2 saját + 1 idegen cég tranzakció (de a mock csak a sajátot adja vissza)
        List<Transaction> ownTransactions = createMockTransactions(targetMonth, 2);
        when(transactionRepository.findByTransactionDateBetweenAndStatusAndCompanyId(
            any(LocalDate.class), any(LocalDate.class), eq(TransactionStatus.COMPLETED), eq(TEST_COMPANY_ID)
        )).thenReturn(ownTransactions);
        
        // WHEN
        monthlyArchiveService.archiveMonth(targetMonth);
        
        // THEN
        // Csak a saját cég 2 tranzakciója archiválódott
        verify(archivedTransactionRepository, times(2)).save(any(ArchivedTransaction.class));
        verify(transactionRepository, times(2)).save(argThat(tx -> 
            tx.getCompany() != null && tx.getCompany().getId().equals(TEST_COMPANY_ID)
        ));
    }

    // ============ STATI STÁTUSZ ELLENŐRZÉS ============

    @Test
    @DisplayName("archiveMonth: csak COMPLETED státuszú tranzakciók archiválódnak (REVERSED nem)")
    void testArchiveMonth_onlyCompleted() {
        // GIVEN
        YearMonth targetMonth = YearMonth.of(2024, 8);
        
        // Mock: NEM archivált
        when(archivedTransactionRepository.existsByArchiveMonthAndCompanyId(
            eq("2024-08"), eq(TEST_COMPANY_ID)
        )).thenReturn(false);
        
        // Mock: 2 COMPLETED, 1 REVERSED (de a mock csak a COMPLETED-et adja vissza)
        List<Transaction> completedOnly = createMockTransactions(targetMonth, 2);
        when(transactionRepository.findByTransactionDateBetweenAndStatusAndCompanyId(
            any(LocalDate.class), any(LocalDate.class), eq(TransactionStatus.COMPLETED), eq(TEST_COMPANY_ID)
        )).thenReturn(completedOnly);
        
        // WHEN
        monthlyArchiveService.archiveMonth(targetMonth);
        
        // THEN
        // Csak a COMPLETED tranzakciók archiválódtak
        verify(archivedTransactionRepository, times(2)).save(any(ArchivedTransaction.class));
        verify(transactionRepository, times(2)).save(argThat(tx -> 
            tx.getStatus() == TransactionStatus.ARCHIVED
        ));
    }

    // ============ HELPER METÓDUS ============

    private List<Transaction> createMockTransactions(YearMonth month, int count) {
        List<Transaction> transactions = new ArrayList<>();
        
        Company mockCompany = new Company();
        mockCompany.setId(TEST_COMPANY_ID);
        
        Branch mockBranch = new Branch();
        mockBranch.setId(TEST_BRANCH_ID);
        
        for (int i = 1; i <= count; i++) {
            Transaction tx = new Transaction();
            tx.setId(UUID.randomUUID());
            tx.setCompany(mockCompany);
            tx.setBranch(mockBranch);
            tx.setTransactionDate(month.atDay(i));
            tx.setTransactionTime(LocalTime.of(10, 0));
            tx.setTransactionType(TransactionType.BUY);
            tx.setCurrencyCode("EUR");
            tx.setForeignAmount(new BigDecimal("100"));
            tx.setHufAmount(new BigDecimal("40000"));
            tx.setRate(new BigDecimal("400.00"));
            tx.setStatus(TransactionStatus.COMPLETED);
            tx.setCustomerName("Test Customer " + i);
            
            transactions.add(tx);
        }
        
        return transactions;
    }
}
