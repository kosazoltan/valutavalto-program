package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
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

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-113 FR-1 / FR-2: ERB/FRB/TRB/PRB to a VAULT_COUNTERPARTY auto-completes on create
 * and COMPLETED storno skips the partner side.
 */
@ExtendWith(MockitoExtension.class)
class TransferVaultCounterpartyFk113Test {

    @Mock private TransferCreateDedupGuard createDedupGuard;
    @InjectMocks private TransferService transferService;
    @Mock private TransferRepository transferRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private ReceiptSequenceService receiptSequenceService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private HufDaybookSequenceService hufDaybookSequenceService;
    @Mock private AuditLogService auditLogService;
    @Mock private VaultStockFlowService vaultStockFlowService;
    @Mock private AccessScopeService accessScopeService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID FROM_BRANCH_ID = UUID.randomUUID();
    private static final UUID TO_BRANCH_ID = UUID.randomUUID();
    private static final Long FROM_WORKER_ID = 1L;
    private static final Long CURRENCY_ID = 10L;

    private Company company;
    private Branch fromBranch;
    private Branch toBranch;
    private Worker fromWorker;
    private Currency currency;
    private CashBalance fromBalance;
    private CashBalance toBalance;

    @BeforeEach
    void setUp() {
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        company = new Company();
        company.setId(COMPANY_ID);

        fromBranch = new Branch();
        fromBranch.setId(FROM_BRANCH_ID);
        fromBranch.setCode("001");
        fromBranch.setName("Ertektar");
        fromBranch.setCompany(company);
        fromBranch.setIsVault(true);

        toBranch = new Branch();
        toBranch.setId(TO_BRANCH_ID);
        toBranch.setCode("ERB");
        toBranch.setName("Raiffeisen");
        toBranch.setCompany(company);
        toBranch.setIsVault(false);
        toBranch.setBranchType(Dictionary.builder().code("VAULT_COUNTERPARTY").build());

        fromWorker = new Worker();
        fromWorker.setId(FROM_WORKER_ID);
        fromWorker.setName("Kovacs Anna");
        fromWorker.setBranch(fromBranch);

        currency = new Currency();
        currency.setId(CURRENCY_ID);
        currency.setCode("EUR");
        currency.setName("Euro");

        fromBalance = CashBalance.builder()
                .id(1L)
                .company(company)
                .branch(fromBranch)
                .currency(currency)
                .currentBalance(new BigDecimal("10000.00"))
                .build();
        toBalance = CashBalance.builder()
                .id(2L)
                .company(company)
                .branch(toBranch)
                .currency(currency)
                .currentBalance(new BigDecimal("5000.00"))
                .build();
    }

