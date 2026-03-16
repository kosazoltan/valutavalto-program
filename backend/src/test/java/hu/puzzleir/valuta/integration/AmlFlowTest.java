package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AmlService;
import org.mockito.MockedStatic;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * AML Flow integrációs tesztek — pénzmosás elleni kontrollok.
 */
@ExtendWith(MockitoExtension.class)
class AmlFlowTest {

    @InjectMocks
    private AmlService amlService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private hu.puzzleir.valuta.repository.AmlReportRepository amlReportRepository;
    @Mock private hu.puzzleir.valuta.repository.AmlThresholdRepository amlThresholdRepository;
    @Mock private hu.puzzleir.valuta.service.SanctionScreeningService sanctionScreeningService;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        // SanctionScreeningService mock: alapértelmezett "nincs találat" válasz
        lenient().when(sanctionScreeningService.screenCustomer(any(), any(), any(), any(), any(), any()))
            .thenReturn(hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult.builder()
                .matched(false)
                .riskLevel("CLEAR")
                .build());
    }

    @Nested
    @DisplayName("AML Basic Check — azonosítási küszöbök")
    class BasicCheckTests {

        @Test
        @DisplayName("testAmlCheck_underThreshold — 300K alatt, azonosítás nem szükséges")
        void testAmlCheck_underThreshold() {
            AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    new BigDecimal("200000"), // 200K Ft < 300K
                    null,
                    null,
                    null
            );

            assertThat(result.isApproved()).isTrue();
            assertThat(result.isRequiresIdentification()).isFalse();
            assertThat(result.isRequiresDetailedId()).isFalse();
        }

        @Test
        @DisplayName("testAmlCheck_overThreshold — 300K felett, azonosítás kötelező, hiányzik → elutasítva")
        void testAmlCheck_overThreshold_noId() {
            AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    new BigDecimal("500000"), // 500K > 300K
                    null,
                    null,  // nincs név
                    null   // nincs okmányszám
            );

            assertThat(result.isApproved()).isFalse();
            assertThat(result.isRequiresIdentification()).isTrue();
            assertThat(result.getRejectionReason()).contains("KOTELEZO");
        }

        @Test
        @DisplayName("testAmlCheck_overThreshold — 300K felett, azonosítás megadva → engedélyezve")
        void testAmlCheck_overThreshold_withId() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(transactionRepository.sumCustomerAnnualTotal(eq(COMPANY_ID), eq("CUST-001"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerDailyTotal(eq(COMPANY_ID), eq("CUST-001"), any()))
                        .thenReturn(BigDecimal.ZERO);

                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                        new BigDecimal("500000"),
                        "CUST-001",
                        "Nagy Béla",
                        "AB123456"
                );

                assertThat(result.isApproved()).isTrue();
                assertThat(result.isRequiresIdentification()).isTrue();
            }
        }

        @Test
        @DisplayName("testAmlCheck_detailedIdThreshold — 1.5M felett részletes azonosítás")
        void testAmlCheck_detailedIdThreshold() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(transactionRepository.sumCustomerAnnualTotal(eq(COMPANY_ID), eq("CUST-001"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerDailyTotal(eq(COMPANY_ID), eq("CUST-001"), any()))
                        .thenReturn(BigDecimal.ZERO);

                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                        new BigDecimal("2000000"), // 2M > 1.5M
                        "CUST-001",
                        "Kiss Éva",
                        "CD987654"
                );

                assertThat(result.isApproved()).isTrue();
                assertThat(result.isRequiresDetailedId()).isTrue();
                assertThat(result.isRequiresIdentification()).isTrue();
            }
        }

        @Test
        @DisplayName("testAmlCheck_negativeAmount — negatív összeg → elutasítva")
        void testAmlCheck_negativeAmount() {
            AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    new BigDecimal("-1000"),
                    null, null, null
            );

            assertThat(result.isApproved()).isFalse();
            assertThat(result.getRejectionReason()).contains("Ervenytelen");
        }

        @Test
        @DisplayName("testAmlCheck_nullAmount — null összeg → elutasítva")
        void testAmlCheck_nullAmount() {
            AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    null,
                    null, null, null
            );

            assertThat(result.isApproved()).isFalse();
        }
    }

    @Nested
    @DisplayName("AML Structuring Detection — gyanús tranzakciók")
    class StructuringTests {

        @Test
        @DisplayName("testStructuringDetection — napi gyanús összeg küszöb")
        void testStructuringDetection() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                // Ügyfél napi összege már 800K
                when(transactionRepository.sumCustomerDailyTotal(COMPANY_ID, "CUST-002", LocalDate.now()))
                        .thenReturn(new BigDecimal("800000"));

                // +200K → összesen 1M > 900K napi gyanúsági limit
                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                        new BigDecimal("200000"),
                        "CUST-002",
                        "Teszt Ügyfél",
                        "XY999888"
                );

                assertThat(result.isApproved()).isTrue();
                assertThat(result.isSuspiciousFlag()).isTrue();
            }
        }

        @Test
        @DisplayName("testStructuringDetection_belowLimit — limit alatt nem gyanús")
        void testStructuringDetection_belowLimit() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(transactionRepository.sumCustomerDailyTotal(COMPANY_ID, "CUST-003", LocalDate.now()))
                        .thenReturn(new BigDecimal("100000"));

                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                        new BigDecimal("50000"),
                        "CUST-003",
                        null,
                        null
                );

                assertThat(result.isApproved()).isTrue();
                assertThat(result.isSuspiciousFlag()).isFalse();
            }
        }
    }

    @Nested
    @DisplayName("AML Classification — TranzTipus")
    class ClassificationTests {

        @Test
        @DisplayName("testClassify_normal — normál tranzakció = 0")
        void testClassify_normal() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CUST-010"), any()))
                        .thenReturn(new BigDecimal("100000"));
                when(transactionRepository.findCustomerYearlyMax(eq(COMPANY_ID), eq("CUST-010"), any(), any()))
                        .thenReturn(new BigDecimal("200000"));
                when(transactionRepository.countCustomerQuarterlyTransactions(eq(COMPANY_ID), eq("CUST-010"), any(), any()))
                        .thenReturn(1L);
                when(transactionRepository.sumCustomerQuarterlyTotal(eq(COMPANY_ID), eq("CUST-010"), any(), any()))
                        .thenReturn(new BigDecimal("200000"));
                when(customerRepository.findByCustomerCodeAndCompanyId("CUST-010", COMPANY_ID))
                        .thenReturn(Optional.empty());

                int type = amlService.classifyTransaction("CUST-010", new BigDecimal("50000"), "EUR");
                assertThat(type).isEqualTo(0);
            }
        }

        @Test
        @DisplayName("testClassify_over50M — 50M+ = TranzTipus 6")
        void testClassify_over50M() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CUST-020"), any()))
                        .thenReturn(new BigDecimal("49000000"));

                int type = amlService.classifyTransaction("CUST-020", new BigDecimal("2000000"), "EUR");
                assertThat(type).isEqualTo(6);
            }
        }

        @Test
        @DisplayName("testClassify_over10M — 10M+ = TranzTipus 5")
        void testClassify_over10M() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CUST-030"), any()))
                        .thenReturn(new BigDecimal("9000000"));

                int type = amlService.classifyTransaction("CUST-030", new BigDecimal("2000000"), "EUR");
                assertThat(type).isEqualTo(5);
            }
        }

        @Test
        @DisplayName("testClassify_foreignUsd — külföldi + USD = -1 BLOKKOLVA")
        void testClassify_foreignUsd() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CUST-040"), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(eq(COMPANY_ID), eq("CUST-040"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(eq(COMPANY_ID), eq("CUST-040"), any(), any()))
                        .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(eq(COMPANY_ID), eq("CUST-040"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);

                Customer foreigner = new Customer();
                foreigner.setIsForeign(true);
                foreigner.setIsPep(false);
                when(customerRepository.findByCustomerCodeAndCompanyId("CUST-040", COMPANY_ID))
                        .thenReturn(Optional.of(foreigner));

                int type = amlService.classifyTransaction("CUST-040", new BigDecimal("50000"), "USD");
                assertThat(type).isEqualTo(-1);
            }
        }

        @Test
        @DisplayName("testClassify_pep — PEP ügyfél = TranzTipus 1")
        void testClassify_pep() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CUST-050"), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(eq(COMPANY_ID), eq("CUST-050"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(eq(COMPANY_ID), eq("CUST-050"), any(), any()))
                        .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(eq(COMPANY_ID), eq("CUST-050"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);

                Customer pep = new Customer();
                pep.setIsForeign(false);
                pep.setIsPep(true);
                when(customerRepository.findByCustomerCodeAndCompanyId("CUST-050", COMPANY_ID))
                        .thenReturn(Optional.of(pep));

                int type = amlService.classifyTransaction("CUST-050", new BigDecimal("50000"), "EUR");
                assertThat(type).isEqualTo(1);
            }
        }

        @Test
        @DisplayName("testClassify_anonymous — névtelen ügyfél összeg alapú")
        void testClassify_anonymous() {
            int type = amlService.classifyTransaction(null, new BigDecimal("100000"), "EUR");
            assertThat(type).isEqualTo(0);
        }

        @Test
        @DisplayName("testClassify_anonymous_over50M — névtelen 50M+ = 6")
        void testClassify_anonymous_over50M() {
            int type = amlService.classifyTransaction(null, new BigDecimal("55000000"), "EUR");
            assertThat(type).isEqualTo(6);
        }
    }

    @Nested
    @DisplayName("AML Full Check — checkAllThresholds")
    class FullCheckTests {

        @Test
        @DisplayName("testCheckAllThresholds_normal — normál tranzakció")
        void testCheckAllThresholds_normal() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CUST-060"), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(eq(COMPANY_ID), eq("CUST-060"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(eq(COMPANY_ID), eq("CUST-060"), any(), any()))
                        .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(eq(COMPANY_ID), eq("CUST-060"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(customerRepository.findByCustomerCodeAndCompanyId("CUST-060", COMPANY_ID))
                        .thenReturn(Optional.empty());

                hu.puzzleir.valuta.dto.aml.AmlCheckResult result =
                        amlService.checkAllThresholds("CUST-060", new BigDecimal("50000"), "EUR");

                assertThat(result.getTransactionType()).isEqualTo(0);
                assertThat(result.isBlocked()).isFalse();
                assertThat(result.isRequiresId()).isFalse();
            }
        }

        @Test
        @DisplayName("testCheckAllThresholds_blocked — külföldi USD blokkolva")
        void testCheckAllThresholds_blocked() {
            try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
                secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CUST-070"), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(eq(COMPANY_ID), eq("CUST-070"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(eq(COMPANY_ID), eq("CUST-070"), any(), any()))
                        .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(eq(COMPANY_ID), eq("CUST-070"), any(), any()))
                        .thenReturn(BigDecimal.ZERO);

                Customer foreigner = new Customer();
                foreigner.setIsForeign(true);
                foreigner.setIsPep(false);
                when(customerRepository.findByCustomerCodeAndCompanyId("CUST-070", COMPANY_ID))
                        .thenReturn(Optional.of(foreigner));

                hu.puzzleir.valuta.dto.aml.AmlCheckResult result =
                        amlService.checkAllThresholds("CUST-070", new BigDecimal("50000"), "USD");

                assertThat(result.getTransactionType()).isEqualTo(-1);
                assertThat(result.isBlocked()).isTrue();
                assertThat(result.getWarnings()).anyMatch(w -> w.contains("BLOKKOLVA"));
            }
        }
    }
}
