package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDraftRequest;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigListDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigLiveDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeePublishRequest;
import hu.puzzleir.valuta.service.BranchHandlingFeeConfigService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-096 WU-7 — BranchFeeConfigController RBAC/security teszt
 * (a ShipmentHandlingFeeControllerSecurityTest mintájára).
 *
 * <p>FR-12: write/publish/admin-read = hasAnyRole('UGYVEZETO','FOERTEKTAR','ADMIN');
 * IRODAVEZETO és BELSO_ELLENOR (és PENZTAR/ERTEKTAR) íráshoz NEM fér.
 * Az /own és /{branchId}/live hitelesített szinten elérhető (isAuthenticated).</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = BranchFeeConfigControllerSecurityTest.TestConfig.class)
class BranchFeeConfigControllerSecurityTest {

    private static final String WRITE_AUTH = "hasAnyRole('UGYVEZETO','FOERTEKTAR','ADMIN')";
    private static final String OPEN_AUTH = "isAuthenticated()";
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    @Autowired private BranchFeeConfigController controller;
    @Autowired private BranchHandlingFeeConfigService service;

    @BeforeEach
    void setUp() {
        reset(service);
    }

    // =====================================================================
    // @PreAuthorize kontrakt (reflection)
    // =====================================================================
    @Test
    @DisplayName("Az osztály-szintű @PreAuthorize az admin-hármas; own/live method-szinten isAuthenticated")
    void handlers_haveRequiredPreAuthorizeContract() throws Exception {
        PreAuthorize classAuth = BranchFeeConfigController.class.getAnnotation(PreAuthorize.class);
        assertThat(classAuth).as("Az osztály RBAC-a az admin-hármas (D10)").isNotNull();
        assertThat(classAuth.value()).isEqualTo(WRITE_AUTH);

        Method list = BranchFeeConfigController.class.getDeclaredMethod("list");
        assertThat(list.getAnnotation(PreAuthorize.class))
                .as("A lista az osztály-szintű (admin) szabályt örökli")
                .isNull();

        Method saveDraft = BranchFeeConfigController.class.getDeclaredMethod(
                "saveDraft", UUID.class, BranchFeeConfigDraftRequest.class);
        assertThat(saveDraft.getAnnotation(PreAuthorize.class))
                .as("A draft-mentés az osztály-szintű (admin) szabályt örökli")
                .isNull();

        Method publish = BranchFeeConfigController.class.getDeclaredMethod(
                "publish", UUID.class, BranchFeePublishRequest.class);
        assertThat(publish.getAnnotation(PreAuthorize.class))
                .as("A publikálás az osztály-szintű (admin) szabályt örökli")
                .isNull();

        Method own = BranchFeeConfigController.class.getDeclaredMethod("own");
        PreAuthorize ownAuth = own.getAnnotation(PreAuthorize.class);
        assertThat(ownAuth).as("Az /own bárki hitelesítettnek elérhető (C3/D10)").isNotNull();
        assertThat(ownAuth.value()).isEqualTo(OPEN_AUTH);

        Method live = BranchFeeConfigController.class.getDeclaredMethod("live", UUID.class);
        PreAuthorize liveAuth = live.getAnnotation(PreAuthorize.class);
        assertThat(liveAuth).as("A /{branchId}/live bárki hitelesítettnek elérhető").isNotNull();
        assertThat(liveAuth.value()).isEqualTo(OPEN_AUTH);
    }

    // =====================================================================
    // FR-12 — tiltott szerepkörök: AccessDeniedException, a service SOHA nem hívódik
    // =====================================================================
    @Test
    @WithMockUser(roles = "PENZTAR")
    @DisplayName("FR-12: PENZTAR nem menthet draft-ot — a service hívása sem történik meg")
    void saveDraft_deniedForPenztar() {
        assertThatThrownBy(() -> controller.saveDraft(BRANCH_ID, validDraft()))
                .isInstanceOf(AccessDeniedException.class);
        verify(service, never()).saveDraft(any(), any());
    }

    @Test
    @WithMockUser(roles = "IRODAVEZETO")
    @DisplayName("FR-12: IRODAVEZETO nem publikálhat — a service hívása sem történik meg")
    void publish_deniedForIrodavezeto() {
        assertThatThrownBy(() -> controller.publish(BRANCH_ID, new BranchFeePublishRequest(0L)))
                .isInstanceOf(AccessDeniedException.class);
        verify(service, never()).publish(any(), any());
    }

