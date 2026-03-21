package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.wu.stub.WuStubRateResponse;
import hu.puzzleir.valuta.dto.wu.stub.WuStubStatusResponse;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.entity.WuTransactionStatus;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.service.WesternUnionStubService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class WesternUnionStubControllerTest {

    private MockMvc mockMvc;

    @Mock
    private WesternUnionStubService westernUnionStubService;

    @InjectMocks
    private WesternUnionStubController controller;

    @BeforeEach
    void setUp() {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @Test
    @DisplayName("POST /western-union-stub/send valós flow-t hív")
    void send_callsServiceAndReturnsTransaction() throws Exception {
        UUID txId = UUID.randomUUID();
        when(westernUnionStubService.send(any())).thenReturn(
                WuTransaction.builder()
                        .id(txId)
                        .transactionType("SEND")
                        .status(WuTransactionStatus.COMPLETED)
                        .mtcn("1234567890")
                        .build()
        );

        mockMvc.perform(post("/api/v1/western-union-stub/send")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "branchId":"11111111-1111-1111-1111-111111111111",
                                  "mtcn":"1234567890",
                                  "amountUsd":100,
                                  "amountHuf":40000
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(txId.toString()))
                .andExpect(jsonPath("$.transactionType").value("SEND"));

        verify(westernUnionStubService).send(any());
    }

    @Test
    @DisplayName("POST /send hibás MTCN esetén 400")
    void send_validationBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/western-union-stub/send")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "branchId":"11111111-1111-1111-1111-111111111111",
                                  "mtcn":"123",
                                  "amountUsd":100,
                                  "amountHuf":40000
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("GET /status not found esetén 404")
    void status_notFound() throws Exception {
        when(westernUnionStubService.status(eq("1234567890")))
                .thenThrow(new ResourceNotFoundException("WU tranzakció nem található"));

        mockMvc.perform(get("/api/v1/western-union-stub/status/1234567890"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
    }

    @Test
    @DisplayName("GET /rates provider inactive esetén kontrollált 409")
    void rates_providerInactive() throws Exception {
        when(westernUnionStubService.rates())
                .thenThrow(new BusinessException("Western Union provider inaktív", "WU_PROVIDER_INACTIVE", HttpStatus.CONFLICT));

        mockMvc.perform(get("/api/v1/western-union-stub/rates"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("WU_PROVIDER_INACTIVE"));
    }

    @Test
    @DisplayName("POST /send provider inactive esetén 409 + WU_PROVIDER_INACTIVE")
    void send_providerInactive() throws Exception {
        when(westernUnionStubService.send(any()))
                .thenThrow(new BusinessException("Western Union provider inaktív", "WU_PROVIDER_INACTIVE", HttpStatus.CONFLICT));

        mockMvc.perform(post("/api/v1/western-union-stub/send")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "branchId":"11111111-1111-1111-1111-111111111111",
                                  "mtcn":"1234567890",
                                  "amountUsd":100,
                                  "amountHuf":40000
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("WU_PROVIDER_INACTIVE"));
    }

    @Test
    @DisplayName("POST /receive provider inactive esetén 409 + WU_PROVIDER_INACTIVE")
    void receive_providerInactive() throws Exception {
        when(westernUnionStubService.receive(any()))
                .thenThrow(new BusinessException("Western Union provider inaktív", "WU_PROVIDER_INACTIVE", HttpStatus.CONFLICT));

        mockMvc.perform(post("/api/v1/western-union-stub/receive")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "branchId":"11111111-1111-1111-1111-111111111111",
                                  "mtcn":"1234567890",
                                  "amountUsd":100,
                                  "amountHuf":40000
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("WU_PROVIDER_INACTIVE"));
    }

    @Test
    @DisplayName("GET /status rövid MTCN esetén 400 (path validáció regresszió)")
    void status_invalidPathValidation() throws Exception {
        mockMvc.perform(get("/api/v1/western-union-stub/status/123"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("BAD_REQUEST"));
    }

    @Test
    @DisplayName("GET /status sikeres válasz")
    void status_ok() throws Exception {
        when(westernUnionStubService.status(eq("1234567890")))
                .thenReturn(WuStubStatusResponse.builder()
                        .mtcn("1234567890")
                        .status("COMPLETED")
                        .transactionType("SEND")
                        .transactionId(UUID.fromString("11111111-1111-1111-1111-111111111111"))
                        .transactionDate(LocalDateTime.of(2026, 3, 21, 16, 0))
                        .provider("INTERNAL")
                        .build());

        mockMvc.perform(get("/api/v1/western-union-stub/status/1234567890"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.provider").value("INTERNAL"))
                .andExpect(jsonPath("$.status").value("COMPLETED"));
    }
}
