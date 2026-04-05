package hu.puzzleir.valuta.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import hu.puzzleir.valuta.dto.aml.AmlReportDto;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.AmlService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Sprint 5 C5 — GET /api/v1/aml/overdue endpoint tesztek.
 *
 * Ellenőrzi:
 * - Endpoint létezik (nem 404)
 * - 200 OK üres lista esetén
 * - 200 OK adatokkal, OVERDUE rekord megjelenik
 * - service.getOverdueReports() meghívódik
 */
@ExtendWith(MockitoExtension.class)
class AmlOverdueEndpointTest {

    private MockMvc mockMvc;

    @Mock
    private AmlService amlService;

    @InjectMocks
    private AmlController amlController;

    @BeforeEach
    void setUp() {
        ObjectMapper om = new ObjectMapper();
        om.registerModule(new JavaTimeModule());
        mockMvc = MockMvcBuilders.standaloneSetup(amlController)
            .setControllerAdvice(new GlobalExceptionHandler())
            .setMessageConverters(new MappingJackson2HttpMessageConverter(om))
            .build();
    }

    @Test
    @DisplayName("C5-6a: GET /api/v1/aml/overdue → 200 OK, üres lista esetén is")
    void testOverdueEndpoint_emptyList_returns200() throws Exception {
        when(amlService.getOverdueReports()).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/v1/aml/overdue"))
            .andExpect(status().isOk())
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$").isArray())
            .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    @DisplayName("C5-6b: GET /api/v1/aml/overdue → adatokkal, OVERDUE státusz megjelenik")
    void testOverdueEndpoint_withData_returns200AndList() throws Exception {
        AmlReportDto dto = AmlReportDto.builder()
            .id(UUID.randomUUID())
            .customerId("C001")
            .reportType("STANDARD")
            .riskLevel("LOW")
            .amountHuf(BigDecimal.valueOf(500000))
            .currencyCode("EUR")
            .status("OVERDUE")
            .deadlineAt(LocalDateTime.now().minusDays(1))
            .overdue(true)
            .build();

        when(amlService.getOverdueReports()).thenReturn(List.of(dto));

        mockMvc.perform(get("/api/v1/aml/overdue"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isArray())
            .andExpect(jsonPath("$[0].status").value("OVERDUE"))
            .andExpect(jsonPath("$[0].overdue").value(true))
            .andExpect(jsonPath("$[0].customerId").value("C001"));
    }

    @Test
    @DisplayName("C5-6c: GET /api/v1/aml/overdue → service.getOverdueReports() meghívódik")
    void testOverdueEndpoint_callsService() throws Exception {
        when(amlService.getOverdueReports()).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/v1/aml/overdue"))
            .andExpect(status().isOk());

        verify(amlService).getOverdueReports();
    }

    @Test
    @DisplayName("C5-6d: GET /api/v1/aml/overdue → több overdue rekord esetén mind visszaadódik")
    void testOverdueEndpoint_multipleRecords() throws Exception {
        List<AmlReportDto> dtos = List.of(
            AmlReportDto.builder().id(UUID.randomUUID()).customerId("C001")
                .reportType("STANDARD").riskLevel("LOW").status("OVERDUE").overdue(true)
                .amountHuf(BigDecimal.valueOf(500000))
                .deadlineAt(LocalDateTime.now().minusDays(2)).build(),
            AmlReportDto.builder().id(UUID.randomUUID()).customerId("C002")
                .reportType("ENHANCED").riskLevel("HIGH").status("OVERDUE").overdue(true)
                .amountHuf(BigDecimal.valueOf(2000000))
                .deadlineAt(LocalDateTime.now().minusDays(1)).build()
        );

        when(amlService.getOverdueReports()).thenReturn(dtos);

        mockMvc.perform(get("/api/v1/aml/overdue"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(2))
            .andExpect(jsonPath("$[0].status").value("OVERDUE"))
            .andExpect(jsonPath("$[1].status").value("OVERDUE"));
    }
}
