package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.aml.AmlDailySummaryDto;
import hu.puzzleir.valuta.dto.aml.AmlReportDto;
import hu.puzzleir.valuta.dto.aml.CreateAmlReportDto;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
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

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Sprint 5 C5 — AML bejelentési határidő tracking tesztek.
 *
 * Lefedett területek:
 * 1. calculateBusinessDayDeadline() — hétvégét átugorja
 * 2. submitReport() — deadlineAt kitöltve, nem null
 * 3. checkAndMarkOverdueReports() — DRAFT + lejárt → OVERDUE; jövőbeli → DRAFT marad
 * 4. submitToAuthority() — OVERDUE státuszból is SUBMITTED-be megy
 * 5. getDailyAmlSummary() — OVERDUE pending-ként számolódik
 * 6. GET /api/v1/aml/overdue — endpoint létezik, 200 OK
 * 7. Regresszió: meglévő AML viselkedés nem törött
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AmlDeadlineTrackingTest {

    @InjectMocks
    private AmlService amlService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private AmlReportRepository amlReportRepository;
    @Mock private AmlThresholdRepository amlThresholdRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private SanctionScreeningService sanctionScreeningService;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID  = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
            1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "MANAGER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken(
            "test", "pass", "ROLE_MANAGER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Alapértelmezett szankciós szűrés: CLEAR
        lenient().when(sanctionScreeningService.screenCustomer(
                any(), any(), any(), any(), any(), any()))
            .thenReturn(SanctionScreeningResult.builder()
                .matched(false).riskLevel("CLEAR").build());
    }

    // =========================================================================
    // 1. calculateBusinessDayDeadline — privát metódus tesztelés reflectionnel
    // =========================================================================

    /**
     * Reflection helper: calculateBusinessDayDeadline hívása.
     */
    private LocalDateTime callCalculateBusinessDayDeadline(LocalDateTime from, int businessDays)
            throws Exception {
        Method m = AmlService.class.getDeclaredMethod(
            "calculateBusinessDayDeadline", LocalDateTime.class, int.class);
        m.setAccessible(true);
        return (LocalDateTime) m.invoke(amlService, from, businessDays);
    }

    @Nested
    @DisplayName("1. calculateBusinessDayDeadline — hétvégét átugorja")
    class BusinessDayDeadlineTests {

        @Test
        @DisplayName("Hétfő + 2 munkanap = szerda")
        void testMonday_plus2_isWednesday() throws Exception {
            // 2026-04-06 = hétfő
            LocalDateTime monday = LocalDate.of(2026, 4, 6).atTime(10, 0);
            assertThat(monday.getDayOfWeek()).isEqualTo(DayOfWeek.MONDAY);

            LocalDateTime result = callCalculateBusinessDayDeadline(monday, 2);

            assertThat(result.toLocalDate()).isEqualTo(LocalDate.of(2026, 4, 8));
            assertThat(result.getDayOfWeek()).isEqualTo(DayOfWeek.WEDNESDAY);
        }

        @Test
        @DisplayName("Péntek + 2 munkanap = kedd (hétvégét átugorja)")
        void testFriday_plus2_isTuesday() throws Exception {
            // 2026-04-03 = péntek
            LocalDateTime friday = LocalDate.of(2026, 4, 3).atTime(10, 0);
            assertThat(friday.getDayOfWeek()).isEqualTo(DayOfWeek.FRIDAY);

            LocalDateTime result = callCalculateBusinessDayDeadline(friday, 2);

            // +1 = szombat (skip), +2 = vasárnap (skip), +3 = hétfő (1. munkanap),
            // +4 = kedd (2. munkanap)
            assertThat(result.toLocalDate()).isEqualTo(LocalDate.of(2026, 4, 7));
            assertThat(result.getDayOfWeek()).isEqualTo(DayOfWeek.TUESDAY);
        }

        @Test
        @DisplayName("Csütörtök + 2 munkanap = hétfő (péntek az 1., hétfő a 2.)")
        void testThursday_plus2_isMonday() throws Exception {
            // 2026-04-02 = csütörtök
            LocalDateTime thursday = LocalDate.of(2026, 4, 2).atTime(10, 0);
            assertThat(thursday.getDayOfWeek()).isEqualTo(DayOfWeek.THURSDAY);

            LocalDateTime result = callCalculateBusinessDayDeadline(thursday, 2);

            // +1 = péntek (1. munkanap), +2 = szombat (skip), +3 = vasárnap (skip), +4 = hétfő (2.)
            assertThat(result.toLocalDate()).isEqualTo(LocalDate.of(2026, 4, 6));
            assertThat(result.getDayOfWeek()).isEqualTo(DayOfWeek.MONDAY);
        }

        @Test
        @DisplayName("Az időpont (óra:perc) megmarad a határidőben")
        void testTimeIsPreserved() throws Exception {
            LocalDateTime input = LocalDate.of(2026, 4, 6).atTime(14, 30);
            LocalDateTime result = callCalculateBusinessDayDeadline(input, 2);

            assertThat(result.getHour()).isEqualTo(14);
            assertThat(result.getMinute()).isEqualTo(30);
        }

        @Test
        @DisplayName("0 munkanap → ugyanaz a nap")
        void testZeroBusinessDays_sameDay() throws Exception {
            LocalDateTime monday = LocalDate.of(2026, 4, 6).atTime(9, 0);
            LocalDateTime result = callCalculateBusinessDayDeadline(monday, 0);
            assertThat(result.toLocalDate()).isEqualTo(monday.toLocalDate());
        }
    }

    // =========================================================================
    // 2. submitReport — deadlineAt kitöltve
    // =========================================================================

    @Nested
    @DisplayName("2. submitReport — deadlineAt nem null, jövőbeli dátum")
    class SubmitReportDeadlineTests {

        @Test
        @DisplayName("submitReport: deadlineAt kitöltve, nem null")
        void testSubmitReport_deadlineAtNotNull() {
            CreateAmlReportDto dto = CreateAmlReportDto.builder()
                .customerId("C001")
                .reportType("STANDARD")
                .riskLevel("LOW")
                .amountHuf(BigDecimal.valueOf(500000))
                .currencyCode("EUR")
                .customerName("Teszt Ügyfél")
                .documentNumber("AB123456")
                .build();

            when(amlReportRepository.save(any(AmlReport.class)))
                .thenAnswer(inv -> {
                    AmlReport r = inv.getArgument(0);
                    r.setId(UUID.randomUUID());
                    return r;
                });

            AmlReportDto result = amlService.submitReport(dto);

            assertThat(result.getDeadlineAt()).isNotNull();
        }

        @Test
        @DisplayName("submitReport: deadlineAt legalább 1 munkanappal a jövőben van")
        void testSubmitReport_deadlineAtIsFuture() {
            CreateAmlReportDto dto = CreateAmlReportDto.builder()
                .customerId("C002")
                .reportType("STANDARD")
                .riskLevel("MEDIUM")
                .amountHuf(BigDecimal.valueOf(1000000))
                .currencyCode("USD")
                .customerName("Másik Ügyfél")
                .documentNumber("CD654321")
                .build();

            when(amlReportRepository.save(any(AmlReport.class)))
                .thenAnswer(inv -> {
                    AmlReport r = inv.getArgument(0);
                    r.setId(UUID.randomUUID());
                    return r;
                });

            LocalDateTime before = LocalDateTime.now();
            AmlReportDto result = amlService.submitReport(dto);

            // deadlineAt > now (legalább 1 nappal a jövőben)
            assertThat(result.getDeadlineAt()).isAfter(before);
        }

        @Test
        @DisplayName("submitReport: deadlineAt = 2 munkanap múlva (nem hétvége)")
        void testSubmitReport_deadlineAt_2BusinessDays() {
            CreateAmlReportDto dto = CreateAmlReportDto.builder()
                .customerId("C003")
                .reportType("ENHANCED")
                .riskLevel("HIGH")
                .amountHuf(BigDecimal.valueOf(2000000))
                .currencyCode("EUR")
                .customerName("Harmadik Ügyfél")
                .documentNumber("EF789012")
                .build();

            when(amlReportRepository.save(any(AmlReport.class)))
                .thenAnswer(inv -> {
                    AmlReport r = inv.getArgument(0);
                    r.setId(UUID.randomUUID());
                    return r;
                });

            LocalDateTime beforeCall = LocalDateTime.now();
            AmlReportDto result = amlService.submitReport(dto);
            LocalDateTime deadline = result.getDeadlineAt();

            assertThat(deadline).isNotNull();
            // Deadline legalább 1 nappal a jövőben (lehet 2, 3, 4 nap ha hétvége közbejön)
            assertThat(deadline.toLocalDate()).isAfter(beforeCall.toLocalDate());
            // De legfeljebb 5 nappal (péntek+2 = max hétfő+2 nap késés)
            assertThat(deadline.toLocalDate()).isBefore(beforeCall.toLocalDate().plusDays(6));
            // Nem esik hétvégére
            assertThat(deadline.getDayOfWeek())
                .isNotIn(DayOfWeek.SATURDAY, DayOfWeek.SUNDAY);
        }

        @Test
        @DisplayName("submitReport: státusz DRAFT, nem OVERDUE")
        void testSubmitReport_statusIsDraft() {
            CreateAmlReportDto dto = CreateAmlReportDto.builder()
                .customerId("C004")
                .reportType("STANDARD")
                .riskLevel("LOW")
                .amountHuf(BigDecimal.valueOf(300000))
                .currencyCode("EUR")
                .build();

            when(amlReportRepository.save(any(AmlReport.class)))
                .thenAnswer(inv -> {
                    AmlReport r = inv.getArgument(0);
                    r.setId(UUID.randomUUID());
                    return r;
                });

            AmlReportDto result = amlService.submitReport(dto);

            assertThat(result.getStatus()).isEqualTo("DRAFT");
        }
    }

    // =========================================================================
    // 3. checkAndMarkOverdueReports — DRAFT + lejárt → OVERDUE
    // =========================================================================

    @Nested
    @DisplayName("3. checkAndMarkOverdueReports — OVERDUE jelölés")
    class CheckAndMarkOverdueTests {

        @Test
        @DisplayName("DRAFT + lejárt deadline → OVERDUE státuszra vált")
        void testCheckAndMark_draftExpired_becomesOverdue() {
            UUID reportId = UUID.randomUUID();
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);

            AmlReport expiredReport = AmlReport.builder()
                .id(reportId)
                .company(company)
                .status(AmlReportStatus.DRAFT)
                .reportType(AmlReportType.STANDARD)
                .riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(500000))
                .currencyCode("EUR")
                .customerId("C001")
                .deadlineAt(LocalDateTime.now().minusDays(1)) // lejárt!
                .build();

            when(amlReportRepository.findOverdueReports(any(LocalDateTime.class)))
                .thenReturn(List.of(expiredReport));
            when(amlReportRepository.save(any(AmlReport.class)))
                .thenAnswer(inv -> inv.getArgument(0));

            int count = amlService.checkAndMarkOverdueReports();

            assertThat(count).isEqualTo(1);

            ArgumentCaptor<AmlReport> captor = ArgumentCaptor.forClass(AmlReport.class);
            verify(amlReportRepository, atLeastOnce()).save(captor.capture());

            AmlReport saved = captor.getValue();
            assertThat(saved.getStatus()).isEqualTo(AmlReportStatus.OVERDUE);
        }

        @Test
        @DisplayName("Nincs lejárt bejelentés → 0 db módosítva")
        void testCheckAndMark_noneExpired_returnsZero() {
            when(amlReportRepository.findOverdueReports(any(LocalDateTime.class)))
                .thenReturn(Collections.emptyList());

            int count = amlService.checkAndMarkOverdueReports();

            assertThat(count).isEqualTo(0);
            verify(amlReportRepository, never()).save(any());
        }

        @Test
        @DisplayName("Több lejárt bejelentés → mind OVERDUE-ra áll")
        void testCheckAndMark_multiple_allBecomeOverdue() {
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);

            List<AmlReport> reports = new ArrayList<>();
            for (int i = 0; i < 3; i++) {
                reports.add(AmlReport.builder()
                    .id(UUID.randomUUID())
                    .company(company)
                    .status(AmlReportStatus.DRAFT)
                    .reportType(AmlReportType.STANDARD)
                    .riskLevel(AmlRiskLevel.LOW)
                    .amountHuf(BigDecimal.valueOf(500000))
                    .customerId("C00" + i)
                    .deadlineAt(LocalDateTime.now().minusHours(i + 1))
                    .build());
            }

            when(amlReportRepository.findOverdueReports(any(LocalDateTime.class)))
                .thenReturn(reports);
            when(amlReportRepository.save(any(AmlReport.class)))
                .thenAnswer(inv -> inv.getArgument(0));

            int count = amlService.checkAndMarkOverdueReports();

            assertThat(count).isEqualTo(3);
            verify(amlReportRepository, times(3)).save(any());
            verify(auditLogService, times(3)).log(eq("AML_REPORT_OVERDUE"), anyString(), anyString());
        }

        @Test
        @DisplayName("DRAFT + jövőbeli deadline → NEM kerül a lejárt listába (repository nem adja vissza)")
        void testCheckAndMark_futureDraft_staysDraft() {
            // A repository findOverdueReports csak deadline < now rekordokat ad vissza.
            // A jövőbeli határidejű DRAFT rekordot NEM adja vissza → a service NEM módosítja.
            when(amlReportRepository.findOverdueReports(any(LocalDateTime.class)))
                .thenReturn(Collections.emptyList()); // jövőbeli nincs a listában

            int count = amlService.checkAndMarkOverdueReports();

            assertThat(count).isEqualTo(0);
            verify(amlReportRepository, never()).save(any());
        }
    }

    // =========================================================================
    // 4. submitToAuthority — OVERDUE státuszból is SUBMITTED
    // =========================================================================

    @Nested
    @DisplayName("4. submitToAuthority — OVERDUE → SUBMITTED")
    class SubmitToAuthorityOverdueTests {

        @Test
        @DisplayName("OVERDUE státuszból SUBMITTED-re vált")
        void testSubmitToAuthority_overdueToSubmitted() {
            UUID reportId = UUID.randomUUID();
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);

            AmlReport overdueReport = AmlReport.builder()
                .id(reportId)
                .company(company)
                .status(AmlReportStatus.OVERDUE)
                .reportType(AmlReportType.STANDARD)
                .riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(500000))
                .currencyCode("EUR")
                .deadlineAt(LocalDateTime.now().minusDays(1))
                .build();

            when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(overdueReport));
            when(amlReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            AmlReportDto result = amlService.submitToAuthority(reportId, "EXT-OVERDUE-001");

            assertThat(result.getStatus()).isEqualTo("SUBMITTED");
            assertThat(result.getExternalReference()).isEqualTo("EXT-OVERDUE-001");
            assertThat(result.getSubmittedAt()).isNotNull();

            verify(auditLogService).log(eq("AML_REPORT_SUBMITTED"), anyString(), eq(reportId.toString()));
        }

        @Test
        @DisplayName("DRAFT státuszból is SUBMITTED-re vált (regresszió)")
        void testSubmitToAuthority_draftToSubmitted_stillWorks() {
            UUID reportId = UUID.randomUUID();
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);

            AmlReport draftReport = AmlReport.builder()
                .id(reportId)
                .company(company)
                .status(AmlReportStatus.DRAFT)
                .reportType(AmlReportType.STANDARD)
                .riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(300000))
                .currencyCode("EUR")
                .build();

            when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(draftReport));
            when(amlReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            AmlReportDto result = amlService.submitToAuthority(reportId, "EXT-DRAFT-001");

            assertThat(result.getStatus()).isEqualTo("SUBMITTED");
        }

        @Test
        @DisplayName("SUBMITTED státuszból NEM lehet újra benyújtani → ValidationException")
        void testSubmitToAuthority_alreadySubmitted_throws() {
            UUID reportId = UUID.randomUUID();
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);

            AmlReport submittedReport = AmlReport.builder()
                .id(reportId)
                .company(company)
                .status(AmlReportStatus.SUBMITTED)
                .reportType(AmlReportType.STANDARD)
                .riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(500000))
                .build();

            when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(submittedReport));

            assertThatThrownBy(() -> amlService.submitToAuthority(reportId, "REF"))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("DRAFT");
        }

        @Test
        @DisplayName("Más cég bejelentése → ValidationException (hozzáférés megtagadva)")
        void testSubmitToAuthority_otherCompany_throws() {
            UUID reportId = UUID.randomUUID();
            Company otherCompany = new Company();
            otherCompany.setId(UUID.randomUUID()); // különböző cég!

            AmlReport report = AmlReport.builder()
                .id(reportId)
                .company(otherCompany)
                .status(AmlReportStatus.DRAFT)
                .reportType(AmlReportType.STANDARD)
                .riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(500000))
                .build();

            when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(report));

            assertThatThrownBy(() -> amlService.submitToAuthority(reportId, "REF"))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("Hozzáférés megtagadva");
        }
    }

    // =========================================================================
    // 5. getDailyAmlSummary — OVERDUE pending-ként számolódik
    // =========================================================================

    @Nested
    @DisplayName("5. getDailyAmlSummary — OVERDUE = pending")
    class DailyAmlSummaryOverdueTests {

        private AmlReport buildReport(AmlReportStatus status) {
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);
            return AmlReport.builder()
                .id(UUID.randomUUID())
                .company(company)
                .status(status)
                .reportType(AmlReportType.STANDARD)
                .riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(500000))
                .currencyCode("EUR")
                .build();
        }

        @Test
        @DisplayName("OVERDUE rekord pendingReports-ban számolódik")
        void testSummary_overdueCountsAsPending() {
            LocalDate today = LocalDate.now();

            AmlReport overdueReport = buildReport(AmlReportStatus.OVERDUE);
            AmlReport draftReport  = buildReport(AmlReportStatus.DRAFT);
            AmlReport submittedReport = buildReport(AmlReportStatus.SUBMITTED);

            when(amlReportRepository.findByCompanyIdAndDateRange(
                    eq(TEST_COMPANY_ID), any(), any()))
                .thenReturn(List.of(overdueReport, draftReport, submittedReport));
            when(amlReportRepository.countByCompanyIdAndDateRangeAndType(any(), any(), any(), any()))
                .thenReturn(0L);

            AmlDailySummaryDto summary = amlService.getDailyAmlSummary(today);

            // 2 pending: 1 OVERDUE + 1 DRAFT
            assertThat(summary.getPendingReports()).isEqualTo(2);
            assertThat(summary.getSubmittedReports()).isEqualTo(1);
            assertThat(summary.getTotalReports()).isEqualTo(3);
        }

        @Test
        @DisplayName("Csak OVERDUE rekord → pending=1, submitted=0")
        void testSummary_onlyOverdue() {
            LocalDate today = LocalDate.now();

            when(amlReportRepository.findByCompanyIdAndDateRange(
                    eq(TEST_COMPANY_ID), any(), any()))
                .thenReturn(List.of(buildReport(AmlReportStatus.OVERDUE)));
            when(amlReportRepository.countByCompanyIdAndDateRangeAndType(any(), any(), any(), any()))
                .thenReturn(0L);

            AmlDailySummaryDto summary = amlService.getDailyAmlSummary(today);

            assertThat(summary.getPendingReports()).isEqualTo(1);
            assertThat(summary.getSubmittedReports()).isEqualTo(0);
        }

        @Test
        @DisplayName("OVERDUE nem flaggedReports-ban számolódik")
        void testSummary_overdueNotInFlagged() {
            LocalDate today = LocalDate.now();

            when(amlReportRepository.findByCompanyIdAndDateRange(
                    eq(TEST_COMPANY_ID), any(), any()))
                .thenReturn(List.of(buildReport(AmlReportStatus.OVERDUE)));
            when(amlReportRepository.countByCompanyIdAndDateRangeAndType(any(), any(), any(), any()))
                .thenReturn(0L);

            AmlDailySummaryDto summary = amlService.getDailyAmlSummary(today);

            assertThat(summary.getFlaggedReports()).isEqualTo(0);
        }
    }

    // =========================================================================
    // 6. GET /api/v1/aml/overdue — endpoint létezik, 200 OK
    // Lásd: AmlOverdueEndpointTest (controller csomag) — külön osztályban van,
    // mert a Nested + @InjectMocks kombinációja MockitoExtension-nel ütközik.
    // =========================================================================

    // =========================================================================
    // 7. Regresszió — meglévő AML tesztek viselkedése nem törött
    // =========================================================================

    @Nested
    @DisplayName("7. Regresszió — meglévő AML viselkedés")
    class RegressionTests {

        @Test
        @DisplayName("OVERDUE státusz az AmlReportStatus enum-ban szerepel")
        void testAmlReportStatus_overdueEnumExists() {
            AmlReportStatus overdue = AmlReportStatus.valueOf("OVERDUE");
            assertThat(overdue).isEqualTo(AmlReportStatus.OVERDUE);
        }

        @Test
        @DisplayName("AmlReport.deadlineAt mező létezik és setelhető")
        void testAmlReport_deadlineAtField() {
            AmlReport report = new AmlReport();
            LocalDateTime deadline = LocalDateTime.now().plusDays(2);
            report.setDeadlineAt(deadline);
            assertThat(report.getDeadlineAt()).isEqualTo(deadline);
        }

        @Test
        @DisplayName("checkTransaction: 150K alatt → approved, no identification (változatlan)")
        void testRegression_checkTransaction_underThreshold() {
            AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("150000"), "C001", "Teszt Ügyfél", "AB123456");

            assertThat(result.isApproved()).isTrue();
            assertThat(result.isRequiresIdentification()).isFalse();
        }

        @Test
        @DisplayName("checkTransaction: 500K + azonosítás nélkül → rejected (változatlan)")
        void testRegression_checkTransaction_reportingRequired() {
            AmlService.AmlBasicCheckResult result = amlService.checkTransaction(
                new BigDecimal("500000"), "C001", null, null);

            assertThat(result.isApproved()).isFalse();
            assertThat(result.getRejectionReason()).isNotNull();
        }

        @Test
        @DisplayName("submitToAuthority: ACKNOWLEDGED státusz nem küldhető be")
        void testRegression_submitToAuthority_acknowledgedThrows() {
            UUID reportId = UUID.randomUUID();
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);

            AmlReport ackReport = AmlReport.builder()
                .id(reportId)
                .company(company)
                .status(AmlReportStatus.ACKNOWLEDGED)
                .reportType(AmlReportType.STANDARD)
                .riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(500000))
                .build();

            when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(ackReport));

            assertThatThrownBy(() -> amlService.submitToAuthority(reportId, "REF"))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class);
        }

        @Test
        @DisplayName("getDailyAmlSummary: DRAFT + SUBMITTED összegzés helyes (OVERDUE nélkül)")
        void testRegression_dailySummary_withoutOverdue() {
            LocalDate today = LocalDate.now();
            Company company = new Company();
            company.setId(TEST_COMPANY_ID);

            AmlReport draft = AmlReport.builder()
                .id(UUID.randomUUID()).company(company).status(AmlReportStatus.DRAFT)
                .reportType(AmlReportType.STANDARD).riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(100000)).build();

            AmlReport submitted = AmlReport.builder()
                .id(UUID.randomUUID()).company(company).status(AmlReportStatus.SUBMITTED)
                .reportType(AmlReportType.STANDARD).riskLevel(AmlRiskLevel.LOW)
                .amountHuf(BigDecimal.valueOf(200000)).build();

            when(amlReportRepository.findByCompanyIdAndDateRange(
                    eq(TEST_COMPANY_ID), any(), any()))
                .thenReturn(List.of(draft, submitted));
            when(amlReportRepository.countByCompanyIdAndDateRangeAndType(any(), any(), any(), any()))
                .thenReturn(0L);

            AmlDailySummaryDto summary = amlService.getDailyAmlSummary(today);

            assertThat(summary.getPendingReports()).isEqualTo(1);
            assertThat(summary.getSubmittedReports()).isEqualTo(1);
            assertThat(summary.getTotalReports()).isEqualTo(2);
        }

        @Test
        @DisplayName("getOverdueReports: üres lista ha nincs cégszintű overdue")
        void testRegression_getOverdueReports_emptyIfNone() {
            when(amlReportRepository.findOverdueByCompanyId(
                    eq(TEST_COMPANY_ID), any(LocalDateTime.class)))
                .thenReturn(Collections.emptyList());

            List<AmlReportDto> result = amlService.getOverdueReports();

            assertThat(result).isEmpty();
        }
    }
}
