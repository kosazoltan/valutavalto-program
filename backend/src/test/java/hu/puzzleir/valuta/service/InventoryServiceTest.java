package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.inventory.BankDepositRequestDto;
import hu.puzzleir.valuta.dto.inventory.BranchTransferRequestDto;
import hu.puzzleir.valuta.dto.inventory.InventoryMovementDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.data.domain.Page;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * InventoryService unit tesztek — Mockito.
 *
 * Fix #1: depositToBank PENDING státusz (négy-szem elv)
 * Fix #2: transferBetweenBranches forrás-készlet ellenőrzés
 * Fix #3: getAllStock @Transactional(readOnly=true)
 * Fix #4: hufValue árfolyamból számítva
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT) // megosztott statikus SecurityUtils-stub minden teszthez
class InventoryServiceTest {

    @InjectMocks
    private InventoryService inventoryService;

    @Mock private InventoryMovementRepository movementRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private InventoryStockAccessor stockAccessor;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OTHER_COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID_2 = UUID.randomUUID();
    private static final Long CURRENCY_ID = 1L;
    private static final Long WORKER_ID = 10L;

    private Branch branch;
    private Branch branch2;
    private Company company;
    private Currency eurCurrency;
    private Currency hufCurrency;
    private Worker worker;

    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

        company = new Company();
        company.setId(COMPANY_ID);

        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setName("Teszt iroda 1");
        branch.setCompany(company);

        branch2 = new Branch();
        branch2.setId(BRANCH_ID_2);
        branch2.setName("Teszt iroda 2");
        branch2.setCompany(company);

        eurCurrency = new Currency();
        eurCurrency.setId(CURRENCY_ID);
        eurCurrency.setCode("EUR");
        eurCurrency.setName("Euró");

        hufCurrency = new Currency();
        hufCurrency.setId(2L);
        hufCurrency.setCode("HUF");
        hufCurrency.setName("Magyar forint");

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Teszt dolgozó");

