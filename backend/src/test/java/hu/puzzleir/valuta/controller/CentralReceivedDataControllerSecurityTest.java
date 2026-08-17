package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.central.CentralReceivedDataOverviewDto;
import hu.puzzleir.valuta.service.CentralReceivedDataService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.time.LocalDate;

import static org.mockito.Mockito.any;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Codex P1 #560 + Copilot P2 #577 follow-up test.
 *
 * <p>Védi a <code>/api/v1/central/received-data/status</code> endpoint role-szűkítését:
 * <ul>
 *   <li>CASHIER → 403 Forbidden (security regression-védelem)</li>
 *   <li>SUPERVISOR / MANAGER / ADMIN (legacy) → 200 OK</li>
 *   <li>FOERTEKTAR / UGYVEZETO / BELSO_ELLENOR / TERULETI_VEZETO (canonical) → 200 OK</li>
 *   <li>Ismeretlen role / UNKNOWN → 403</li>
 * </ul></p>
 */
@ExtendWith(SpringExtension.class)
@WebAppConfiguration
@ContextConfiguration(classes = CentralReceivedDataControllerSecurityTest.TestConfig.class)
class CentralReceivedDataControllerSecurityTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private CentralReceivedDataService centralReceivedDataService;

    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
        // Stubolt service: ne dobjon exception-t a felhasznaloi szerepkor-tesztekben.
        when(centralReceivedDataService.getOverview(any()))
                .thenReturn(CentralReceivedDataOverviewDto.builder().build());
        // A mock service bean a kontextus-kessel együtt él; a verify-alapú param-tesztek
        // elszigeteléséhez töröljük a korábbi hívásokat (assert-ok bájt-azonosak maradnak).
        clearInvocations(centralReceivedDataService);
    }

    @Configuration
    @EnableWebMvc
    @EnableWebSecurity
    @EnableMethodSecurity
    static class TestConfig {

        @Bean
        CentralReceivedDataService centralReceivedDataService() {
            return mock(CentralReceivedDataService.class);
        }

        @Bean
        CentralReceivedDataController centralReceivedDataController(CentralReceivedDataService svc) {
            return new CentralReceivedDataController(svc);
        }

        @Bean
        SecurityFilterChain testSecurityFilterChain(HttpSecurity http) throws Exception {
            // CodeQL P1 #577 (security/spring-disable-csrf-protection) fix: NEM disable-elunk
            // CSRF-et a teszt-konfigban. A teszt csak GET requestet hasznal (default CSRF
            // exempt), igy nem kell explicit disable. Production SecurityConfig-ban a CSRF
            // a JWT stateless flow miatt van letiltva (lasd hu.puzzleir.valuta.config.SecurityConfig);
            // ez itt teszt-only es nem ervinteti a production konfigot.
            http
                    .authorizeHttpRequests(authz -> authz.anyRequest().authenticated())
                    .httpBasic(Customizer.withDefaults());
            return http.build();
        }
    }

    // ----- DENY -----

    @Test
    @WithMockUser(username = "cashier1", roles = {"CASHIER"})
    @DisplayName("CASHIER legacy role → 403 Forbidden")
    void cashier_isForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "unknown1", roles = {"PENZTAR"})
    @DisplayName("PENZTAR canonical (cashier) → 403 Forbidden")
    void penztar_isForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "unknown2", roles = {"ERTEKTAR"})
    @DisplayName("ERTEKTAR canonical (vault keeper) → 403 Forbidden (NEM központi role)")
    void ertektar_isForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "anon1", authorities = {"VIDEO_EXPORT"})
    @DisplayName("Csak permission authority (NEM role) → 403 Forbidden")
    void permissionOnly_isForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isForbidden());
    }

    // ----- ALLOW (legacy roles) -----

    @Test
    @WithMockUser(username = "supervisor1", roles = {"SUPERVISOR"})
    @DisplayName("SUPERVISOR legacy → 200 OK")
    void supervisor_isAllowed() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "manager1", roles = {"MANAGER"})
    @DisplayName("MANAGER legacy → 200 OK")
    void manager_isAllowed() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "admin1", roles = {"ADMIN"})
    @DisplayName("ADMIN legacy → 200 OK")
    void admin_isAllowed() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    // ----- ALLOW (canonical roles) -----

    @Test
    @WithMockUser(username = "fo1", roles = {"FOERTEKTAR"})
    @DisplayName("FOERTEKTAR canonical → 200 OK (chief vault, central role)")
    void foertektar_isAllowed() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "ugy1", roles = {"UGYVEZETO"})
    @DisplayName("UGYVEZETO canonical → 200 OK (managing director)")
    void ugyvezeto_isAllowed() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "bel1", roles = {"BELSO_ELLENOR"})
    @DisplayName("BELSO_ELLENOR canonical → 200 OK (internal auditor)")
    void belsoEllenor_isAllowed() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(username = "ter1", roles = {"TERULETI_VEZETO"})
    @DisplayName("TERULETI_VEZETO canonical → 200 OK (regional manager)")
    void teruletiVezeto_isAllowed() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    // ----- ALLOW (mixed legacy + canonical) -----

    @Test
    @WithMockUser(username = "mixed1", roles = {"CASHIER", "FOERTEKTAR"})
    @DisplayName("Mixed CASHIER + FOERTEKTAR → 200 OK (canonical role is enough)")
    void mixedCashierAndFoertektar_isAllowed() throws Exception {
        // Codex P1 #577 follow-up: a canonical-only worker (legacy=CASHIER + foertektar canonical)
        // ne kapjon hamis 403-at. A guard hasAnyRole bármelyik allow-listed-re engedélyez.
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());
    }

    // ----- FK-088 FR-3: endDate referencia-dátum paraméter (additív, backward compat) -----

    @Test
    @WithMockUser(username = "param1", roles = {"ADMIN"})
    @DisplayName("FR-3: endDate param felülírja a legacy date param-et")
    void endDateParam_beatsLegacyDate() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status")
                        .param("endDate", "2026-05-22")
                        .param("date", "2026-05-20"))
                .andExpect(status().isOk());

        verify(centralReceivedDataService).getOverview(LocalDate.of(2026, 5, 22));
    }

    @Test
    @WithMockUser(username = "param2", roles = {"ADMIN"})
    @DisplayName("FR-3 regresszió: legacy date param egyedül is működik (régi kliensek)")
    void legacyDateParam_stillWorks() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status")
                        .param("date", "2026-05-20"))
                .andExpect(status().isOk());

        verify(centralReceivedDataService).getOverview(LocalDate.of(2026, 5, 20));
    }

    @Test
    @WithMockUser(username = "param3", roles = {"ADMIN"})
    @DisplayName("FR-3: param nélkül a mai nap a referencia")
    void noParam_defaultsToToday() throws Exception {
        mockMvc.perform(get("/api/v1/central/received-data/status"))
                .andExpect(status().isOk());

        verify(centralReceivedDataService).getOverview(eq(LocalDate.now()));
    }
}
