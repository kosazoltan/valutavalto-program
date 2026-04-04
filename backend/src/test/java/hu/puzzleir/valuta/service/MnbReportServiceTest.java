package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.mnb.MnbSubmissionResult;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.MnbReportRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
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
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MnbReportService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class MnbReportServiceTest {

    @InjectMocks
    private MnbReportService mnbReportService;

    @Mock
    private MnbReportRepository mnbReportRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;

    @Mock
    private OwnCompanyService ownCompanyService;

    @Mock
    private MnbApiClient mnbApiClient;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID  = UUID.randomUUID();
    private static final UUID TEST_REPORT_ID  = UUID.randomUUID();

    private Branch testBranch;
    private Company testCompany;

    @BeforeEach
    void setUp() {
        testCompany = Company.builder()
            .id(TEST_COMPANY_ID)
            .code("BEST")
            .name("Best Change Kft.")
            .taxNumber("12345678-2-41")
            .build();

        testBranch = Branch.builder()
            .id(TEST_BRANCH_ID)
            .code("BP01")
            .name("Budapest Központ")
            .company(testCompany)
            .build();

        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
            1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "MANAGER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_MANAGER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ============ generateDailyReport ============

    @Test
    @DisplayName("generateDailyReport: sikeres napi riport generálás tranzakciókkal")
    void testGenerateDailyReport() {
        LocalDate date = LocalDate.of(2026, 3, 5);

        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(testBranch));
        when(mnbReportRepository.findByReportTypeAndReportDateAndBranchId(any(), eq(date), eq(TEST_BRANCH_ID)))
            .thenReturn(Optional.empty());

        Currency eur = Currency.builder().code("EUR").build();
        Transaction tx1 = createTransaction(1L, TransactionType.BUY, eur,
            new BigDecimal("1000"), new BigDecimal("395000"), new BigDecimal("395"));
        Transaction tx2 = createTransaction(2L, TransactionType.SELL, eur,
            new BigDecimal("500"), new BigDecimal("200000"), new BigDecimal("400"));

        when(transactionRepository.findActiveByBranchAndDate(eq(TEST_BRANCH_ID), eq(date)))
            .thenReturn(List.of(tx1, tx2));

        when(mnbReportRepository.save(any(MnbReport.class)))
            .thenAnswer(inv -> {
                MnbReport report = inv.getArgument(0);
                report.setId(UUID.randomUUID());
                return report;
            });

        when(ownCompanyService.listActive()).thenReturn(List.of());

        MnbReport result = mnbReportService.generateDailyReport(TEST_BRANCH_ID, date);

        assertThat(result).isNotNull();
        assertThat(result.getReportType()).isEqualTo(MnbReportType.DAILY);
        assertThat(result.getTotalTransactions()).isEqualTo(2);
        assertThat(result.getTotalBuyHuf()).isEqualByComparingTo(new BigDecimal("395000"));
        assertThat(result.getTotalSellHuf()).isEqualByComparingTo(new BigDecimal("200000"));
        assertThat(result.getXmlContent()).isNotNull();
        // XSD-kompatibilis XML elemek
        assertThat(result.getXmlContent()).contains("<Jelentes");
        assertThat(result.getXmlContent()).contains("http://www.mnb.hu/penzvaltok/2010");
        assertThat(result.getXmlContent()).contains("<Devizanem");

        verify(mnbReportRepository).save(any());
    }

    // ============ exportMnbXml ============

    @Test
    @DisplayName("exportMnbXml: XSD-kompatibilis XML formátum ellenőrzése")
    void testExportXml_validFormat() {
        LocalDate date = LocalDate.of(2026, 3, 5);

        Currency usd = Currency.builder().code("USD").build();
        Transaction tx = createTransaction(1L, TransactionType.BUY, usd,
            new BigDecimal("2000"), new BigDecimal("780000"), new BigDecimal("390"));

        when(transactionRepository.findActiveByCompanyAndDate(eq(TEST_COMPANY_ID), eq(date)))
            .thenReturn(List.of(tx));

        when(ownCompanyService.listActive()).thenReturn(List.of());

        String xml = mnbReportService.exportMnbXml(date);

        assertThat(xml).isNotNull();
        assertThat(xml).startsWith("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        assertThat(xml).contains("<Jelentes xmlns=\"http://www.mnb.hu/penzvaltok/2010\"");
        assertThat(xml).contains("<RiportTipus>DAILY</RiportTipus>");
        assertThat(xml).contains("<RiportDatum>" + date + "</RiportDatum>");
        assertThat(xml).contains("kod=\"USD\"");
        assertThat(xml).contains("<Vetel>");
        assertThat(xml).contains("<Eladas>");
        assertThat(xml).contains("<OsszesTranzakcio>1</OsszesTranzakcio>");
        assertThat(xml).contains("</Jelentes>");
    }

    // ============ submitReport ============

    @Test
    @DisplayName("submitReport: sikeres beküldés DRAFT → ACKNOWLEDGED")
    void testSubmitReport_success_acknowledged() {
        MnbReport report = buildDraftReport();
        when(mnbReportRepository.findById(TEST_REPORT_ID)).thenReturn(Optional.of(report));
        when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        MnbSubmissionResult apiResult = MnbSubmissionResult.builder()
            .success(true).referenceNumber("MNB-ABCD1234").build();
        when(mnbApiClient.submitXml(anyString(), anyString())).thenReturn(apiResult);

        MnbSubmissionResult result = mnbReportService.submitReport(TEST_REPORT_ID);

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getReferenceNumber()).isEqualTo("MNB-ABCD1234");
        assertThat(report.getStatus()).isEqualTo(MnbReportStatus.ACKNOWLEDGED);
        assertThat(report.getMnbReferenceNumber()).isEqualTo("MNB-ABCD1234");
        assertThat(report.getAcknowledgedAt()).isNotNull();
    }

    @Test
    @DisplayName("submitReport: API hiba esetén DRAFT → REJECTED")
    void testSubmitReport_failure_rejected() {
        MnbReport report = buildDraftReport();
        when(mnbReportRepository.findById(TEST_REPORT_ID)).thenReturn(Optional.of(report));
        when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        MnbSubmissionResult apiResult = MnbSubmissionResult.builder()
            .success(false).errorMessage("MNB API 500 hiba").build();
        when(mnbApiClient.submitXml(anyString(), anyString())).thenReturn(apiResult);

        MnbSubmissionResult result = mnbReportService.submitReport(TEST_REPORT_ID);

        assertThat(result.isSuccess()).isFalse();
        assertThat(report.getStatus()).isEqualTo(MnbReportStatus.REJECTED);
        assertThat(report.getRejectedAt()).isNotNull();
        assertThat(report.getSubmissionError()).contains("500");
    }

    @Test
    @DisplayName("submitReport: nem-DRAFT riport → ValidationException")
    void testSubmitReport_notDraft_throws() {
        MnbReport report = buildDraftReport();
        report.setStatus(MnbReportStatus.SUBMITTED);
        when(mnbReportRepository.findById(TEST_REPORT_ID)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> mnbReportService.submitReport(TEST_REPORT_ID))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("DRAFT");
    }

    // ============ retrySubmission ============

    @Test
    @DisplayName("retrySubmission: REJECTED riport újraküldés → ACKNOWLEDGED")
    void testRetrySubmission_success() {
        MnbReport report = buildDraftReport();
        report.setStatus(MnbReportStatus.REJECTED);
        report.setRetryCount(0);

        when(mnbReportRepository.findById(TEST_REPORT_ID)).thenReturn(Optional.of(report));
        when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        MnbSubmissionResult apiResult = MnbSubmissionResult.builder()
            .success(true).referenceNumber("MNB-RETRY01").build();
        when(mnbApiClient.submitXml(anyString(), anyString())).thenReturn(apiResult);

        MnbSubmissionResult result = mnbReportService.retrySubmission(TEST_REPORT_ID);

        assertThat(result.isSuccess()).isTrue();
        assertThat(report.getStatus()).isEqualTo(MnbReportStatus.ACKNOWLEDGED);
        assertThat(report.getRetryCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("retrySubmission: max kísérletek túllépve → ValidationException")
    void testRetrySubmission_maxRetriesExceeded() {
        MnbReport report = buildDraftReport();
        report.setStatus(MnbReportStatus.REJECTED);
        report.setRetryCount(MnbReportService.MAX_RETRY_COUNT);

        when(mnbReportRepository.findById(TEST_REPORT_ID)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> mnbReportService.retrySubmission(TEST_REPORT_ID))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("Maximális újraküldési");
    }

    @Test
    @DisplayName("retrySubmission: nem-REJECTED riport → ValidationException")
    void testRetrySubmission_notRejected_throws() {
        MnbReport report = buildDraftReport();
        report.setStatus(MnbReportStatus.SUBMITTED);

        when(mnbReportRepository.findById(TEST_REPORT_ID)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> mnbReportService.retrySubmission(TEST_REPORT_ID))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("REJECTED");
    }

    // ============ generateWeeklyReport ============

    @Test
    @DisplayName("generateWeeklyReport: WEEKLY típusú riport, helyes dátumtartomány (hétfő–vasárnap)")
    void testGenerateWeeklyReport_createsWeeklyType() {
        // 2026-03-09 hétfő
        LocalDate monday = LocalDate.of(2026, 3, 9);
        LocalDate sunday = LocalDate.of(2026, 3, 15);

        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(testBranch));
        when(mnbReportRepository.findByReportTypeAndReportDateAndBranchId(
            eq(MnbReportType.WEEKLY), eq(sunday), eq(TEST_BRANCH_ID)))
            .thenReturn(Optional.empty());

        Currency eur = Currency.builder().code("EUR").build();
        Transaction tx = createTransaction(1L, TransactionType.BUY, eur,
            new BigDecimal("500"), new BigDecimal("200000"), new BigDecimal("400"));

        when(transactionRepository.findActiveByBranchAndDateRange(
            eq(TEST_BRANCH_ID), eq(monday), eq(sunday)))
            .thenReturn(List.of(tx));

        when(mnbReportRepository.save(any(MnbReport.class)))
            .thenAnswer(inv -> {
                MnbReport r = inv.getArgument(0);
                r.setId(UUID.randomUUID());
                return r;
            });

        when(ownCompanyService.listActive()).thenReturn(List.of());

        MnbReport result = mnbReportService.generateWeeklyReport(TEST_BRANCH_ID, monday);

        assertThat(result.getReportType()).isEqualTo(MnbReportType.WEEKLY);
        assertThat(result.getReportDate()).isEqualTo(sunday);
        assertThat(result.getTotalTransactions()).isEqualTo(1);
        assertThat(result.getXmlContent()).contains("<Jelentes");

        // Ellenőrizzük, hogy a lekérdezés hétfő–vasárnap tartományra ment
        verify(transactionRepository).findActiveByBranchAndDateRange(TEST_BRANCH_ID, monday, sunday);
    }

    @Test
    @DisplayName("generateWeeklyReport: ha nem hétfőt adunk meg, normalizál hétfőre")
    void testGenerateWeeklyReport_normalizesToMonday() {
        // 2026-03-11 szerda → normalizálva: 2026-03-09 hétfő
        LocalDate wednesday = LocalDate.of(2026, 3, 11);
        LocalDate expectedMonday = LocalDate.of(2026, 3, 9);
        LocalDate expectedSunday = LocalDate.of(2026, 3, 15);

        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(testBranch));
        when(mnbReportRepository.findByReportTypeAndReportDateAndBranchId(
            eq(MnbReportType.WEEKLY), eq(expectedSunday), eq(TEST_BRANCH_ID)))
            .thenReturn(Optional.empty());

        when(transactionRepository.findActiveByBranchAndDateRange(any(), any(), any()))
            .thenReturn(List.of());
        when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(ownCompanyService.listActive()).thenReturn(List.of());

        mnbReportService.generateWeeklyReport(TEST_BRANCH_ID, wednesday);

        // Normalizált tartományra hívódott
        verify(transactionRepository).findActiveByBranchAndDateRange(
            TEST_BRANCH_ID, expectedMonday, expectedSunday);
    }

    @Test
    @DisplayName("generateWeeklyReport: már létező heti riport → ValidationException")
    void testGenerateWeeklyReport_alreadyExists_throws() {
        LocalDate monday = LocalDate.of(2026, 3, 9);
        LocalDate sunday = LocalDate.of(2026, 3, 15);

        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(testBranch));
        when(mnbReportRepository.findByReportTypeAndReportDateAndBranchId(
            eq(MnbReportType.WEEKLY), eq(sunday), eq(TEST_BRANCH_ID)))
            .thenReturn(Optional.of(buildDraftReport()));

        assertThatThrownBy(() -> mnbReportService.generateWeeklyReport(TEST_BRANCH_ID, monday))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("Már létezik");
    }

    // ============ HELPER METHODS ============

    private MnbReport buildDraftReport() {
        return MnbReport.builder()
            .id(TEST_REPORT_ID)
            .reportType(MnbReportType.DAILY)
            .reportDate(LocalDate.of(2026, 3, 5))
            .branch(testBranch)
            .status(MnbReportStatus.DRAFT)
            .xmlContent("<?xml version=\"1.0\"?><Jelentes/>")
            .retryCount(0)
            .build();
    }

    private Transaction createTransaction(Long id, TransactionType type, Currency currency,
                                           BigDecimal currencyAmount, BigDecimal hufAmount, BigDecimal rate) {
        return Transaction.builder()
            .id(id)
            .transactionType(type)
            .currency(currency)
            .currencyAmount(currencyAmount)
            .hufAmount(hufAmount)
            .exchangeRate(rate)
            .transactionDate(LocalDate.of(2026, 3, 5))
            .transactionTime(LocalTime.of(10, 30))
            .build();
    }
}
