package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
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
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Sprint 5 — C1 + C2 + C3 AML/BIGCTRL javítás tesztek
 *
 * C1: GET /api/v1/aml/check-all-thresholds endpoint (AmlControllerCheckAllThresholdsTest-ban)
 * C2: getWeeklyTotal() — 8 napos ablak (minusDays(8))
 * C3: classifyTransaction() beintegrálva checkTransaction()-ba, transactionType mező kitöltve
 *
 * TranzTipus szintek (legacy BIGCTRL.DLL):
 *  6 = hasforint >= 50M
 *  5 = hasforint >= 10M
 *  4 = negyedév 4+ tranzakció ÉS >= 25M
 *  3 = évi max >= 8M ÉS hasforint >= 8M
 *  2 = külföldi ügyfél (nem USD)
 *  1 = belföldi kiemelt közszereplő (PEP)
 * -1 = külföldi ügyfél, USD blokkolva
 *  0 = normál
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AmlBigctrlC1C2C3Test {

    @InjectMocks
    private AmlService amlService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private AmlReportRepository amlReportRepository;
    @Mock private AmlThresholdRepository amlThresholdRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private SanctionScreeningService sanctionScreeningService;
    @Mock private BlacklistService blacklistService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID  = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                1L, COMPANY_ID, BRANCH_ID, "MANAGER");
        TestingAuthenticationToken auth =
            new TestingAuthenticationToken("test", "pass", "ROLE_MANAGER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // SanctionScreeningService: alapértelmezett "nincs találat"
        when(sanctionScreeningService.screenCustomer(any(), any(), any(), any(), any(), any()))
            .thenReturn(hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult.builder()
                .matched(false)
                .riskLevel("CLEAR")
                .build());
        when(blacklistService.findActivePersonMatch(any(), any())).thenReturn(Optional.empty());
    }

    // =========================================================
    // C2 — getWeeklyTotal() 8 napos ablak
    // =========================================================

    @Nested
    @DisplayName("C2 — getWeeklyTotal: 8 napos ablak")
    class WeeklyTotalWindowTests {

        @Test
        @DisplayName("C2-1: sinceDate = now().minusDays(8) — nem minusDays(7)")
        void testGetWeeklyTotal_usesEightDayWindow() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C001"), any()))
                    .thenReturn(new BigDecimal("500000"));

                amlService.getWeeklyTotal("C001");

                ArgumentCaptor<LocalDate> dateCaptor = ArgumentCaptor.forClass(LocalDate.class);
                verify(transactionRepository).sumCustomerWeeklyTotal(
                    eq(COMPANY_ID), eq("C001"), dateCaptor.capture());

                LocalDate captured = dateCaptor.getValue();
                LocalDate expected8 = LocalDate.now().minusDays(8);
                LocalDate wrong7   = LocalDate.now().minusDays(7);

                assertThat(captured)
                    .as("A legacy ablak 8 napos (minusDays(8)), NEM 7 napos")
                    .isEqualTo(expected8)
                    .isNotEqualTo(wrong7);
            }
        }

        @Test
        @DisplayName("C2-2: 8. napon belüli tranzakció benne van (sinceDate <= 8 nap)")
        void testGetWeeklyTotal_eightDayBoundary_included() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                // Repository visszaad összeget → a 8. napi tranzakció BENNE van
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C002"), any()))
                    .thenReturn(new BigDecimal("1200000"));

                BigDecimal result = amlService.getWeeklyTotal("C002");

                assertThat(result).isEqualByComparingTo("1200000");

                // sinceDate ellenőrzés: a passed dátum 8 nappal korábbi
                ArgumentCaptor<LocalDate> dateCaptor = ArgumentCaptor.forClass(LocalDate.class);
                verify(transactionRepository).sumCustomerWeeklyTotal(
                    eq(COMPANY_ID), eq("C002"), dateCaptor.capture());

                assertThat(dateCaptor.getValue())
                    .isEqualTo(LocalDate.now().minusDays(8));
            }
        }

        @Test
        @DisplayName("C2-3: null repository eredmény → BigDecimal.ZERO (nincs NPE)")
        void testGetWeeklyTotal_nullResult_returnsZero() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(any(), eq("C003"), any()))
                    .thenReturn(null);

                BigDecimal result = amlService.getWeeklyTotal("C003");

                assertThat(result).isEqualByComparingTo(BigDecimal.ZERO);
            }
        }
    }

    // =========================================================
    // C3 — classifyTransaction() minden TranzTipus szint
    // =========================================================

    @Nested
    @DisplayName("C3 — classifyTransaction: minden TranzTipus (-1..6)")
    class ClassifyTransactionTests {

        /**
         * Alap mock beállítás ügyfélnél (hasforint közepes → nem trigg. 5/6).
         * Override-oljuk a konkrét tesztesetekben.
         */
        private void mockLowWeekly(String customerId) {
            when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq(customerId), any()))
                .thenReturn(BigDecimal.ZERO);
        }

        private void mockLowQuarterly(String customerId) {
            when(transactionRepository.countCustomerQuarterlyTransactions(
                    eq(COMPANY_ID), eq(customerId), any(), any()))
                .thenReturn(1L);
            when(transactionRepository.sumCustomerQuarterlyTotal(
                    eq(COMPANY_ID), eq(customerId), any(), any()))
                .thenReturn(new BigDecimal("200000"));
        }

        private void mockLowYearlyMax(String customerId) {
            when(transactionRepository.findCustomerYearlyMax(
                    eq(COMPANY_ID), eq(customerId), any(), any()))
                .thenReturn(new BigDecimal("100000"));
        }

        @Test
        @DisplayName("TranzTipus 6: hasforint >= 50.000.000")
        void testClassify_type6_over50M() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                // weekly = 49M, aktuális = 2M → hasforint = 51M >= 50M
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C6"), any()))
                    .thenReturn(new BigDecimal("49000000"));

                int type = amlService.classifyTransaction("C6", new BigDecimal("2000000"), "EUR");
                assertThat(type).isEqualTo(6);
            }
        }

        @Test
        @DisplayName("TranzTipus 5: hasforint >= 10.000.000 (< 50M)")
        void testClassify_type5_over10M() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                // weekly = 9M, aktuális = 2M → hasforint = 11M (10M <= 11M < 50M) → 5
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C5"), any()))
                    .thenReturn(new BigDecimal("9000000"));

                int type = amlService.classifyTransaction("C5", new BigDecimal("2000000"), "EUR");
                assertThat(type).isEqualTo(5);
            }
        }

        @Test
        @DisplayName("TranzTipus 4: negyedéves 4+ trx ÉS >= 25M (hasforint < 10M)")
        void testClassify_type4_quarterly() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                // weekly = 1M → hasforint = 2M (< 10M, < 50M) → nem 5/6
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C4"), any()))
                    .thenReturn(new BigDecimal("1000000"));
                // quarterly: 4 trx, 26M → teljesíti a feltételt
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("C4"), any(), any()))
                    .thenReturn(4L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("C4"), any(), any()))
                    .thenReturn(new BigDecimal("26000000"));

                int type = amlService.classifyTransaction("C4", new BigDecimal("1000000"), "EUR");
                assertThat(type).isEqualTo(4);
            }
        }

        @Test
        @DisplayName("TranzTipus 4 NEM teljesül: csak 3 trx (< 4) — nem 4")
        void testClassify_notType4_insufficientCount() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C4b"), any()))
                    .thenReturn(new BigDecimal("1000000"));
                // csak 3 trx → NEM teljesül a 4+ feltétel
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("C4b"), any(), any()))
                    .thenReturn(3L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("C4b"), any(), any()))
                    .thenReturn(new BigDecimal("26000000"));
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("C4b"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(customerRepository.findByCustomerCodeAndCompanyId("C4b", COMPANY_ID))
                    .thenReturn(Optional.empty());

                int type = amlService.classifyTransaction("C4b", new BigDecimal("1000000"), "EUR");
                assertThat(type).isNotEqualTo(4);
            }
        }

        @Test
        @DisplayName("TranzTipus 3: éves max >= 8M ÉS hasforint >= 8M (nem trigg. 4/5/6)")
        void testClassify_type3_yearlyMaxAndWeekly() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                // weekly = 7M → hasforint = 7M + 2M = 9M … de kelljen 8M+
                // weekly = 5M, aktuális = 4M → hasforint = 9M >= 8M → de < 10M → nem 5/6
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C3"), any()))
                    .thenReturn(new BigDecimal("5000000"));
                // quarterly: nem teljesül
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("C3"), any(), any()))
                    .thenReturn(1L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("C3"), any(), any()))
                    .thenReturn(new BigDecimal("1000000"));
                // yearlyMax >= 8M
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("C3"), any(), any()))
                    .thenReturn(new BigDecimal("9000000"));

                // hasforint = 5M + 4M = 9M >= 8M → TranzTipus 3
                int type = amlService.classifyTransaction("C3", new BigDecimal("4000000"), "EUR");
                assertThat(type).isEqualTo(3);
            }
        }

        @Test
        @DisplayName("TranzTipus 2: külföldi ügyfél, EUR (nem USD)")
        void testClassify_type2_foreignNonUsd() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C2"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("C2"), any(), any()))
                    .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("C2"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("C2"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);

                Customer foreign = new Customer();
                foreign.setIsForeign(true);
                foreign.setIsPep(false);
                when(customerRepository.findByCustomerCodeAndCompanyId("C2", COMPANY_ID))
                    .thenReturn(Optional.of(foreign));

                int type = amlService.classifyTransaction("C2", new BigDecimal("50000"), "EUR");
                assertThat(type).isEqualTo(2);
            }
        }

        @Test
        @DisplayName("TranzTipus 1: belföldi PEP ügyfél")
        void testClassify_type1_pep() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C1"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("C1"), any(), any()))
                    .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("C1"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("C1"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);

                Customer pep = new Customer();
                pep.setIsForeign(false);
                pep.setIsPep(true);
                when(customerRepository.findByCustomerCodeAndCompanyId("C1", COMPANY_ID))
                    .thenReturn(Optional.of(pep));

                int type = amlService.classifyTransaction("C1", new BigDecimal("50000"), "EUR");
                assertThat(type).isEqualTo(1);
            }
        }

        @Test
        @DisplayName("TranzTipus -1: külföldi ügyfél + USD → BLOKKOLVA")
        void testClassify_typeNeg1_foreignUsd() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("Cm1"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("Cm1"), any(), any()))
                    .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("Cm1"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("Cm1"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);

                Customer foreign = new Customer();
                foreign.setIsForeign(true);
                foreign.setIsPep(false);
                when(customerRepository.findByCustomerCodeAndCompanyId("Cm1", COMPANY_ID))
                    .thenReturn(Optional.of(foreign));

                int type = amlService.classifyTransaction("Cm1", new BigDecimal("50000"), "USD");
                assertThat(type).isEqualTo(-1);
            }
        }

        @Test
        @DisplayName("TranzTipus 0: normál ügyfél, kis összeg → 0")
        void testClassify_type0_normal() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C0"), any()))
                    .thenReturn(new BigDecimal("100000"));
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("C0"), any(), any()))
                    .thenReturn(1L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("C0"), any(), any()))
                    .thenReturn(new BigDecimal("200000"));
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("C0"), any(), any()))
                    .thenReturn(new BigDecimal("200000"));
                when(customerRepository.findByCustomerCodeAndCompanyId("C0", COMPANY_ID))
                    .thenReturn(Optional.empty());

                int type = amlService.classifyTransaction("C0", new BigDecimal("50000"), "EUR");
                assertThat(type).isEqualTo(0);
            }
        }

        @Test
        @DisplayName("TranzTipus 0: névtelen ügyfél (null customerId), kis összeg → 0")
        void testClassify_type0_anonymous_small() {
            int type = amlService.classifyTransaction(null, new BigDecimal("100000"), "EUR");
            assertThat(type).isEqualTo(0);
        }

        @Test
        @DisplayName("TranzTipus 6: névtelen ügyfél, 55M → 6")
        void testClassify_type6_anonymous_over50M() {
            int type = amlService.classifyTransaction(null, new BigDecimal("55000000"), "EUR");
            assertThat(type).isEqualTo(6);
        }

        @Test
        @DisplayName("TranzTipus 5: névtelen ügyfél, 12M → 5")
        void testClassify_type5_anonymous_over10M() {
            int type = amlService.classifyTransaction(null, new BigDecimal("12000000"), "EUR");
            assertThat(type).isEqualTo(5);
        }
    }

    // =========================================================
    // C3 — checkTransaction(): transactionType mező kitöltve
    // =========================================================

    @Nested
    @DisplayName("C3 — checkTransaction: transactionType mező kitöltve")
    class CheckTransactionTypeFieldTests {

        @Test
        @DisplayName("C3-1: normál ügyfél kis összeg → transactionType = 0")
        void testCheckTransaction_normalCustomer_typeZero() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(transactionRepository.sumCustomerAnnualTotal(eq(COMPANY_ID), eq("C0"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerDailyTotal(eq(COMPANY_ID), eq("C0"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C0"), any()))
                    .thenReturn(new BigDecimal("100000"));
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("C0"), any(), any()))
                    .thenReturn(1L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("C0"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("C0"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(customerRepository.findByCustomerCodeAndCompanyId("C0", COMPANY_ID))
                    .thenReturn(Optional.empty());

                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    new BigDecimal("50000"), "C0", "Normál Ügyfél", "AB123456");

                assertThat(result.isApproved()).isTrue();
                assertThat(result.getTransactionType()).isEqualTo(0);
            }
        }

        @Test
        @DisplayName("C3-2: heti 10M+ ügyfél → transactionType = 5 (nem 0)")
        void testCheckTransaction_over10M_typeIs5() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(transactionRepository.sumCustomerAnnualTotal(eq(COMPANY_ID), eq("C5"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerDailyTotal(eq(COMPANY_ID), eq("C5"), any()))
                    .thenReturn(BigDecimal.ZERO);
                // weekly = 9M → hasforint = 9M + 2M = 11M >= 10M → type 5
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("C5"), any()))
                    .thenReturn(new BigDecimal("9000000"));

                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    new BigDecimal("2000000"), "C5", "Nagy Ügyfél", "AB999999");

                assertThat(result.getTransactionType())
                    .as("C3 fix: transactionType be kell legyen állítva (nem 0)")
                    .isEqualTo(5)
                    .isNotEqualTo(0);
                assertThat(result.isRequiresIdentification()).isTrue();
                assertThat(result.isRequiresDetailedId()).isTrue();
            }
        }

        @Test
        @DisplayName("C3-3: PEP ügyfél → transactionType = 1, requiresIdentification = true")
        void testCheckTransaction_pep_typeIs1() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(transactionRepository.sumCustomerAnnualTotal(eq(COMPANY_ID), eq("CPEP"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerDailyTotal(eq(COMPANY_ID), eq("CPEP"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CPEP"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("CPEP"), any(), any()))
                    .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("CPEP"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("CPEP"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);

                Customer pep = new Customer();
                pep.setIsForeign(false);
                pep.setIsPep(true);
                when(customerRepository.findByCustomerCodeAndCompanyId("CPEP", COMPANY_ID))
                    .thenReturn(Optional.of(pep));

                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    new BigDecimal("50000"), "CPEP", "PEP Ügyfél", "PEP12345");

                assertThat(result.getTransactionType()).isEqualTo(1);
                assertThat(result.isRequiresIdentification()).isTrue();
                assertThat(result.isRequiresDetailedId()).isTrue();
            }
        }

        @Test
        @DisplayName("C3-4: külföldi USD ügyfél → transactionType = -1, approved = false")
        void testCheckTransaction_foreignUsd_blocked() {
            try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
                su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
                su.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

                when(transactionRepository.sumCustomerAnnualTotal(eq(COMPANY_ID), eq("CFOR"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerDailyTotal(eq(COMPANY_ID), eq("CFOR"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.sumCustomerWeeklyTotal(eq(COMPANY_ID), eq("CFOR"), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.countCustomerQuarterlyTransactions(
                        eq(COMPANY_ID), eq("CFOR"), any(), any()))
                    .thenReturn(0L);
                when(transactionRepository.sumCustomerQuarterlyTotal(
                        eq(COMPANY_ID), eq("CFOR"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);
                when(transactionRepository.findCustomerYearlyMax(
                        eq(COMPANY_ID), eq("CFOR"), any(), any()))
                    .thenReturn(BigDecimal.ZERO);

                Customer foreign = new Customer();
                foreign.setIsForeign(true);
                foreign.setIsPep(false);
                when(customerRepository.findByCustomerCodeAndCompanyId("CFOR", COMPANY_ID))
                    .thenReturn(Optional.of(foreign));

                AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                    new BigDecimal("50000"), "CFOR", "Külföldi Ügyfél", "FOR99999", "USD");

                assertThat(result.getTransactionType()).isEqualTo(-1);
                assertThat(result.isApproved()).isFalse();
                assertThat(result.getRejectionReason()).contains("USD");
                assertThat(result.isRequiresIdentification()).isTrue();
            }
        }

        @Test
        @DisplayName("C3-5: névtelen ügyfél → transactionType = 0 (null customerId)")
        void testCheckTransaction_anonymous_typeZero() {
            // Névtelen ügyfél, kis összeg (100K küszöb alatt) — sem annual/daily sem weekly nem hívódik
            AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("99000"), null, null, null);

            assertThat(result.isApproved()).isTrue();
            assertThat(result.getTransactionType()).isEqualTo(0);
        }
    }
}
