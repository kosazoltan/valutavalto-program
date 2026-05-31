package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
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
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * StornoService.executeOtpRefund() unit tesztek.
 *
 * P3-15: Részleges visszatérítés — a refundAmount paraméter alapján
 * teljes sztornó (executeReversal) vagy részleges visszatérítés (executePartialRefund) fut le.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class StornoServiceTest {

    @InjectMocks
    private StornoService stornoService;

    @Mock private TransactionRepository transactionRepository;
    @Mock private StornoApprovalRepository stornoApprovalRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private TransactionService transactionService;
    @Mock private DictionaryRepository dictionaryRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private NotificationService notificationService;
    @Mock private org.springframework.context.ApplicationEventPublisher eventPublisher;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long TRANSACTION_ID = 100L;

    private Transaction originalCardTransaction;

    @BeforeEach
    void setUp() {
        // SecurityContext beállítása
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Alap bankkártyás tranzakció (BUY, 100 000 Ft)
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);

        Currency eur = new Currency();
        eur.setId(2L);
        eur.setCode("EUR");

        originalCardTransaction = Transaction.builder()
                .id(TRANSACTION_ID)
                .branch(branch)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .paymentMethod(PaymentMethod.CARD)
                .hufAmount(new BigDecimal("100000"))
                .currencyAmount(new BigDecimal("250.00"))
                .exchangeRate(new BigDecimal("400.00"))
                .currency(eur)
                .receiptNumber("V0316-00001")
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .posAuthorizationCode("AUTH123")
                .posReferenceNumber("REF123")
                .posTerminalId("TERM001")
                .build();

        when(transactionRepository.findById(TRANSACTION_ID))
                .thenReturn(Optional.of(originalCardTransaction));
    }

    // ─── 1. 50% visszatérítés → executePartialRefund hívódik, NEM executeReversal ───

    @Test
    @DisplayName("50% részleges visszatérítés esetén executePartialRefund hívódik, nem executeReversal")
    void halfRefund_callsExecutePartialRefund_notExecuteReversal() {
        BigDecimal refundAmount = new BigDecimal("50000"); // 50% of 100 000

        Transaction fakePartial = Transaction.builder()
                .id(200L)
                .transactionType(TransactionType.PARTIAL_REFUND)
                .receiptNumber("PR0316-00001")
                .build();
        when(transactionService.executePartialRefund(any())).thenReturn(fakePartial);
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Transaction result = stornoService.executeOtpRefund(TRANSACTION_ID, WORKER_ID, refundAmount, "teszt");

        verify(transactionService, times(1)).executePartialRefund(argThat(req ->
                req.getOriginalTransactionId().equals(TRANSACTION_ID)
                && req.getRefundHufAmount().compareTo(refundAmount) == 0));
        verify(transactionService, never()).executeReversal(any());
        assertThat(result.getTransactionType()).isEqualTo(TransactionType.PARTIAL_REFUND);
    }

    // ─── 2. Összeg > original → ValidationException ───

    @Test
    @DisplayName("Visszatérítési összeg meghaladja az eredetit → ValidationException")
    void refundAmountExceedsOriginal_throwsValidationException() {
        BigDecimal tooMuch = new BigDecimal("150000");

        assertThatThrownBy(() ->
                stornoService.executeOtpRefund(TRANSACTION_ID, WORKER_ID, tooMuch, "teszt"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem haladhatja meg");

        verify(transactionService, never()).executePartialRefund(any());
        verify(transactionService, never()).executeReversal(any());
    }

    // ─── 3. null összeg → teljes sztornó (backward compat) ───

    @Test
    @DisplayName("null refundAmount esetén teljes sztornó fut (executeReversal)")
    void nullRefundAmount_callsFullReversal() {
        Transaction fakeReversal = Transaction.builder()
                .id(201L)
                .transactionType(TransactionType.REVERSAL)
                .receiptNumber("S0316-00001")
                .build();
        when(transactionService.executeReversal(any())).thenReturn(fakeReversal);
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Transaction result = stornoService.executeOtpRefund(TRANSACTION_ID, WORKER_ID, null, "teszt");

        verify(transactionService, times(1)).executeReversal(any());
        verify(transactionService, never()).executePartialRefund(any());
        assertThat(result.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
    }

    // ─── 4. Teljes összeg → teljes sztornó ───

    @Test
    @DisplayName("refundAmount == originalHufAmount esetén teljes sztornó fut (executeReversal)")
    void fullAmountRefund_callsFullReversal() {
        BigDecimal fullAmount = new BigDecimal("100000");

        Transaction fakeReversal = Transaction.builder()
                .id(202L)
                .transactionType(TransactionType.REVERSAL)
                .receiptNumber("S0316-00002")
                .build();
        when(transactionService.executeReversal(any())).thenReturn(fakeReversal);
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Transaction result = stornoService.executeOtpRefund(TRANSACTION_ID, WORKER_ID, fullAmount, "teszt");

        verify(transactionService, times(1)).executeReversal(any());
        verify(transactionService, never()).executePartialRefund(any());
        assertThat(result.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
    }

    // ─── 5. 0 összeg → ValidationException ───

    @Test
    @DisplayName("0 összeg esetén ValidationException dobódik")
    void zeroRefundAmount_throwsValidationException() {
        assertThatThrownBy(() ->
                stornoService.executeOtpRefund(TRANSACTION_ID, WORKER_ID, BigDecimal.ZERO, "teszt"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("pozitív");

        verify(transactionService, never()).executePartialRefund(any());
        verify(transactionService, never()).executeReversal(any());
    }

    // ─── 6. Nem kártyás fizetés → ValidationException ───

    @Test
    @DisplayName("Nem bankkártyás tranzakcióra OTP visszatérítés → ValidationException")
    void cashTransaction_throwsValidationException() {
        originalCardTransaction.setPaymentMethod(PaymentMethod.CASH);

        assertThatThrownBy(() ->
                stornoService.executeOtpRefund(TRANSACTION_ID, WORKER_ID,
                        new BigDecimal("50000"), "teszt"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("bankkártyás");

        verify(transactionService, never()).executePartialRefund(any());
        verify(transactionService, never()).executeReversal(any());
    }

    // ─── 7. PARTIAL_REFUND típus a visszatérített tranzakción ───

    @Test
    @DisplayName("Részleges visszatérítés eredménye PARTIAL_REFUND típusú tranzakció")
    void partialRefund_resultHasPartialRefundType() {
        BigDecimal refundAmount = new BigDecimal("30000");

        Transaction partialResult = Transaction.builder()
                .id(203L)
                .transactionType(TransactionType.PARTIAL_REFUND)
                .partialRefundAmount(refundAmount)
                .receiptNumber("PR0316-00002")
                .build();
        when(transactionService.executePartialRefund(any())).thenReturn(partialResult);
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Transaction result = stornoService.executeOtpRefund(TRANSACTION_ID, WORKER_ID, refundAmount, "visszatérítés");

        assertThat(result.getTransactionType()).isEqualTo(TransactionType.PARTIAL_REFUND);
        assertThat(result.getPartialRefundAmount()).isEqualByComparingTo(refundAmount);
    }

    // ─── G12: sztornó jóváhagyás-kérés aktív értesítés ───
    @Test
    @DisplayName("G12: requestApproval AFTER_COMMIT értesítési eseményt publikál (nem közvetlen sendToBranch)")
    void requestApproval_publishesNotificationEvent() {
        Worker worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt Penztaros");
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));

        when(transactionRepository.countReversalsByBranchAndDate(eq(COMPANY_ID), eq(BRANCH_ID), any()))
                .thenReturn(1L);
        when(stornoApprovalRepository.save(any())).thenAnswer(inv -> {
            StornoApproval a = inv.getArgument(0);
            a.setId(java.util.UUID.randomUUID());
            return a;
        });

        stornoService.requestApproval(TRANSACTION_ID, WORKER_ID, "Teves rogzites");

        // A jóváhagyás-kérés tranzakcióján belül NEM hívunk közvetlen sendToBranch-et
        // (a rollback-only kockázat miatt), hanem AFTER_COMMIT eseményt publikálunk.
        verify(notificationService, never()).sendToBranch(any(), any(), any());
        ArgumentCaptor<StornoService.StornoApprovalNotificationEvent> cap =
                ArgumentCaptor.forClass(StornoService.StornoApprovalNotificationEvent.class);
        verify(eventPublisher, times(1)).publishEvent(cap.capture());
        assertThat(cap.getValue().branchId()).isEqualTo(BRANCH_ID);
        assertThat(cap.getValue().title()).isEqualTo("Sztornó jóváhagyás kérés");
    }

    @Test
    @DisplayName("G12: az AFTER_COMMIT listener elküldi az értesítést (sendToBranch)")
    void onStornoApprovalNotification_sendsToBranch() {
        stornoService.onStornoApprovalNotification(
                new StornoService.StornoApprovalNotificationEvent(BRANCH_ID, "Cim", "Uzenet"));

        verify(notificationService, times(1)).sendToBranch(BRANCH_ID, "Cim", "Uzenet");
    }

    @Test
    @DisplayName("G12: a listener elnyeli az értesítési hibát (best-effort)")
    void onStornoApprovalNotification_swallowsException() {
        org.mockito.Mockito.doThrow(new RuntimeException("email down"))
                .when(notificationService).sendToBranch(any(), any(), any());

        // Nem dob — a hiba elnyelve (best-effort), a jóváhagyás-kérés érintetlen.
        stornoService.onStornoApprovalNotification(
                new StornoService.StornoApprovalNotificationEvent(BRANCH_ID, "Cim", "Uzenet"));

        verify(notificationService, times(1)).sendToBranch(BRANCH_ID, "Cim", "Uzenet");
    }

    // === Audit #2 (2026-05-31) — korábbi napi tranzakció a precheck/approval úton is tiltott ===

    @Test
    @DisplayName("Audit #2: checkStorno korábbi napra DOB (nem approval-flow) — a UI ne ígérjen lehetetlen jóváhagyást")
    void checkStorno_previousDayTransaction_throwsBlocked() {
        originalCardTransaction.setTransactionDate(LocalDate.now().minusDays(1));

        assertThatThrownBy(() -> stornoService.checkStorno(TRANSACTION_ID, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("aznapi");
    }

    @Test
    @DisplayName("Audit #2: requestApproval korábbi napra DOB — ne keletkezzen elárvult jóváhagyás-kérés")
    void requestApproval_previousDayTransaction_throwsNoOrphanRequest() {
        originalCardTransaction.setTransactionDate(LocalDate.now().minusDays(1));
        Worker w = new Worker();
        w.setId(WORKER_ID);
        w.setName("Teszt Penztaros");
        Branch b = new Branch();
        b.setId(BRANCH_ID);
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(w));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(b));

        assertThatThrownBy(() -> stornoService.requestApproval(TRANSACTION_ID, WORKER_ID, "tegnapi teves"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("aznapi");
        verify(stornoApprovalRepository, never()).save(any());
    }

    // === Codex P2 (2026-05-31, #944 review) — a precheck a kikenyszeritessel (executeReversal)
    //     AZONOS branch-szintu plafon-szemantikat tukrozze: 3. = approval, 4.+ = lehetetlen. ===

    @Test
    @DisplayName("Codex P2: checkStorno 3. sztorno ma (branch count=2) -> requiresApproval=true (a UI ne ugorja at a supervisor-flow-t)")
    void checkStorno_thirdReversalToday_requiresApproval() {
        // Ma mar 2 irodai sztorno volt -> ez a 3., amit az execute supervisorhoz kot.
        when(transactionRepository.countReversalsByBranchAndDate(eq(COMPANY_ID), eq(BRANCH_ID), any()))
                .thenReturn(2L);
        when(transactionRepository.countReversalsByBranchAndWorkerAndDate(eq(COMPANY_ID), eq(BRANCH_ID), eq(WORKER_ID), any()))
                .thenReturn(0L);

        hu.puzzleir.valuta.dto.storno.StornoCheckResultDto result =
                stornoService.checkStorno(TRANSACTION_ID, WORKER_ID);

        assertThat(result.getRequiresApproval()).isTrue();
    }

    @Test
    @DisplayName("Codex P2: checkStorno 4. sztorno ma (branch count=3) -> DOB abszolut plafon (nem hasznalhatatlan approval-flow)")
    void checkStorno_fourthReversalToday_throwsBlocked() {
        // Ma mar 3 irodai sztorno volt (a plafon) -> a 4. supervisorral SEM lehetseges -> a precheck DOB.
        when(transactionRepository.countReversalsByBranchAndDate(eq(COMPANY_ID), eq(BRANCH_ID), any()))
                .thenReturn(3L);

        assertThatThrownBy(() -> stornoService.checkStorno(TRANSACTION_ID, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("plafon");
    }

    @Test
    @DisplayName("Codex P2: requestApproval 4. sztorno ma (branch count=3) -> DOB abszolut plafon, nem keletkezik elarvult jovahagyas-keres")
    void requestApproval_fourthReversalToday_throwsNoOrphanRequest() {
        Worker w = new Worker();
        w.setId(WORKER_ID);
        w.setName("Teszt Penztaros");
        Branch b = new Branch();
        b.setId(BRANCH_ID);
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(w));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(b));
        // Ma mar 3 irodai sztorno (a plafon) -> jovahagyast kerni ertelmetlen, az execute ugyis tilt.
        when(transactionRepository.countReversalsByBranchAndDate(eq(COMPANY_ID), eq(BRANCH_ID), any()))
                .thenReturn(3L);

        assertThatThrownBy(() -> stornoService.requestApproval(TRANSACTION_ID, WORKER_ID, "4. sztorno"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("plafon");
        verify(stornoApprovalRepository, never()).save(any());
    }
}