    @Test
    @WithMockUser(roles = "BELSO_ELLENOR")
    @DisplayName("FR-12: BELSO_ELLENOR sem publikálhat")
    void publish_deniedForBelsoEllenor() {
        assertThatThrownBy(() -> controller.publish(BRANCH_ID, new BranchFeePublishRequest(0L)))
                .isInstanceOf(AccessDeniedException.class);
        verify(service, never()).publish(any(), any());
    }

    @Test
    @WithMockUser(roles = "ERTEKTAR")
    @DisplayName("FR-12: ERTEKTAR sem publikálhat")
    void publish_deniedForErtektar() {
        assertThatThrownBy(() -> controller.publish(BRANCH_ID, new BranchFeePublishRequest(0L)))
                .isInstanceOf(AccessDeniedException.class);
        verify(service, never()).publish(any(), any());
    }

    @Test
    @WithMockUser(roles = "PENZTAR")
    @DisplayName("FR-12: PENZTAR az admin listát sem láthatja")
    void list_deniedForPenztar() {
        assertThatThrownBy(() -> controller.list()).isInstanceOf(AccessDeniedException.class);
        verify(service, never()).listForCompany();
    }

    // =====================================================================
    // Engedélyezett szerepkörök delegálnak
    // =====================================================================
    @Test
    @WithMockUser(roles = "UGYVEZETO")
    @DisplayName("UGYVEZETO publikálhat és delegál (B2: expectedVersion=0 a törzsben)")
    void publish_allowedForUgyvezeto() {
        BranchFeeConfigDto dto = BranchFeeConfigDto.builder().branchId(BRANCH_ID).version(1L).build();
        when(service.publish(eq(BRANCH_ID), eq(0L))).thenReturn(dto);

        assertThat(controller.publish(BRANCH_ID, new BranchFeePublishRequest(0L)).getBody())
                .isSameAs(dto);
        verify(service).publish(BRANCH_ID, 0L);
    }

    @Test
    @WithMockUser(roles = "FOERTEKTAR")
    @DisplayName("FOERTEKTAR draft-ot menthet és delegál")
    void saveDraft_allowedForFoertektar() {
        BranchFeeConfigDraftRequest request = validDraft();
        BranchFeeConfigDto dto = BranchFeeConfigDto.builder().branchId(BRANCH_ID).build();
        when(service.saveDraft(eq(BRANCH_ID), eq(request))).thenReturn(dto);

        assertThat(controller.saveDraft(BRANCH_ID, request).getBody()).isSameAs(dto);
        verify(service).saveDraft(BRANCH_ID, request);
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("ADMIN listázhat és delegál")
    void list_allowedForAdmin() {
        BranchFeeConfigListDto list = BranchFeeConfigListDto.builder().build();
        when(service.listForCompany()).thenReturn(list);

        assertThat(controller.list().getBody()).isSameAs(list);
        verify(service).listForCompany();
    }

    // =====================================================================
    // own/live — hitelesített szinten elérhető
    // =====================================================================
    @Test
    @WithMockUser(roles = "PENZTAR")
    @DisplayName("Az /own PENZTAR-ként is elérhető (C3/D12)")
    void own_reachableForPenztar() {
        BranchFeeConfigLiveDto live = BranchFeeConfigLiveDto.builder().branchId(BRANCH_ID).build();
        when(service.getOwnLive()).thenReturn(live);

        assertThat(controller.own().getBody()).isSameAs(live);
        verify(service).getOwnLive();
    }

    @Test
    @WithMockUser(roles = "PENZTAR")
    @DisplayName("A /{branchId}/live PENZTAR-ként is elérhető (a saját-iroda guard a service-ben van)")
    void live_reachableForPenztar() {
        BranchFeeConfigLiveDto live = BranchFeeConfigLiveDto.builder().branchId(BRANCH_ID).build();
        when(service.getLiveForBranch(BRANCH_ID)).thenReturn(live);

        assertThat(controller.live(BRANCH_ID).getBody()).isSameAs(live);
        verify(service).getLiveForBranch(BRANCH_ID);
    }

    // ============================ HELPEREK ============================

    private static BranchFeeConfigDraftRequest validDraft() {
        BranchFeeConfigDraftRequest request = new BranchFeeConfigDraftRequest();
        request.setFeeMode("PER_MILLE");
        request.setPerMilleRate(new BigDecimal("3.5"));
        request.setPerMilleCap(new BigDecimal("2000"));
        return request;
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {

        @Bean
        BranchHandlingFeeConfigService branchHandlingFeeConfigService() {
            return mock(BranchHandlingFeeConfigService.class);
        }

        @Bean
        BranchFeeConfigController branchFeeConfigController(
                BranchHandlingFeeConfigService branchHandlingFeeConfigService) {
            return new BranchFeeConfigController(branchHandlingFeeConfigService);
        }
    }
}
