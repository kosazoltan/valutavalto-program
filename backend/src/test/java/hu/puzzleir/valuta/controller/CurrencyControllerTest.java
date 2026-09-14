package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.service.AdminCurrencyService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FK13 (FR-9) — {@code PATCH /api/v1/currencies/{id}/zero-rate-policy} szerződés-teszt (RED, 2026-09-14).
 *
 * <p>URL-alapú MockMvc a valós {@link CurrencyController} bean-en, {@code @EnableMethodSecurity}
 * AOP-proxyval (a {@code @PreAuthorize} a {@code @WithMockUser} SecurityContextjére érvényesül) és a
 * projekt {@link GlobalExceptionHandler}-ével (AccessDenied → 403, Bean Validation → 400). Szándékosan
 * NEM a controller-metódust hívjuk közvetlenül: a végpont a RED fázisban még nem létezik, és a
 * tesztnek a HIÁNYZÓ funkció miatt kell buknia (404), nem fordítási hibával.</p>
 *
 * <p>Jogosultsági kör (eldöntött, Scope OUT: helyettes-bővítés): ugyanaz, mint a mai currency-write —
 * ADMIN, MANAGER, FOERTEKTAR, UGYVEZETO. ERTEKTAR és SUPERVISOR 403 marad.</p>
 */
@ExtendWith(SpringExtension.class)
@WebAppConfiguration
@ContextConfiguration(classes = CurrencyControllerTest.TestConfig.class)
class CurrencyControllerTest {

    private static final String URL = "/api/v1/currencies/21/zero-rate-policy";
    private static final String BODY_ALLOW_BUY = """
            {"buyZeroAllowed": true, "sellZeroAllowed": false, "note": "UAH-t csak eladjuk"}
            """;

    @Autowired
    private WebApplicationContext wac;

    @Autowired
    private AdminCurrencyService adminCurrencyService;

    private MockMvc mockMvc;

    @BeforeEach
    void setup() {
        reset(adminCurrencyService);
        mockMvc = MockMvcBuilders.webAppContextSetup(wac).build();
    }

    @Configuration
    @EnableWebMvc
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        AdminCurrencyService adminCurrencyService() {
            return mock(AdminCurrencyService.class);
        }

        @Bean
        CurrencyRepository currencyRepository() {
            return mock(CurrencyRepository.class);
        }

        @Bean
        CurrencyController currencyController(CurrencyRepository currencyRepository,
                                              AdminCurrencyService adminCurrencyService) {
            return new CurrencyController(currencyRepository, adminCurrencyService);
        }

        @Bean
        GlobalExceptionHandler globalExceptionHandler() {
            return new GlobalExceptionHandler();
        }
    }

    private static Currency uahWithPolicy(boolean buyZero, boolean sellZero) {
        return Currency.builder().id(21L).code("UAH").name("Ukrán hrivnya").active(true)
                .decimalPlaces(2).displayOrder(20)
                .buyZeroAllowed(buyZero).sellZeroAllowed(sellZero).build();
    }

    @Test
    @DisplayName("FK13 FR-9: FOERTEKTAR → 200, a válasz DTO hordozza a beállított jelölőket")
    @WithMockUser(roles = "FOERTEKTAR")
    void setZeroRatePolicy_foertektar_ok() throws Exception {
        when(adminCurrencyService.setZeroRatePolicy(eq(21L), eq(true), eq(false), eq("UAH-t csak eladjuk")))
                .thenReturn(uahWithPolicy(true, false));

        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON).content(BODY_ALLOW_BUY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value("UAH"))
                .andExpect(jsonPath("$.buyZeroAllowed").value(true))
                .andExpect(jsonPath("$.sellZeroAllowed").value(false));

        verify(adminCurrencyService).setZeroRatePolicy(21L, true, false, "UAH-t csak eladjuk");
    }

    @Test
    @DisplayName("FK13 FR-9: UGYVEZETO → 200 (a currency-write kör tagja)")
    @WithMockUser(roles = "UGYVEZETO")
    void setZeroRatePolicy_ugyvezeto_ok() throws Exception {
        when(adminCurrencyService.setZeroRatePolicy(anyLong(), anyBoolean(), anyBoolean(), any()))
                .thenReturn(uahWithPolicy(true, false));

        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON).content(BODY_ALLOW_BUY))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("FK13 FR-9: ADMIN és MANAGER → 200 (paritás a POST / PATCH active végpontokkal)")
    @WithMockUser(roles = "ADMIN")
    void setZeroRatePolicy_admin_ok() throws Exception {
        when(adminCurrencyService.setZeroRatePolicy(anyLong(), anyBoolean(), anyBoolean(), any()))
                .thenReturn(uahWithPolicy(true, false));

        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON).content(BODY_ALLOW_BUY))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("FK13 FR-9: MANAGER → 200")
    @WithMockUser(roles = "MANAGER")
    void setZeroRatePolicy_manager_ok() throws Exception {
        when(adminCurrencyService.setZeroRatePolicy(anyLong(), anyBoolean(), anyBoolean(), any()))
                .thenReturn(uahWithPolicy(true, false));

        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON).content(BODY_ALLOW_BUY))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("FK13 FR-9 / Scope OUT: ERTEKTAR (helyettes gyakorlati szerepe) → 403, a service NEM hívódik")
    @WithMockUser(roles = "ERTEKTAR")
    void setZeroRatePolicy_ertektar_forbidden() throws Exception {
        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON).content(BODY_ALLOW_BUY))
                .andExpect(status().isForbidden());

        verify(adminCurrencyService, never()).setZeroRatePolicy(anyLong(), anyBoolean(), anyBoolean(), any());
    }

    @Test
    @DisplayName("FK13 FR-9 / Scope OUT: SUPERVISOR (legacy helyettes-role) → 403")
    @WithMockUser(roles = "SUPERVISOR")
    void setZeroRatePolicy_supervisor_forbidden() throws Exception {
        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON).content(BODY_ALLOW_BUY))
                .andExpect(status().isForbidden());

        verify(adminCurrencyService, never()).setZeroRatePolicy(anyLong(), anyBoolean(), anyBoolean(), any());
    }

    @Test
    @DisplayName("FK13 FR-9: PENZTAR (osztály-szintű olvasó kör) → 403 az írásra")
    @WithMockUser(roles = "PENZTAR")
    void setZeroRatePolicy_penztar_forbidden() throws Exception {
        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON).content(BODY_ALLOW_BUY))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("FK13 FR-9: request-validáció — mindkét irány-jelölő kötelező (hiányzó sellZeroAllowed → 400)")
    @WithMockUser(roles = "FOERTEKTAR")
    void setZeroRatePolicy_missingDirection_badRequest() throws Exception {
        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"buyZeroAllowed\": true}"))
                .andExpect(status().isBadRequest());

        verify(adminCurrencyService, never()).setZeroRatePolicy(anyLong(), anyBoolean(), anyBoolean(), any());
    }

    @Test
    @DisplayName("FK13 FR-9: request-validáció — 500 karakternél hosszabb indoklás → 400 (SetActiveRequest paritás)")
    @WithMockUser(roles = "FOERTEKTAR")
    void setZeroRatePolicy_noteTooLong_badRequest() throws Exception {
        String longNote = "x".repeat(501);
        mockMvc.perform(patch(URL).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"buyZeroAllowed\": true, \"sellZeroAllowed\": false, \"note\": \"" + longNote + "\"}"))
                .andExpect(status().isBadRequest());

        verify(adminCurrencyService, never()).setZeroRatePolicy(anyLong(), anyBoolean(), anyBoolean(), any());
    }
}
