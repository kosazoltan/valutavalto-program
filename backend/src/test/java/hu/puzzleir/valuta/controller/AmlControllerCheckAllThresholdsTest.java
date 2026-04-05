package hu.puzzleir.valuta.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import hu.puzzleir.valuta.dto.aml.AmlCheckResult;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.AmlService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Sprint 5 — C1: GET /api/v1/aml/check-all-thresholds endpoint teszt
 *
 * Ellenőrzi:
 * 1. Az endpoint létezik (nem 404)
 * 2. AmlCheckResult formátumú a válasz (JSON mezők jelen vannak)
 * 3. Helyes paraméterek átadódnak a service-nek
 * 4. Normál és blocked eset is helyesen válaszol
 */
@ExtendWith(MockitoExtension.class)
class AmlControllerCheckAllThresholdsTest {

    private MockMvc mockMvc;

    @Mock
    private AmlService amlService;

    @InjectMocks
    private AmlController controller;

    @BeforeEach
    void setUp() {
        ObjectMapper om = new ObjectMapper();
        om.registerModule(new JavaTimeModule());

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
            .setControllerAdvice(new GlobalExceptionHandler())
            .setMessageConverters(new MappingJackson2HttpMessageConverter(om))
            .build();
    }

    @Test
    @DisplayName("C1-1: GET /api/v1/aml/check-all-thresholds → 200 OK, nem 404")
    void testCheckAllThresholds_endpoint_exists_returns200() throws Exception {
        AmlCheckResult mockResult = AmlCheckResult.builder()
            .transactionType(0)
            .weeklyTotal(BigDecimal.ZERO)
            .yearlyMax(BigDecimal.ZERO)
            .quarterlyCount(0)
            .quarterlyTotal(BigDecimal.ZERO)
            .requiresId(false)
            .requiresEnhanced(false)
            .blocked(false)
            .warnings(List.of())
            .build();

        when(amlService.checkAllThresholds(
                ArgumentMatchers.eq("C001"),
                ArgumentMatchers.<BigDecimal>any(),
                ArgumentMatchers.eq("EUR")))
            .thenReturn(mockResult);

        mockMvc.perform(get("/api/v1/aml/check-all-thresholds")
                .param("customerId", "C001")
                .param("hufAmount", "50000")
                .param("currencyCode", "EUR"))
            .andExpect(status().isOk());
    }

