package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.InventoryService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * InventoryController UNIT tests - standalone MockMvc.
 *
 * Regression goal: /api/v1/inventory/stock must return service data,
 * and must not fall back to hardcoded empty placeholder list.
 */
@ExtendWith(MockitoExtension.class)
class InventoryControllerTest {

    private MockMvc mockMvc;

    @Mock
    private InventoryService inventoryService;

    @InjectMocks
    private InventoryController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("GET /inventory/stock returns service-provided balances")
    void getAllStock_returnsServiceData_notPlaceholder() throws Exception {
        UUID branchId = UUID.randomUUID();

        Branch branch = Branch.builder()
                .id(branchId)
                .code("BORSI")
                .build();

        Currency currency = Currency.builder()
                .id(1L)
                .code("EUR")
                .name("Euro")
                .build();

        CashBalance balance = CashBalance.builder()
                .id(10L)
                .branch(branch)
                .currency(currency)
                .currentBalance(new BigDecimal("1234.56"))
                .openingBalance(new BigDecimal("1200.00"))
                .build();

        when(inventoryService.getAllStock()).thenReturn(List.of(balance));

        // branch, currency, company are @JsonIgnore on CashBalance entity
        // so only directly serialized fields appear in JSON response
        mockMvc.perform(get("/api/v1/inventory/stock"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(10))
                .andExpect(jsonPath("$[0].currentBalance").value(1234.56))
                .andExpect(jsonPath("$[0].openingBalance").value(1200.00));

        verify(inventoryService, times(1)).getAllStock();
        verifyNoMoreInteractions(inventoryService);
    }
}
