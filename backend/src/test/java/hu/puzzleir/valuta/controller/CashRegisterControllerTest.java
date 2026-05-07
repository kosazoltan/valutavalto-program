package hu.puzzleir.valuta.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.service.BranchService;
import hu.puzzleir.valuta.service.CashRegisterDeviceService;
import hu.puzzleir.valuta.service.CashRegisterService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class CashRegisterControllerTest {

    private static final UUID BRANCH_ID = UUID.fromString("20000000-0000-0000-0000-000000000001");

    private MockMvc mockMvc;

    @Mock private CashRegisterService cashRegisterService;
    @Mock private CashRegisterDeviceService cashRegisterDeviceService;
    @Mock private BranchService branchService;

    private CashRegisterController controller;

    @BeforeEach
    void setUp() {
        controller = new CashRegisterController(
                cashRegisterService,
                cashRegisterDeviceService,
                branchService,
                new ObjectMapper()
        );
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    @DisplayName("NAV bridge ERROR rawResponse nem HTTP 200")
    void printReceipt_returns502WhenEventContainsErrorStatus() throws Exception {
        String rawResponse = """
                {
                  "message": "Bizonylat NAV továbbítás sikertelen",
                  "status": "ERROR"
                }
                """;
        when(cashRegisterService.printReceipt(any()))
                .thenReturn(event(rawResponse));

        mockMvc.perform(post("/api/v1/cash-register/receipt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(receiptRequestJson()))
                .andExpect(status().isBadGateway())
                .andExpect(jsonPath("$.rawResponse").value(rawResponse));
    }

    @Test
    @DisplayName("OK rawResponse tovabbra is HTTP 200")
    void printReceipt_returns200WhenEventContainsOkStatus() throws Exception {
        when(cashRegisterService.printReceipt(any()))
                .thenReturn(event("{\"status\":\"OK\",\"message\":\"Bizonylat sikeresen nyomtatva\"}"));

        mockMvc.perform(post("/api/v1/cash-register/receipt")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(receiptRequestJson()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rawResponse").value("{\"status\":\"OK\",\"message\":\"Bizonylat sikeresen nyomtatva\"}"));
    }

    private String receiptRequestJson() {
        return """
                {
                  "branchId": "%s",
                  "receiptNumber": "R-1",
                  "amount": 1000,
                  "currencyCode": "HUF",
                  "amountHuf": 1000
                }
                """.formatted(BRANCH_ID);
    }

    private CashRegisterEventDto event(String rawResponse) {
        return CashRegisterEventDto.builder()
                .id(UUID.randomUUID())
                .branchId(BRANCH_ID)
                .eventType("RECEIPT")
                .receiptNumber("R-1")
                .amount(new BigDecimal("1000"))
                .currencyCode("HUF")
                .amountHuf(new BigDecimal("1000"))
                .eventTimestamp(LocalDateTime.now())
                .rawResponse(rawResponse)
                .build();
    }
}
