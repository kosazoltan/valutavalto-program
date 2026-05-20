package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.repository.AmlReportRepository;
import hu.puzzleir.valuta.repository.AmlThresholdRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
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

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * SAR auto-flag invariáns-teszt (Pmt. — gyanús tranzakció bejelentés, VV-ELVI 9.1).
 *
 * <p>Az {@code AmlService} a napi göngyölt ügyfél-összeget figyeli: ha
 * {@code dailyTotal + összeg >= DAILY_SUSPICIOUS_LIMIT (900 000 Ft)}, a tranzakció
 * automatikusan gyanús-flag-et kap ({@code suspiciousFlag=true}). Ez a strukturálás
 * (több, azonosítási limit alatti tranzakció ugyanattól az ügyféltől) elleni védelem.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SarAutoFlagTest {

    @InjectMocks
    private AmlService amlService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private AmlReportRepository amlReportRepository;
    @Mock private AmlThresholdRepository amlThresholdRepository;
    @Mock private hu.puzzleir.valuta.service.SanctionScreeningService sanctionScreeningService;
    @Mock private hu.puzzleir.valuta.service.BlacklistService blacklistService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final String CUSTOMER = "C100";

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(1L, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Alapértelmezett "tiszta" szankció + tiltólista válasz.
        when(sanctionScreeningService.screenCustomer(any(), any(), any(), any(), any(), any()))
                .thenReturn(SanctionScreeningResult.builder().matched(false).riskLevel("CLEAR").build());
        when(blacklistService.findActivePersonMatch(any(), any())).thenReturn(Optional.empty());
        // Éves göngyölés alacsony — ne triggereljen éves limitet.
        when(transactionRepository.sumCustomerAnnualTotal(any(), eq(CUSTOMER), any(), any()))
                .thenReturn(new BigDecimal("100000"));
        // BIGCTRL (5. szekció) classifyTransaction → customerRepository: explicit "nincs ügyfél"
        // válasz, hogy a teszt ne unmocked-null viselkedésre támaszkodjon (Copilot #720).
        when(customerRepository.findByCustomerCodeAndCompanyId(any(), any()))
                .thenReturn(Optional.empty());
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("napi göngyölt összeg 900 000 Ft alatt → NINCS gyanús-flag")
    void belowDailyLimit_noFlag() {
        when(transactionRepository.sumCustomerDailyTotal(any(), eq(CUSTOMER), any()))
                .thenReturn(new BigDecimal("800000"));
        // 800 000 + 50 000 = 850 000 < 900 000
        AmlService.AmlBasicCheckResult result =
                amlService.checkTransaction(new BigDecimal("50000"), CUSTOMER, null, null);
        assertThat(result.isSuspiciousFlag()).isFalse();
    }

    @Test
    @DisplayName("napi göngyölt összeg pontosan eléri a 900 000 Ft-ot → gyanús-flag (>= határ)")
    void atDailyLimit_flagged() {
        when(transactionRepository.sumCustomerDailyTotal(any(), eq(CUSTOMER), any()))
                .thenReturn(new BigDecimal("850000"));
        // 850 000 + 50 000 = 900 000 >= 900 000
        AmlService.AmlBasicCheckResult result =
                amlService.checkTransaction(new BigDecimal("50000"), CUSTOMER, null, null);
        assertThat(result.isSuspiciousFlag()).isTrue();
    }

    @Test
    @DisplayName("strukturálás: több azonosítási-limit alatti tétel átlépi a napi gyanús küszöböt → flag")
    void structuringBelowIdLimit_flagged() {
        // Korábbi napi göngyölés 850 000 (sok kis tétel), most +99 000 (< 100 000 ID-limit, így
        // azonosítás sem kötelező) → 949 000 >= 900 000 → gyanús.
        when(transactionRepository.sumCustomerDailyTotal(any(), eq(CUSTOMER), any()))
                .thenReturn(new BigDecimal("850000"));
        AmlService.AmlBasicCheckResult result =
                amlService.checkTransaction(new BigDecimal("99000"), CUSTOMER, null, null);
        assertThat(result.isSuspiciousFlag()).isTrue();
        assertThat(result.isRequiresIdentification()).isFalse();
    }

    @Test
    @DisplayName("üres customerId → napi göngyölés kihagyva (hardening), nincs flag")
    void blankCustomerId_noFlag() {
        AmlService.AmlBasicCheckResult result =
                amlService.checkTransaction(new BigDecimal("50000"), "   ", null, null);
        assertThat(result.isSuspiciousFlag()).isFalse();
        // Bizonyítja a hardeninget: üres customerId-nél a napi göngyölés NEM fut le.
        verify(transactionRepository, never()).sumCustomerDailyTotal(any(), any(), any());
    }

    @Test
    @DisplayName("null customerId → napi göngyölés kihagyva, nincs flag")
    void nullCustomerId_noFlag() {
        AmlService.AmlBasicCheckResult result =
                amlService.checkTransaction(new BigDecimal("50000"), null, null, null);
        assertThat(result.isSuspiciousFlag()).isFalse();
        // Bizonyítja a guardot: null customerId-nél a napi göngyölés NEM fut le.
        verify(transactionRepository, never()).sumCustomerDailyTotal(any(), any(), any());
    }
}
