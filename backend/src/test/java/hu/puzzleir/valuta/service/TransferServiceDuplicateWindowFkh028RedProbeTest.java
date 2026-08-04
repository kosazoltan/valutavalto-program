package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ConflictException;
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

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * FKH-028 Fázis 2 — ELDOBHATÓ RED-PROBE (ld. memory: red-teszt-mockito-strict-stubs-csapda).
 *
 * A végleges duplikátum-védelem új repository-metódust vezet be, amit a RED fázisban még
 * nem lehet stubolni (nem fordulna a teszt) — ezért ez a próba a MAI viselkedést fogja meg:
 * két, azonos paraméterű create() hívás gyors egymásutánban ma MINDKÉTSZER sikeres
 * (két transfer jön létre). Az elvárt új viselkedés: a második hívás a rövid időablakon
 * belül ConflictException-nel elutasítva.
 *
 * GREEN után ez a fájl TÖRLENDŐ, és a végleges (az új repo-metódust stuboló) teszt veszi át.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransferServiceDuplicateWindowFkh028RedProbeTest {

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
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L, 2L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                        eq(fromId), anyLong(), eq(company.getId())))
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
    @DisplayName("RED-PROBE: két azonos create() gyors egymásutánban → a másodiknak ConflictException kell legyen")
    void secondIdenticalCreateWithinWindow_rejected() {
        service.create(dto(), 1L);

        assertThatThrownBy(() -> service.create(dto(), 1L))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("duplik");
    }
}
