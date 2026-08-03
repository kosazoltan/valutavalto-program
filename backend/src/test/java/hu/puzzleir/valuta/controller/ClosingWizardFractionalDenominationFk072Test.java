package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.ClosingWizardService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FK-072_v2 FR-3: a záró-varázsló POST /denominations végpontjának védelmi validációja.
 *
 * A tört (1 alatti) névértékű kulcs ma a Jackson Integer-kulcs bindingben hal el
 * (HttpMessageNotReadableException → kontextus nélküli, nyers 400). Az elvárt új
 * viselkedés: egyértelmű, MAGYAR nyelvű validációs hiba VV-VALID-kóddal.
 *
 * Szándékosan sima mock() (nem MockitoExtension): a tört-esetben a request ma a
 * deszerializációban hal el, a service-stubok nem futnak — strict stubbing alatt ez
 * UnnecessaryStubbing lenne (ld. memory: red-teszt-mockito-strict-stubs-csapda).
 */
class ClosingWizardFractionalDenominationFk072Test {

    private static final UUID WIZARD_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID BRANCH_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");

    private ClosingWizardService service;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        service = mock(ClosingWizardService.class);
        mockMvc = MockMvcBuilders.standaloneSetup(new ClosingWizardController(service))
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
        when(service.getWizard(WIZARD_ID)).thenReturn(ClosingWizardDto.builder()
                .branchId(BRANCH_ID.toString())
                .closingDate("2026-08-03")
                .build());
        when(service.countDenominations(any(), any(), any())).thenReturn(Map.of());
    }

    @Test
    @DisplayName("FR-3: 1 alatti névértékű, nem-nulla darabszámú bejegyzés → magyar VV-VALID hiba, nem nyers 400")
    void fractionalFaceValue_returnsHungarianValidationError() throws Exception {
        mockMvc.perform(post("/api/v1/closing-wizard/{wizardId}/denominations", WIZARD_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"EUR\": {\"0.5\": 3}}"))
                .andExpect(status().isBadRequest())
                // Egyértelmű, magyar, VV-VALID-kódos üzenet kell — nem a generikus
                // "Hiányzó vagy érvénytelen request body" deszerializációs válasz.
                .andExpect(jsonPath("$.message",
                        allOf(containsString("VV-VALID"), containsString("címlet"))));
    }

    @Test
    @DisplayName("FR-3/FR-7 regresszió: egész címletek (EUR 1 és 2 is) változatlanul átmennek")
    void wholeFaceValues_stillAccepted() throws Exception {
        mockMvc.perform(post("/api/v1/closing-wizard/{wizardId}/denominations", WIZARD_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"EUR\": {\"1\": 2, \"2\": 3}, \"HUF\": {\"20000\": 5}}"))
                .andExpect(status().isOk());

        verify(service).countDenominations(
                eq(BRANCH_ID),
                eq(LocalDate.parse("2026-08-03")),
                eq(Map.of(
                        "EUR", Map.of(1, 2, 2, 3),
                        "HUF", Map.of(20000, 5))));
    }
}
