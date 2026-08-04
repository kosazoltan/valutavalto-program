package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transfer.CreateTransferDto;
import hu.puzzleir.valuta.dto.transfer.ReceiveTransferDto;
import hu.puzzleir.valuta.dto.transfer.TransferDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * TransferService counter-transaction logika UNIT tesztek.
 * Legacy U/F/UF/FF irány kezelés tesztelése.
 */
@ExtendWith(MockitoExtension.class)
class TransferCounterTransactionTest {

    // FKH-028 5. kor: uj konstruktor-fuggoseg — mechanikus fixture-bovites (no-op mock).
    @org.mockito.Mock private TransferCreateDedupGuard createDedupGuard;

    @InjectMocks
    private TransferService transferService;

    @Mock
    private TransferRepository transferRepository;
    @Mock
    private BranchRepository branchRepository;
    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private WorkerRepository workerRepository;
    @Mock
    private CashBalanceRepository cashBalanceRepository;
    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private ReceiptSequenceService receiptSequenceService;
    @Mock
    private TransferSerialSequenceService transferSerialSequenceService;
    @Mock
    private HufDaybookSequenceService hufDaybookSequenceService;
    @Mock
    private AuditLogService auditLogService;

    @Mock
    private VaultStockFlowService vaultStockFlowService;

    @Mock
    private AccessScopeService accessScopeService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID FROM_BRANCH_ID = UUID.randomUUID();
    private static final UUID TO_BRANCH_ID = UUID.randomUUID();
    private static final Long FROM_WORKER_ID = 1L;
    private static final Long TO_WORKER_ID = 2L;
    private static final Long CURRENCY_ID = 10L;

    private Company company;
    private Branch fromBranch;
    private Branch toBranch;
    private Worker fromWorker;
    private Worker toWorker;
    private Currency currency;
    private CashBalance fromBalance;
    private CashBalance toBalance;

    @BeforeEach
    void setUp() {
        // Mockito collection defaults are empty rather than null; preserve the legacy central-role fixture.
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        company = new Company();
        company.setId(COMPANY_ID);

        fromBranch = new Branch();
        fromBranch.setId(FROM_BRANCH_ID);
        fromBranch.setCode("001");
        fromBranch.setName("Iroda 1");
        fromBranch.setCompany(company);

        toBranch = new Branch();
        toBranch.setId(TO_BRANCH_ID);
        toBranch.setCode("002");
        toBranch.setName("Iroda 2");
        toBranch.setCompany(company);

        fromWorker = new Worker();
        fromWorker.setId(FROM_WORKER_ID);
        fromWorker.setName("Teszt Pénztáros 1");
        fromWorker.setBranch(fromBranch);

        toWorker = new Worker();
        toWorker.setId(TO_WORKER_ID);
        toWorker.setName("Teszt Pénztáros 2");
        toWorker.setBranch(toBranch);

        currency = new Currency();
        currency.setId(CURRENCY_ID);
        currency.setCode("EUR");
        currency.setName("Euró");

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

    // === F mód tesztek ===

    @Test
    @DisplayName("F mód: create létrehozza a TRANSFER_OUT tranzakciót és csökkenti a küldő kassza egyenlegét")
    void fMode_createShouldCreateTransferOutAndDecreaseFromBalance() {
        // Given
        CreateTransferDto dto = createDto("F");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);

        // When
        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getDirection()).isEqualTo("F");

