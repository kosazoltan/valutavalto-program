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

    @Mock
    private ShiftedCalendarDayRepository shiftedCalendarDayRepository;

    @Mock
    private FatfCountryRiskService fatfCountryRiskService;

    @Mock
    private SystemParameterService systemParameterService;

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
        when(blacklistService.findActiveCompanyMatch(any(), any())).thenReturn(Optional.empty());
    }

    // ============ checkTransaction tesztek ============

    @Test
    @DisplayName("checkTransaction: tiltott CÉG találat → elutasítva (N6, legacy JOGI TILTVA)")
    void testCheckTransaction_prohibitedCompany() {
        when(blacklistService.findActiveCompanyMatch(any(), any())).thenReturn(
            Optional.of(hu.puzzleir.valuta.entity.ProhibitedCompany.builder()
                .companyName("Tiltott Kft.").build()));

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            new BigDecimal("250000"), "C900", "Tiltott Kft.", "12345678-2-42");

        assertThat(result.isApproved()).isFalse();
        assertThat(result.getRejectionReason()).contains("cég").contains("Tiltott Kft.");
    }

    // ============ FATF tier-bekötés tesztek (Pmt./MNB 14/2025 V.2.6) ============

    @Test
    @DisplayName("FATF 1/a (ellenintézkedés) + enforce → vezetői jóváhagyás kötelező")
    void testCheckTransaction_fatf1a_enforce_requiresApproval() {
        when(fatfCountryRiskService.classify("iran"))
            .thenReturn(FatfCountryRiskService.FatfTier.TIER_1A_COUNTERMEASURE);
        when(systemParameterService.getValue(eq("AML_FATF_TIER_ENFORCEMENT"), any())).thenReturn("true");

        // customerId=null → izolálva az éves/napi göngyölés úttól; csak a FATF dönt.
        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            new BigDecimal("250000"), null, "Teszt Ügyfél", "DOC1", "EUR", "iran");

        assertThat(result.getFatfTier()).isEqualTo("TIER_1A_COUNTERMEASURE");
        assertThat(result.isRequiresApproval()).isTrue();
        assertThat(result.getApprovalReason()).contains("1/a");
    }

    @Test
    @DisplayName("FATF 1/a + flag KIKAPCSOLVA → besorolás megvan, de NEM kér jóváhagyást")
    void testCheckTransaction_fatf1a_flagOff_noEnforcement() {
        when(fatfCountryRiskService.classify("iran"))
            .thenReturn(FatfCountryRiskService.FatfTier.TIER_1A_COUNTERMEASURE);
        when(systemParameterService.getValue(eq("AML_FATF_TIER_ENFORCEMENT"), any())).thenReturn("false");

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            new BigDecimal("250000"), null, "Teszt Ügyfél", "DOC1", "EUR", "iran");

        assertThat(result.getFatfTier()).isEqualTo("TIER_1A_COUNTERMEASURE");
        assertThat(result.isRequiresApproval()).isFalse();
    }

    @Test
    @DisplayName("FATF NONE (alacsony-kockázatú ország) → fatfTier=NONE, nincs hatás")
    void testCheckTransaction_fatfNone() {
        when(fatfCountryRiskService.classify("magyar"))
            .thenReturn(FatfCountryRiskService.FatfTier.NONE);

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            new BigDecimal("250000"), null, "Teszt Ügyfél", "DOC1", "EUR", "magyar");

        assertThat(result.getFatfTier()).isEqualTo("NONE");
        assertThat(result.isRequiresApproval()).isFalse();
    }

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

    @Test
    @DisplayName("FS-4: lejárt okmány 300000 Ft-nál fail-closed BLOKK")
    void testCheckTransaction_expiredDocumentAtIdentificationLimit_rejected() {
        Customer master = Customer.builder().customerCode("C123").build();
        master.setDocumentExpiry(LocalDate.now().minusDays(1));
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.of(master));

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("300000"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(result.isApproved()).isFalse();
        assertThat(result.getRejectionReason()).contains("lejárt");
    }

    @Test
    @DisplayName("FS-4: lejárt okmány 300000 Ft alatt WARN-only, approved marad")
    void testCheckTransaction_expiredDocumentBelowIdentificationLimit_warnOnly() {
        Customer master = Customer.builder().customerCode("C123").build();
        master.setDocumentExpiry(LocalDate.now().minusDays(1));
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.of(master));

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("299999"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(result.isApproved()).isTrue();
    }

    @Test
    @DisplayName("FS-4: érvényes okmány 300000 Ft felett átmegy")
    void testCheckTransaction_validDocumentAboveIdentificationLimit_approved() {
        Customer master = Customer.builder().customerCode("C123").build();
        master.setDocumentExpiry(LocalDate.now().plusDays(1));
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.of(master));

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("500000"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(result.isApproved()).isTrue();
    }

    @Test
    @DisplayName("FS-4: null documentExpiry backward-compatible, átmegy")
    void testCheckTransaction_nullDocumentExpiryBackwardCompatible_approved() {
        Customer master = Customer.builder().customerCode("C123").build();
        master.setDocumentExpiry(null);
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.of(master));

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("500000"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(result.isApproved()).isTrue();
    }

    @Test
    @DisplayName("FS-4/FS-2: ismeretlen customerCode backward-compatible, átmegy")
    void testCheckTransaction_unknownCustomerBackwardCompatible_approved() {
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.empty());

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("500000"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(result.isApproved()).isTrue();
    }

    @Test
    @DisplayName("FS-2: HIGH kockázati besorolású ügyfél cashiernél felsővezetői jóváhagyást kér")
    void testCheckTransaction_highRiskCashier_requiresApproval() {
        Customer master = Customer.builder().customerCode("C123").build();
        master.setRiskRating(CustomerRiskRating.HIGH);
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.of(master));

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("500000"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(result.isRequiresApproval()).isTrue();
        assertThat(result.getApprovalReason()).contains("Magas kockázati");
    }

    @Test
    @DisplayName("FS-2: HIGH kockázati besorolás supervisor kontextusban nem kér külön jóváhagyást")
    void testCheckTransaction_highRiskSupervisor_noApproval() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails supDetails =
                new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(2L, TEST_COMPANY_ID, TEST_BRANCH_ID, "SUPERVISOR");
        TestingAuthenticationToken supAuth = new TestingAuthenticationToken("sup", "pass", "ROLE_SUPERVISOR");
        supAuth.setDetails(supDetails);
        SecurityContextHolder.getContext().setAuthentication(supAuth);
        Customer master = Customer.builder().customerCode("C123").build();
        master.setRiskRating(CustomerRiskRating.HIGH);
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.of(master));

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("500000"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(result.isRequiresApproval()).isFalse();
    }

    @Test
    @DisplayName("FS-2: LOW és null riskRating nem kér felsővezetői jóváhagyást")
    void testCheckTransaction_lowAndNullRiskRating_noApproval() {
        Customer lowMaster = Customer.builder().customerCode("C123").build();
        lowMaster.setRiskRating(CustomerRiskRating.LOW);
        Customer nullMaster = Customer.builder().customerCode("C124").build();
        nullMaster.setRiskRating(null);
        when(customerRepository.findByCustomerCodeAndCompanyId("C123", TEST_COMPANY_ID))
                .thenReturn(Optional.of(lowMaster));
        when(customerRepository.findByCustomerCodeAndCompanyId("C124", TEST_COMPANY_ID))
                .thenReturn(Optional.of(nullMaster));

        AmlService.AmlBasicCheckResult lowResult = amlService.checkTransaction(
                new BigDecimal("500000"), "C123", "Teszt Ügyfél", "AB123456", "EUR", null);
        AmlService.AmlBasicCheckResult nullResult = amlService.checkTransaction(
                new BigDecimal("500000"), "C124", "Teszt Ügyfél", "AB123456", "EUR", null);

        assertThat(lowResult.isRequiresApproval()).isFalse();
        assertThat(nullResult.isRequiresApproval()).isFalse();
    }

    // ============ PP-03 IDOR: AML tranzakció-csatolás teszt ============

    @Test
    @DisplayName("submitReport: más cég / nem létező tranzakció csatolása → ValidationException (PP-03, nincs oldalcsatorna)")
    void testSubmitReport_crossTenantOrMissingTransactionBlocked() {
        // findByIdAndCompanyId üres eredményt ad: más cég tranzakciója ÉS nem létező egyaránt
        when(transactionRepository.findByIdAndCompanyId(eq(999L), eq(TEST_COMPANY_ID)))
            .thenReturn(Optional.empty());

        hu.puzzleir.valuta.dto.aml.CreateAmlReportDto dto =
            hu.puzzleir.valuta.dto.aml.CreateAmlReportDto.builder()
                .transactionId(999L)
                .reportType("SUSPICIOUS")
                .amountHuf(new BigDecimal("2000000"))
                .build();

        assertThatThrownBy(() -> amlService.submitReport(dto))
            .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
            .hasMessageContaining("nem kapcsolható össze");
        // A bejelentés NEM mentődik el, ha a tranzakció-csatolás elutasításra kerül
        verify(amlReportRepository, never()).save(any());
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
