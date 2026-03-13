package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.BranchRepository;
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
    private OwnCompanyService ownCompanyService;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

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

        // SecurityContext
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
            1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "MANAGER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_MANAGER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("generateDailyReport: sikeres napi riport generálás tranzakciókkal")
    void testGenerateDailyReport() {
        LocalDate date = LocalDate.of(2026, 3, 5);

        when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(testBranch));
        when(mnbReportRepository.findByReportTypeAndReportDateAndBranchId(any(), eq(date), eq(TEST_BRANCH_ID)))
            .thenReturn(Optional.empty());

        // Teszt tranzakciók
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
        assertThat(result.getXmlContent()).contains("<MNBReport>");

        verify(mnbReportRepository).save(any());
    }

    @Test
    @DisplayName("exportMnbXml: valid XML formátum ellenőrzése")
    void testExportXml_validFormat() {
        LocalDate date = LocalDate.of(2026, 3, 5);

        // Tranzakciók
        Currency usd = Currency.builder().code("USD").build();
        Transaction tx = createTransaction(1L, TransactionType.BUY, usd,
            new BigDecimal("2000"), new BigDecimal("780000"), new BigDecimal("390"));

        when(transactionRepository.findActiveByCompanyAndDate(eq(TEST_COMPANY_ID), eq(date)))
            .thenReturn(List.of(tx));

        when(ownCompanyService.listActive()).thenReturn(List.of());

        String xml = mnbReportService.exportMnbXml(date);

        assertThat(xml).isNotNull();
        assertThat(xml).startsWith("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        assertThat(xml).contains("<MNBReport>");
        assertThat(xml).contains("<ReportType>DAILY</ReportType>");
        assertThat(xml).contains("<ReportDate>" + date + "</ReportDate>");
        assertThat(xml).contains("code=\"USD\"");
        assertThat(xml).contains("<TotalTransactions>1</TotalTransactions>");
        assertThat(xml).contains("</MNBReport>");
    }

    // ============ HELPER ============

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
