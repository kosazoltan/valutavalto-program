package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.aml.AmlReportDto;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * AML completion tesztek:
 * - submitToAuthority DRAFT→SUBMITTED
 * - submitToAuthority rejects non-DRAFT
 * - acknowledgeReport SUBMITTED→ACKNOWLEDGED
 * - szankciós lista találat blokkolja a tranzakciót
 * - reverseAccumulation törli a highRiskFlag-et
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AmlServiceCompletionTest {

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
    private AuditLogService auditLogService;

    @Mock
    private SanctionScreeningService sanctionScreeningService;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
            1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ============ submitToAuthority tesztek ============

    @Test
    @DisplayName("submitToAuthority: DRAFT → SUBMITTED státuszváltás")
    void testSubmitToAuthority_draftToSubmitted() {
        UUID reportId = UUID.randomUUID();
        Company company = new Company();
        company.setId(TEST_COMPANY_ID);

        AmlReport report = AmlReport.builder()
            .id(reportId)
            .company(company)
            .status(AmlReportStatus.DRAFT)
            .reportType(AmlReportType.STANDARD)
            .riskLevel(AmlRiskLevel.LOW)
            .amountHuf(BigDecimal.valueOf(500000))
            .currencyCode("EUR")
            .build();

        when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(report));
        when(amlReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        AmlReportDto result = amlService.submitToAuthority(reportId, "EXT-REF-001");

        assertThat(result.getStatus()).isEqualTo("SUBMITTED");
        assertThat(result.getExternalReference()).isEqualTo("EXT-REF-001");
        assertThat(result.getSubmittedAt()).isNotNull();

        verify(auditLogService).log(eq("AML_REPORT_SUBMITTED"), anyString(), eq(reportId.toString()));
    }

    @Test
    @DisplayName("submitToAuthority: nem DRAFT státusz → ValidationException")
    void testSubmitToAuthority_rejectsNonDraft() {
        UUID reportId = UUID.randomUUID();
        Company company = new Company();
        company.setId(TEST_COMPANY_ID);

        AmlReport report = AmlReport.builder()
            .id(reportId)
            .company(company)
            .status(AmlReportStatus.SUBMITTED)  // már SUBMITTED
            .reportType(AmlReportType.STANDARD)
            .riskLevel(AmlRiskLevel.LOW)
            .amountHuf(BigDecimal.valueOf(500000))
            .currencyCode("EUR")
            .build();

        when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> amlService.submitToAuthority(reportId, "EXT-REF-002"))
            .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
            .hasMessageContaining("DRAFT");
    }

    // ============ acknowledgeReport tesztek ============

    @Test
    @DisplayName("acknowledgeReport: SUBMITTED → ACKNOWLEDGED státuszváltás")
    void testAcknowledgeReport_submittedToAcknowledged() {
        UUID reportId = UUID.randomUUID();
        Company company = new Company();
        company.setId(TEST_COMPANY_ID);

        AmlReport report = AmlReport.builder()
            .id(reportId)
            .company(company)
            .status(AmlReportStatus.SUBMITTED)
            .reportType(AmlReportType.STANDARD)
            .riskLevel(AmlRiskLevel.LOW)
            .amountHuf(BigDecimal.valueOf(700000))
            .currencyCode("USD")
            .submittedAt(LocalDateTime.now().minusHours(2))
            .build();

        when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(report));
        when(amlReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        AmlReportDto result = amlService.acknowledgeReport(reportId, "ACK-2026-0316");

        assertThat(result.getStatus()).isEqualTo("ACKNOWLEDGED");
        assertThat(result.getAcknowledgedAt()).isNotNull();
        assertThat(result.getExternalReference()).isEqualTo("ACK-2026-0316");

        verify(auditLogService).log(eq("AML_REPORT_ACKNOWLEDGED"), anyString(), eq(reportId.toString()));
    }

    // ============ Szankciós lista szűrés ============

    @Test
    @DisplayName("checkTransaction: szankciós lista találat → blokkolva (approved=false)")
    void testCheckTransaction_sanctionMatchBlocks() {
        SanctionScreeningResult sanctionResult = SanctionScreeningResult.builder()
            .matched(true)
            .riskLevel("CONFIRMED")
            .matches(Collections.emptyList())
            .build();

        when(sanctionScreeningService.screenCustomer(
            eq("Terror Ügyfél"), any(), any(), any(), any(), any()))
            .thenReturn(sanctionResult);

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            new BigDecimal("100000"), "C999", "Terror Ügyfél", "TT999999");

        assertThat(result.isApproved()).isFalse();
        assertThat(result.getRejectionReason()).contains("Szankciós lista találat");
        assertThat(result.getRejectionReason()).contains("CONFIRMED");
    }

    @Test
    @DisplayName("checkTransaction: szankciós lista TISZTA → tranzakció folytatódhat")
    void testCheckTransaction_sanctionClearAllowsContinue() {
        SanctionScreeningResult clearResult = SanctionScreeningResult.builder()
            .matched(false)
            .riskLevel("CLEAR")
            .matches(Collections.emptyList())
            .build();

        when(sanctionScreeningService.screenCustomer(
            eq("Normál Ügyfél"), any(), any(), any(), any(), any()))
            .thenReturn(clearResult);

        when(transactionRepository.sumCustomerAnnualTotal(any(), any(), any(), any()))
            .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.sumCustomerDailyTotal(any(), any(), any()))
            .thenReturn(BigDecimal.ZERO);

        AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
            new BigDecimal("100000"), "C001", "Normál Ügyfél", "NM123456");

        assertThat(result.isApproved()).isTrue();
    }

    // ============ reverseAccumulation — highRiskFlag törlése ============

    @Test
    @DisplayName("reverseAccumulation: ha limit alá csökken → highRiskFlag törölve")
    void testReverseAccumulation_clearsHighRiskFlag() {
        String customerId = "C_HIGH";
        // Aktuális éves összeg: 4M (limit felett)
        BigDecimal currentAnnual = new BigDecimal("4000000");
        // Sztornózott összeg: 1M → új összeg 3M (limit=3.6M alá csökken)
        BigDecimal stornoAmount = new BigDecimal("1000000");

        Company company = new Company();
        company.setId(TEST_COMPANY_ID);

        Customer customer = Customer.builder()
            .id(1L)
            .customerCode(customerId)
            .name("High Risk Ügyfél")
            .company(company)
            .highRiskFlag(true)
            .highRiskReason("Éves limit elérve")
            .highRiskSetAt(LocalDateTime.now().minusDays(5))
            .build();

        when(transactionRepository.sumCustomerAnnualTotal(eq(TEST_COMPANY_ID), eq(customerId), any(), any()))
            .thenReturn(currentAnnual);
        when(customerRepository.findByCustomerCodeAndCompanyId(customerId, TEST_COMPANY_ID))
            .thenReturn(Optional.of(customer));
        when(customerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        amlService.reverseAccumulation(customerId, stornoAmount, LocalDateTime.now());

        // highRiskFlag-nek törölve kell lennie
        ArgumentCaptor<Customer> captor = ArgumentCaptor.forClass(Customer.class);
        verify(customerRepository).save(captor.capture());
        Customer saved = captor.getValue();

        assertThat(saved.getHighRiskFlag()).isFalse();
        assertThat(saved.getHighRiskReason()).isNull();
        assertThat(saved.getHighRiskSetAt()).isNull();
    }

    @Test
    @DisplayName("reverseAccumulation: ha limit felett marad → highRiskFlag nem változik")
    void testReverseAccumulation_staysAboveLimit_noChange() {
        String customerId = "C_STILL_HIGH";
        // Aktuális éves összeg: 8M, sztornó 1M → 7M (még mindig limit felett)
        BigDecimal currentAnnual = new BigDecimal("8000000");
        BigDecimal stornoAmount = new BigDecimal("1000000");

        when(transactionRepository.sumCustomerAnnualTotal(eq(TEST_COMPANY_ID), eq(customerId), any(), any()))
            .thenReturn(currentAnnual);

        amlService.reverseAccumulation(customerId, stornoAmount, LocalDateTime.now());

        // customerRepository.save() NEM hívódhat (nem kell flag módosítás)
        verify(customerRepository, never()).save(any());
    }
}