        // TRANSFER_OUT tranzakció létrejött
        verify(transactionRepository, times(1)).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_OUT
                        && tx.getBranch().getId().equals(FROM_BRANCH_ID)));

        // TRANSFER_IN NEM jött létre a create-nál
        verify(transactionRepository, never()).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_IN));

        // Küldő kassza csökkent. 2x find: (1) cross-branch + cash-first elo-lock (CashLockOrdering, #952),
        // (2) decreaseCashBalance no-op re-lock + mutacio (ugyanaz a sor).
        verify(cashBalanceRepository, times(2)).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(FROM_BRANCH_ID, CURRENCY_ID, COMPANY_ID);
        assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo(new BigDecimal("9500.00"));

        // CASH-FIRST (#952): a cash_balance elo-lock a bizonylatszam-generalas (receipt_sequence
        // per-branch PESSIMISTIC lock) ELOTT tortenik -> minden penzmozgato ut cash->receipt sorrendben
        // halad, nincs cash<->receipt_sequence deadlock-axis.
        InOrder cashBeforeReceipt = inOrder(cashBalanceRepository, receiptSequenceService);
        cashBeforeReceipt.verify(cashBalanceRepository).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(FROM_BRANCH_ID, CURRENCY_ID, COMPANY_ID);
        cashBeforeReceipt.verify(receiptSequenceService).generateReceiptNumber(eq(FROM_BRANCH_ID), any());

        // Fogadó kassza NEM módosult (F mód single-branch → a fogadó sort nem is elo-lockoljuk)
        verify(cashBalanceRepository, never()).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(TO_BRANCH_ID), anyLong(), any());

        // Audit log
        verify(auditLogService).log(eq("TRANSFER_CREATED"), anyString(), any(Long.class));
    }

    @Test
    @DisplayName("F mód: receive létrehozza a TRANSFER_IN tranzakciót és növeli a fogadó kassza egyenlegét")
    void fMode_receiveShouldCreateTransferInAndIncreaseToBalance() {
        // Given
        Transfer transfer = createTransfer(Transfer.TransferDirection.F, Transfer.TransferStatus.PENDING);
        when(transferRepository.findById(1L)).thenReturn(Optional.of(transfer));
        when(workerRepository.findByIdAndCompanyId(TO_WORKER_ID, COMPANY_ID)).thenReturn(Optional.of(toWorker));
        setupCashBalanceMock(TO_BRANCH_ID, toBalance);
        when(receiptSequenceService.generateReceiptNumber(eq(TO_BRANCH_ID), eq(TransactionType.TRANSFER_IN)))
                .thenReturn("U002000001");
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));
        when(transferRepository.save(any(Transfer.class))).thenAnswer(inv -> inv.getArgument(0));

        ReceiveTransferDto receiveDto = ReceiveTransferDto.builder()
                .receivedAmount(new BigDecimal("500.0000"))
                .build();

        // When
        TransferDto result = transferService.receive(1L, receiveDto, TO_WORKER_ID);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("COMPLETED");

        // TRANSFER_IN tranzakció létrejött a receive-nél
        verify(transactionRepository).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_IN
                        && tx.getBranch().getId().equals(TO_BRANCH_ID)));

        // Fogadó kassza növekedett
        assertThat(toBalance.getCurrentBalance()).isEqualByComparingTo(new BigDecimal("5500.00"));
        verify(workerRepository).findByIdAndCompanyId(TO_WORKER_ID, COMPANY_ID);
        verify(workerRepository, never()).findById(TO_WORKER_ID);
    }

    // === U mód tesztek ===

    @Test
    @DisplayName("U mód: create létrehozza a TRANSFER_IN tranzakciót a fogadó (fromBranch) irodánál és növeli annak kasszáját")
    void uMode_createShouldCreateTransferInAndIncreaseFromBalance() {
        // Given
        CreateTransferDto dto = createDto("U");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);
        lenient().when(receiptSequenceService.generateReceiptNumber(eq(FROM_BRANCH_ID), eq(TransactionType.TRANSFER_IN)))
                .thenReturn("U001000001");

        // When
        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getDirection()).isEqualTo("U");

        // TRANSFER_IN tranzakció a fogadó (fromBranch) irodánál jött létre
        verify(transactionRepository, times(1)).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_IN
                        && tx.getBranch().getId().equals(FROM_BRANCH_ID)));

        // TRANSFER_OUT NEM jött létre
        verify(transactionRepository, never()).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_OUT));

        // Fogadó (fromBranch) kassza növekedett
        assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo(new BigDecimal("10500.00"));

        // Küldő (toBranch) kassza NEM módosult
        verify(cashBalanceRepository, never()).findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(eq(TO_BRANCH_ID), anyLong(), any());
    }

    // === UF mód tesztek ===

    @Test
    @DisplayName("UF mód: create mindkét tranzakciót létrehozza és mindkét kasszát frissíti, státusz COMPLETED")
    void ufMode_createShouldCreateBothTransactionsAndUpdateBothBalances() {
        // Given
        CreateTransferDto dto = createDto("UF");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);
        setupCashBalanceMock(TO_BRANCH_ID, toBalance);
        when(receiptSequenceService.generateReceiptNumber(eq(TO_BRANCH_ID), eq(TransactionType.TRANSFER_IN)))
                .thenReturn("U002000001");

        // When
        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getDirection()).isEqualTo("UF");
        // UF módban a transfer azonnal COMPLETED
        assertThat(result.getStatus()).isEqualTo("COMPLETED");

        // TRANSFER_OUT tranzakció a küldő fióknál
        verify(transactionRepository).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_OUT
                        && tx.getBranch().getId().equals(FROM_BRANCH_ID)));

        // TRANSFER_IN tranzakció a fogadó fióknál
        verify(transactionRepository).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_IN
                        && tx.getBranch().getId().equals(TO_BRANCH_ID)));

        // Mindkét kassza frissült
        assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo(new BigDecimal("9500.00"));
        assertThat(toBalance.getCurrentBalance()).isEqualByComparingTo(new BigDecimal("5500.00"));
    }

    // === FF mód tesztek ===

    @Test
    @DisplayName("FF mód: create két TRANSFER_OUT tranzakciót hoz létre és mindkét kasszát csökkenti")
    void ffMode_createShouldCreateTwoTransferOutAndDecreaseBothBalances() {
        // Given
        CreateTransferDto dto = createDto("FF");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);
        setupCashBalanceMock(TO_BRANCH_ID, toBalance);
        when(receiptSequenceService.generateReceiptNumber(eq(TO_BRANCH_ID), eq(TransactionType.TRANSFER_OUT)))
                .thenReturn("F002000001");

        // When
        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getDirection()).isEqualTo("FF");

        // Két TRANSFER_OUT tranzakció
        verify(transactionRepository, times(2)).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_OUT));

        // TRANSFER_IN NEM jött létre
        verify(transactionRepository, never()).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_IN));

        // Mindkét kassza csökkent
        assertThat(fromBalance.getCurrentBalance()).isEqualByComparingTo(new BigDecimal("9500.00"));
        assertThat(toBalance.getCurrentBalance()).isEqualByComparingTo(new BigDecimal("4500.00"));
    }

    // === Default direction teszt ===

    @Test
    @DisplayName("Null direction default UF módot használ")
    void nullDirection_shouldDefaultToUF() {
        // Given
        CreateTransferDto dto = createDto(null);
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);
        setupCashBalanceMock(TO_BRANCH_ID, toBalance);
        when(receiptSequenceService.generateReceiptNumber(eq(TO_BRANCH_ID), eq(TransactionType.TRANSFER_IN)))
                .thenReturn("U002000001");

        // When
        TransferDto result = transferService.create(dto, FROM_WORKER_ID);

        // Then
        assertThat(result.getDirection()).isEqualTo("UF");
        assertThat(result.getStatus()).isEqualTo("COMPLETED");

        // Mindkét tranzakció létrejött
        verify(transactionRepository).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_OUT));
        verify(transactionRepository).save(argThat(tx ->
                tx.getTransactionType() == TransactionType.TRANSFER_IN));
    }

    // === Negatív kassza védelem ===

    @Test
    @DisplayName("F mód: nem elegendő egyenleg esetén ValidationException")
    void fMode_insufficientBalance_shouldThrowValidationException() {
        // Given
        fromBalance.setCurrentBalance(new BigDecimal("100.00")); // kevesebb mint 500
        CreateTransferDto dto = createDto("F");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);

        // When/Then
        assertThatThrownBy(() -> transferService.create(dto, FROM_WORKER_ID))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("egyenlege nem elegendő");
    }

    // === Bizonylat szám generálás ===

    @Test
    @DisplayName("TRANSFER_OUT és TRANSFER_IN bizonylat számok generálódnak")
    void receiptNumbers_shouldBeGenerated() {
        // Given
        CreateTransferDto dto = createDto("UF");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);
        setupCashBalanceMock(TO_BRANCH_ID, toBalance);
        when(receiptSequenceService.generateReceiptNumber(eq(FROM_BRANCH_ID), eq(TransactionType.TRANSFER_OUT)))
                .thenReturn("F001000001");
        when(receiptSequenceService.generateReceiptNumber(eq(TO_BRANCH_ID), eq(TransactionType.TRANSFER_IN)))
                .thenReturn("U002000001");

        // When
        transferService.create(dto, FROM_WORKER_ID);

        // Then
        verify(receiptSequenceService).generateReceiptNumber(FROM_BRANCH_ID, TransactionType.TRANSFER_OUT);
        verify(receiptSequenceService).generateReceiptNumber(TO_BRANCH_ID, TransactionType.TRANSFER_IN);
    }

    // === Reference number teszt ===

    @Test
    @DisplayName("Counter-tranzakciók referenceNumber-je a transfer számra mutat")
    void counterTransactions_shouldReferenceTransferNumber() {
        // Given
        CreateTransferDto dto = createDto("F");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);

        // When
        transferService.create(dto, FROM_WORKER_ID);

        // Then
        // Az átadás-átvétel sorszám cégszintű formátuma: AT/AV/FF/UF-NNNNNN
        // (a counter-tranzakció erre a számra hivatkozik).
        verify(transactionRepository).save(argThat(tx ->
                tx.getReferenceNumber() != null && tx.getReferenceNumber().matches("^(AT|AV|FF|UF)-\\d{6}$")));
    }

    // === Audit log tesztek ===

    @Test
    @DisplayName("Audit log bejegyzés jön létre minden transfer lépésnél")
    void auditLog_shouldBeCreatedForEachStep() {
        // Given
        CreateTransferDto dto = createDto("F");
        setupCommonMocks();
        setupCashBalanceMock(FROM_BRANCH_ID, fromBalance);

        // When
        transferService.create(dto, FROM_WORKER_ID);

        // Then
        verify(auditLogService).log(eq("TRANSFER_CREATED"), anyString(), any(Long.class));
    }

    // === Helper methods ===

    private CreateTransferDto createDto(String direction) {
        return CreateTransferDto.builder()
                .toBranchId(TO_BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("500.0000"))
                .hufValue(new BigDecimal("190000.00"))
                .transferType("CURRENCY")
                .direction(direction)
                .build();
    }

    private Transfer createTransfer(Transfer.TransferDirection direction, Transfer.TransferStatus status) {
        return Transfer.builder()
                .id(1L)
                .transferNumber("TR-20260319-0001")
                .companyId(COMPANY_ID)
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .fromWorker(fromWorker)
                .transferType(Transfer.TransferType.CURRENCY)
                .status(status)
                .transferDate(java.time.LocalDate.now())
                .transferTime(java.time.LocalTime.now())
                .currency(currency)
                .amount(new BigDecimal("500.0000"))
                .hufValue(new BigDecimal("190000.00"))
                .direction(direction)
                .build();
    }

    private void setupCommonMocks() {
        when(workerRepository.findById(FROM_WORKER_ID)).thenReturn(Optional.of(fromWorker));
        when(branchRepository.findById(TO_BRANCH_ID)).thenReturn(Optional.of(toBranch));
        // IDOR-guard (audit 2026-06-15): create() ellenőrzi, hogy a cél-fiók a forrás cégéhez tartozik.
        when(branchRepository.existsByIdAndCompanyId(eq(TO_BRANCH_ID), eq(COMPANY_ID))).thenReturn(true);
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(currency));
        when(transferRepository.save(any(Transfer.class))).thenAnswer(inv -> {
            Transfer t = inv.getArgument(0);
            if (t.getId() == null) t.setId(1L);
            return t;
        });
        lenient().when(transferSerialSequenceService.next(any(), anyString())).thenReturn(1L);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));
        // Default receipt number mock
        lenient().when(receiptSequenceService.generateReceiptNumber(eq(FROM_BRANCH_ID), eq(TransactionType.TRANSFER_OUT)))
                .thenReturn("F001000001");
        lenient().when(receiptSequenceService.generateReceiptNumber(eq(TO_BRANCH_ID), eq(TransactionType.TRANSFER_IN)))
                .thenReturn("U002000001");
        lenient().when(receiptSequenceService.generateReceiptNumber(eq(TO_BRANCH_ID), eq(TransactionType.TRANSFER_OUT)))
                .thenReturn("F002000001");
    }

    private void setupCashBalanceMock(UUID branchId, CashBalance balance) {
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(branchId, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
    }
}
