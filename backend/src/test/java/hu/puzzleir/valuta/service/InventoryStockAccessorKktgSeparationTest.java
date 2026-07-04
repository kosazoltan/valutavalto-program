package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
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
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InventoryStockAccessorKktgSeparationTest {

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
    @DisplayName("KKTG: vault getBalance nem olvas cash_balance repository-t")
    void getBalance_vaultNeverTouchesCashBalanceRepository() {
        CurrencyStock stock = vaultStock("4200.00");
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.of(stock));

        assertThat(accessor.getBalance(vaultBranch, eur)).isEqualByComparingTo("4200.00");

        verify(currencyStockRepository).findForUpdate(COMPANY_ID, "VAULT", "12", "EUR");
        verifyNoInteractions(cashBalanceRepository);
    }

    @Test
    @DisplayName("KKTG: vault adjust nem ír cash_balance repository-t")
    void adjust_vaultNeverTouchesCashBalanceRepository() {
        CurrencyStock stock = vaultStock("1000.00");
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.of(stock));

        accessor.adjust(vaultBranch, eur, new BigDecimal("125.00"));

        assertThat(stock.getQuantity()).isEqualByComparingTo("1125.00");
        verify(currencyStockRepository).save(stock);
        verifyNoInteractions(cashBalanceRepository);
    }

    @Test
    @DisplayName("KKTG: pénztár getBalance nem olvas currency_stock repository-t")
    void getBalance_cashierNeverTouchesCurrencyStockRepository() {
        CashBalance balance = cashBalance("1500.00");
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(CASHIER_BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));

        assertThat(accessor.getBalance(cashierBranch, eur)).isEqualByComparingTo("1500.00");

        verify(cashBalanceRepository).findByBranchIdAndCurrencyId(CASHIER_BRANCH_ID, CURRENCY_ID);
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("KKTG: pénztár adjust nem ír currency_stock repository-t")
    void adjust_cashierNeverTouchesCurrencyStockRepository() {
        CashBalance balance = cashBalance("1000.00");
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(CASHIER_BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(balance));

        accessor.adjust(cashierBranch, eur, new BigDecimal("-75.00"));

        assertThat(balance.getCurrentBalance()).isEqualByComparingTo("925.00");
        verify(cashBalanceRepository).save(balance);
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("KKTG: vegyes vault+pénztár szekvencia csak a saját készlettábláját módosítja")
    void adjust_mixedSequenceKeepsVaultAndCashierDeltasSeparated() {
        CurrencyStock vaultStock = vaultStock("1000.00");
        CashBalance cashierBalance = cashBalance("500.00");
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "12", "EUR"))
                .thenReturn(Optional.of(vaultStock));
        when(cashBalanceRepository.findByBranchIdAndCurrencyId(CASHIER_BRANCH_ID, CURRENCY_ID))
                .thenReturn(Optional.of(cashierBalance));

        accessor.adjust(vaultBranch, eur, new BigDecimal("200.00"));
        accessor.adjust(cashierBranch, eur, new BigDecimal("-50.00"));

        assertThat(vaultStock.getQuantity()).isEqualByComparingTo("1200.00");
        assertThat(cashierBalance.getCurrentBalance()).isEqualByComparingTo("450.00");
        verify(currencyStockRepository).save(vaultStock);
        verify(cashBalanceRepository).save(cashierBalance);
    }

    private CurrencyStock vaultStock(String quantity) {
        return CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId("12")
                .currencyCode("EUR")
                .quantity(new BigDecimal(quantity))
                .weightedAvgCost(new BigDecimal("397.2500"))
                .build();
    }

    private CashBalance cashBalance(String currentBalance) {
        return CashBalance.builder()
                .branch(cashierBranch)
                .currency(eur)
                .currentBalance(new BigDecimal(currentBalance))
                .build();
    }
}
