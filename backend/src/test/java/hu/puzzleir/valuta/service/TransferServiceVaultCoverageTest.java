package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
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

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransferServiceVaultCoverageTest {

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
    // FKH-028 5. kor: uj konstruktor-fuggoseg — mechanikus fixture-bovites (no-op mock),
    // a HufDaybookSequenceService-precedens szerint; assert nem valtozott.
    @Mock private TransferCreateDedupGuard createDedupGuard;
    @InjectMocks private TransferService service;

    @BeforeEach
    void setUpAccessScope() {
        // Mockito collection defaults are empty rather than null; preserve the legacy central-role fixture.
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @Test
    @DisplayName("FK-053: vault-forrású F átadás elégtelen currency_stockkal a sorszám és pénzmozgás előtt blokkol")
    void create_fromVault_insufficientVaultStock_blocksBeforeMoneyMovement() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromVault = Branch.builder()
                .id(fromId)
                .code("BR105")
                .company(company)
                .isVault(true)
                .vaultTerritoryId(1)
                .build();
        Branch toBranch = Branch.builder().id(toId).code("BR035").company(company).isVault(false).build();
        Worker worker = Worker.builder().id(1L).branch(fromVault).build();
        Currency eur = Currency.builder().id(978L).code("EUR").name("Euró").build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(toId, company.getId())).thenReturn(true);
        when(currencyRepository.findById(978L)).thenReturn(Optional.of(eur));
        doThrow(new ValidationException("Nincs elegendő értéktári EUR készlet! Elérhető: 0.00, szükséges: 5000.00 "
                + "(territory: 1). A művelet nem hajtható végre — készleten túli forgalmazás tiltva."))
                .when(vaultStockFlowService).validateVaultStockCoverage(fromVault, "EUR", new BigDecimal("5000.00"));

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(978L);
        dto.setAmount(new BigDecimal("5000.00"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");

        assertThatThrownBy(() -> service.create(dto, 1L))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs elegendő értéktári EUR készlet")
                .hasMessageContaining("készleten túli forgalmazás tiltva");

        verify(transferSerialSequenceService, never()).next(any(), anyString());
        verify(transferRepository, never()).save(any(Transfer.class));
        verify(transactionRepository, never()).save(any(Transaction.class));
        verify(cashBalanceRepository, never()).save(any(CashBalance.class));
    }

    @Test
    @DisplayName("FK-053: vault-forrású F átadás fedezettel lefut, cash_balance és currency_stock mirror is csökken")
    void create_fromVault_withVaultStockCoverage_booksCashAndVaultMirror() {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch fromVault = Branch.builder()
                .id(fromId)
                .code("BR105")
                .company(company)
                .isVault(true)
                .vaultTerritoryId(1)
                .build();
        Branch toBranch = Branch.builder().id(toId).code("BR035").company(company).isVault(false).build();
        Worker worker = Worker.builder().id(1L).branch(fromVault).build();
        Currency eur = Currency.builder().id(978L).code("EUR").name("Euró").build();
        CashBalance fromBalance = CashBalance.builder().currentBalance(new BigDecimal("6000.00")).currency(eur).build();

        when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
        when(branchRepository.findById(toId)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(toId, company.getId())).thenReturn(true);
        when(currencyRepository.findById(978L)).thenReturn(Optional.of(eur));
        when(transferSerialSequenceService.next(any(), eq("AT"))).thenReturn(1L);
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-001");
        when(transactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(fromId), anyLong(), eq(company.getId())))
                .thenReturn(Optional.of(fromBalance));

        CreateTransferDto dto = new CreateTransferDto();
        dto.setToBranchId(toId.toString());
        dto.setCurrencyId(978L);
        dto.setAmount(new BigDecimal("5000.00"));
        dto.setTransferType("CURRENCY");
        dto.setDirection("F");

        TransferDto result = service.create(dto, 1L);

        assertThat(result.getTransferNumber()).isEqualTo("AT-000001");
        assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo("1000.00");
        verify(vaultStockFlowService, times(2)).validateVaultStockCoverage(fromVault, "EUR", new BigDecimal("5000.00"));
        verify(vaultStockFlowService).applyGenericVaultStock(fromVault, "EUR", new BigDecimal("5000.00"), false);
    }
}
