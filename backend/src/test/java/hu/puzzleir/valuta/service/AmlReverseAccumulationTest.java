package hu.puzzleir.valuta.service;

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
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * AmlService.reverseAccumulation() UNIT tesztek.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class AmlReverseAccumulationTest {

    @InjectMocks
    private AmlService amlService;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private AuditLogService auditLogService;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("reverseAccumulation: sztornó → éves göngyölt csökken")
    void testReverseAccumulation_basicDeduction() {
        String customerId = "C12345";
        BigDecimal reversedAmount = new BigDecimal("500000");
        LocalDateTime originalDate = LocalDateTime.of(2024, 12, 15, 10, 30);

        // Mock: current annual total = 4M
        when(transactionRepository.sumCustomerAnnualTotal(
            eq(TEST_COMPANY_ID), eq(customerId),
            eq(LocalDate.of(2024, 1, 1)), eq(LocalDate.of(2024, 12, 31))
        )).thenReturn(new BigDecimal("4000000"));

        // WHEN
        amlService.reverseAccumulation(customerId, reversedAmount, originalDate);

        // THEN — audit log written
        verify(auditLogService, atLeastOnce()).log(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("reverseAccumulation: null customerId → skip, no exception")
    void testReverseAccumulation_nullCustomerId() {
        assertThatNoException().isThrownBy(() ->
            amlService.reverseAccumulation(null, new BigDecimal("100000"), LocalDateTime.now())
        );

        verifyNoInteractions(transactionRepository);
    }

    @Test
    @DisplayName("reverseAccumulation: blank customerId → skip")
    void testReverseAccumulation_blankCustomerId() {
        assertThatNoException().isThrownBy(() ->
            amlService.reverseAccumulation("  ", new BigDecimal("100000"), LocalDateTime.now())
        );

        verifyNoInteractions(transactionRepository);
    }

    @Test
    @DisplayName("reverseAccumulation: zero amount → skip")
    void testReverseAccumulation_zeroAmount() {
        assertThatNoException().isThrownBy(() ->
            amlService.reverseAccumulation("C12345", BigDecimal.ZERO, LocalDateTime.now())
        );

        verifyNoInteractions(transactionRepository);
    }

    @Test
    @DisplayName("reverseAccumulation: negative amount → skip")
    void testReverseAccumulation_negativeAmount() {
        assertThatNoException().isThrownBy(() ->
            amlService.reverseAccumulation("C12345", new BigDecimal("-100"), LocalDateTime.now())
        );

        verifyNoInteractions(transactionRepository);
    }

    @Test
    @DisplayName("reverseAccumulation: null annual total → no NPE")
    void testReverseAccumulation_nullAnnualTotal() {
        String customerId = "C99999";
        LocalDateTime originalDate = LocalDateTime.of(2024, 6, 1, 9, 0);

        when(transactionRepository.sumCustomerAnnualTotal(
            eq(TEST_COMPANY_ID), eq(customerId),
            eq(LocalDate.of(2024, 1, 1)), eq(LocalDate.of(2024, 12, 31))
        )).thenReturn(null);

        assertThatNoException().isThrownBy(() ->
            amlService.reverseAccumulation(customerId, new BigDecimal("50000"), originalDate)
        );
    }
}
