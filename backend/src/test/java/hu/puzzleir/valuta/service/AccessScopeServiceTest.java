package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * FK-005/A3 — a terület (region_code) alapú értéktáros adat-scope egységtesztje.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AccessScopeServiceTest {

    @Mock
    private BranchRepository branchRepository;

    @InjectMocks
    private AccessScopeService accessScopeService;

    private final UUID companyId = UUID.randomUUID();
    private final UUID vaultBranchId = UUID.randomUUID();

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateWith(String authority, UUID branchId) {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(
                        "WORKER", null, List.of(new SimpleGrantedAuthority(authority)));
        auth.setDetails(new WorkerAuthenticationDetails(7L, companyId, branchId, authority.replace("ROLE_", "")));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("Cég-szintű role (MANAGER) → null scope (nincs terület-szűkítés)")
    void companyWideRole_noScope() {
        authenticateWith("ROLE_MANAGER", vaultBranchId);
        assertNull(accessScopeService.vaultRegionBranchScopeOrNull());
    }

    @Test
    @DisplayName("ADMIN és UGYVEZETO szintén cég-szintű → null scope")
    void adminAndDirector_noScope() {
        authenticateWith("ROLE_ADMIN", vaultBranchId);
        assertNull(accessScopeService.vaultRegionBranchScopeOrNull());
        authenticateWith("ROLE_UGYVEZETO", vaultBranchId);
        assertNull(accessScopeService.vaultRegionBranchScopeOrNull());
    }

    @Test
    @DisplayName("Értéktáros (ERTEKTAR) region_code-dal → a saját régió pénztárai + a saját fiók")
    void vaultRole_withRegion_scopedToRegion() {
        UUID b1 = UUID.randomUUID();
        UUID b2 = UUID.randomUUID();
        Branch vault = Branch.builder().id(vaultBranchId).regionCode("20").build();
        when(branchRepository.findById(vaultBranchId)).thenReturn(Optional.of(vault));
        when(branchRepository.findActiveByCompanyIdAndRegionCode(eq(companyId), eq("20")))
                .thenReturn(List.of(
                        Branch.builder().id(b1).regionCode("20").build(),
                        Branch.builder().id(b2).regionCode("20").build()));

        authenticateWith("ROLE_ERTEKTAR", vaultBranchId);
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();

        assertEquals(Set.of(b1, b2, vaultBranchId), scope);
    }

    @Test
    @DisplayName("Codex P1: vault aktív role + MANAGER base-role → MÉGIS terület-scope (vault precedencia)")
    void vaultPlusManagerBase_stillScoped() {
        UUID b1 = UUID.randomUUID();
        Branch vault = Branch.builder().id(vaultBranchId).regionCode("20").build();
        when(branchRepository.findById(vaultBranchId)).thenReturn(Optional.of(vault));
        when(branchRepository.findActiveByCompanyIdAndRegionCode(eq(companyId), eq("20")))
                .thenReturn(List.of(Branch.builder().id(b1).regionCode("20").build()));

        // A JWT mindkét authority-t hordozza: base ROLE_MANAGER + aktív ROLE_ERTEKTAR.
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                "WORKER", null, List.of(
                        new SimpleGrantedAuthority("ROLE_MANAGER"),
                        new SimpleGrantedAuthority("ROLE_ERTEKTAR")));
        auth.setDetails(new WorkerAuthenticationDetails(7L, companyId, vaultBranchId, "ERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        assertEquals(Set.of(b1, vaultBranchId), scope);
    }

    @Test
    @DisplayName("FOERTEKTAR region_code nélkül → biztonságos default: csak a saját fiók")
    void chiefVault_noRegion_ownBranchOnly() {
        Branch vault = Branch.builder().id(vaultBranchId).regionCode(null).build();
        when(branchRepository.findById(vaultBranchId)).thenReturn(Optional.of(vault));

        authenticateWith("ROLE_FOERTEKTAR", vaultBranchId);
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();

        assertEquals(Set.of(vaultBranchId), scope);
    }

    @Test
    @DisplayName("isBranchVisible: null scope → mindig látható; scope-olt → csak a halmazban lévő")
    void isBranchVisible_semantics() {
        UUID inScope = UUID.randomUUID();
        UUID outOfScope = UUID.randomUUID();
        // null scope = cég-szintű → minden látható
        assertTrue(accessScopeService.isBranchVisible(null, inScope.toString()));
        // scope-olt
        Set<UUID> scope = Set.of(inScope);
        assertTrue(accessScopeService.isBranchVisible(scope, inScope.toString()));
        assertFalse(accessScopeService.isBranchVisible(scope, outOfScope.toString()));
        assertFalse(accessScopeService.isBranchVisible(scope, null));
        assertFalse(accessScopeService.isBranchVisible(scope, "nem-uuid"));
    }

    @Test
    @DisplayName("Nem értéktári és nem cég-szintű role (PENZTAR) → null scope (a @PreAuthorize governál)")
    void otherRole_noScope() {
        lenient().when(branchRepository.findById(any())).thenReturn(Optional.empty());
        authenticateWith("ROLE_PENZTAR", vaultBranchId);
        assertNull(accessScopeService.vaultRegionBranchScopeOrNull());
    }
}
