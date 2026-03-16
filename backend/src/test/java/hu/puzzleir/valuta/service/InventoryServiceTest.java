package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.inventory.BankDepositRequestDto;
import hu.puzzleir.valuta.dto.inventory.BranchTransferRequestDto;
import hu.puzzleir.valuta.dto.inventory.InventoryMovementDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
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
class InventoryServiceTest {

    @InjectMocks
    private InventoryService inventoryService;

    @Mock private InventoryMovementRepository movementRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID_2 = UUID.randomUUID();
    private static final Long CURRENCY_ID = 1L;
    private static final Long WORKER_ID = 10L;

    private Branch branch;
    private Branch branch2;
    private Currency eurCurrency;
    private Currency hufCurrency;
    private Worker worker;

    @BeforeEach
    void setUp() {
        branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setName("Teszt iroda 1");

        branch2 = new Branch();
        branch2.setId(BRANCH_ID_2);
        branch2.setName("Teszt iroda 2");

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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode("EUR"))
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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
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
        movement.setInitiatedBy(worker);

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();

        when(movementRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));
        when(movementRepository.save(any(InventoryMovement.class))).thenReturn(movement);

        // Act
        inventoryService.approveMovement(1L, WORKER_ID);

        // Assert: balance csökkent (subtractBalance hívódott)
        verify(cashBalanceRepository).save(argThat((CashBalance cb) ->
                cb.getCurrentBalance().compareTo(new BigDecimal("4000")) == 0
        ));
    }

    @Test
    @DisplayName("approveMovement: BANK_DEPOSIT után státusz APPROVED (nem IN_TRANSIT)")
    void approveMovement_bankDeposit_statusIsApproved() {
        // Arrange
        InventoryMovement movement = buildMovement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING,
                eurCurrency, branch, null);
        movement.setId(2L);
        movement.setInitiatedBy(worker);

        CashBalance balance = CashBalance.builder()
                .branch(branch)
                .currency(eurCurrency)
                .currentBalance(new BigDecimal("5000"))
                .build();

        when(movementRepository.findByIdForUpdate(2L)).thenReturn(Optional.of(movement));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));

        ArgumentCaptor<InventoryMovement> captor = ArgumentCaptor.forClass(InventoryMovement.class);
        when(movementRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        // Act
        inventoryService.approveMovement(2L, WORKER_ID);

        // Assert
        assertThat(captor.getValue().getStatus()).isEqualTo(MovementStatus.APPROVED);
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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(sourceBalance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode("EUR"))
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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.empty());

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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode("EUR"))
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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode("EUR"))
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
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_ID, 2L))
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
        verify(exchangeRateRepository, never()).findLatestMidRateByCurrencyCode(anyString());
        assertThat(captor.getValue().getHufValue()).isEqualByComparingTo(new BigDecimal("50000"));
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
}
