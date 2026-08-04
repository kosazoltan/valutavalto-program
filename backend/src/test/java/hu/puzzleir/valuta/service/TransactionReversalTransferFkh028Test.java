package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-028 Fázis 3: a teljes sztornó-útvonal (executeReversal) TRANSFER_OUT/TRANSFER_IN
 * ága. A mai kód a BUY/SELL if-else után némán kiesik — a REVERSAL tranzakció létrejön,
 * de a cash_balance NEM áll vissza (készlet-eltérés marad a fiókban).
 *
 * Elvárt új viselkedés (a BUY/SELL minta alapján, DE a transfer-tranzakciónak NINCS
 * HUF-ellenlába — egylábú készletmozgás):
 *  - eredeti TRANSFER_OUT (pénz KI a fiókból) sztornója: valuta VISSZA (+), HUF érintetlen;
 *  - eredeti TRANSFER_IN (pénz BE a fiókba) sztornója: valuta KI (-) készlet-validációval,
 *    HUF érintetlen.
 *
 * A részleges-visszaváltás útvonala (428-434. sor környéke) SZÁNDÉKOSAN nem része a
 * körnek (FKH-028 scope-döntés) — arra itt nincs teszt.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionReversalTransferFkh028Test {

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
    @Mock private WacService wacService;
    @Mock private CustomerRepository customerRepository;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;
    private static final Long USD_ID = 11L;
    private static final Long HUF_ID = 1L;

    private Company company;
    private Branch branch;
    private Worker worker;
    private Currency usdCurrency;

    @BeforeEach
    void setUp() {
        company = new Company();
        company.setId(COMPANY_ID);
        company.setName("Test Ceg");

        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCode("BR035");
        branch.setName("Teszt Penztar");

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt Penztaros");

        usdCurrency = new Currency();
        usdCurrency.setId(USD_ID);
        usdCurrency.setCode("USD");
        usdCurrency.setName("USA dollar");

        when(receiptSequenceService.generateReversalReceiptNumber(any(), any()))
                .thenReturn("STORNO-001");
        when(helper.getHufCurrencyId()).thenReturn(HUF_ID);
        when(helper.getDailyReversalLimit()).thenReturn(3);
        when(customerRepository.findByCustomerCodeAndCompanyId(any(), any()))
                .thenReturn(Optional.empty());
        when(dailySessionService.getDailyReversalCountForUpdate()).thenReturn(0);
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction t = inv.getArgument(0);
            if (t.getId() == null) {
                t.setId(200L);
            }
            return t;
        });
    }

    private Transaction transferTransaction(TransactionType type) {
        return Transaction.builder()
                .id(100L)
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber("AA035100002")
                .transactionType(type)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(usdCurrency)
                .currencyAmount(new BigDecimal("1000"))
                .exchangeRate(new BigDecimal("340.00"))
                .hufAmount(new BigDecimal("340000"))
                .handlingFee(BigDecimal.ZERO)
                .discountPercent(BigDecimal.ZERO)
                .discountAmount(BigDecimal.ZERO)
                .build();
    }

    private Transaction executeReversalOf(TransactionType type) {
        when(transactionRepository.findByIdForUpdate(100L))
                .thenReturn(Optional.of(transferTransaction(type)));

        TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                .originalTransactionId(100L)
                .reason("Duplikalt atadas rendezese")
                .approvedBy("SUPERVISOR")
                .build();

        return reversalService.executeReversal(request);
    }

    @Test
    @DisplayName("FKH-028: TRANSFER_OUT sztornó → a valuta VISSZAÁLL a kasszába (+), HUF-ellenláb NINCS")
    void transferOutReversal_restoresCashBalance_withoutHufLeg() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

            Transaction reversal = executeReversalOf(TransactionType.TRANSFER_OUT);

            assertThat(reversal.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
            // Eredeti kimenő átadás visszavonása: a valuta visszakerül a kasszába.
            verify(helper).updateCashBalance(
                    eq(BRANCH_ID), eq(USD_ID), eq(new BigDecimal("1000")), eq(true));
            // Egylábú készletmozgás: HUF-ellenláb SOSEM mozoghat transfer-sztornónál.
            verify(helper, never()).updateCashBalance(eq(BRANCH_ID), eq(HUF_ID), any(), anyBoolean());
        }
    }

    @Test
    @DisplayName("FKH-028/V370-guard: a V370-korrekcióval jelölt tranzakcióra a sztornó 409-cel elutasítva, kassza-mozgás és mentés NÉLKÜL")
    void v370MarkedTransaction_stornoRejected() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

            Transaction marked = transferTransaction(TransactionType.TRANSFER_OUT);
            marked.setNotes("[FKH-028 V370] duplikalt tetel — az egyenleg-korrekcio a V370 migracioban rendezve; app-szintu sztorno TILOS ra.");
            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(marked));

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("Duplikalt atadas rendezese")
                    .approvedBy("SUPERVISOR")
                    .build();

            org.assertj.core.api.Assertions.assertThatThrownBy(() -> reversalService.executeReversal(request))
                    .isInstanceOf(hu.puzzleir.valuta.exception.ConflictException.class)
                    .hasMessageContaining("V370");

            verify(helper, never()).updateCashBalance(any(), any(), any(), anyBoolean());
            verify(transactionRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("FKH-028/5.kör HIGH-1: idegen iroda V370-jelölt bizonylatára a sztornó-elutasítás NEM különböztethető meg a jelöletlen esettől (nincs V370-infó-szivárgás)")
    void foreignBranchStorno_uniformRejection_noV370Leak() {
        UUID foreignBranchId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            // A hívó egy MÁSIK iroda dolgozója.
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(foreignBranchId);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

            TransactionService.ReversalRequest request = TransactionService.ReversalRequest.builder()
                    .originalTransactionId(100L)
                    .reason("Idegen sztorno kiserlet")
                    .approvedBy("SUPERVISOR")
                    .build();

            // (1) V370-jelölt idegen bizonylat
            Transaction marked = transferTransaction(TransactionType.TRANSFER_OUT);
            marked.setNotes("[FKH-028 V370] duplikalt tetel — rendezve.");
            when(transactionRepository.findByIdForUpdate(100L)).thenReturn(Optional.of(marked));
            String markedMessage = org.assertj.core.api.Assertions.catchThrowable(
                    () -> reversalService.executeReversal(request)).getMessage();

            // (2) jelöletlen idegen bizonylat
            when(transactionRepository.findByIdForUpdate(100L))
                    .thenReturn(Optional.of(transferTransaction(TransactionType.TRANSFER_OUT)));
            String unmarkedMessage = org.assertj.core.api.Assertions.catchThrowable(
                    () -> reversalService.executeReversal(request)).getMessage();

            // A tulajdonjog-guard fut ELŐSZÖR: mindkét eset UGYANAZT a hibát adja,
            // a V370-státusz nem szivároghat idegen iroda felé.
            org.assertj.core.api.Assertions.assertThat(markedMessage)
                    .as("Idegen+jelölt eset üzenete a tulajdonjog-hiba, nem a V370-guard")
                    .doesNotContain("V370")
                    .isEqualTo(unmarkedMessage);
        }
    }

    @Test
    @DisplayName("FKH-028: TRANSFER_IN sztornó → a valuta KIKERÜL a kasszából (-) készlet-validációval, HUF-ellenláb NINCS")
    void transferInReversal_removesCashBalance_withStockValidation_withoutHufLeg() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(BRANCH_ID);
            secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(WORKER_ID);
            secUtils.when(SecurityUtils::isSupervisorOrAbove).thenReturn(true);

            Transaction reversal = executeReversalOf(TransactionType.TRANSFER_IN);

            assertThat(reversal.getTransactionType()).isEqualTo(TransactionType.REVERSAL);
            // Eredeti bejövő átvétel visszavonása: van-e még ennyi a kasszában, majd kivét.
            verify(helper).validateCurrencyStock(eq(BRANCH_ID), eq(USD_ID), eq(new BigDecimal("1000")));
            verify(helper).updateCashBalance(
                    eq(BRANCH_ID), eq(USD_ID), eq(new BigDecimal("1000").negate()), eq(false));
            verify(helper, never()).updateCashBalance(eq(BRANCH_ID), eq(HUF_ID), any(), anyBoolean());
        }
    }
}
