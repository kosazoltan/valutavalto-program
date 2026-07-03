package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
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
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Batch3-B (currency_stock-doc FR-1/FR-2): a generikus átadás-átvétel vault-ági
 * currency_stock tükrözésének unit tesztjei.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class VaultStockFlowGenericTest {

    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private VaultTerritoryRepository vaultTerritoryRepository;
    @Mock private CompanyRepository companyRepository;

    @InjectMocks private VaultStockFlowService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    private Branch vaultBranch(Integer territoryId) {
        Company company = new Company();
        company.setId(COMPANY_ID);
        Branch b = new Branch();
        b.setCode("BR020");
        b.setName("Szeged Értéktár");
        b.setIsVault(true);
        b.setVaultTerritoryId(territoryId);
        b.setCompany(company);
        return b;
    }

    private CurrencyStock stock(String code, String qty, String wac) {
        return CurrencyStock.builder()
                .company(Company.builder().id(COMPANY_ID).build())
                .entityType("VAULT")
                .entityId("3")
                .currencyCode(code)
                .quantity(new BigDecimal(qty))
                .weightedAvgCost(new BigDecimal(wac))
                .lastUpdated(LocalDateTime.now())
                .build();
    }

    @BeforeEach
    void setUp() {
        when(currencyStockRepository.save(any(CurrencyStock.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    @DisplayName("nem-vault branch: no-op (nincs stock-lekérdezés)")
    void nonVaultBranchIsNoOp() {
        Branch penztar = vaultBranch(3);
        penztar.setIsVault(false);
        service.applyGenericVaultStock(penztar, "EUR", new BigDecimal("100"), true);
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("kitöltetlen vault_territory_id → EXPLICIT ValidationException (doc edge-case: ne csendes 0)")
    void missingTerritoryThrowsExplicitly() {
        Branch vault = vaultBranch(null);
        assertThatThrownBy(() ->
                service.applyGenericVaultStock(vault, "EUR", new BigDecimal("100"), true))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("vault_territory_id");
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("növelés: a quantity nő, a meglévő WAC változatlan (átlagár-invariáns belső mozgásnál)")
    void increaseKeepsExistingWac() {
        CurrencyStock s = stock("EUR", "100", "395.5000");
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "3", "EUR"))
                .thenReturn(Optional.of(s));

        service.applyGenericVaultStock(vaultBranch(3), "EUR", new BigDecimal("50"), true);

        assertThat(s.getQuantity()).isEqualByComparingTo("150");
        assertThat(s.getWeightedAvgCost()).isEqualByComparingTo("395.5000");
        verify(currencyStockRepository).save(s);
    }

    @Test
    @DisplayName("HUF növelés üres stockon: WAC=1 (V159 konvenció)")
    void hufIncreaseOnEmptyStockUsesWacOne() {
        CurrencyStock s = stock("HUF", "0", "0");
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "3", "HUF"))
                .thenReturn(Optional.of(s));

        service.applyGenericVaultStock(vaultBranch(3), "HUF", new BigDecimal("100000"), true);

        assertThat(s.getQuantity()).isEqualByComparingTo("100000");
        assertThat(s.getWeightedAvgCost()).isEqualByComparingTo("1");
    }

    @Test
    @DisplayName("csökkentés elegendő készletnél: issueStock útvonal")
    void decreaseWithSufficientStock() {
        CurrencyStock s = stock("USD", "500", "350.0000");
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "3", "USD"))
                .thenReturn(Optional.of(s));

        service.applyGenericVaultStock(vaultBranch(3), "USD", new BigDecimal("200"), false);

        assertThat(s.getQuantity()).isEqualByComparingTo("300");
    }

    @Test
    @DisplayName("csökkentés ELÉGTELEN készletnél: fail-closed, a stock változatlan marad")
    void decreaseWithInsufficientStockFailsClosed() {
        CurrencyStock s = stock("USD", "100", "350.0000");
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "3", "USD"))
                .thenReturn(Optional.of(s));

        // FK-053 terv (2026-07-03): "FEDEZET NÉLKÜL NINCS PÉNZMOZGÁS" — a régi negatív stock spec hibás volt.
        assertThatThrownBy(() ->
                service.applyGenericVaultStock(vaultBranch(3), "USD", new BigDecimal("250"), false))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("készleten túli forgalmazás tiltva");
        assertThat(s.getQuantity()).isEqualByComparingTo("100");
    }

    @Test
    @DisplayName("hiányzó stock-sor: getOrCreateStock létrehozza (qty=0, wac=0), majd könyvel")
    void missingStockRowIsCreated() {
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", "3", "CHF"))
                .thenReturn(Optional.empty());

        service.applyGenericVaultStock(vaultBranch(3), "CHF", new BigDecimal("40"), true);

        verify(currencyStockRepository, times(2)).save(any(CurrencyStock.class));
    }
}
