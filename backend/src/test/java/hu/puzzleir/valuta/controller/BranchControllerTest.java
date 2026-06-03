package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.BranchDto;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.BranchService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * FK-016 (2026-06-03): a Központi Munkaállomás (clientType=CENTRAL) felületein a virtuális
 * partnerek (VAULT_COUNTERPARTY branchType) nem jelenhetnek meg, az értéktári/pénztári kliens
 * (clientType nélkül) viszont változatlanul látja őket (regresszió-mentesség).
 *
 * <p>A szűrés a meglévő {@code branchType.code = 'VAULT_COUNTERPARTY'} diszkriminátorra épül
 * (V277 seed) — nincs redundáns is_virtual flag.</p>
 */
@ExtendWith(MockitoExtension.class)
class BranchControllerTest {

    @Mock private BranchService branchService;
    @Mock private AccessScopeService accessScopeService;
    @InjectMocks private BranchController controller;

    private BranchDto branch(String code, String typeCode) {
        return BranchDto.builder().id(UUID.randomUUID()).code(code).name(code).branchTypeCode(typeCode).build();
    }

    /** PENZTAR + ERTEKTAR + 3 minta a VAULT_COUNTERPARTY partnerekből (a 10 könyvelési entitásból). */
    private List<BranchDto> mixedBranches() {
        return List.of(
                branch("BR010", "PENZTAR"),
                branch("BR050", "ERTEKTAR"),
                branch("ERB", "VAULT_COUNTERPARTY"),
                branch("FRB", "VAULT_COUNTERPARTY"),
                branch("FOP1", "VAULT_COUNTERPARTY"));
    }

    @Test
    @DisplayName("getAllBranches clientType=CENTRAL → a VAULT_COUNTERPARTY partnerek kizárva")
    void getAllBranches_central_excludesVaultCounterparties() {
        when(branchService.findAll()).thenReturn(mixedBranches());

        List<BranchDto> result = controller.getAllBranches(null, null, null, false, "CENTRAL").getBody();

        assertThat(result).extracting(BranchDto::getCode).containsExactly("BR010", "BR050");
        assertThat(result).noneMatch(b -> "VAULT_COUNTERPARTY".equals(b.getBranchTypeCode()));
    }

    @Test
    @DisplayName("getAllBranches clientType=central (kisbetű, activeOnly) → szintén kizár")
    void getAllBranches_centralCaseInsensitive_activeOnly_excludes() {
        when(branchService.findAllActive()).thenReturn(mixedBranches());

        List<BranchDto> result = controller.getAllBranches(null, null, null, true, "central").getBody();

        assertThat(result).extracting(BranchDto::getCode).containsExactly("BR010", "BR050");
    }

    @Test
    @DisplayName("getAllBranches clientType nélkül (értéktári/pénztári kliens) → partnerek MEGMARADNAK")
    void getAllBranches_noClientType_keepsVaultCounterparties() {
        when(branchService.findAll()).thenReturn(mixedBranches());

        List<BranchDto> result = controller.getAllBranches(null, null, null, false, null).getBody();

        assertThat(result).extracting(BranchDto::getCode)
                .containsExactly("BR010", "BR050", "ERB", "FRB", "FOP1");
    }

    @Test
    @DisplayName("getMyTerritoryBranches clientType=CENTRAL + nincs vault-scope → partnerek kizárva")
    void getMyTerritory_central_excludesVaultCounterparties() {
        when(branchService.findAllActive()).thenReturn(mixedBranches());
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        List<BranchDto> result = controller.getMyTerritoryBranches("CENTRAL").getBody();

        assertThat(result).extracting(BranchDto::getCode).containsExactly("BR010", "BR050");
    }
}