    @Test
    @DisplayName("FK-113 FR-1: ERB F VAULT_COUNTERPARTY azonnal COMPLETED, partner-kassza intatlan")
    void erbHandoverToCounterpartyAutoCompletesWithoutPartnerCash() {
        CreateTransferDto dto = dto("F", "ERB");
        setupCreateMocks();
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                FROM_BRANCH_ID, CURRENCY_ID, COMPANY_ID)).thenReturn(Optional.of(fromBalance));

        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo("9500.00");
        verify(transactionRepository).save(org.mockito.ArgumentMatchers.argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_OUT
                        && tx.getBranch().getId().equals(FROM_BRANCH_ID)));
        verify(transactionRepository, never()).save(org.mockito.ArgumentMatchers.argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_IN));
        verify(cashBalanceRepository, never())
                .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(TO_BRANCH_ID), anyLong(), any());
        verify(auditLogService).log(eq("TRANSFER_AUTO_COMPLETED"), contains("igazoló dolgozó: NINCS"), any(Long.class));
        assertThat(toBalance.getCurrentBalance()).isEqualByComparingTo("5000.00");
    }

    @Test
    @DisplayName("FK-113 FR-1: ERB U VAULT_COUNTERPARTY azonnal COMPLETED")
    void erbReceiptFromCounterpartyAutoCompletes() {
        CreateTransferDto dto = dto("U", "ERB");
        setupCreateMocks();
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                FROM_BRANCH_ID, CURRENCY_ID, COMPANY_ID)).thenReturn(Optional.of(fromBalance));
        lenient().when(receiptSequenceService.generateReceiptNumber(eq(FROM_BRANCH_ID), eq(TransactionType.TRANSFER_IN)))
                .thenReturn("U001000001");

        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo("10500.00");
        verify(auditLogService).log(eq("TRANSFER_AUTO_COMPLETED"), contains("irány: U"), any(Long.class));
        verify(cashBalanceRepository, never())
                .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(TO_BRANCH_ID), anyLong(), any());
    }

    @Test
    @DisplayName("FK-113 FR-1: peer-vault ERB F PENDING marad — emberi receive kell")
    void erbHandoverToPeerVaultStaysPending() {
        toBranch.setIsVault(true);
        toBranch.setBranchType(Dictionary.builder().code("VAULT").build());
        CreateTransferDto dto = dto("F", "ERB");
        setupCreateMocks();
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                FROM_BRANCH_ID, CURRENCY_ID, COMPANY_ID)).thenReturn(Optional.of(fromBalance));

        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("PENDING");
        verify(auditLogService, never()).log(eq("TRANSFER_AUTO_COMPLETED"), anyString(), any(Long.class));
    }

    @Test
    @DisplayName("FK-113 FR-1: CURRENCY F VAULT_COUNTERPARTY nem záródik automatikusan")
    void nonRbToCounterpartyStaysPending() {
        fromBranch.setIsVault(false);
        CreateTransferDto dto = dto("F", "CURRENCY");
        setupCreateMocks();
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                FROM_BRANCH_ID, CURRENCY_ID, COMPANY_ID)).thenReturn(Optional.of(fromBalance));

        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("PENDING");
        verify(auditLogService, never()).log(eq("TRANSFER_AUTO_COMPLETED"), anyString(), any(Long.class));
    }

    @Test
    @DisplayName("FK-113 FR-2: COMPLETED F counterparty sztornó csak a sajat oldalt forditja")
    void completedCounterpartyStornoSkipsPartnerSide() {
        Transfer transfer = Transfer.builder()
                .id(50L)
                .transferNumber("AT-000113")
                .companyId(COMPANY_ID)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(fromWorker)
                .transferType(Transfer.TransferType.ERB)
                .direction(Transfer.TransferDirection.F)
                .status(Transfer.TransferStatus.COMPLETED)
                .transferDate(java.time.LocalDate.now())
                .transferTime(java.time.LocalTime.now())
                .currency(currency)
                .amount(new BigDecimal("500.0000"))
                .receivedAmount(new BigDecimal("500.0000"))
                .isCancelled(false)
                .build();
        when(transferRepository.findByIdForUpdate(50L)).thenReturn(Optional.of(transfer));
        when(transferRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(workerRepository.findById(FROM_WORKER_ID)).thenReturn(Optional.of(fromWorker));
        when(receiptSequenceService.generateReceiptNumber(any(), any())).thenReturn("R-SZ-1");
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
                FROM_BRANCH_ID, CURRENCY_ID, COMPANY_ID)).thenReturn(Optional.of(fromBalance));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(FROM_WORKER_ID);
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(FROM_BRANCH_ID);

            TransferDto result = transferService.storno(50L, "Banki tétel visszavonása");

            assertThat(result.getIsCancelled()).isTrue();
            assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo("10500.00");
            assertThat(toBalance.getCurrentBalance()).isEqualByComparingTo("5000.00");
            verify(cashBalanceRepository, never())
                    .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(TO_BRANCH_ID), anyLong(), any());
            verify(transactionRepository).save(org.mockito.ArgumentMatchers.argThat(tx ->
                    tx.getTransactionType() == TransactionType.TRANSFER_IN
                            && tx.getBranch().getId().equals(FROM_BRANCH_ID)));
            verify(transactionRepository, never()).save(org.mockito.ArgumentMatchers.argThat(tx ->
                    tx.getBranch() != null && TO_BRANCH_ID.equals(tx.getBranch().getId())));
        }
    }

    @Test
    @DisplayName("FK-113: a diszkriminator null-safe")
    void counterpartyDiscriminatorIsNullSafe() {
        assertThat(TransferService.isVaultCounterpartyTarget(null)).isFalse();
        Transfer noTo = Transfer.builder().fromBranch(fromBranch).build();
        assertThat(TransferService.isVaultCounterpartyTarget(noTo)).isFalse();
        toBranch.setBranchType(null);
        Transfer noType = Transfer.builder().toBranch(toBranch).build();
        assertThat(TransferService.isVaultCounterpartyTarget(noType)).isFalse();
    }

    private CreateTransferDto dto(String direction, String type) {
        return CreateTransferDto.builder()
                .toBranchId(TO_BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("500.0000"))
                .hufValue(new BigDecimal("190000.00"))
                .transferType(type)
                .direction(direction)
                .build();
    }

    private void setupCreateMocks() {
        when(workerRepository.findById(FROM_WORKER_ID)).thenReturn(Optional.of(fromWorker));
        when(branchRepository.findById(TO_BRANCH_ID)).thenReturn(Optional.of(toBranch));
        when(branchRepository.existsByIdAndCompanyId(eq(TO_BRANCH_ID), eq(COMPANY_ID))).thenReturn(true);
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(currency));
        when(transferRepository.save(any(Transfer.class))).thenAnswer(inv -> {
            Transfer t = inv.getArgument(0);
            if (t.getId() == null) {
                t.setId(1L);
            }
            return t;
        });
        lenient().when(transferSerialSequenceService.next(any(), anyString())).thenReturn(1L);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(receiptSequenceService.generateReceiptNumber(eq(FROM_BRANCH_ID), eq(TransactionType.TRANSFER_OUT)))
                .thenReturn("F001000001");
    }
}
