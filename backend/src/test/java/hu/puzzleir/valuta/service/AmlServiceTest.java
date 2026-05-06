package hu.puzzleir.valuta.service;

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
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * AmlService UNIT tesztek — Mockito.
 *
 * checkTransaction + isStructuring tesztelése.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class AmlServiceTest {

    @InjectMocks
    private AmlService amlService;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private AmlReportRepository amlReportRepository;

    @Mock
    private AmlThresholdRepository amlThresholdRepository;

    @Mock
    private SanctionScreeningService sanctionScreeningService;

    @Mock
    private BlacklistService blacklistService;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        // SecurityContext beállítása a multi-tenant metódusokhoz
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // SanctionScreeningService mock: alapértelmezett "nincs találat" válasz
        when(sanctionScreeningService.screenCustomer(any(), any(), any(), any(), any(), any()))
            .thenReturn(hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult.builder()
                .matched(false)
                .riskLevel("CLEAR")
                .build());
        when(blacklistService.findActivePersonMatch(any(), any())).thenReturn(Optional.empty());
    }

    // ============ checkTransaction tesztek ============

    @Test
    @DisplayName("checkTransaction: küszöb alatti összeg → NO_REPORT (approved, no identification)")
    void testCheckTransaction_underThreshold() {
        BigDecimal amount = new BigDecimal("50000"); // 50K < 100K limit

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            amount, "C001", "Teszt Ügyfél", "AB123456");

        assertThat(result.isApproved()).isTrue();
        assertThat(result.isRequiresIdentification()).isFalse();
        assertThat(result.isRequiresDetailedId()).isFalse();
        assertThat(result.getRejectionReason()).isNull();
    }

    @Test
    @DisplayName("checkTransaction: 100K+ → IDENTIFICATION szükséges (de approved ha van adat)")
    void testCheckTransaction_identification() {
        BigDecimal amount = new BigDecimal("500000"); // 500K > 100K limit, > 300K → detailed

        // Mock: éves és napi összegek
        when(transactionRepository.sumCustomerAnnualTotal(any(), eq("C001"), any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumCustomerDailyTotal(any(), eq("C001"), any()))
            .thenReturn(BigDecimal.ZERO);

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            amount, "C001", "Teszt Ügyfél", "AB123456");

        assertThat(result.isApproved()).isTrue();
        assertThat(result.isRequiresIdentification()).isTrue();
        assertThat(result.isRequiresDetailedId()).isTrue(); // 500K > 300K → teljes azonosítás
    }

    @Test
    @DisplayName("checkTransaction: 1.5M+ → ENHANCED (részletes azonosítás + bejelentési kötelezettség)")
    void testCheckTransaction_enhanced() {
        BigDecimal amount = new BigDecimal("2000000"); // 2M > 1.5M limit

        when(transactionRepository.sumCustomerAnnualTotal(any(), eq("C001"), any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumCustomerDailyTotal(any(), eq("C001"), any()))
            .thenReturn(BigDecimal.ZERO);

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            amount, "C001", "Teszt Ügyfél", "AB123456");

        assertThat(result.isApproved()).isTrue();
        assertThat(result.isRequiresIdentification()).isTrue();
        assertThat(result.isRequiresDetailedId()).isTrue();
    }

    @Test
    @DisplayName("checkTransaction: 300K+ azonosítás nélkül → REPORTING (rejected)")
    void testCheckTransaction_reporting() {
        BigDecimal amount = new BigDecimal("500000"); // 500K > 300K limit

        // Ügyfél név + okmányszám nélkül → rejected
        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            amount, "C001", null, null);

        assertThat(result.isApproved()).isFalse();
        assertThat(result.isRequiresIdentification()).isTrue();
        assertThat(result.getRejectionReason()).isNotNull();
        assertThat(result.getRejectionReason()).contains("KOTELEZO");
    }

    // ============ isStructuring tesztek ============

    @Test
    @DisplayName("isStructuring: 3+ tranzakció a limit közelében → gyanús (detected)")
    void testIsStructuring_detected() {
        // 3 tranzakció, mind 240K-290K között (IDENTIFICATION_LIMIT = 300K, 80% = 240K)
        List<Transaction> dailyTxs = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            Transaction tx = Transaction.builder()
                .id((long) i)
                .hufAmount(new BigDecimal("280000")) // 93% of 300K limit
                .build();
            dailyTxs.add(tx);
        }

        when(transactionRepository.findCustomerDailyTransactions(any(), eq("C001"), any()))
            .thenReturn(dailyTxs);

        boolean result = amlService.isStructuring("C001");

        assertThat(result).isTrue();
    }

    @Test
    @DisplayName("isStructuring: normál tranzakciók → nem gyanús (false)")
    void testIsStructuring_normal() {
        // 2 tranzakció — a minimum 3 alatt
        List<Transaction> dailyTxs = new ArrayList<>();
        dailyTxs.add(Transaction.builder().id(1L).hufAmount(new BigDecimal("50000")).build());
        dailyTxs.add(Transaction.builder().id(2L).hufAmount(new BigDecimal("100000")).build());

        when(transactionRepository.findCustomerDailyTransactions(any(), eq("C001"), any()))
            .thenReturn(dailyTxs);

        boolean result = amlService.isStructuring("C001");

        assertThat(result).isFalse();
    }
}
