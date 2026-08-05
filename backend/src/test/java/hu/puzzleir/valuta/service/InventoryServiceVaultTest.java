package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.inventory.BankDepositRequestDto;
import hu.puzzleir.valuta.dto.inventory.BankWithdrawRequestDto;
import hu.puzzleir.valuta.dto.inventory.BranchTransferRequestDto;
import hu.puzzleir.valuta.dto.inventory.CorrectionRequestDto;
import hu.puzzleir.valuta.dto.inventory.InventoryMovementDto;
import hu.puzzleir.valuta.dto.inventory.ReceiveMovementDto;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.InventoryMovement;
import hu.puzzleir.valuta.entity.MovementStatus;
import hu.puzzleir.valuta.entity.MovementType;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.InventoryMovementRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class InventoryServiceVaultTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID VAULT_BRANCH_ID = UUID.randomUUID();
    private static final UUID CASHIER_BRANCH_ID = UUID.randomUUID();
    private static final Long CURRENCY_ID = 978L;
    private static final Long WORKER_ID = 10L;

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

    @InjectMocks
    private InventoryService inventoryService;

    private Company company;
    private Branch vaultBranch;
    private Branch cashierBranch;
    private Currency eur;
    private Worker worker;
    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

        company = new Company();
        company.setId(COMPANY_ID);

        vaultBranch = Branch.builder()
                .id(VAULT_BRANCH_ID)
                .company(company)
                .code("VLT01")
                .name("Szekszárd Értéktár")
                .isVault(true)
                .vaultTerritoryId(12)
                .build();
        cashierBranch = Branch.builder()
                .id(CASHIER_BRANCH_ID)
                .company(company)
                .code("BR001")
                .name("Szekszárd Pénztár")
                .isVault(false)
                .build();

        eur = new Currency();
        eur.setId(CURRENCY_ID);
        eur.setCode("EUR");
        eur.setName("Euró");

        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setName("Értéktáros");

        when(branchRepository.findById(VAULT_BRANCH_ID)).thenReturn(Optional.of(vaultBranch));
        when(branchRepository.findById(CASHIER_BRANCH_ID)).thenReturn(Optional.of(cashierBranch));
        when(currencyRepository.findById(CURRENCY_ID)).thenReturn(Optional.of(eur));
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(exchangeRateRepository.findLatestMidRateByCurrencyCode(eq(COMPANY_ID), eq("EUR")))
                .thenReturn(Optional.of(new BigDecimal("390")));
        when(movementRepository.findMaxReferenceNumber(anyString())).thenReturn(0L);
        when(movementRepository.save(any(InventoryMovement.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) {
            securityUtilsMock.close();
        }
    }

    @Test
    @DisplayName("vault bankbefizetés: currency_stock egyenlegen ellenőriz, mozgássort ír, de PENDING-ben nem terhel")
    void depositToBank_vaultChecksCurrencyStockAndCreatesPendingMovement() {
        when(stockAccessor.getBalance(vaultBranch, eur)).thenReturn(new BigDecimal("5000.00"));
        BankDepositRequestDto dto = BankDepositRequestDto.builder()
                .branchId(VAULT_BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("1000.00"))
                .notes("Vault bank befizetés")
                .build();

        InventoryMovementDto result = inventoryService.depositToBank(dto, WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("PENDING");
        verify(stockAccessor).getBalance(vaultBranch, eur);
        verify(stockAccessor, never()).adjust(any(), any(), any());
        verify(movementRepository).save(any(InventoryMovement.class));
    }

    @Test
    @DisplayName("vault bankbefizetés: elégtelen currency_stock készlet ValidationException")
    void depositToBank_vaultInsufficientStockFails() {
        when(stockAccessor.getBalance(vaultBranch, eur)).thenReturn(new BigDecimal("50.00"));
        BankDepositRequestDto dto = BankDepositRequestDto.builder()
                .branchId(VAULT_BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("1000.00"))
                .build();

        assertThatThrownBy(() -> inventoryService.depositToBank(dto, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs elegendő készlet");
    }

    @Test
    @DisplayName("vault bankkivét: receive jóváírja a cél vault currency_stock-ot")
    void receiveMovement_bankWithdrawCreditsVaultStock() {
        InventoryMovement movement = movement(MovementType.BANK_WITHDRAW, MovementStatus.IN_TRANSIT, null, vaultBranch, new BigDecimal("1000.00"));
        movement.setId(1L);
        when(movementRepository.findByIdForUpdate(1L)).thenReturn(Optional.of(movement));

        inventoryService.receiveMovement(1L, WORKER_ID, ReceiveMovementDto.builder()
                .receivedAmount(new BigDecimal("950.00"))
                .build());

        verify(stockAccessor).adjust(vaultBranch, eur, new BigDecimal("950.00"));
        verify(movementRepository).save(movement);
    }

    @Test
    @DisplayName("vault bankbefizetés jóváhagyás: a vault currency_stock-ot terheli")
    void approveMovement_bankDepositDebitsVaultStock() {
        InventoryMovement movement = movement(MovementType.BANK_DEPOSIT, MovementStatus.PENDING, vaultBranch, null, new BigDecimal("1000.00"));
        movement.setId(2L);
        Worker initiator = new Worker();
        initiator.setId(99L);
        movement.setInitiatedBy(initiator);
        when(movementRepository.findByIdForUpdate(2L)).thenReturn(Optional.of(movement));

        inventoryService.approveMovement(2L, WORKER_ID);

        verify(stockAccessor).adjust(vaultBranch, eur, new BigDecimal("-1000.00"));
        assertThat(movement.getStatus()).isEqualTo(MovementStatus.APPROVED);
    }

    @Test
    @DisplayName("vault→pénztár átadás: receive a forrást terheli és a cél cash_balance rezsimet jóváírja")
    void receiveMovement_vaultToCashierTransferDebitsAndCreditsBothSides() {
        InventoryMovement movement = movement(MovementType.BRANCH_TRANSFER, MovementStatus.IN_TRANSIT,
                vaultBranch, cashierBranch, new BigDecimal("1000.00"));
        movement.setId(3L);
        when(movementRepository.findByIdForUpdate(3L)).thenReturn(Optional.of(movement));

        inventoryService.receiveMovement(3L, WORKER_ID, ReceiveMovementDto.builder()
                .receivedAmount(new BigDecimal("990.00"))
                .build());

        verify(stockAccessor).adjust(vaultBranch, eur, new BigDecimal("-1000.00"));
        verify(stockAccessor).adjust(cashierBranch, eur, new BigDecimal("990.00"));
        verify(movementRepository).save(movement);
        verify(auditLogRepository).save(any(AuditLog.class));
    }

    @Test
    @DisplayName("vault korrekció: régi currency_stock egyenleghez képest diffet könyvel és inventory_movement sort ír")
    void correctInventory_vaultAdjustsCurrencyStockByDifferenceAndWritesMovement() {
        when(stockAccessor.getBalance(vaultBranch, eur)).thenReturn(new BigDecimal("1000.00"));
        when(stockAccessor.isVaultContext(vaultBranch)).thenReturn(true);
        CorrectionRequestDto dto = CorrectionRequestDto.builder()
                .branchId(VAULT_BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .newAmount(new BigDecimal("1250.00"))
                .reason("Leltár")
                .build();

        inventoryService.correctInventory(dto, WORKER_ID);

        verify(stockAccessor).adjust(vaultBranch, eur, new BigDecimal("250.0000"));
        verify(movementRepository).save(any(InventoryMovement.class));
        verify(auditLogRepository).save(any(AuditLog.class));
    }

    @Test
    @DisplayName("vault transfer kérés: source currency_stock elégség-ellenőrzés után PENDING mozgássort ír")
    void transferBetweenBranches_vaultSourceChecksStockAndCreatesMovement() {
        when(stockAccessor.getBalance(vaultBranch, eur)).thenReturn(new BigDecimal("1000.00"));
        BranchTransferRequestDto dto = BranchTransferRequestDto.builder()
                .fromBranchId(VAULT_BRANCH_ID.toString())
                .toBranchId(CASHIER_BRANCH_ID.toString())
                .currencyId(CURRENCY_ID)
                .amount(new BigDecimal("300.00"))
                .build();

        InventoryMovementDto result = inventoryService.transferBetweenBranches(dto, WORKER_ID);

        assertThat(result.getStatus()).isEqualTo("PENDING");
        verify(stockAccessor).getBalance(vaultBranch, eur);
        verify(movementRepository).save(any(InventoryMovement.class));
    }

    // ============ FKH-029 kieg.: getCurrentStock vault-delegálás ============

    @Test
    @DisplayName("FKH-029 kieg.: getCurrentStock vault branch-re a currency_stock VAULT soraiból ad készletet, nem a 0-s cash_balance-ból")
    void getCurrentStock_vaultBranch_readsCurrencyStock() {
        // Sourcery-kör: a territory-szűrés a dedikált repo-query dolga — a szivárgás-mentességet
        // a PONTOS territory-argumentum verify-je garantálja.
        when(currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityId(COMPANY_ID, "VAULT", "12"))
                .thenReturn(List.of(vaultStockRow("12", "EUR", "5000.00")));
        when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of(eur));

        List<CashBalance> result = inventoryService.getCurrentStock(VAULT_BRANCH_ID);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCurrency().getCode()).isEqualTo("EUR");
        assertThat(result.get(0).getCurrentBalance()).isEqualByComparingTo("5000.00");
        assertThat(result.get(0).getBranch().getId()).isEqualTo(VAULT_BRANCH_ID);
        verify(currencyStockRepository).findByCompanyIdAndEntityTypeAndEntityId(COMPANY_ID, "VAULT", "12");
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }

    @Test
    @DisplayName("FKH-029 kieg.: getCurrentStock pénztári branch-re változatlanul cash_balance-ból olvas")
    void getCurrentStock_cashierBranch_unchangedCashBalancePath() {
        CashBalance cb = CashBalance.builder()
                .branch(cashierBranch).currency(eur).currentBalance(new BigDecimal("100")).build();
        when(cashBalanceRepository.findByBranchIdAndCompanyId(CASHIER_BRANCH_ID, COMPANY_ID))
                .thenReturn(List.of(cb));

        List<CashBalance> result = inventoryService.getCurrentStock(CASHIER_BRANCH_ID);

        assertThat(result).containsExactly(cb);
        verify(currencyStockRepository, never()).findByCompanyIdAndEntityTypeAndEntityId(any(), any(), any());
    }

    @Test
    @DisplayName("FKH-029 kieg.: getCurrentStock vault branch-re vault_territory_id nélkül üres listát ad (fail-closed, nincs kivétel)")
    void getCurrentStock_vaultBranchWithoutTerritory_returnsEmpty() {
        vaultBranch.setVaultTerritoryId(null);

        List<CashBalance> result = inventoryService.getCurrentStock(VAULT_BRANCH_ID);

        assertThat(result).isEmpty();
        verify(currencyStockRepository, never()).findByCompanyIdAndEntityTypeAndEntityId(any(), any(), any());
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }

    private CurrencyStock vaultStockRow(String territoryEntityId, String currencyCode, String quantity) {
        return CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId(territoryEntityId)
                .currencyCode(currencyCode)
                .quantity(new BigDecimal(quantity))
                .lastUpdated(java.time.LocalDateTime.now())
                .build();
    }

    private InventoryMovement movement(MovementType type, MovementStatus status,
                                       Branch fromBranch, Branch toBranch, BigDecimal amount) {
        return InventoryMovement.builder()
                .fromBranch(fromBranch)
                .toBranch(toBranch)
                .currency(eur)
                .amount(amount)
                .hufValue(amount.multiply(new BigDecimal("390")))
                .movementType(type)
                .status(status)
                .initiatedBy(worker)
                .referenceNumber("INV-20260703-0001")
                .movementDate(LocalDate.now())
                .movementTime(LocalTime.now())
                .build();
    }
}