        lenient().when(stockAccessor.getBalance(branch, eurCurrency)).thenReturn(new BigDecimal("5000"));
        lenient().when(stockAccessor.getBalance(branch, hufCurrency)).thenReturn(new BigDecimal("100000"));
        lenient().when(stockAccessor.getBalance(branch2, eurCurrency)).thenReturn(new BigDecimal("500"));
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) {
            securityUtilsMock.close();
        }
    }

    // ============ Fix #1: depositToBank — PENDING státusz ============

    @Test
    @DisplayName("depositToBank: PENDING státuszt kell létrehozni (nem APPROVED)")
    void depositToBank_createsPendingMovement() {
        // Arrange
        BankDepositRequestDto dto = BankDepositRequestDto.builder()
                .branchId(BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("1000"))
                .notes("Teszt befizetés")
                .build();

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode(any(), eq("EUR")))
                .thenReturn(Optional.of(new BigDecimal("390")));

        InventoryMovement savedMovement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING, eurCurrency, branch, null);
        when(movementRepository.save(any(InventoryMovement.class))).thenReturn(savedMovement);
        when(movementRepository.findMaxReferenceNumber(anyString())).thenReturn(0L);

        // Act
        InventoryMovementDto result = inventoryService.depositToBank(dto, WORKER_ID);

        // Assert
        assertThat(result.getStatus()).isEqualTo("PENDING");

        // CashBalance NEM csökkent azonnal
        verify(cashBalanceRepository, never()).save(any(CashBalance.class));
    }

    @Test
    @DisplayName("depositToBank: nincs elegendő készlet → ValidationException")
    void depositToBank_insufficientBalance_throwsValidationException() {
        // Arrange
        BankDepositRequestDto dto = BankDepositRequestDto.builder()
                .branchId(BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("9999"))
                .build();

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("100"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));

        // Act & Assert
        assertThatThrownBy(() -> inventoryService.depositToBank(dto, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs elegendő készlet");
    }

    // ============ Fix #1b: approveMovement — CashBalance csökkentés BANK_DEPOSIT esetén ============

    @Test
    @DisplayName("approveMovement: BANK_DEPOSIT jóváhagyásakor CashBalance csökkentés")
    void approveMovement_bankDeposit_decreasesCashBalance() {
        // Arrange
        InventoryMovement movement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING,
                eurCurrency, branch, null);
        movement.setId(1L);
        Worker initiator = new Worker();
        initiator.setId(99L);
        initiator.setName("Rögzítő dolgozó");
        movement.setInitiatedBy(initiator);

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();

        when(movementRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(movementRepository.save(any(InventoryMovement.class))).thenReturn(movement);

        // Act
        inventoryService.approveMovement(1L, WORKER_ID);

        // Assert: a készlet-hozzáférőn keresztül csökkentjük (nem-vault ágban cash_balance)
        verify(stockAccessor).adjust(branch, eurCurrency, new BigDecimal("-1000"));
    }

    @Test
    @DisplayName("approveMovement: BANK_DEPOSIT után státusz APPROVED (nem IN_TRANSIT)")
    void approveMovement_bankDeposit_statusIsApproved() {
        // Arrange
        InventoryMovement movement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING,
                eurCurrency, branch, null);
        movement.setId(2L);
        Worker initiator = new Worker();
        initiator.setId(99L);
        initiator.setName("Rögzítő dolgozó");
        movement.setInitiatedBy(initiator);

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();

        when(movementRepository.findByIdForUpdate(2L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));

        ArgumentCaptor<InventoryMovement> captor = ArgumentCaptor.forClass(InventoryMovement.class);
        when(movementRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        // Act
        inventoryService.approveMovement(2L, WORKER_ID);

        // Assert
        assertThat(captor.getValue().getStatus()).isEqualTo(MovementStatus.APPROVED);
    }

    // ============ FK-xxx: 4-szem-elv — self-approval tilalom (approveMovement) ============

    @Test
    @DisplayName("approveMovement: a rögzítő NEM hagyhatja jóvá a saját mozgását (4-szem-elv) → ValidationException, nincs mutáció")
    void approveMovement_selfApproval_throwsValidationException() {
        InventoryMovement movement = buildMovement(MovementType.BANK_WITHDRAW, MovementStatus.PENDING,
                eurCurrency, null, branch);
        movement.setId(7L);
        movement.setInitiatedBy(worker); // worker.id == WORKER_ID
        when(movementRepository.findByIdForUpdate(7L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        assertThatThrownBy(() -> inventoryService.approveMovement(7L, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("4-szem");

        verify(movementRepository, never()).save(any());
        verify(stockAccessor, never()).adjust(any(), any(), any());
        assertThat(movement.getStatus()).isEqualTo(MovementStatus.PENDING);
    }

    @Test
    @DisplayName("approveMovement: azonosíthatatlan rögzítő (initiatedBy null) → fail-closed ValidationException")
    void approveMovement_nullInitiator_failClosed() {
        InventoryMovement movement = buildMovement(MovementType.BANK_WITHDRAW, MovementStatus.PENDING,
                eurCurrency, null, branch);
        movement.setId(8L);
        movement.setInitiatedBy(null);
        when(movementRepository.findByIdForUpdate(8L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        assertThatThrownBy(() -> inventoryService.approveMovement(8L, WORKER_ID))
                .isInstanceOf(ValidationException.class);
        verify(movementRepository, never()).save(any());
        verify(stockAccessor, never()).adjust(any(), any(), any());
    }

    @Test
    @DisplayName("approveMovement: MÁSIK dolgozó jóváhagyhatja (4-szem teljesül) → APPROVED/IN_TRANSIT")
    void approveMovement_differentApprover_succeeds() {
        Worker initiator = new Worker();
        initiator.setId(99L);
        initiator.setName("Rögzítő dolgozó");
        InventoryMovement movement = buildMovement(MovementType.BANK_WITHDRAW, MovementStatus.PENDING,
                eurCurrency, null, branch);
        movement.setId(9L);
        movement.setInitiatedBy(initiator);
        when(movementRepository.findByIdForUpdate(9L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(movementRepository.save(any(InventoryMovement.class))).thenAnswer(i -> i.getArgument(0));

        InventoryMovementDto dto = inventoryService.approveMovement(9L, WORKER_ID);

        assertThat(dto).isNotNull();
        assertThat(movement.getStatus()).isEqualTo(MovementStatus.IN_TRANSIT); // BANK_WITHDRAW → IN_TRANSIT
    }

    // ============ Fix #2: transferBetweenBranches — forrás-készlet ellenőrzés ============

    @Test
    @DisplayName("transferBetweenBranches: elégtelen forrás-készlet → ValidationException")
    void transferBetweenBranches_insufficientSourceStock_throwsValidationException() {
        // Arrange
        BranchTransferRequestDto dto = BranchTransferRequestDto.builder()
                .fromBranchId(BRANCH_ID.toString())
                .toBranchId(BRANCH_ID_2.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("9999"))
                .build();

        CashBalance sourceBalance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("500"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(branchRepository.findById(BRANCH_ID_2)).thenReturn(Optional.of(branch2));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(sourceBalance));

        // Act & Assert
        assertThatThrownBy(() -> inventoryService.transferBetweenBranches(dto, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs elegendő készlet a forrás irodánál");
    }

    @Test
    @DisplayName("transferBetweenBranches: elegendő forrás-készlet → PENDING mozgás létrejön")
    void transferBetweenBranches_sufficientSourceStock_createsPendingMovement() {
        // Arrange
        BranchTransferRequestDto dto = BranchTransferRequestDto.builder()
                .fromBranchId(BRANCH_ID.toString())
                .toBranchId(BRANCH_ID_2.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("200"))
                .build();

        CashBalance sourceBalance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("500"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(branchRepository.findById(BRANCH_ID_2)).thenReturn(Optional.of(branch2));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(sourceBalance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode(any(), eq("EUR")))
                .thenReturn(Optional.of(new BigDecimal("390")));
        when(movementRepository.findMaxReferenceNumber(anyString())).thenReturn(0L);

        InventoryMovement savedMovement = buildMovement(MovementType.BRANCH_TRANSFER, MovementStatus.PENDING,
                eurCurrency, branch, branch2);
        when(movementRepository.save(any(InventoryMovement.class))).thenReturn(savedMovement);

        // Act
        InventoryMovementDto result = inventoryService.transferBetweenBranches(dto, WORKER_ID);

        // Assert
        assertThat(result.getStatus()).isEqualTo("PENDING");
        verify(movementRepository).save(any(InventoryMovement.class));
    }

    @Test
    @DisplayName("transferBetweenBranches: nincs kassza egyenleg a forrás irodánál → ValidationException")
    void transferBetweenBranches_noSourceBalance_throwsValidationException() {
        // Arrange
        BranchTransferRequestDto dto = BranchTransferRequestDto.builder()
                .fromBranchId(BRANCH_ID.toString())
                .toBranchId(BRANCH_ID_2.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("100"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(branchRepository.findById(BRANCH_ID_2)).thenReturn(Optional.of(branch2));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(stockAccessor.getBalance(branch, eurCurrency))
                .thenThrow(new ValidationException("Nincs kassza egyenleg a forrás irodánál ehhez a valutához: EUR"));

        // Act & Assert
        assertThatThrownBy(() -> inventoryService.transferBetweenBranches(dto, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs kassza egyenleg a forrás irodánál");
    }

    // ============ Fix #3: getAllStock — @Transactional(readOnly=true) ============

    @Test
    @DisplayName("getAllStock: @Transactional(readOnly=true) annotáció megléte")
    void getAllStock_hasTransactionalReadOnlyAnnotation() throws NoSuchMethodException {
        Method method = InventoryService.class.getMethod("getAllStock");
        Transactional tx = method.getAnnotation(Transactional.class);
        assertThat(tx).isNotNull();
        assertThat(tx.readOnly()).isTrue();
    }

    // ============ Fix #4: hufValue számítás ============

    @Test
    @DisplayName("depositToBank: hufValue az árfolyam alapján számítódik (EUR × mid rate)")
    void depositToBank_hufValueCalculatedFromExchangeRate() {
        // Arrange: 1000 EUR, mid rate = 390 → hufValue = 390_000
        BankDepositRequestDto dto = BankDepositRequestDto.builder()
                .branchId(BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("1000"))
                .build();

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode(any(), eq("EUR")))
                .thenReturn(Optional.of(new BigDecimal("390")));
        when(movementRepository.findMaxReferenceNumber(anyString())).thenReturn(0L);

        ArgumentCaptor<InventoryMovement> captor = ArgumentCaptor.forClass(InventoryMovement.class);
        InventoryMovement savedMovement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING,
                eurCurrency, branch, null);
        savedMovement.setHufValue(new BigDecimal("390000"));
        when(movementRepository.save(captor.capture())).thenReturn(savedMovement);

        // Act
        inventoryService.depositToBank(dto, WORKER_ID);

        // Assert: a mentett mozgásban hufValue = 1000 × 390 = 390_000
        BigDecimal capturedHufValue = captor.getValue().getHufValue();
        assertThat(capturedHufValue).isEqualByComparingTo(new BigDecimal("390000"));
    }

    @Test
    @DisplayName("depositToBank: ha nincs árfolyam, hufValue = ZERO")
    void depositToBank_noExchangeRate_hufValueIsZero() {
        // Arrange
        BankDepositRequestDto dto = BankDepositRequestDto.builder()
                .branchId(BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("500"))
                .build();

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode(any(), eq("EUR")))
                .thenReturn(Optional.empty());
        when(movementRepository.findMaxReferenceNumber(anyString())).thenReturn(0L);

        ArgumentCaptor<InventoryMovement> captor = ArgumentCaptor.forClass(InventoryMovement.class);
        InventoryMovement savedMovement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING,
                eurCurrency, branch, null);
        savedMovement.setHufValue(BigDecimal.ZERO);
        when(movementRepository.save(captor.capture())).thenReturn(savedMovement);

        // Act
        inventoryService.depositToBank(dto, WORKER_ID);

        // Assert
        assertThat(captor.getValue().getHufValue()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("HUF valuta esetén hufValue == amount (nincs szorzás)")
    void depositToBank_hufCurrency_hufValueEqualsAmount() {
        // Arrange: HUF befizetés
        BankDepositRequestDto dto = BankDepositRequestDto.builder()
                .branchId(BRANCH_ID.toString())
                .currencyId(2L)
                .amount(new BigDecimal("50000"))
                .build();

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(hufCurrency)
                .currentBalance(new BigDecimal("100000"))
                .build();

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(2L)).thenReturn(Optional.of(hufCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, 2L, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(movementRepository.findMaxReferenceNumber(anyString())).thenReturn(0L);

        ArgumentCaptor<InventoryMovement> captor = ArgumentCaptor.forClass(InventoryMovement.class);
        InventoryMovement savedMovement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING,
                hufCurrency, branch, null);
        savedMovement.setHufValue(new BigDecimal("50000"));
        when(movementRepository.save(captor.capture())).thenReturn(savedMovement);

        // Act
        inventoryService.depositToBank(dto, WORKER_ID);

        // Assert: HUF esetén nincs árfolyam lookup, hufValue == amount
        verify(exchangeRateRepository, never()).findLatestMidRateByCurrencyCode(any(), anyString());
        assertThat(captor.getValue().getHufValue()).isEqualByComparingTo(new BigDecimal("50000"));
    }

    // ============ Audit 2026-05-31 (P1): receiveMovement difference + audit ============

    @Test
    @DisplayName("receiveMovement: receivedAmount ≠ amount → difference rögzítve + DIFF-audit (készlet=SUM(tx) védelem)")
    void receiveMovement_shortage_recordsDifferenceAndAudits() {
        InventoryMovement movement = buildMovement(MovementType.BANK_WITHDRAW, MovementStatus.APPROVED,
                eurCurrency, null, branch);
        movement.setId(5L);
        movement.setAmount(new BigDecimal("1000"));
        hu.puzzleir.valuta.dto.inventory.ReceiveMovementDto dto =
                hu.puzzleir.valuta.dto.inventory.ReceiveMovementDto.builder()
                        .receivedAmount(new BigDecimal("950")).build();
        CashBalance balance = CashBalance.builder()
                .branch(branch).currency(eurCurrency).currentBalance(new BigDecimal("5000")).build();
        when(movementRepository.findByIdForUpdate(5L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(movementRepository.save(any(InventoryMovement.class))).thenAnswer(i -> i.getArgument(0));

        inventoryService.receiveMovement(5L, WORKER_ID, dto);

        // A különbség mostantól RÖGZÍTVE van a mozgáson (nem tűnik el nyom nélkül).
        assertThat(movement.getReceivedAmount()).isEqualByComparingTo(new BigDecimal("950"));
        assertThat(movement.getDifference()).isEqualByComparingTo(new BigDecimal("-50"));
        // ÉS auditálva (DIFF action, a különbség a changes-ben).
        ArgumentCaptor<AuditLog> cap = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(cap.capture());
        assertThat(cap.getValue().getAction()).isEqualTo("INVENTORY_MOVEMENT_RECEIVED_DIFF");
        assertThat(cap.getValue().getChanges()).contains("-50");
    }

    @Test
    @DisplayName("receiveMovement: pontos fogadás (received == amount) → difference 0, sima RECEIVED-audit")
    void receiveMovement_exact_zeroDifference() {
        InventoryMovement movement = buildMovement(MovementType.BANK_WITHDRAW, MovementStatus.APPROVED,
                eurCurrency, null, branch);
        movement.setId(6L);
        movement.setAmount(new BigDecimal("1000"));
        hu.puzzleir.valuta.dto.inventory.ReceiveMovementDto dto =
                hu.puzzleir.valuta.dto.inventory.ReceiveMovementDto.builder()
                        .receivedAmount(new BigDecimal("1000")).build();
        CashBalance balance = CashBalance.builder()
                .branch(branch).currency(eurCurrency).currentBalance(new BigDecimal("5000")).build();
        when(movementRepository.findByIdForUpdate(6L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(movementRepository.save(any(InventoryMovement.class))).thenAnswer(i -> i.getArgument(0));

        inventoryService.receiveMovement(6L, WORKER_ID, dto);

        assertThat(movement.getDifference()).isEqualByComparingTo(BigDecimal.ZERO);
        ArgumentCaptor<AuditLog> cap = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(cap.capture());
        assertThat(cap.getValue().getAction()).isEqualTo("INVENTORY_MOVEMENT_RECEIVED");
    }

    @Test
    @DisplayName("correctInventory nem-vault audit: CashBalance entityId bit-azonosan a cash_balance rekord id-ja marad")
    void correctInventory_nonVaultAuditUsesCashBalanceEntityId() {
        hu.puzzleir.valuta.dto.inventory.CorrectionRequestDto dto =
                hu.puzzleir.valuta.dto.inventory.CorrectionRequestDto.builder()
                        .branchId(BRANCH_ID.toString())
                        .currencyId(CURRENCY_ID)
                        .newAmount(new BigDecimal("5500"))
                        .reason("Leltár")
                        .build();
        CashBalance balance = CashBalance.builder()
                .id(42L)
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eurCurrency));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(stockAccessor.getBalance(branch, eurCurrency)).thenReturn(new BigDecimal("5000"));
        when(stockAccessor.isVaultContext(branch)).thenReturn(false);
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyId(BRANCH_ID, CURRENCY_ID, COMPANY_ID))
                .thenReturn(Optional.of(balance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode(any(), eq("EUR")))
                .thenReturn(Optional.of(new BigDecimal("390")));
        when(movementRepository.findMaxReferenceNumber(anyString())).thenReturn(0L);
        when(movementRepository.save(any(InventoryMovement.class))).thenAnswer(i -> i.getArgument(0));

        inventoryService.correctInventory(dto, WORKER_ID);

        ArgumentCaptor<AuditLog> cap = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(cap.capture());
        assertThat(cap.getValue().getEntityType()).isEqualTo("CashBalance");
        assertThat(cap.getValue().getEntityId()).isEqualTo("42");
    }

    // ============ Audit 2026-05-31: multi-tenant IDOR védelem ============

    private Branch foreignBranch() {
        Company otherCompany = new Company();
        otherCompany.setId(OTHER_COMPANY_ID);
        Branch foreign = new Branch();
        foreign.setId(UUID.randomUUID());
        foreign.setName("Idegen cég irodája");
        foreign.setCompany(otherCompany);
        return foreign;
    }

    @Test
    @DisplayName("IDOR: idegen cég irodájára kért bank-kivét → 404 (ResourceNotFound), nincs mozgás-mentés")
    void requestBankWithdraw_foreignBranch_throwsNotFound() {
        Branch foreign = foreignBranch();
        hu.puzzleir.valuta.dto.inventory.BankWithdrawRequestDto dto =
                hu.puzzleir.valuta.dto.inventory.BankWithdrawRequestDto.builder()
                        .branchId(foreign.getId().toString())
                        .currencyId(CURRENCY_ID)
                        .amount(new BigDecimal("1000"))
                        .build();
        when(branchRepository.findById(foreign.getId())).thenReturn(Optional.of(foreign));

        assertThatThrownBy(() -> inventoryService.requestBankWithdraw(dto, WORKER_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Iroda nem található");
        verify(movementRepository, never()).save(any(InventoryMovement.class));
    }

    @Test
    @DisplayName("ERTEKTAR: idegen territory branch-re bank-kivét → 403 VV-AUTH-001 + ACCESS_DENIED audit")
    void requestBankWithdraw_ertektarOtherTerritory_throwsAccessDeniedAndAudits() {
        branch.setVaultTerritoryId(2);
        branch2.setVaultTerritoryId(1);
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID_2);

        hu.puzzleir.valuta.dto.inventory.BankWithdrawRequestDto dto =
                hu.puzzleir.valuta.dto.inventory.BankWithdrawRequestDto.builder()
                        .branchId(BRANCH_ID.toString())
                        .currencyId(CURRENCY_ID)
                        .amount(new BigDecimal("1000"))
                        .build();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(branchRepository.findById(BRANCH_ID_2)).thenReturn(Optional.of(branch2));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));

        assertThatThrownBy(() -> inventoryService.requestBankWithdraw(dto, WORKER_ID))
                .isInstanceOf(org.springframework.security.access.AccessDeniedException.class)
                .hasMessageContaining("VV-AUTH-001");

        // Codex #1227 P2: a megtagadás-audit REQUIRES_NEW tranzakcióban megy (AuditLogService),
        // hogy a hívó rollbackje ELLENÉRE megmaradjon.
        verify(auditLogService).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("InventoryMovement"), isNull(),
                any(), any(), any(), any(), contains("error_code=VV-AUTH-001"));
        verify(movementRepository, never()).save(any(InventoryMovement.class));
    }

    @Test
    @DisplayName("IDOR: idegen cég irodái közti transzfer → 404, nincs mozgás-mentés")
    void transferBetweenBranches_foreignBranch_throwsNotFound() {
        Branch foreign = foreignBranch();
        BranchTransferRequestDto dto = BranchTransferRequestDto.builder()
                .fromBranchId(foreign.getId().toString())
                .toBranchId(BRANCH_ID_2.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("100"))
                .build();
        when(branchRepository.findById(foreign.getId())).thenReturn(Optional.of(foreign));

        assertThatThrownBy(() -> inventoryService.transferBetweenBranches(dto, WORKER_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Iroda nem található");
        verify(movementRepository, never()).save(any(InventoryMovement.class));
    }

    @Test
    @DisplayName("IDOR: idegen cég mozgásának jóváhagyása → 404, nincs cash_balance-írás")
    void approveMovement_foreignMovement_throwsNotFound() {
        InventoryMovement foreignMovement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING,
                eurCurrency, foreignBranch(), null);
        foreignMovement.setId(99L);
        when(movementRepository.findByIdForUpdate(99L)).thenReturn(Optional.of(foreignMovement));

        assertThatThrownBy(() -> inventoryService.approveMovement(99L, WORKER_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Készlet mozgás nem található");
        verify(cashBalanceRepository, never()).save(any(CashBalance.class));
    }

    @Test
    @DisplayName("IDOR: kevert-tenant BRANCH_TRANSFER (saját from + idegen to) jóváhagyása → 404 (Codex P1 #934)")
    void approveMovement_mixedTenantTransfer_throwsNotFound() {
        // Egy oldal a sajátunk, a másik IDEGEN — a receive MINDKÉT cash_balance-t írná, ezért tiltjuk.
        InventoryMovement mixed = buildMovement(MovementType.BRANCH_TRANSFER, MovementStatus.PENDING,
                eurCurrency, branch /* saját */, foreignBranch() /* idegen */);
        mixed.setId(88L);
        when(movementRepository.findByIdForUpdate(88L)).thenReturn(Optional.of(mixed));

        assertThatThrownBy(() -> inventoryService.approveMovement(88L, WORKER_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Készlet mozgás nem található");
        verify(cashBalanceRepository, never()).save(any(CashBalance.class));
    }

    @Test
    @DisplayName("IDOR: idegen cég mozgásának lekérése (getMovement) → 404")
    void getMovement_foreignMovement_throwsNotFound() {
        InventoryMovement foreignMovement = buildMovement(MovementType.BRANCH_TRANSFER, MovementStatus.PENDING,
                eurCurrency, foreignBranch(), foreignBranch());
        foreignMovement.setId(77L);
        when(movementRepository.findById(77L)).thenReturn(Optional.of(foreignMovement));

        assertThatThrownBy(() -> inventoryService.getMovement(77L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Készlet mozgás nem található");
    }

    @Test
    @DisplayName("IDOR: saját cég mozgása (bank-művelet, fromBranch=null) lekérhető")
    void getMovement_ownBankMovement_succeeds() {
        // BANK_WITHDRAW: fromBranch=null, toBranch=saját → a tenant-check a toBranch-en átmegy
        InventoryMovement ownMovement = buildMovement(MovementType.BANK_WITHDRAW, MovementStatus.PENDING,
                eurCurrency, null, branch);
        ownMovement.setId(55L);
        when(movementRepository.findById(55L)).thenReturn(Optional.of(ownMovement));

        InventoryMovementDto result = inventoryService.getMovement(55L);
        assertThat(result).isNotNull();
    }

    @Test
    @DisplayName("searchMovements: a hívó cég companyId-ját adja át a repo-nak (nem szivárog cross-tenant)")
    void searchMovements_passesCurrentCompanyId() {
        when(movementRepository.search(eq(COMPANY_ID), any(), any(), any(), any(), any(), any()))
                .thenReturn(Page.empty());

        inventoryService.searchMovements(null, null, null, null, null,
                org.springframework.data.domain.PageRequest.of(0, 20));

        verify(movementRepository).search(eq(COMPANY_ID), isNull(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("searchMovements: idegen cég branchId-jére szűrve → 404")
    void searchMovements_foreignBranchFilter_throwsNotFound() {
        Branch foreign = foreignBranch();
        when(branchRepository.findById(foreign.getId())).thenReturn(Optional.of(foreign));

        assertThatThrownBy(() -> inventoryService.searchMovements(foreign.getId(), null, null, null, null,
                org.springframework.data.domain.PageRequest.of(0, 20)))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Iroda nem található");
        verify(movementRepository, never()).search(any(), any(), any(), any(), any(), any(), any());
    }

    // ============ Segéd factory ============

    private InventoryMovement buildMovement(MovementType type, MovementStatus status,
                                             Currency currency, Branch from, Branch to) {
        InventoryMovement m = new InventoryMovement();
        m.setMovementType(type);
        m.setStatus(status);
        m.setCurrency(currency);
        m.setFromBranch(from);
        m.setToBranch(to);
        m.setAmount(new BigDecimal("1000"));
        m.setHufValue(BigDecimal.ZERO);
        m.setInitiatedBy(worker);
        m.setReferenceNumber("INV-20260316-0001");
        m.setMovementDate(LocalDate.now());
        m.setMovementTime(LocalTime.now());
        return m;
    }

    // ============ FK-ÉRTÉKTÁR (2026-06-02): getVaultStockFlow territory-scoping ============

    @Test
    @DisplayName("getVaultStockFlow: ERTEKTAR (territory-scoped) csak a SAJÁT értéktára készletét látja")
    void getVaultStockFlow_ertektar_onlyOwnTerritoryVault() {
        // Két vault branch külön területen: branch=terület 1, branch2=terület 2.
        branch.setIsVault(true);
        branch.setVaultTerritoryId(1);
        branch2.setIsVault(true);
        branch2.setVaultTerritoryId(2);

        // ERTEKTAR user a branch-en (terület 1) → territoryFilter = 1.
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));

        when(branchRepository.findByCompanyIdAndIsVaultTrueAndIsActiveTrue(COMPANY_ID))
                .thenReturn(List.of(branch, branch2));

        // KÓDBÁZIS-KONVENCIÓ: VAULT currency_stock.entity_id = vault_territory.id (::TEXT), NEM branch UUID.
        CurrencyStock ownStock = CurrencyStock.builder()
                .entityType("VAULT").entityId("1")   // saját terület (territoryFilter = 1)
                .currencyCode("EUR").quantity(new BigDecimal("1000")).build();
        CurrencyStock otherStock = CurrencyStock.builder()
                .entityType("VAULT").entityId("2")   // másik terület
                .currencyCode("EUR").quantity(new BigDecimal("5000")).build();
        when(currencyStockRepository.findByCompanyIdAndEntityType(COMPANY_ID, "VAULT"))
                .thenReturn(List.of(ownStock, otherStock));

        when(movementRepository.findCompletedByCompanyIdAndDate(eq(COMPANY_ID), any()))
                .thenReturn(List.of());
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurCurrency));

        var result = inventoryService.getVaultStockFlow();

        // Csak a saját terület (entity_id="1") EUR sora — a másik terület készlete NEM szivárog ki.
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCurrencyCode()).isEqualTo("EUR");
        assertThat(result.get(0).getClosing()).isEqualByComparingTo("1000");
    }

    @Test
    @DisplayName("getVaultStockFlow: ERTEKTAR vault_territory NÉLKÜL → fail-closed (üres lista)")
    void getVaultStockFlow_ertektar_noTerritory_failClosed() {
        // ERTEKTAR user, de a branch-nek NINCS vault_territory_id-je → territoryFilter null.
        branch.setVaultTerritoryId(null);
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        // Még ha lenne is VAULT készlet, NEM szabad visszaadni (fail-closed).
        CurrencyStock anyStock = CurrencyStock.builder()
                .entityType("VAULT").entityId("1").currencyCode("EUR").quantity(new BigDecimal("9999")).build();
        when(currencyStockRepository.findByCompanyIdAndEntityType(COMPANY_ID, "VAULT"))
                .thenReturn(List.of(anyStock));

        var result = inventoryService.getVaultStockFlow();

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("getVaultStockFlow: központi role (territoryFilter null) minden értéktár készletét látja")
    void getVaultStockFlow_centralRole_seesAllVaults() {
        branch.setIsVault(true);
        branch.setVaultTerritoryId(1);
        branch2.setIsVault(true);
        branch2.setVaultTerritoryId(2);

        // UGYVEZETO NEM territory-scoped → territoryFilter null → nincs szűrés.
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ugyvezeto");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ugyvezeto");

        when(branchRepository.findByCompanyIdAndIsVaultTrueAndIsActiveTrue(COMPANY_ID))
                .thenReturn(List.of(branch, branch2));

        CurrencyStock s1 = CurrencyStock.builder()
                .entityType("VAULT").entityId(BRANCH_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("1000")).build();
        CurrencyStock s2 = CurrencyStock.builder()
                .entityType("VAULT").entityId(BRANCH_ID_2.toString())
                .currencyCode("USD").quantity(new BigDecimal("5000")).build();
        when(currencyStockRepository.findByCompanyIdAndEntityType(COMPANY_ID, "VAULT"))
                .thenReturn(List.of(s1, s2));

        when(movementRepository.findCompletedByCompanyIdAndDate(eq(COMPANY_ID), any()))
                .thenReturn(List.of());
        when(currencyRepository.findByCode(anyString())).thenReturn(Optional.empty());

        var result = inventoryService.getVaultStockFlow();

        // Mindkét értéktár készlete látszik.
        assertThat(result).hasSize(2);
        assertThat(result).extracting(r -> r.getCurrencyCode())
                .containsExactlyInAnyOrder("EUR", "USD");
    }

    // ============ FK-029: Országos készlet — szintetikus 0-sorok ============

    @Test
    @DisplayName("FK-029 getAllStock: szintetikus 0-sor a cash_balance nélküli aktív branch-ekre (FR-1/FR-6)")
    void getAllStock_includesSyntheticZeroRowsForBranchesWithoutCashBalance() {
        // branch-nek van EUR cash_balance sora; branch2-nek SEMMI.
        CashBalance realEur = CashBalance.builder()
                .branch(branch).currency(eurCurrency).company(company)
                .currentBalance(new BigDecimal("5000")).openingBalance(BigDecimal.ZERO)
                .build();
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of(realEur));
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(java.util.List.of(branch, branch2));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(hufCurrency, eurCurrency));

        var result = inventoryService.getAllStock();

        // FR-6: minden aktív branch szerepel — branch ÉS a cash_balance nélküli branch2 is.
        assertThat(result).extracting(cb -> cb.getBranch().getId())
                .contains(BRANCH_ID, BRANCH_ID_2);
        // branch2 (cash_balance nélkül) mind a 2 aktív valutára 0-egyenlegű szintetikus sort kap.
        assertThat(result).filteredOn(cb -> BRANCH_ID_2.equals(cb.getBranch().getId()))
                .hasSize(2)
                .allMatch(cb -> cb.getCurrentBalance().compareTo(BigDecimal.ZERO) == 0);
        // branch valódi EUR sora megmarad (5000), + szintetikus HUF (0) = 2 sor.
        assertThat(result).filteredOn(cb -> BRANCH_ID.equals(cb.getBranch().getId())
                        && "EUR".equals(cb.getCurrency().getCode()))
                .singleElement()
                .extracting(CashBalance::getCurrentBalance)
                .isEqualTo(new BigDecimal("5000"));
    }

    @Test
    @DisplayName("FK-029 getAllStock: a szintetikus sorok NEM perzisztálódnak (FR-3)")
    void getAllStock_syntheticRowsNotPersisted() {
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(java.util.List.of(branch));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(hufCurrency, eurCurrency));

        inventoryService.getAllStock();

        verify(cashBalanceRepository, never()).save(any(CashBalance.class));
    }

    @Test
    @DisplayName("FK-029 getAllStock: a szintetikus sorszám az aktív valuta-számmal egyezik, nem hardcode (FR-7)")
    void getAllStock_syntheticRowCountMatchesActiveCurrencyCount() {
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of());
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID)).thenReturn(java.util.List.of(branch));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(hufCurrency, eurCurrency)); // 2 aktív

        var result = inventoryService.getAllStock();

        // 1 branch × 2 aktív valuta = 2 szintetikus sor (nincs valódi cash_balance).
        assertThat(result).hasSize(2);
        assertThat(result).allMatch(cb -> cb.getCurrentBalance().compareTo(BigDecimal.ZERO) == 0);
    }

    // ============ FK-051: Országos/Pénztári készlet — territory-scoped értéktáros REGION-scope ============

    @Test
    @DisplayName("FK-051 getAllStock (értéktáros): a saját RÉGIÓ nem-vault pénztárainak készletét látja (nem 0)")
    void getAllStock_territoryScoped_seesRegionNonVaultBranches() {
        // VALÓS ORSZÁGOS BUG (W1-W4 Neon-diagnosztika, 2026-07-01): a régiós értéktáros (ERTEKTAR)
        // a Pénztári/Országos készlet nézetben MINDEN valutára 0-t látott. Gyökérok: a getAllStock
        // territory-ága a vault_territory_id-szűrőt (findByCompanyIdAndVaultTerritoryId) használta,
        // de a V322/V326 CSAK is_vault=TRUE branch-re töltött vt_id-t — a nem-vault PÉNZTÁRAKNAK
        // (ahol a cash_balance van) vt_id=NULL → a metszet ÜRES → 0. A helyes scope a `region`-alapú
        // (mint az AccessScopeService), amely a nem-vault pénztárakat is tartalmazza.

        // Az értéktáros saját (vault) fiókja: region=SZEGED, van vt_id (mint prod BR020).
        branch.setRegion("SZEGED");
        branch.setIsVault(true);
        branch.setVaultTerritoryId(4);
        branch.setIsActive(true);

        // Ugyanabban a régióban egy NEM-vault PÉNZTÁR, ahol a valódi készlet van, vt_id=NULL (mint prod BR035).
        branch2.setRegion("SZEGED");
        branch2.setIsVault(false);
        branch2.setVaultTerritoryId(null);
        branch2.setIsActive(true);

        CashBalance penztarHuf = CashBalance.builder()
                .branch(branch2).currency(hufCurrency).company(company)
                .currentBalance(new BigDecimal("1376165")).openingBalance(BigDecimal.ZERO).build();

        // ERTEKTAR user a saját (vault) fiókján → territory-scoped, region=SZEGED.
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of(penztarHuf));
        // A region-scope a SZEGED régió aktív branch-eit adja (a nem-vault pénztár is benne).
        when(branchRepository.findActiveByCompanyIdAndRegion(COMPANY_ID, "SZEGED"))
                .thenReturn(java.util.List.of(branch, branch2));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(hufCurrency, eurCurrency));

        var result = inventoryService.getAllStock();

        // A JAVÍTÁS ELŐTT ez ÜRES (0 sor) → a teszt bukik (RED). A fix után a nem-vault pénztár
        // valódi HUF sora (1 376 165) megjelenik.
        assertThat(result).as("az értéktáros a saját régiója pénztár-készletét látja")
                .isNotEmpty();
        assertThat(result).filteredOn(cb -> BRANCH_ID_2.equals(cb.getBranch().getId())
                        && "HUF".equals(cb.getCurrency().getCode()))
                .singleElement()
                .extracting(CashBalance::getCurrentBalance)
                .isEqualTo(new BigDecimal("1376165"));
    }

    @Test
    @DisplayName("FK-051 getStockMatrix (értéktáros): a saját RÉGIÓ nem-vault pénztárai megjelennek a mátrixban")
    void getStockMatrix_territoryScoped_seesRegionNonVaultBranches() {
        branch.setRegion("SZEGED");
        branch.setIsVault(true);
        branch.setVaultTerritoryId(4);
        branch.setIsActive(true);
        branch2.setRegion("SZEGED");
        branch2.setIsVault(false);
        branch2.setVaultTerritoryId(null);
        branch2.setIsActive(true);

        CashBalance penztarHuf = CashBalance.builder()
                .branch(branch2).currency(hufCurrency).company(company)
                .currentBalance(new BigDecimal("1376165")).openingBalance(BigDecimal.ZERO).build();

        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of(penztarHuf));
        when(branchRepository.findActiveByCompanyIdAndRegion(COMPANY_ID, "SZEGED"))
                .thenReturn(java.util.List.of(branch, branch2));

        var matrix = inventoryService.getStockMatrix().getMatrix();

        // A fix előtt üres (vt_id-szűrő) → a nem-vault pénztár most a mátrixban van a valódi HUF-fal.
        assertThat(matrix).containsKey(BRANCH_ID_2.toString());
        assertThat(matrix.get(BRANCH_ID_2.toString()).get("HUF")).isEqualByComparingTo("1376165");
        // FK-051 GLM #4: a saját VAULT (értéktár) fiók NEM jelenik meg a pénztár-mátrixban (konzisztens getAllStock-kal).
        assertThat(matrix).doesNotContainKey(BRANCH_ID.toString());
    }

    @Test
    @DisplayName("FK-051 getAllStock (központi role): null scope → nincs szűrés, mindent lát")
    void getAllStock_centralRole_noScopeFilter() {
        // UGYVEZETO nem territory-scoped → regionScope == null → nincs region-szűrés (minden branch).
        branch.setRegion("SZEGED");
        branch.setIsVault(false);
        branch.setIsActive(true);
        branch2.setRegion("DEBRECEN");
        branch2.setIsVault(false);
        branch2.setIsActive(true);
        CashBalance szeged = CashBalance.builder().branch(branch).currency(hufCurrency).company(company)
                .currentBalance(new BigDecimal("100")).openingBalance(BigDecimal.ZERO).build();
        CashBalance debrecen = CashBalance.builder().branch(branch2).currency(hufCurrency).company(company)
                .currentBalance(new BigDecimal("200")).openingBalance(BigDecimal.ZERO).build();

        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ugyvezeto");
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of(szeged, debrecen));
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(java.util.List.of(branch, branch2));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(hufCurrency));

        var result = inventoryService.getAllStock();

        // Központi role: MINDKÉT régió pénztára látszik (nincs territory-szűkítés).
        assertThat(result).extracting(cb -> cb.getBranch().getId()).contains(BRANCH_ID, BRANCH_ID_2);
    }

    @Test
    @DisplayName("FK-051 getAllStock (értéktáros, más régió): SZEGED user NEM látja DEBRECEN pénztárát (cross-region izoláció)")
    void getAllStock_territoryScoped_crossRegionIsolation() {
        // A SZEGED-es értéktáros régió-scope-ja CSAK a SZEGED branch-eket adja — a DEBRECEN pénztár kiesik.
        branch.setRegion("SZEGED");
        branch.setIsVault(true);
        branch.setVaultTerritoryId(4);
        branch.setIsActive(true);
        Branch debrecenPenztar = new Branch();
        debrecenPenztar.setId(UUID.randomUUID());
        debrecenPenztar.setName("Debrecen Plaza");
        debrecenPenztar.setCompany(company);
        debrecenPenztar.setRegion("DEBRECEN");
        debrecenPenztar.setIsVault(false);
        debrecenPenztar.setIsActive(true);
        CashBalance debrecenHuf = CashBalance.builder().branch(debrecenPenztar).currency(hufCurrency).company(company)
                .currentBalance(new BigDecimal("999999")).openingBalance(BigDecimal.ZERO).build();

        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of(debrecenHuf));
        // A SZEGED region-scope csak a saját (vault) fiókot adja (nincs SZEGED-es nem-vault pénztár a mockban).
        when(branchRepository.findActiveByCompanyIdAndRegion(COMPANY_ID, "SZEGED"))
                .thenReturn(java.util.List.of(branch));
        when(branchRepository.findAllById(any())).thenReturn(java.util.List.of(branch));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(hufCurrency));

        var result = inventoryService.getAllStock();

        // A DEBRECEN pénztár készlete NEM szivárog ki a SZEGED-es értéktárosnak.
        assertThat(result).extracting(cb -> cb.getBranch().getId())
                .doesNotContain(debrecenPenztar.getId());
    }

    @Test
    @DisplayName("FK-051 getAllStock (értéktáros, region nélkül): fail-closed — csak saját fiók, nincs országos szivárgás")
    void getAllStock_territoryScoped_noRegion_failClosed() {
        // A user branch-nek NINCS region-je → fail-closed: a scope csak a saját branchId.
        branch.setRegion(null);
        branch.setIsVault(true);
        branch.setIsActive(true);
        Branch masikPenztar = new Branch();
        masikPenztar.setId(UUID.randomUUID());
        masikPenztar.setName("Másik pénztár");
        masikPenztar.setCompany(company);
        masikPenztar.setRegion("DEBRECEN");
        masikPenztar.setIsVault(false);
        masikPenztar.setIsActive(true);
        CashBalance masikHuf = CashBalance.builder().branch(masikPenztar).currency(hufCurrency).company(company)
                .currentBalance(new BigDecimal("500000")).openingBalance(BigDecimal.ZERO).build();

        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(BRANCH_ID);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID)).thenReturn(java.util.List.of(masikHuf));
        when(branchRepository.findAllById(any())).thenReturn(java.util.List.of(branch));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(hufCurrency));

        var result = inventoryService.getAllStock();

        // Fail-closed: a másik régió pénztára NEM látszik (a scope csak a saját fiók, ami vault → kizárva).
        assertThat(result).extracting(cb -> cb.getBranch().getId()).doesNotContain(masikPenztar.getId());
    }

    // ============ FK-032: Országos készlet — VAULT_COUNTERPARTY virtuális partnerek kizárása ============

    @Test
    @DisplayName("FK-032 getAllStock (központi): a VAULT_COUNTERPARTY virtuális partnerek kizárva (FR-1/FR-5)")
    void getAllStock_central_excludesVaultCounterpartyBranches() {
        // Egy VAULT_COUNTERPARTY virtuális partner (pl. Magyar Nemzeti Bank): is_vault=FALSE (V277 seed),
        // így a !isVault szűrőn átmenne, ha bekerülne a scope-listába. A kizáró repo-metódus (JPQL) NEM
        // adja vissza — a fix EZT a metódust hívja a központi ágon (a sima findByCompanyIdAndIsActiveTrue
        // helyett, ami visszaadná). A virtuális partnereknek 0 valódi cash_balance soruk van (prod-tény).
        Branch vaultCounterparty = new Branch();
        vaultCounterparty.setId(UUID.randomUUID());
        vaultCounterparty.setName("Magyar Nemzeti Bank");
        vaultCounterparty.setCompany(company);

        // A counterparty-nak VAN egy valódi cash_balance sora (admin-retrofit edge-case): a findByCompanyId
        // visszaadja, de a scope-szűrésnek (defense-in-depth, Codex P2) ki kell zárnia. Így a teszt NEM vak
        // (Copilot review #1195): a counterparty valós sora ténylegesen jelen van a bemenetben.
        CashBalance counterpartyReal = CashBalance.builder()
                .branch(vaultCounterparty).currency(eurCurrency).company(company)
                .currentBalance(new BigDecimal("999")).openingBalance(BigDecimal.ZERO).build();
        CashBalance realEur = CashBalance.builder()
                .branch(branch).currency(eurCurrency).company(company)
                .currentBalance(new BigDecimal("5000")).openingBalance(BigDecimal.ZERO).build();
        when(cashBalanceRepository.findByCompanyId(COMPANY_ID))
                .thenReturn(java.util.List.of(realEur, counterpartyReal));
        // A kizáró metódus a valódi branch-et adja vissza, a VAULT_COUNTERPARTY-t NEM (JPQL-szimuláció).
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                .thenReturn(java.util.List.of(branch));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(java.util.List.of(eurCurrency));

        var result = inventoryService.getAllStock();

        // FR-1/FR-5: a VAULT_COUNTERPARTY branch egyetlen sorban sem szerepel — a 999-es VALÓDI sora is
        // kiesett (defense-in-depth), nem csak a szintetikus.
        assertThat(result).extracting(cb -> cb.getBranch().getId())
                .doesNotContain(vaultCounterparty.getId())
                .containsOnly(BRANCH_ID);
        // A fix igazolása: a központi ág a KIZÁRÓ metódust hívja, NEM a sima findByCompanyIdAndIsActiveTrue-t.
        verify(branchRepository).findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID);
        verify(branchRepository, never()).findByCompanyIdAndIsActiveTrue(COMPANY_ID);
    }
}
