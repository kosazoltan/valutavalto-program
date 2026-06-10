package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.bankapi.BankApiConfigDto;
import hu.puzzleir.valuta.entity.BankApiAuthType;
import hu.puzzleir.valuta.entity.BankApiMode;
import hu.puzzleir.valuta.entity.BankApiRunStatus;
import hu.puzzleir.valuta.service.BankApiConfigService;
import hu.puzzleir.valuta.service.RaiffeisenRateService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class BankApiConfigControllerTest {

    private MockMvc mockMvc;

    @Mock
    private BankApiConfigService bankApiConfigService;

    @Mock
    private RaiffeisenRateService raiffeisenRateService;

    @InjectMocks
    private BankApiConfigController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    @DisplayName("Bank API config list nem tartalmaz secret mezot")
    void list_doesNotExposeSecret() throws Exception {
        when(bankApiConfigService.list()).thenReturn(List.of(dto(true)));

        mockMvc.perform(get("/api/v1/bank-api-config"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].providerName").value("RAIFFEISEN"))
                .andExpect(jsonPath("$[0].clientSecretConfigured").value(true))
                .andExpect(jsonPath("$[0].clientSecret").doesNotExist());
    }

    @Test
    @DisplayName("Admin update provider path alapjan ment, secretet nem echo-zik")
    void update_usesProviderPathAndMasksSecret() throws Exception {
        when(bankApiConfigService.update(eq("raiffeisen"), any())).thenReturn(dto(true));

        mockMvc.perform(put("/api/v1/bank-api-config/raiffeisen")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "mode": "REST_PRIMARY_WITH_HTML_FALLBACK",
                                  "endpointUrl": "https://bank.example/rates",
                                  "authType": "OAUTH2_CLIENT_CREDENTIALS",
                                  "clientId": "client-1",
                                  "clientSecret": "secret-value",
                                  "updateFrequency": "0 30 8 * * MON-FRI",
                                  "enabled": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.clientSecretConfigured").value(true))
                .andExpect(jsonPath("$.clientSecret").doesNotExist());

        verify(bankApiConfigService).update(eq("raiffeisen"), any());
    }

    @Test
    @DisplayName("Raiffeisen manual fetch service-t hiv es friss configot ad vissza")
    void fetchRaiffeisenNow_returnsSavedCountAndConfig() throws Exception {
        when(raiffeisenRateService.fetchAndCacheRates()).thenReturn(14);
        when(bankApiConfigService.getDto("RAIFFEISEN")).thenReturn(dto(false));

        mockMvc.perform(post("/api/v1/bank-api-config/raiffeisen/fetch-now"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.savedRates").value(14))
                .andExpect(jsonPath("$.config.providerName").value("RAIFFEISEN"));
    }

    private BankApiConfigDto dto(boolean secretConfigured) {
        return BankApiConfigDto.builder()
                .id(UUID.randomUUID())
                .providerName("RAIFFEISEN")
                .mode(BankApiMode.REST_PRIMARY_WITH_HTML_FALLBACK)
                .endpointUrl("https://bank.example/rates")
                .authType(BankApiAuthType.OAUTH2_CLIENT_CREDENTIALS)
                .clientId("client-1")
                .clientSecretConfigured(secretConfigured)
                .updateFrequency("0 30 8 * * MON-FRI")
                .enabled(true)
                .lastRunStatus(BankApiRunStatus.NEVER_RUN)
                .build();
    }
}
