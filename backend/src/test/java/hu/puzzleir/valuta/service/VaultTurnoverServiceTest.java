package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-066 FR-1/FR-2: the vault-facing daily turnover endpoint is territory-scoped.
 *
 * <p>Territory leakage is the whole point of this ticket: opening the existing turnover data to
 * ERTEKTAR without a scope check would let a vault manager read another territory's cash desk
 * turnover. A branch outside the caller's scope must behave as if it did not exist (404), which
 * is the established convention of {@code InventoryMovementService.requireOwnBranch}.</p>
 */
class VaultTurnoverServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID OWN_BRANCH = UUID.fromString("20000000-0000-0000-0000-00000000000a");
    private static final UUID FOREIGN_BRANCH = UUID.fromString("30000000-0000-0000-0000-00000000000f");
    private static final LocalDate DATE = LocalDate.of(2026, 9, 10);

    private final BranchRepository branchRepository = mock(BranchRepository.class);
    private final AccessScopeService accessScopeService = mock(AccessScopeService.class);
    private final TurnoverService turnoverService = mock(TurnoverService.class);

    private final VaultTurnoverService service =
            new VaultTurnoverService(branchRepository, accessScopeService, turnoverService);

    private void withCompany(Runnable body) {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            body.run();
        }
    }

    @Test
    @DisplayName("FR-2: own-territory branch delegates to the EXISTING daily aggregation unchanged")
    void ownBranchDelegatesToExistingAggregation() {
        withCompany(() -> {
            when(branchRepository.existsByIdAndCompanyId(OWN_BRANCH, COMPANY_ID)).thenReturn(true);
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of(OWN_BRANCH));
            when(accessScopeService.isBranchVisible(any(), any())).thenReturn(true);
            TurnoverReportDto expected = TurnoverReportDto.builder().period(DATE.toString()).build();
            when(turnoverService.getDailyTurnover(OWN_BRANCH, DATE)).thenReturn(expected);

            TurnoverReportDto actual = service.getVaultDailyTurnover(OWN_BRANCH, DATE);

            // No new calculation: the very same report object the existing endpoint would return.
            assertThat(actual).isSameAs(expected);
            verify(turnoverService).getDailyTurnover(OWN_BRANCH, DATE);
        });
    }

    @Test
    @DisplayName("FR-1: a branch outside the vault territory scope yields 404 and is NEVER queried")
    void foreignTerritoryBranchIsNotFound() {
        withCompany(() -> {
            when(branchRepository.existsByIdAndCompanyId(FOREIGN_BRANCH, COMPANY_ID)).thenReturn(true);
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of(OWN_BRANCH));
            when(accessScopeService.isBranchVisible(any(), any())).thenReturn(false);

            assertThatThrownBy(() -> service.getVaultDailyTurnover(FOREIGN_BRANCH, DATE))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(turnoverService, never()).getDailyTurnover(any(), any());
        });
    }

    @Test
    @DisplayName("VV-TENANT-001: a branch of another company yields 404 and is NEVER queried")
    void crossTenantBranchIsNotFound() {
        withCompany(() -> {
            when(branchRepository.existsByIdAndCompanyId(FOREIGN_BRANCH, COMPANY_ID)).thenReturn(false);

            assertThatThrownBy(() -> service.getVaultDailyTurnover(FOREIGN_BRANCH, DATE))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(turnoverService, never()).getDailyTurnover(any(), any());
        });
    }

    @Test
    @DisplayName("FR-1: a company-wide (non territory-scoped) role sees every branch of its company")
    void nullScopeMeansCompanyWideAccess() {
        withCompany(() -> {
            when(branchRepository.existsByIdAndCompanyId(OWN_BRANCH, COMPANY_ID)).thenReturn(true);
            // null scope = not a territory-bound role (e.g. FOERTEKTAR)
            when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
            when(accessScopeService.isBranchVisible(null, OWN_BRANCH.toString())).thenReturn(true);
            TurnoverReportDto expected = TurnoverReportDto.builder().period(DATE.toString()).build();
            when(turnoverService.getDailyTurnover(OWN_BRANCH, DATE)).thenReturn(expected);

            assertThat(service.getVaultDailyTurnover(OWN_BRANCH, DATE)).isSameAs(expected);
        });
    }

    @Test
    @DisplayName("FR-1: a null branchId is rejected as not found, without touching the scope service")
    void nullBranchIdIsNotFound() {
        withCompany(() -> assertThatThrownBy(() -> service.getVaultDailyTurnover(null, DATE))
                .isInstanceOf(ResourceNotFoundException.class));
    }
}
