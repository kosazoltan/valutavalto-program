package hu.puzzleir.valuta.controller;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.entity.CommissionCalculation;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.service.CommissionCalculationService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CommissionCalculationController INTEGRÁCIÓS tesztek — @WebMvcTest.
 *
 * HTTP endpoint tesztek: kalkuláció, lista, jóváhagyás.
 */
@WebMvcTest(
    controllers = CommissionCalculationController.class,
    excludeFilters = @ComponentScan.Filter(
        type = FilterType.ASSIGNABLE_TYPE,
        classes = JwtAuthenticationFilter.class
    )
)
class CommissionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CommissionCalculationService service;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    /**
     * Segéd: teszt CommissionCalculation entity.
     */
    private CommissionCalculation createTestCalc() {
        return CommissionCalculation.builder()
                .id(UUID.randomUUID())
                .workerId(1L)
                .branchId(UUID.randomUUID())
                .period("2026-01")
                .calculationType(CommissionCalculation.CalculationType.MONTHLY)
                .totalTransactions(50)
                .totalVolumeHuf(new BigDecimal("3000000"))
                .commissionRate(new BigDecimal("0.015"))
                .commissionAmount(new BigDecimal("45000"))
                .bonusAmount(BigDecimal.ZERO)
                .deductions(BigDecimal.ZERO)
                .netCommission(new BigDecimal("45000"))
                .status(CommissionCalculation.CommissionStatus.CALCULATED)
                .calculatedAt(LocalDateTime.now())
                .build();
    }

    // =====================================================================
    // POST /calculate → 201
    // =====================================================================
    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /commissions/calculate → 201 CREATED")
    void testCalculate_200() throws Exception {
        // Arrange
        CommissionCalculation calc = createTestCalc();
        when(service.calculateMonthly(eq(1L), eq("2026-01"), anyInt()))
                .thenReturn(calc);

        // Act & Assert
        mockMvc.perform(post("/api/v1/commissions/calculate")
                        .param("workerId", "1")
                        .param("month", "2026-01"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.period").value("2026-01"))
                .andExpect(jsonPath("$.totalTransactions").value(50))
                .andExpect(jsonPath("$.status").value("CALCULATED"));
    }

    // =====================================================================
    // POST /calculate-all → 201
    // =====================================================================
    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /commissions/calculate-all → 201 CREATED")
    void testCalculateAll_200() throws Exception {
        // Arrange
        List<CommissionCalculation> calcs = List.of(createTestCalc(), createTestCalc());
        when(service.calculateAllWorkers(any(UUID.class), eq("2026-01"), anyInt()))
                .thenReturn(calcs);

        UUID branchId = UUID.randomUUID();

        // Act & Assert
        mockMvc.perform(post("/api/v1/commissions/calculate-all")
                        .param("branchId", branchId.toString())
                        .param("month", "2026-01"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.length()").value(2));
    }

    // =====================================================================
    // POST /{id}/approve → 200
    // =====================================================================
    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /commissions/{id}/approve → 200 OK")
    void testApprove_200() throws Exception {
        // Arrange
        CommissionCalculation calc = createTestCalc();
        calc.setStatus(CommissionCalculation.CommissionStatus.APPROVED);
        calc.setApprovedAt(LocalDateTime.now());

        when(service.approveCommission(any(UUID.class))).thenReturn(calc);

        // Act & Assert
        mockMvc.perform(post("/api/v1/commissions/" + UUID.randomUUID() + "/approve"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"));
    }

    // =====================================================================
    // POST /{id}/approve → 400 (nem létező ID)
    // =====================================================================
    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /commissions/{id}/approve → 400 BAD REQUEST (nem létező)")
    void testApprove_404() throws Exception {
        // Arrange — ValidationException a service-ből
        UUID fakeId = UUID.randomUUID();
        when(service.approveCommission(fakeId))
                .thenThrow(new ValidationException("Jutalék számítás nem található: " + fakeId));

        // Act & Assert
        mockMvc.perform(post("/api/v1/commissions/" + fakeId + "/approve"))
                .andExpect(status().isBadRequest());
    }
}
