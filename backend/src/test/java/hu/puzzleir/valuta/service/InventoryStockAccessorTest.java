package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.ArgumentCaptor;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.times;

@ExtendWith(MockitoExtension.class)
class InventoryStockAccessorTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID CASHIER_BRANCH_ID = UUID.randomUUID();
    private static final UUID VAULT_BRANCH_ID = UUID.randomUUID();
    private static final Long CURRENCY_ID = 978L;

    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;

    @InjectMocks
    private InventoryStockAccessor accessor;

    private Company company;
    private Currency eur;
    private Branch cashierBranch;
    private Branch vaultBranch;

    @BeforeEach
    void setUp() {
        company = new Company();
        company.setId(COMPANY_ID);

        eur = new Currency();
        eur.setId(CURRENCY_ID);
        eur.setCode("EUR");
        eur.setName("Euró");

        cashierBranch = Branch.builder()
                .id(CASHIER_BRANCH_ID)
                .company(company)
                .code("BR001")
                .name("Pénztár")
                .isVault(false)
                .build();

        vaultBranch = Branch.builder()
                .id(VAULT_BRANCH_ID)
                .company(company)
                .code("VLT01")
                .name("Értéktár")
                .isVault(true)
                .vaultTerritoryId(12)
                .build();
    }

    @Test
    @DisplayName("nem-vault ág: cash_balance-ből olvas és a meglévő hibaüzenettel fail-closed")
    void getBalance_nonVaultReadsCashBalance() {
        CashBalance balance = CashBalance.builder()
                .branch(cashierBranch)
                .currency(eur)
                .currentBalance(new BigDecimal("1500.00"))
                .build();
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(CASHIER_BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));

        assertThat(accessor.getBalance(cashierBranch, eur)).isEqualByComparingTo("1500.00");
    }

    @Test
    @DisplayName("vault ág: currency_stock VAULT sort olvas companyId + vaultTerritoryId + currencyCode kulccsal")
    void getBalance_vaultReadsCurrencyStockWithTenantScope() {
        CurrencyStock stock = CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId("12")
                .currencyCode("EUR")
                .quantity(new BigDecimal("4200.00"))
                .weightedAvgCost(new BigDecimal("395.0000"))
                .build();
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.of(stock));

        assertThat(accessor.getBalance(vaultBranch, eur)).isEqualByComparingTo("4200.00");
        verify(currencyStockRepository).findForUpdate(COMPANY_ID, "VAULT", "12", "EUR");
    }

    @Test
    @DisplayName("vault ág: vaultTerritoryId nélkül fail-closed ValidationException")
    void getBalance_vaultWithoutTerritoryFailsClosed() {
        vaultBranch.setVaultTerritoryId(null);

        assertThatThrownBy(() -> accessor.getBalance(vaultBranch, eur))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("vault_territory_id")
                .hasMessageContaining("készletkönyvelés nem végezhető el");
    }

    @Test
    @DisplayName("nem-vault ág: pozitív és negatív delta ugyanazzal az updateBalance+save mintával könyvelődik")
    void adjust_nonVaultUsesCashBalanceUpdateBalanceAndSaveForPositiveAndNegativeDeltas() {
        CashBalance balance = CashBalance.builder()
                .branch(cashierBranch)
                .currency(eur)
                .currentBalance(new BigDecimal("1000.00"))
                .build();
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(CASHIER_BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));

        accessor.adjust(cashierBranch, eur, new BigDecimal("125.00"));
        accessor.adjust(cashierBranch, eur, new BigDecimal("-25.00"));

        assertThat(balance.getCurrentBalance()).isEqualByComparingTo("1100.00");
        verify(cashBalanceRepository, times(2)).save(balance);
    }

    @Test
    @DisplayName("vault ág: adjust csökkenti a quantity-t, de a WAC unit_cost nem változik")
    void adjust_vaultDecreasesQuantityWithoutChangingWac() {
        CurrencyStock stock = CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId("12")
                .currencyCode("EUR")
                .quantity(new BigDecimal("1000.00"))
                .weightedAvgCost(new BigDecimal("397.2500"))
                .build();
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.of(stock));

        accessor.adjust(vaultBranch, eur, new BigDecimal("-250.00"));

        assertThat(stock.getQuantity()).isEqualByComparingTo("750.00");
        assertThat(stock.getWeightedAvgCost()).isEqualByComparingTo("397.2500");
        verify(currencyStockRepository).save(stock);
    }

    @Test
    @DisplayName("vault ág: hiányzó pozitív stock sort saveAndFlush-sal hoz létre")
    void adjust_vaultCreatesMissingPositiveStockWithSaveAndFlush() {
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.empty());

        accessor.adjust(vaultBranch, eur, new BigDecimal("125.00"));

        ArgumentCaptor<CurrencyStock> captor = ArgumentCaptor.forClass(CurrencyStock.class);
        verify(currencyStockRepository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getCompany()).isSameAs(company);
        assertThat(captor.getValue().getEntityType()).isEqualTo("VAULT");
        assertThat(captor.getValue().getEntityId()).isEqualTo("12");
        assertThat(captor.getValue().getCurrencyCode()).isEqualTo("EUR");
        assertThat(captor.getValue().getQuantity()).isEqualByComparingTo("125.00");
        assertThat(captor.getValue().getWeightedAvgCost()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("vault ág: párhuzamos első insert unique ütközés után lockolt újraolvasással retry-ol")
    void adjust_vaultRetriesAfterConcurrentFirstInsertRace() {
        CurrencyStock locked = CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId("12")
                .currencyCode("EUR")
                .quantity(new BigDecimal("200.00"))
                .weightedAvgCost(new BigDecimal("397.2500"))
                .build();
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.empty(), Optional.of(locked));
        when(currencyStockRepository.saveAndFlush(any(CurrencyStock.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate currency_stock"));

        accessor.adjust(vaultBranch, eur, new BigDecimal("125.00"));

        assertThat(locked.getQuantity()).isEqualByComparingTo("325.00");
        assertThat(locked.getWeightedAvgCost()).isEqualByComparingTo("397.2500");
        verify(currencyStockRepository).save(locked);
    }

    @Test
    @DisplayName("vault ág: tenant-szűrt hiányzó stock nem pótolható más cég sorával")
    void adjust_vaultMissingTenantScopedStockFails() {
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> accessor.adjust(vaultBranch, eur, new BigDecimal("-10.00")))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nincs elegendő készlet");
    }
}
