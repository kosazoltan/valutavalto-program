package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import hu.puzzleir.valuta.dto.inventory.VaultStockChangedMessage;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * F1 fix-batch (Eszter audit) penzugyi-integritas verifikacio.
 *
 * Eszter P1 finding: a `VaultStockFlowService` korabbi `log.warn -> return` skip logikaja
 * reszleges konyveleshez vezetett (vault stock no, branch cash_balance NEM csokken).
 * A javitas: minden hianyzo referencia (branch, valuta, balance) -> ResourceNotFoundException,
 * a `@Transactional(rollbackFor = Exception.class)` a teljes muveletet visszagorgeti.
 */
@ExtendWith(MockitoExtension.class)
class VaultStockFlowServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final Integer TERRITORY_ID = 1;
    private static final UUID BRANCH_SOURCE_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID BRANCH_TARGET_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");

    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private CashBalanceRepository cashBalanceRepository;
    @Mock
    private BranchRepository branchRepository;
    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private VaultTerritoryRepository vaultTerritoryRepository;
    @Mock
    private CompanyRepository companyRepository;
    @Mock
    private org.springframework.messaging.simp.SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private VaultStockFlowService service;

    private VaultTerritory territory;
    private Branch sourceBranch;
    private Branch targetBranch;
    private Currency eurCurrency;
    private CashBalance sourceBalance;
    private CashBalance targetBalance;

    @BeforeEach
    void setUp() {
        Company company = Company.builder().id(COMPANY_ID).build();

        territory = VaultTerritory.builder()
                .id(TERRITORY_ID).company(company).active(Boolean.TRUE).build();

        sourceBranch = Branch.builder()
                .id(BRANCH_SOURCE_ID).code("BR017").company(company).build();
        targetBranch = Branch.builder()
                .id(BRANCH_TARGET_ID).code("BR035").company(company).build();

        eurCurrency = Currency.builder().id(978L).code("EUR").build();

        sourceBalance = CashBalance.builder()
                .company(company).branch(sourceBranch).currency(eurCurrency)
                .currentBalance(new BigDecimal("1000.00"))
                .openingBalance(new BigDecimal("1000.00")).build();
        targetBalance = CashBalance.builder()
                .company(company).branch(targetBranch).currency(eurCurrency)
                .currentBalance(new BigDecimal("0.00"))
                .openingBalance(new BigDecimal("0.00")).build();
    }

    // ============== applyTransfer happy path ==============

    @Test
    @DisplayName("applyTransfer: source -= amount, target += amount, save 2x")
    void applyTransfer_happyPath_decrementsAndIncrements() {
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR017")).thenReturn(Optional.of(sourceBranch));
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR035")).thenReturn(Optional.of(targetBranch));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurCurrency));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_SOURCE_ID, 978L)).thenReturn(Optional.of(sourceBalance));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_TARGET_ID, 978L)).thenReturn(Optional.of(targetBalance));
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));

        service.applyTransfer(COMPANY_ID, "BR017", "BR035", "EUR", new BigDecimal("50.00"));

        // FR-3: az applyTransfer csak branch cash_balance-t mozgat, vault currency_stock-ot NEM
        // → NEM publikál vault-stock invalidációt.
        verifyNoInteractions(messagingTemplate);

        assertThat(sourceBalance.getCurrentBalance()).isEqualByComparingTo("950.00");
        assertThat(targetBalance.getCurrentBalance()).isEqualByComparingTo("50.00");
        verify(cashBalanceRepository, times(2)).save(any(CashBalance.class));
    }

    // ============== applyTransfer FIX: hianyzo branch -> THROW (NEM skip) ==============

    @Test
    @DisplayName("FIX: applyTransfer source branch nem letezik -> ResourceNotFoundException (NEM silent skip)")
    void applyTransfer_missingSourceBranch_throwsResourceNotFound_noPartialBookkeeping() {
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR_MISSING")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.applyTransfer(COMPANY_ID, "BR_MISSING", "BR035", "EUR", new BigDecimal("50.00")))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("BR_MISSING");

        // Nem szabad EGYETLEN cash_balance save sem (atomicity)
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FIX: applyTransfer target branch nem letezik -> ResourceNotFoundException, source NEM csokken")
    void applyTransfer_missingTargetBranch_throwsResourceNotFound_sourceUnchanged() {
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR017")).thenReturn(Optional.of(sourceBranch));
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR_MISSING")).thenReturn(Optional.empty());
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurCurrency));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_SOURCE_ID, 978L)).thenReturn(Optional.of(sourceBalance));

        assertThatThrownBy(() -> service.applyTransfer(COMPANY_ID, "BR017", "BR_MISSING", "EUR", new BigDecimal("50.00")))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("BR_MISSING");

        // A source balance memoria-szinten ugyan modosult, de a Spring @Transactional rollback-elte volna.
        // Ezt unit-szinten csak az tudja igazolni, hogy a target oldalon NEM tortent save (atomicity bizonyitva).
        verify(cashBalanceRepository, never()).save(targetBalance);
    }

    @Test
    @DisplayName("FIX: applyTransfer ismeretlen valuta -> ResourceNotFoundException")
    void applyTransfer_missingCurrency_throwsResourceNotFound() {
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR017")).thenReturn(Optional.of(sourceBranch));
        when(currencyRepository.findByCode("ZZZ")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.applyTransfer(COMPANY_ID, "BR017", "BR035", "ZZZ", new BigDecimal("50.00")))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("ZZZ");

        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FIX: applyTransfer source cash_balance hianyzik -> ResourceNotFoundException")
    void applyTransfer_missingSourceBalance_throwsResourceNotFound() {
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR017")).thenReturn(Optional.of(sourceBranch));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurCurrency));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_SOURCE_ID, 978L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.applyTransfer(COMPANY_ID, "BR017", "BR035", "EUR", new BigDecimal("50.00")))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("cash_balance nem talalhato");

        verify(cashBalanceRepository, never()).save(any());
    }

    // ============== applyCollection happy path ==============

    @Test
    @DisplayName("applyCollection: source branch -= amount, vault stock += amount")
    void applyCollection_happyPath() {
        when(vaultTerritoryRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(territory));
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR017")).thenReturn(Optional.of(sourceBranch));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurCurrency));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_SOURCE_ID, 978L)).thenReturn(Optional.of(sourceBalance));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ID.toString(), "EUR"))
                .thenReturn(Optional.empty());
        when(currencyStockRepository.save(any(CurrencyStock.class))).thenAnswer(inv -> inv.getArgument(0));

        // FR-3: aktív tranzakcióban a publish CSAK afterCommit-kor megy ki (rollbacknál NEM).
        TransactionSynchronizationManager.initSynchronization();
        try {
            service.applyCollection(COMPANY_ID, "BR017", "EUR", new BigDecimal("100.00"), new BigDecimal("395.5"));

            // commit ELŐTT: a vault-stock invalidáció még nem ment ki (afterCommit-re halasztva)
            verifyNoInteractions(messagingTemplate);

            // commit szimuláció → MOST megy ki a jelzés a company-topicra
            TransactionSynchronizationManager.getSynchronizations()
                    .forEach(TransactionSynchronization::afterCommit);
            verify(messagingTemplate).convertAndSend(
                    eq("/topic/vault-stock/" + COMPANY_ID), any(VaultStockChangedMessage.class));
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }

        assertThat(sourceBalance.getCurrentBalance()).isEqualByComparingTo("900.00");
        verify(currencyStockRepository, times(2)).save(any(CurrencyStock.class)); // 1x getOrCreate + 1x receive
    }

    @Test
    @DisplayName("FIX: applyCollection nincs aktiv territory -> ValidationException (kovetkezetes)")
    void applyCollection_noActiveTerritory_throwsValidation() {
        when(vaultTerritoryRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of());

        assertThatThrownBy(() -> service.applyCollection(COMPANY_ID, "BR017", "EUR", new BigDecimal("100.00"), null))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs aktiv ertektari terulet");
    }

    // ============== applyDistributionLine ==============

    @Test
    @DisplayName("applyDistributionLine: vault stock -= amount, target branch += amount")
    void applyDistributionLine_happyPath() {
        when(vaultTerritoryRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(territory));
        Company company = Company.builder().id(COMPANY_ID).build();
        CurrencyStock vaultStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("500.00"))
                .weightedAvgCost(new BigDecimal("395.5")).build();

        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ID.toString(), "EUR"))
                .thenReturn(Optional.of(vaultStock));
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR035")).thenReturn(Optional.of(targetBranch));
        when(currencyRepository.findByCode("EUR")).thenReturn(Optional.of(eurCurrency));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(BRANCH_TARGET_ID, 978L)).thenReturn(Optional.of(targetBalance));
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));

        // FR-3: aktív tranzakcióban a publish CSAK afterCommit-kor megy ki (rollbacknál NEM).
        TransactionSynchronizationManager.initSynchronization();
        try {
            service.applyDistributionLine(COMPANY_ID, "BR035", "EUR", new BigDecimal("100.00"));

            assertThat(vaultStock.getQuantity()).isEqualByComparingTo("400.00");
            assertThat(targetBalance.getCurrentBalance()).isEqualByComparingTo("100.00");

            // commit ELŐTT: a jelzés még nem ment ki
            verifyNoInteractions(messagingTemplate);

            // commit szimuláció → MOST megy ki a jelzés a company-topicra
            TransactionSynchronizationManager.getSynchronizations()
                    .forEach(TransactionSynchronization::afterCommit);
            verify(messagingTemplate).convertAndSend(
                    eq("/topic/vault-stock/" + COMPANY_ID), any(VaultStockChangedMessage.class));
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    @DisplayName("FIX: applyDistributionLine target branch hianyzik -> ResourceNotFoundException")
    void applyDistributionLine_missingTargetBranch_throwsResourceNotFound() {
        when(vaultTerritoryRepository.findByCompanyIdAndActiveTrue(COMPANY_ID)).thenReturn(List.of(territory));
        Company company = Company.builder().id(COMPANY_ID).build();
        CurrencyStock vaultStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ID.toString())
                .currencyCode("EUR").quantity(new BigDecimal("500.00"))
                .weightedAvgCost(new BigDecimal("395.5")).build();
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ID.toString(), "EUR"))
                .thenReturn(Optional.of(vaultStock));
        when(branchRepository.findByCompanyIdAndCode(COMPANY_ID, "BR_MISSING")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.applyDistributionLine(COMPANY_ID, "BR_MISSING", "EUR", new BigDecimal("100.00")))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("BR_MISSING");

        // Atomicity: a target oldal nem mentodott (a forras-oldal save-je transactional rollback-kel terul vissza)
        verify(cashBalanceRepository, never()).save(any());
    }
}
