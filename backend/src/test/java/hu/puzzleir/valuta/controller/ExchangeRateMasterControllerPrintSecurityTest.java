package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.ExchangeRateMasterService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.JacksonJsonHttpMessageConverter;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import tools.jackson.databind.json.JsonMapper;

import java.lang.reflect.Method;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class ExchangeRateMasterControllerPrintSecurityTest {

    private static final UUID DISTRIBUTION_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Mock private ExchangeRateMasterService masterService;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        ExchangeRateMasterController controller = new ExchangeRateMasterController(masterService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setMessageConverters(new JacksonJsonHttpMessageConverter(new JsonMapper()))
                .build();
    }

    @Test
    @DisplayName("acknowledge proof body nélkül 400-at ad és nem hív service-t proof nélkül")
    void acknowledgeWithoutProofBodyReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/exchange-rate-master/distribution/{id}/acknowledge", DISTRIBUTION_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(""))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("acknowledge a printProofToken body-t adja át a service-nek")
    void acknowledgePassesProofTokenToService() throws Exception {
        mockMvc.perform(post("/api/v1/exchange-rate-master/distribution/{id}/acknowledge", DISTRIBUTION_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"printProofToken\":\"token-123\"}"))
                .andExpect(status().isOk());

        verify(masterService).acknowledgeDistribution(DISTRIBUTION_ID, "token-123");
    }

    @Test
    @DisplayName("pending-print endpoint a service-ből adja vissza a nyomtatási kötelezettségeket")
    void pendingPrintReturnsObligations() throws Exception {
        when(masterService.getPendingPrintObligations()).thenReturn(List.of());

        mockMvc.perform(get("/api/v1/exchange-rate-master/distribution/pending-print"))
                .andExpect(status().isOk());

        verify(masterService).getPendingPrintObligations();
    }

    @Test
    @DisplayName("nyomtatási endpointok explicit @PreAuthorize operatív szereplistát kapnak")
    void printEndpointsHavePreAuthorize() throws Exception {
        Method acknowledge = ExchangeRateMasterController.class.getMethod(
                "acknowledgeDistribution", UUID.class, ExchangeRateMasterController.AcknowledgeRequest.class);
        Method pending = ExchangeRateMasterController.class.getMethod("getPendingPrintObligations");

        assertThat(acknowledge.getAnnotation(PreAuthorize.class).value())
                .contains("CASHIER")
                .contains("SUPERVISOR")
                .contains("MANAGER")
                .contains("ADMIN")
                .contains("FOERTEKTAR")
                .contains("UGYVEZETO");
        assertThat(pending.getAnnotation(PreAuthorize.class).value()).isEqualTo(acknowledge.getAnnotation(PreAuthorize.class).value());
    }
}
