package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.BracketSetDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeBracketDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeConfigDto;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.BranchHandlingFeeConfigService;
import hu.puzzleir.valuta.service.SystemParameterService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.MockedStatic;
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
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * FK-096 R2-WU-5 (round 2, ITEM 1) — a legacy handling-fee-config író-végpontok
 * RBAC + no-LIVE-write bizonyítása (a BranchFeeConfigControllerSecurityTest mintájára).
 *
 * <p>R2-D1: a legacy sáv-írás DRAFT-ként delegál a {@code saveBracketDraft}-ba —
 * LIVE sor többé nem keletkezhet ezen az úton. R2-D2: az író-végpontok method-szintű
 * RBAC-a pontosan {@code UGYVEZETO}/{@code FOERTEKTAR}/{@code ADMIN} — a class-level
 * bő körből IRODAVEZETO, BELSO_ELLENOR és MANAGER írásból kizárva (FR-12). A GET
 * pénztáros read-only elérhetősége (FK-KEZDIJ B.1) változatlan.</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = HandlingFeeConfigControllerSecurityTest.TestConfig.class)
class HandlingFeeConfigControllerSecurityTest {

    private static final String WRITE_AUTH = "hasAnyRole('UGYVEZETO','FOERTEKTAR','ADMIN')";
    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Autowired private HandlingFeeConfigController controller;
    @Autowired private SystemParameterService systemParameterService;
    @Autowired private HandlingFeeBracketRepository bracketRepository;
    @Autowired private BranchHandlingFeeConfigService branchHandlingFeeConfigService;

    @BeforeEach
    void setUp() {
        reset(systemParameterService, bracketRepository, branchHandlingFeeConfigService);
        // A getConfig paraméter-olvasásai opcionálisak — az alap-stub szám-formátumú.
        when(systemParameterService.getValue(anyString())).thenReturn("1");
    }

    // =====================================================================
    // R2-D2 — method-szintű @PreAuthorize kontrakt (reflection)
    // =====================================================================
    @Test
    @DisplayName("R2-D2: updateConfig ÉS saveBracketsEndpoint method-szintű RBAC-a pontosan az admin-hármas")
    void writeHandlers_haveExactThreeRoleRbac() throws Exception {
        Method updateConfig = HandlingFeeConfigController.class
                .getDeclaredMethod("updateConfig", HandlingFeeConfigDto.class);
        PreAuthorize putAuth = updateConfig.getAnnotation(PreAuthorize.class);
        assertThat(putAuth).as("A legacy PUT method-szintű RBAC-ot kap (R2-D2)").isNotNull();
        assertThat(putAuth.value()).isEqualTo(WRITE_AUTH);
        assertThat(putAuth.value())
                .as("FR-12: IRODAVEZETO/BELSO_ELLENOR/MANAGER nem írhatja a legacy díjkonfigot")
                .doesNotContain("IRODAVEZETO")
                .doesNotContain("BELSO_ELLENOR")
                .doesNotContain("MANAGER");

        Method saveBracketsEndpoint = HandlingFeeConfigController.class
                .getDeclaredMethod("saveBracketsEndpoint", List.class);
        PreAuthorize postAuth = saveBracketsEndpoint.getAnnotation(PreAuthorize.class);
        assertThat(postAuth).as("A legacy POST /brackets method-szintű RBAC-ot kap (R2-D2)").isNotNull();
        assertThat(postAuth.value()).isEqualTo(WRITE_AUTH);
        assertThat(postAuth.value())
                .doesNotContain("IRODAVEZETO")
                .doesNotContain("BELSO_ELLENOR")
                .doesNotContain("MANAGER");
    }

    // =====================================================================
    // FR-12 — tiltott szerepkörök: AccessDeniedException, delegáció NÉLKÜL
    // =====================================================================
    @Test
    @WithMockUser(roles = "IRODAVEZETO")
    @DisplayName("FR-12: IRODAVEZETO a legacy PUT-ot nem hívhatja — sem paraméter-, sem sáv-írás")
    void updateConfig_deniedForIrodavezeto() {
        HandlingFeeConfigDto dto = HandlingFeeConfigDto.builder()
                .feeType("PER_MILLE")
                .perMilleRate(new BigDecimal("3"))
                .build();

        assertThatThrownBy(() -> controller.updateConfig(dto))
                .isInstanceOf(AccessDeniedException.class);
        verify(branchHandlingFeeConfigService, never()).saveBracketDraft(any());
        verify(systemParameterService, never()).upsert(any(), any(), any(), any());
    }

