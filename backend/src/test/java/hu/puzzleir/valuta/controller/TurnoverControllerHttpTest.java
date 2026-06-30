package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TurnoverService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FK-045 FR-9 — a /turnover/territory végpont HTTP-szintű státuszkód-tesztjei (a spec §9.2 Fázis 4
 * által név szerint megkövetelt esetek). Standalone MockMvc + GlobalExceptionHandler advice, így a
 * ResourceNotFoundException → 404 és a hiányzó kötelező @RequestParam → 400 leképezés is verifikált.
 */
class TurnoverControllerHttpTest {

    private MockMvc mockMvc;
    private TurnoverService turnoverService;
    private MockedStatic<SecurityUtils> securityUtils;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        turnoverService = mock(TurnoverService.class);
        mockMvc = MockMvcBuilders.standaloneSetup(new TurnoverController(turnoverService))
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
        securityUtils = mockStatic(SecurityUtils.class);
        securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
    }

    @AfterEach
    void tearDown() {
        securityUtils.close();
    }

    @Test
    @DisplayName("territory_cross_tenant_404: idegen tenant / nemlétező terület → HTTP 404")
    void territory_cross_tenant_404() throws Exception {
        when(turnoverService.getVaultTerritoryTurnover(eq(COMPANY_ID), eq(99), any(), any()))
                .thenThrow(new ResourceNotFoundException("Értéktári terület nem található a jelenlegi cégben: 99"));

        mockMvc.perform(get("/api/v1/turnover/territory")
                        .param("vaultTerritoryId", "99")
                        .param("from", "2026-06-01")
                        .param("to", "2026-06-30"))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("territory_missing_vaultTerritoryId_400: hiányzó kötelező paraméter → HTTP 400")
    void territory_missing_vaultTerritoryId_400() throws Exception {
        // a vaultTerritoryId @RequestParam kötelező (required=true) → MissingServletRequestParameterException → 400
        mockMvc.perform(get("/api/v1/turnover/territory")
                        .param("from", "2026-06-01")
                        .param("to", "2026-06-30"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("territory_success: érvényes paraméterekkel → HTTP 200")
    void territory_success() throws Exception {
        when(turnoverService.getVaultTerritoryTurnover(eq(COMPANY_ID), eq(5), any(), any()))
                .thenReturn(hu.puzzleir.valuta.dto.turnover.TurnoverReportDto.builder().build());

        mockMvc.perform(get("/api/v1/turnover/territory")
                        .param("vaultTerritoryId", "5")
                        .param("from", "2026-06-01")
                        .param("to", "2026-06-30"))
                .andExpect(status().isOk());
    }
}