    @Test
    @DisplayName("C1-2: GET /api/v1/aml/check-all-thresholds → AmlCheckResult JSON mezők megvannak")
    void testCheckAllThresholds_response_hasAmlCheckResultFields() throws Exception {
        AmlCheckResult mockResult = AmlCheckResult.builder()
            .transactionType(2)
            .weeklyTotal(new BigDecimal("200000"))
            .yearlyMax(new BigDecimal("500000"))
            .quarterlyCount(1)
            .quarterlyTotal(new BigDecimal("200000"))
            .requiresId(true)
            .requiresEnhanced(false)
            .blocked(false)
            .warnings(List.of("KÜLFÖLDI ÜGYFÉL: Fokozott azonosítás szükséges"))
            .build();

        when(amlService.checkAllThresholds(
                ArgumentMatchers.eq("C002"),
                ArgumentMatchers.<BigDecimal>any(),
                ArgumentMatchers.eq("EUR")))
            .thenReturn(mockResult);

        mockMvc.perform(get("/api/v1/aml/check-all-thresholds")
                .param("customerId", "C002")
                .param("hufAmount", "100000")
                .param("currencyCode", "EUR"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.transactionType").value(2))
            .andExpect(jsonPath("$.requiresId").value(true))
            .andExpect(jsonPath("$.requiresEnhanced").value(false))
            .andExpect(jsonPath("$.blocked").value(false))
            .andExpect(jsonPath("$.weeklyTotal").isNumber())
            .andExpect(jsonPath("$.yearlyMax").isNumber())
            .andExpect(jsonPath("$.quarterlyCount").isNumber())
            .andExpect(jsonPath("$.warnings").isArray())
            .andExpect(jsonPath("$.warnings[0]", containsString("KÜLFÖLDI")));
    }

    @Test
    @DisplayName("C1-3: GET /api/v1/aml/check-all-thresholds → blocked=true ha transactionType=-1")
    void testCheckAllThresholds_blocked_response() throws Exception {
        AmlCheckResult blockedResult = AmlCheckResult.builder()
            .transactionType(-1)
            .weeklyTotal(BigDecimal.ZERO)
            .yearlyMax(BigDecimal.ZERO)
            .quarterlyCount(0)
            .quarterlyTotal(BigDecimal.ZERO)
            .requiresId(true)
            .requiresEnhanced(false)
            .blocked(true)
            .warnings(List.of("BLOKKOLVA: Külföldi ügyfél nem kaphat USD-t"))
            .build();

        when(amlService.checkAllThresholds(
                ArgumentMatchers.eq("CFOR"),
                ArgumentMatchers.<BigDecimal>any(),
                ArgumentMatchers.eq("USD")))
            .thenReturn(blockedResult);

        mockMvc.perform(get("/api/v1/aml/check-all-thresholds")
                .param("customerId", "CFOR")
                .param("hufAmount", "50000")
                .param("currencyCode", "USD"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.transactionType").value(-1))
            .andExpect(jsonPath("$.blocked").value(true))
            .andExpect(jsonPath("$.warnings[0]", containsString("BLOKKOLVA")));
    }

    @Test
    @DisplayName("C1-4: GET /api/v1/aml/check-all-thresholds — currencyCode opcionális (null)")
    void testCheckAllThresholds_withoutCurrencyCode() throws Exception {
        AmlCheckResult mockResult = AmlCheckResult.builder()
            .transactionType(0)
            .weeklyTotal(BigDecimal.ZERO)
            .yearlyMax(BigDecimal.ZERO)
            .quarterlyCount(0)
            .quarterlyTotal(BigDecimal.ZERO)
            .requiresId(false)
            .requiresEnhanced(false)
            .blocked(false)
            .warnings(List.of())
            .build();

        when(amlService.checkAllThresholds(
                ArgumentMatchers.eq("C003"),
                ArgumentMatchers.<BigDecimal>any(),
                ArgumentMatchers.isNull()))
            .thenReturn(mockResult);

        mockMvc.perform(get("/api/v1/aml/check-all-thresholds")
                .param("customerId", "C003")
                .param("hufAmount", "50000"))
            // currencyCode elhagyva → required = false → nem 400
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.transactionType").value(0))
            .andExpect(jsonPath("$.blocked").value(false));
    }

    @Test
    @DisplayName("C1-5: GET /api/v1/aml/check-all-thresholds — hiányzó hufAmount → 400")
    void testCheckAllThresholds_missingHufAmount_returns400() throws Exception {
        mockMvc.perform(get("/api/v1/aml/check-all-thresholds")
                .param("customerId", "C004"))
            .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("C1-6: service-nek átadódik a helyes customerId, hufAmount, currencyCode")
    void testCheckAllThresholds_passesCorrectParamsToService() throws Exception {
        AmlCheckResult mockResult = AmlCheckResult.builder()
            .transactionType(5)
            .weeklyTotal(new BigDecimal("9000000"))
            .yearlyMax(BigDecimal.ZERO)
            .quarterlyCount(0)
            .quarterlyTotal(BigDecimal.ZERO)
            .requiresId(true)
            .requiresEnhanced(true)
            .blocked(false)
            .warnings(List.of("FOKOZOTT: Heti göngyölt összeg >= 10.000.000 Ft"))
            .build();

        when(amlService.checkAllThresholds(
                ArgumentMatchers.eq("BIG_CUST"),
                ArgumentMatchers.eq(new BigDecimal("2000000")),
                ArgumentMatchers.eq("CHF")))
            .thenReturn(mockResult);

        mockMvc.perform(get("/api/v1/aml/check-all-thresholds")
                .param("customerId", "BIG_CUST")
                .param("hufAmount", "2000000")
                .param("currencyCode", "CHF"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.transactionType").value(5))
            .andExpect(jsonPath("$.requiresEnhanced").value(true));

        verify(amlService).checkAllThresholds("BIG_CUST", new BigDecimal("2000000"), "CHF");
    }
}
