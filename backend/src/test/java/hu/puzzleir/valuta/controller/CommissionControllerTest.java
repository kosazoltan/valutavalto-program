package hu.puzzleir.valuta.controller;

import tools.jackson.databind.json.JsonMapper;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.CommissionCalculation;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.CommissionCalculationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.converter.json.JacksonJsonHttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CommissionCalculationController UNIT tesztek â€” standalone MockMvc.
 *
 * HTTP endpoint tesztek: kalkulĂˇciĂł, lista, jĂłvĂˇhagyĂˇs.
 * Spring kontextus nĂ©lkĂĽl â†’ gyors, izolĂˇlt tesztek.
 */
@ExtendWith(MockitoExtension.class)
class CommissionControllerTest {

    private MockMvc mockMvc;

    @Mock
    private CommissionCalculationService service;

    @InjectMocks
    private CommissionCalculationController controller;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        JsonMapper om = new JsonMapper();

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setMessageConverters(new JacksonJsonHttpMessageConverter(om))
                .build();
    }

    /**
     * SegĂ©d: teszt CommissionCalculation entity.
     */
    private CommissionCalculation createTestCalc() {
        return CommissionCalculation.builder()
                .id(UUID.randomUUID())
                .workerId(1L)
                .branchId(BRANCH_ID)
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
    // POST /calculate â†’ 201
    // =====================================================================
    @Test
    @DisplayName("POST /commissions/calculate â†’ 201 CREATED")
    void testCalculate_200() throws Exception {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            CommissionCalculation calc = createTestCalc();
            when(service.calculateMonthly(eq(1L), eq("2026-01"), any(UUID.class)))
                    .thenReturn(calc);

            mockMvc.perform(post("/api/v1/commissions/calculate")
                            .param("workerId", "1")
                            .param("month", "2026-01"))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.period").value("2026-01"))
                    .andExpect(jsonPath("$.totalTransactions").value(50))
                    .andExpect(jsonPath("$.status").value("CALCULATED"));
        }
    }

    // =====================================================================
    // POST /calculate-all â†’ 201
    // =====================================================================
    @Test
    @DisplayName("POST /commissions/calculate-all â†’ 201 CREATED")
    void testCalculateAll_200() throws Exception {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            List<CommissionCalculation> calcs = List.of(createTestCalc(), createTestCalc());
            when(service.calculateAllWorkers(any(UUID.class), eq("2026-01"), any(UUID.class)))
                    .thenReturn(calcs);

            mockMvc.perform(post("/api/v1/commissions/calculate-all")
                            .param("branchId", BRANCH_ID.toString())
                            .param("month", "2026-01"))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.length()").value(2));
        }
    }

    // =====================================================================
    // POST /{id}/approve â†’ 200
    // =====================================================================
    @Test
    @DisplayName("POST /commissions/{id}/approve â†’ 200 OK")
    void testApprove_200() throws Exception {
        CommissionCalculation calc = createTestCalc();
        calc.setStatus(CommissionCalculation.CommissionStatus.APPROVED);
        calc.setApprovedAt(LocalDateTime.now());

        when(service.approveCommission(any(UUID.class))).thenReturn(calc);

        mockMvc.perform(post("/api/v1/commissions/" + UUID.randomUUID() + "/approve"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"));
    }

    // =====================================================================
    // POST /{id}/approve â†’ 400 (ValidationException)
    // =====================================================================
    @Test
    @DisplayName("POST /commissions/{id}/approve â†’ 400 BAD REQUEST")
    void testApprove_404() throws Exception {
        UUID fakeId = UUID.randomUUID();
        when(service.approveCommission(fakeId))
                .thenThrow(new ValidationException("JutalĂ©k szĂˇmĂ­tĂˇs nem talĂˇlhatĂł: " + fakeId));

        mockMvc.perform(post("/api/v1/commissions/" + fakeId + "/approve"))
                .andExpect(status().isBadRequest());
    }
}
