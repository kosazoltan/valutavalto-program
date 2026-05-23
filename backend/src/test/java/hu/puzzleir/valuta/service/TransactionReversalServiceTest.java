package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Tesztek a kiszervezett TransactionReversalService-hez.
 * Korabban TransactionFlowTest.StornoFlowTests volt.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionReversalServiceTest {

    @InjectMocks
    private TransactionReversalService reversalService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private DailySessionService dailySessionService;
    @Mock private PosTerminalService posTerminalService;
    @Mock private AmlService amlService;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransactionOperationHelper helper;
    @Mock private AuditLogService auditLogService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long EUR_ID = 10L;
    private static final Long HUF_ID = 1L;

    private Company company;
    private Branch branch;
    private Worker worker;
    private Currency eurCurrency;
    private CashBalance eurBalance;
    private CashBalance hufBalance;

    @BeforeEach
    void setUp() {
        company = new Company();
        company.setId(COMPANY_ID);
        company.setName("Test Ceg");

        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("B01");
        branch.setName("Teszt Iroda");

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt Penztaros");

        eurCurrency = new Currency();
        eurCurrency.setId(EUR_ID);
        eurCurrency.setCode("EUR");
        eurCurrency.setName("Euro");

        eurBalance = new CashBalance();
        eurBalance.setId(1L);
        eurBalance.setCurrency(eurCurrency);
        eurBalance.setCurrentBalance(new BigDecimal("50000"));

        hufBalance = new CashBalance();
        hufBalance.setId(2L);
        hufBalance.setCurrentBalance(new BigDecimal("5000000"));

        when(receiptSequenceService.generateReversalReceiptNumber(any(), any()))
            .thenReturn("STORNO-001");
        when(helper.getHufCurrencyId()).thenReturn(HUF_ID);
    }

    @Test
    @DisplayName("Sztorno flow - eladas sztorno, keszlet visszaall")
    void testStornoFlow() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

            when(dailySessionService.getDailyReversalCount()).thenReturn(0);

            Transaction original = Transaction.builder()
                    .id(100L)
                    .company(company)
                    .branch(branch)
                    .worker(worker)
                    .receiptNumber("E030600001")
                    .transactionType(TransactionType.SELL)
                    .status(TransactionStatus.COMPLETED)
                    .transactionDate(LocalDate.now())
                    .transactionTime(LocalTime.now())
                    .currency(eurCurrency)
                    .currencyAmount(new BigDecimal("200"))
                    .exchangeRate(new BigDecimal("400.00"))
                    .hufAmount(new BigDecimal("80000"))
                    .handlingFee(BigDecimal.ZERO)
                    .discountPercent(BigDecimal.ZERO)
                    .discountAmount(BigDecimal.ZERO)
                    .build();

            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(original));
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                Transaction t = inv.getArgument(0);
                if (t.getId() == null) t.setId(200L);
                return t;
            });

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("Teves rogzites")
                    .approvedBy("SUPERVISOR")
                    .build();

            Transaction reversal = reversalService.executeReversal(request);

            assertThat(reversal).isNotNull();
            assertThat(reversal.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
            assertThat(reversal.getStatus()).isEqualTo(TransactionStatus.COMPLETED);
            assertThat(reversal.getReversalReason()).isEqualTo("Teves rogzites");

            verify(transactionRepository, atLeast(2)).save(any(Transaction.class));
            verify(helper).updateCashBalance(eq(BRANCH_ID), eq(EUR_ID), any(), eq(true));
            verify(helper).updateCashBalance(eq(BRANCH_ID), eq(HUF_ID), any(), eq(false));
            verify(dailySessionService).updateSessionStats(eq(TransactionType.REVERSAL), any(), any());
        }
    }

    @Test
    @DisplayName("G2: sztorno aktualis arfolyammal - reversal a custom rate-tel konyvel")
    void testStorno_currentRate() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);
            when(dailySessionService.getDailyReversalCount()).thenReturn(0);

            Transaction original = Transaction.builder()
                    .id(100L).company(company).branch(branch).worker(worker)
                    .receiptNumber("E030600001").transactionType(TransactionType.SELL)
                    .status(TransactionStatus.COMPLETED)
                    .transactionDate(LocalDate.now()).transactionTime(LocalTime.now())
                    .currency(eurCurrency).currencyAmount(new BigDecimal("200"))
                    .exchangeRate(new BigDecimal("400.00")).hufAmount(new BigDecimal("80000"))
                    .handlingFee(BigDecimal.ZERO).discountPercent(BigDecimal.ZERO).discountAmount(BigDecimal.ZERO)
                    .build();

            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(original));
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                Transaction t = inv.getArgument(0);
                if (t.getId() == null) t.setId(200L);
                return t;
            });

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L).reason("Arfolyam valtozott").approvedBy("SUPERVISOR")
                    .useCurrentRate(true).customExchangeRate(new BigDecimal("410.00"))
                    .build();

            Transaction reversal = reversalService.executeReversal(request);

            // 200 × (410-400) = 2000 → reversal HUF = 80000 + 2000 = 82000, rate = 410
            assertThat(reversal.getExchangeRate()).isEqualByComparingTo("410.00");
            assertThat(reversal.getHufAmount()).isEqualByComparingTo("82000");
            assertThat(reversal.getNotes()).contains("arfolyam-kulonbozet");

            ArgumentCaptor<BigDecimal> hufCap = ArgumentCaptor.forClass(BigDecimal.class);
            verify(helper).updateCashBalance(eq(BRANCH_ID), eq(HUF_ID), hufCap.capture(), eq(false));
            assertThat(hufCap.getValue()).isEqualByComparingTo("-82000");
        }
    }

    @Test
    @DisplayName("G2: sztorno alapertelmezett (nincs useCurrentRate) - eredeti arfolyam valtozatlan")
    void testStorno_defaultRate_unchanged() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);
            when(dailySessionService.getDailyReversalCount()).thenReturn(0);

            Transaction original = Transaction.builder()
                    .id(100L).company(company).branch(branch).worker(worker)
                    .receiptNumber("E030600001").transactionType(TransactionType.SELL)
                    .status(TransactionStatus.COMPLETED)
                    .transactionDate(LocalDate.now()).transactionTime(LocalTime.now())
                    .currency(eurCurrency).currencyAmount(new BigDecimal("200"))
                    .exchangeRate(new BigDecimal("400.00")).hufAmount(new BigDecimal("80000"))
                    .handlingFee(BigDecimal.ZERO).discountPercent(BigDecimal.ZERO).discountAmount(BigDecimal.ZERO)
                    .build();

            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(original));
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                Transaction t = inv.getArgument(0);
                if (t.getId() == null) t.setId(200L);
                return t;
            });

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L).reason("Teves rogzites").approvedBy("SUPERVISOR")
                    .build();

            Transaction reversal = reversalService.executeReversal(request);

            assertThat(reversal.getExchangeRate()).isEqualByComparingTo("400.00");
            assertThat(reversal.getHufAmount()).isEqualByComparingTo("80000");
            assertThat(reversal.getNotes()).doesNotContain("arfolyam-kulonbozet");
        }
    }

    @Test
    @DisplayName("Sztorno - mar sztornozott tranzakcio")
    void testStornoFlow_alreadyReversed() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Transaction reversedTx = Transaction.builder()
                    .id(100L)
                    .branch(branch)
                    .status(TransactionStatus.REVERSED)
                    .transactionType(TransactionType.SELL)
                    .transactionDate(LocalDate.now())
                    .build();

            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(reversedTx));

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("Teszt")
                    .build();

            assertThatThrownBy(() -> reversalService.executeReversal(request))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("sztorn");
        }
    }

    @Test
    @DisplayName("Sztorno - mas iroda tranzakciojat nem lehet sztornozni")
    void testStornoFlow_differentBranch() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            Branch otherBranch = new Branch();
            otherBranch.setId(UUID.randomUUID());

            Transaction otherBranchTx = Transaction.builder()
                    .id(100L)
                    .branch(otherBranch)
                    .status(TransactionStatus.COMPLETED)
                    .transactionType(TransactionType.SELL)
                    .transactionDate(LocalDate.now())
                    .build();

            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(otherBranchTx));

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("Teszt")
                    .build();

            assertThatThrownBy(() -> reversalService.executeReversal(request))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("iroda");
        }
    }

    // === Audit P2.7 (2026-05-17) — VV-ELVI 5.6 negatív tesztek ===

    @Test
    @DisplayName("Sztorno (audit P2.7) - regi napi tranzakcio supervisor nelkul -> ValidationException")
    void testStornoFlow_olderTransactionWithoutSupervisor() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(false);

            Transaction olderTx = Transaction.builder()
                    .id(100L)
                    .branch(branch)
                    .status(TransactionStatus.COMPLETED)
                    .transactionType(TransactionType.SELL)
                    .transactionDate(LocalDate.now().minusDays(1))
                    .build();

            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(olderTx));

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("Tegnapi teves rogzites")
                    .build();

            assertThatThrownBy(() -> reversalService.executeReversal(request))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("supervisor");
        }
    }

    @Test
    @DisplayName("Sztorno (audit P2.7) - regi napi tranzakcio SUPERVISOR jovahagyassal -> success")
    void testStornoFlow_olderTransactionWithSupervisor() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

            when(dailySessionService.getDailyReversalCount()).thenReturn(0);

            Transaction olderTx = Transaction.builder()
                    .id(100L)
                    .company(company)
                    .branch(branch)
                    .worker(worker)
                    .receiptNumber("E030600002")
                    .transactionType(TransactionType.SELL)
                    .status(TransactionStatus.COMPLETED)
                    .transactionDate(LocalDate.now().minusDays(1))
                    .transactionTime(LocalTime.now())
                    .currency(eurCurrency)
                    .currencyAmount(new BigDecimal("100"))
                    .exchangeRate(new BigDecimal("400.00"))
                    .hufAmount(new BigDecimal("40000"))
                    .handlingFee(BigDecimal.ZERO)
                    .discountPercent(BigDecimal.ZERO)
                    .discountAmount(BigDecimal.ZERO)
                    .build();

            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(olderTx));
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
            when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
                Transaction t = inv.getArgument(0);
                if (t.getId() == null) t.setId(201L);
                return t;
            });

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("SUPERVISOR override")
                    .approvedBy("SUPERVISOR")
                    .build();

            Transaction reversal = reversalService.executeReversal(request);

            assertThat(reversal).isNotNull();
            assertThat(reversal.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
        }
    }

    @Test
    @DisplayName("Sztorno (audit P2.7) - nincs nyitott session (napzaras utan) -> ValidationException")
    void testStornoFlow_noOpenSession() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);

            doThrow(new ValidationException("Nincs nyitott napi session — napzaras utan sztorno nem lehetseges!"))
                    .when(helper).validateOpenSession();

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("Teszt")
                    .build();

            assertThatThrownBy(() -> reversalService.executeReversal(request))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("session");
        }
    }
}
