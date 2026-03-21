package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.pos.PosClosingResult;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import hu.puzzleir.valuta.dto.pos.TerminalStatus;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.service.PosTerminalService;
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

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class PosTerminalStubControllerTest {

    private MockMvc mockMvc;

    @Mock
    private PosTerminalService posTerminalService;

    @InjectMocks
    private PosTerminalStubController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("POST /pos-terminal-stub/authorize DTO validáció mellett szolgáltatást hív")
    void authorize_callsServiceAndReturnsResult() throws Exception {
        when(posTerminalService.initiatePayment(eq(new BigDecimal("12500")), eq("HUF"), eq("TERM-01")))
                .thenReturn(PosTransactionResult.approved("AUTH01", "REF01"));

        mockMvc.perform(post("/api/v1/pos-terminal-stub/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"terminalId\":\"TERM-01\",\"currency\":\"HUF\",\"amount\":12500}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.approved").value(true))
                .andExpect(jsonPath("$.status").value("APPROVED"))
                .andExpect(jsonPath("$.authorizationCode").value("AUTH01"));

        verify(posTerminalService).initiatePayment(eq(new BigDecimal("12500")), eq("HUF"), eq("TERM-01"));
    }

    @Test
    @DisplayName("POST /authorize üres terminalId esetén 400")
    void authorize_returns400_whenTerminalIdMissing() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"terminalId\":\"\",\"currency\":\"HUF\",\"amount\":12500}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.terminalId").exists());
    }

    @Test
    @DisplayName("POST /authorize amount <= 0 esetén 400")
    void authorize_returns400_whenAmountNonPositive() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"terminalId\":\"TERM-01\",\"currency\":\"HUF\",\"amount\":0}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.amount").exists());
    }

    @Test
    @DisplayName("POST /authorize hibás currency formátum esetén 400")
    void authorize_returns400_whenCurrencyInvalid() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"terminalId\":\"TERM-01\",\"currency\":\"hu\",\"amount\":100}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.currency").exists());
    }

    @Test
    @DisplayName("POST /authorize currency hiány esetén HUF default")
    void authorize_defaultsCurrencyToHuf() throws Exception {
        when(posTerminalService.initiatePayment(eq(new BigDecimal("100")), eq("HUF"), eq("TERM-01")))
                .thenReturn(PosTransactionResult.approved("AUTH-HUF", "REF-HUF"));

        mockMvc.perform(post("/api/v1/pos-terminal-stub/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"terminalId\":\"TERM-01\",\"amount\":100}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currency").value("HUF"));

        verify(posTerminalService).initiatePayment(eq(new BigDecimal("100")), eq("HUF"), eq("TERM-01"));
    }

    @Test
    @DisplayName("POST /authorize not found kivétel esetén 404")
    void authorize_mapsResourceNotFoundTo404() throws Exception {
        when(posTerminalService.initiatePayment(eq(new BigDecimal("12500")), eq("HUF"), eq("TERM-404")))
                .thenThrow(new ResourceNotFoundException("POS terminál nem található: TERM-404"));

        mockMvc.perform(post("/api/v1/pos-terminal-stub/authorize")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"terminalId\":\"TERM-404\",\"currency\":\"HUF\",\"amount\":12500}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
    }

    @Test
    @DisplayName("POST /void kompatibilis route működik")
    void void_callsServiceAndReturnsResult() throws Exception {
        when(posTerminalService.initiateReversal(eq("TX-01"), eq("TERM-01")))
                .thenReturn(PosTransactionResult.approved("AUTH-VOID", "REF-VOID"));

        mockMvc.perform(post("/api/v1/pos-terminal-stub/void/TX-01").param("terminalId", "TERM-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.action").value("VOID"))
                .andExpect(jsonPath("$.transactionId").value("TX-01"))
                .andExpect(jsonPath("$.approved").value(true));

        verify(posTerminalService).initiateReversal(eq("TX-01"), eq("TERM-01"));
    }

    @Test
    @DisplayName("POST /void hibás transactionId esetén 400")
    void void_returns400_whenTransactionIdInvalid() throws Exception {
        mockMvc.perform(post("/api/v1/pos-terminal-stub/void/TX$01").param("terminalId", "TERM-01"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /settlement kompatibilis route működik")
    void settlement_callsServiceAndReturnsResult() throws Exception {
        when(posTerminalService.dailyClose(eq("TERM-01")))
                .thenReturn(PosClosingResult.success(3, new BigDecimal("21000")));

        mockMvc.perform(post("/api/v1/pos-terminal-stub/settlement").param("terminalId", "TERM-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.action").value("SETTLEMENT"))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.transactionCount").value(3));

        verify(posTerminalService).dailyClose(eq("TERM-01"));
    }

    @Test
    @DisplayName("GET /pos-terminal-stub/status connected mezőt active+reachable alapján ad")
    void status_mapsConnectedFromTerminalStatus() throws Exception {
        when(posTerminalService.getStatus("TERM-01"))
                .thenReturn(new TerminalStatus("TERM-01", "OTP 1", "OTP", true, true,
                        LocalDateTime.of(2026, 3, 21, 15, 0), "Terminál elérhető"));

        mockMvc.perform(get("/api/v1/pos-terminal-stub/status").param("terminalId", "TERM-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.terminalId").value("TERM-01"))
                .andExpect(jsonPath("$.connected").value(true))
                .andExpect(jsonPath("$.active").value(true))
                .andExpect(jsonPath("$.reachable").value(true));

        verify(posTerminalService).getStatus("TERM-01");
    }

}