    @Test
    @WithMockUser(roles = "BELSO_ELLENOR")
    @DisplayName("FR-12: BELSO_ELLENOR a legacy sáv-írást nem hívhatja")
    void saveBrackets_deniedForBelsoEllenor() {
        assertThatThrownBy(() -> controller.saveBracketsEndpoint(validRows()))
                .isInstanceOf(AccessDeniedException.class);
        verify(branchHandlingFeeConfigService, never()).saveBracketDraft(any());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    @DisplayName("FR-12: MANAGER a legacy sáv-írást nem hívhatja (R2-D2: szándékos szűkítés)")
    void saveBrackets_deniedForManager() {
        assertThatThrownBy(() -> controller.saveBracketsEndpoint(validRows()))
                .isInstanceOf(AccessDeniedException.class);
        verify(branchHandlingFeeConfigService, never()).saveBracketDraft(any());
    }

    // =====================================================================
    // R2-D1 — FOERTEKTAR DRAFT-ként delegál
    // =====================================================================
    @Test
    @WithMockUser(roles = "FOERTEKTAR")
    @DisplayName("R2-D1: FOERTEKTAR sáv-írása a saveBracketDraft-ba delegál (DRAFT), a választ az adja")
    void saveBrackets_allowedForFoertektar_DRAFTkentDelegal() {
        List<HandlingFeeBracketDto> rows = validRows();
        when(branchHandlingFeeConfigService.saveBracketDraft(rows))
                .thenReturn(BracketSetDto.builder().live(List.of()).draft(rows).build());

        assertThat(controller.saveBracketsEndpoint(rows).getBody()).isEqualTo(rows);
        verify(branchHandlingFeeConfigService).saveBracketDraft(rows);
    }

    // =====================================================================
    // FK-KEZDIJ B.1 — a pénztáros READ-only GET változatlanul elérhető
    // =====================================================================
    @Test
    @WithMockUser(roles = "PENZTAR")
    @DisplayName("B.1: a GET PENZTAR-ként is elérhető marad (method-level override)")
    void getConfig_readableForPenztar() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatCode(() -> controller.getConfig()).doesNotThrowAnyException();
        }
    }

    // =====================================================================
    // R2-D1 — a controller NEM végez többé HandlingFeeBracket-írást
    // =====================================================================
    @Test
    @WithMockUser(roles = "FOERTEKTAR")
    @DisplayName("R2-D1: a privát LIVE-író saveBrackets segédmetódus megszűnt; a delegált írás nem nyúl a bracket-repositoryhoz")
    void controller_nemHivHandlingFeeBracketIrast() {
        assertThat(Arrays.stream(HandlingFeeConfigController.class.getDeclaredMethods())
                .map(Method::getName))
                .as("A privát saveBrackets (LIVE-insert) segédmetódus törölve")
                .doesNotContain("saveBrackets");

        List<HandlingFeeBracketDto> rows = validRows();
        when(branchHandlingFeeConfigService.saveBracketDraft(rows))
                .thenReturn(BracketSetDto.builder().live(List.of()).draft(rows).build());

        controller.saveBracketsEndpoint(rows);

        // A legacy író-út teljes egészében a service-re delegál — a controller szintjén
        // egyetlen bracket-repository interakció sem történhet (a GET-é a másik végpont).
        verifyNoInteractions(bracketRepository);
    }

    // ============================ HELPEREK ============================

    private static List<HandlingFeeBracketDto> validRows() {
        return List.of(HandlingFeeBracketDto.builder()
                .bracketOrder(1)
                .upperLimit(new BigDecimal("100000"))
                .feeAmount(new BigDecimal("300"))
                .active(true)
                .build());
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {

        @Bean
        SystemParameterService systemParameterService() {
            return mock(SystemParameterService.class);
        }

        @Bean
        HandlingFeeBracketRepository handlingFeeBracketRepository() {
            return mock(HandlingFeeBracketRepository.class);
        }

        @Bean
        CompanyRepository companyRepository() {
            return mock(CompanyRepository.class);
        }

        @Bean
        BranchHandlingFeeConfigService branchHandlingFeeConfigService() {
            return mock(BranchHandlingFeeConfigService.class);
        }

        @Bean
        HandlingFeeConfigController handlingFeeConfigController(
                SystemParameterService systemParameterService,
                HandlingFeeBracketRepository handlingFeeBracketRepository,
                CompanyRepository companyRepository) {
            return new HandlingFeeConfigController(
                    systemParameterService, handlingFeeBracketRepository, companyRepository);
        }
    }
}
