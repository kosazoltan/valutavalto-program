package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-028 6. kör (Codex MEDIUM): a dedup-kulcs feloldásának (release) hibája nem
 * maradhat az órás TTL/cleanup-ra — az afterCompletion-ből hívott release gyors,
 * korlátos újrapróbálkozást kap; végleges bukásnál a kivétel NEM terjed tovább
 * (log.error), a beragadt kulcsot pedig az acquire stale-átvétele oldja fel.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransferServiceDedupReleaseRetryFkh028Test {

    @Mock private TransferRepository transferRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private HufDaybookSequenceService hufDaybookSequenceService;
    @Mock private AuditLogService auditLogService;
    @Mock private VaultStockFlowService vaultStockFlowService;
    @Mock private AccessScopeService accessScopeService;
    @Mock private TransferCreateDedupGuard createDedupGuard;
    @InjectMocks private TransferService service;

    private final UUID fromId = UUID.randomUUID();
    private final UUID toId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromBranch = Branch.builder().id(fromId).code("BR076").company(company).build();
        Branch toBranch = Branch.builder().id(toId).code("BR001").company(company).build();
        Worker worker = Worker.builder().id(1L).branch(fromBranch).build();
        Currency eur = Currency.builder().id(4L).code("EUR").name("Euró").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(toId), any())).thenReturn(true);
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(eur));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                        eq(fromId), anyLong(), any()))
                .thenAnswer(inv -> Optional.of(
                        CashBalance.builder().currentBalance(new BigDecimal("100000")).build()));
    }

    private CreateTransferDto dto() {
        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(4L);
        dto.setAmount(new BigDecimal("1000"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");
        return dto;
    }

    @Test
    @DisplayName("MEDIUM: a release() átmeneti hibáinál gyors retry fut (3. kísérletre siker), kivétel nem terjed tovább")
    void releaseTransientFailure_retriedQuickly() {
        doThrow(new RuntimeException("REQUIRES_NEW tx hiba (szimulált)"))
                .doThrow(new RuntimeException("REQUIRES_NEW tx hiba (szimulált)"))
                .doNothing()
                .when(createDedupGuard).release(any(), any(), anyBoolean());

        TransactionSynchronizationManager.initSynchronization();
        try {
            service.create(dto(), 1L);
            List<TransactionSynchronization> syncs =
                    List.copyOf(TransactionSynchronizationManager.getSynchronizations());
            assertThatCode(() -> {
                for (TransactionSynchronization sync : syncs) {
                    sync.afterCompletion(TransactionSynchronization.STATUS_COMMITTED);
                }
            }).as("A release-hiba nem terjedhet ki az afterCompletion-ből")
                    .doesNotThrowAnyException();
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }

        verify(createDedupGuard, times(3)).release(any(), any(), eq(true));
    }

    @Test
    @DisplayName("MEDIUM: végleges release-bukásnál sincs kivétel-terjedés (a beragadt kulcsot az acquire stale-átvétele oldja)")
    void releasePermanentFailure_doesNotPropagate() {
        doThrow(new RuntimeException("tartós DB-hiba (szimulált)"))
                .when(createDedupGuard).release(any(), any(), anyBoolean());

        TransactionSynchronizationManager.initSynchronization();
        try {
            service.create(dto(), 1L);
            List<TransactionSynchronization> syncs =
                    List.copyOf(TransactionSynchronizationManager.getSynchronizations());
            assertThatCode(() -> {
                for (TransactionSynchronization sync : syncs) {
                    sync.afterCompletion(TransactionSynchronization.STATUS_COMMITTED);
                }
            }).doesNotThrowAnyException();
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }

        verify(createDedupGuard, times(3)).release(any(), any(), eq(true));
    }
}
