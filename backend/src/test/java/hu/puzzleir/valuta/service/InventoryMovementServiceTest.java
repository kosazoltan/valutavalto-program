package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.inventory.InventoryBalanceDto;
import hu.puzzleir.valuta.dto.inventory.InventoryMovementDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.InventoryMovementRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.data.domain.Page;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Multi-tenant IDOR guard tesztek a branchId-vel paraméterezett lekérdezésekre
 * (audit/Codex P1 #934): a getMovements / getDailyBalance csak a hívó cégének irodájára szólhat,
 * és a cash-balance lookup nem szivárogtathat idegen egyenleget.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class InventoryMovementServiceTest {

    @InjectMocks private InventoryMovementService service;

    @Mock private InventoryMovementRepository movementRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private AccessScopeService accessScopeService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OWN_BRANCH = UUID.randomUUID();
    private static final UUID FOREIGN_BRANCH = UUID.randomUUID();

    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        when(accessScopeService.isBranchVisible(isNull(), anyString())).thenReturn(true);
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) {
            securityUtilsMock.close();
        }
    }

    @Test
    @DisplayName("getDailyBalance: idegen cég irodája → 404, NINCS cash_balance lookup (nincs egyenleg-szivárgás)")
    void getDailyBalance_foreignBranch_throwsNotFoundAndNoBalanceLeak() {
        when(branchRepository.existsByIdAndCompanyId(FOREIGN_BRANCH, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.getDailyBalance(FOREIGN_BRANCH, "EUR", LocalDate.now()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Iroda nem található");
        verify(cashBalanceRepository, never()).findByBranchId(any());
        verify(movementRepository, never()).search(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("getMovements: idegen cég irodája → 404, NINCS mozgás-lekérdezés")
    void getMovements_foreignBranch_throwsNotFound() {
        when(branchRepository.existsByIdAndCompanyId(FOREIGN_BRANCH, COMPANY_ID)).thenReturn(false);

        assertThatThrownBy(() -> service.getMovements(FOREIGN_BRANCH, "EUR", LocalDate.now()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Iroda nem található");
        verify(movementRepository, never()).search(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("getDailyBalance: saját iroda → a cégre szűrt mozgás-query fut, egyenleg visszaadva")
    void getDailyBalance_ownBranch_succeeds() {
        when(branchRepository.existsByIdAndCompanyId(OWN_BRANCH, COMPANY_ID)).thenReturn(true);
        when(movementRepository.search(eq(COMPANY_ID), eq(OWN_BRANCH), any(), any(), any(), any(), any()))
                .thenReturn(Page.empty());
        Currency eur = new Currency();
        eur.setId(1L);
        eur.setCode("EUR");
        CashBalance cb = CashBalance.builder().currency(eur).currentBalance(new BigDecimal("1000")).build();
        when(cashBalanceRepository.findByBranchId(OWN_BRANCH)).thenReturn(List.of(cb));

        InventoryBalanceDto result = service.getDailyBalance(OWN_BRANCH, "EUR", LocalDate.now());

        assertThat(result).isNotNull();
        assertThat(result.getClosingBalance()).isEqualByComparingTo(new BigDecimal("1000.0000"));
        verify(movementRepository).search(eq(COMPANY_ID), eq(OWN_BRANCH), any(), any(), any(), any(), any());
    }

    // ============ FR-0 (FK-039): movement-log territory-scoping ============
    // ERTEKTAR (territory-scoped) CSAK a saját vault_territory pénztárainak mozgásait kérheti le.
    // Központi role (foertektar/ugyvezeto/manager/admin) → companyId-scope a határ, nincs területi megkötés.

    private static final UUID USER_BRANCH = UUID.randomUUID();

    private static Branch branchWithTerritory(Integer territoryId) {
        return Branch.builder().vaultTerritoryId(territoryId).build();
    }

    @Test
    @DisplayName("getMovements: ERTEKTAR a SAJÁT territory pénztárát lekérheti (mozgás-query fut)")
    void getMovements_ertektar_ownTerritory_succeeds() {
        when(branchRepository.existsByIdAndCompanyId(OWN_BRANCH, COMPANY_ID)).thenReturn(true);
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(USER_BRANCH);
        when(branchRepository.findById(USER_BRANCH)).thenReturn(Optional.of(branchWithTerritory(1)));
        when(branchRepository.findById(OWN_BRANCH)).thenReturn(Optional.of(branchWithTerritory(1)));
        when(movementRepository.search(eq(COMPANY_ID), eq(OWN_BRANCH), any(), any(), any(), any(), any()))
                .thenReturn(Page.empty());

        List<InventoryMovementDto> result = service.getMovements(OWN_BRANCH, null, LocalDate.now());

        assertThat(result).isNotNull();
        verify(movementRepository).search(eq(COMPANY_ID), eq(OWN_BRANCH), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("getMovements: ERTEKTAR IDEGEN territory pénztárát NEM kérheti le (404, nincs mozgás-query)")
    void getMovements_ertektar_otherTerritory_throws404() {
        when(branchRepository.existsByIdAndCompanyId(OWN_BRANCH, COMPANY_ID)).thenReturn(true);
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ertektar");
        // FK-039 szándék az AccessScopeService-en át: az idegen-territory pénztár NEM látható
        // a hívó vault/region scope-jában → 404 (cross-territory szivárgás ellen).
        when(accessScopeService.isBranchVisible(any(), eq(OWN_BRANCH.toString()))).thenReturn(false);

        assertThatThrownBy(() -> service.getMovements(OWN_BRANCH, null, LocalDate.now()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Iroda nem található");
        verify(movementRepository, never()).search(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("getMovements: ERTEKTAR vault_territory NÉLKÜL → fail-closed (404, nincs mozgás-query)")
    void getMovements_ertektar_noTerritory_failClosed() {
        when(branchRepository.existsByIdAndCompanyId(OWN_BRANCH, COMPANY_ID)).thenReturn(true);
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ertektar");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ertektar");
        // AccessScopeService fail-closed: ha a territory-scoped role-nak nincs meghatározható
        // scope-ja, a pénztár nem látható → 404 (nincs cross-territory szivárgás).
        when(accessScopeService.isBranchVisible(any(), eq(OWN_BRANCH.toString()))).thenReturn(false);

        assertThatThrownBy(() -> service.getMovements(OWN_BRANCH, null, LocalDate.now()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Iroda nem található");
        verify(movementRepository, never()).search(any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("getMovements: központi role (ugyvezeto) területi megkötés NÉLKÜL kérheti le a cégen belüli pénztárt")
    void getMovements_centralRole_anyBranch_succeeds() {
        when(branchRepository.existsByIdAndCompanyId(OWN_BRANCH, COMPANY_ID)).thenReturn(true);
        securityUtilsMock.when(SecurityUtils::getActiveOperationalRole).thenReturn("ugyvezeto");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ugyvezeto");
        when(movementRepository.search(eq(COMPANY_ID), eq(OWN_BRANCH), any(), any(), any(), any(), any()))
                .thenReturn(Page.empty());

        List<InventoryMovementDto> result = service.getMovements(OWN_BRANCH, null, LocalDate.now());

        assertThat(result).isNotNull();
        verify(movementRepository).search(eq(COMPANY_ID), eq(OWN_BRANCH), any(), any(), any(), any(), any());
        // központi role → NEM kérdez le user-branch territory-t
        verify(branchRepository, never()).findById(any());
    }
}
