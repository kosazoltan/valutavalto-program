package hu.puzzleir.valuta.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningRequest;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.repository.SanctionEntryRepository;
import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.service.SanctionScreeningService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Collections;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * SanctionScreeningController INTEGRÁCIÓS tesztek — @WebMvcTest.
 *
 * HTTP endpoint tesztek: ügyfél szűrés és XML import.
 */
@WebMvcTest(
    controllers = SanctionScreeningController.class,
    excludeFilters = @ComponentScan.Filter(
        type = FilterType.ASSIGNABLE_TYPE,
        classes = JwtAuthenticationFilter.class
    )
)
class SanctionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private SanctionScreeningService screeningService;

    @MockBean
    private SanctionEntryRepository sanctionEntryRepository;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    // =====================================================================
    // POST /screen → 200 OK
    // =====================================================================
    @Test
    @WithMockUser(roles = "CASHIER")
    @DisplayName("POST /sanctions/screen → 200 OK, CLEAR eredmény")
    void testScreen_200() throws Exception {
        // Arrange
        SanctionScreeningResult clearResult = SanctionScreeningResult.builder()
                .matched(false)
                .matches(Collections.emptyList())
                .riskLevel("CLEAR")
                .build();

        when(screeningService.screenCustomer(
                eq("Kiss János"), any(), any(), any(), any(), any()
        )).thenReturn(clearResult);

        SanctionScreeningRequest request = SanctionScreeningRequest.builder()
                .name("Kiss János")
                .documentNumber("123456AB")
                .build();

        // Act & Assert
        mockMvc.perform(post("/api/v1/sanctions/screen")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matched").value(false))
                .andExpect(jsonPath("$.riskLevel").value("CLEAR"));
    }

    // =====================================================================
    // POST /import → 201 CREATED
    // =====================================================================
    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /sanctions/import → 201 CREATED, XML feldolgozva")
    void testImport_200() throws Exception {
        // Arrange — mock XML fájl
        String xmlContent = """
                <?xml version="1.0" encoding="UTF-8"?>
                <CONSOLIDATED_LIST>
                    <INDIVIDUAL>
                        <FIRST_NAME>Test</FIRST_NAME>
                        <SECOND_NAME>Person</SECOND_NAME>
                        <THIRD_NAME/>
                        <DATE_OF_BIRTH/>
                        <NATIONALITY/>
                        <REFERENCE_NUMBER>QDi.999</REFERENCE_NUMBER>
                    </INDIVIDUAL>
                </CONSOLIDATED_LIST>
                """;

        MockMultipartFile file = new MockMultipartFile(
                "file", "sanctions.xml", "application/xml",
                xmlContent.getBytes()
        );

        when(screeningService.importSanctionList(any())).thenReturn(1);

        // Act & Assert
        mockMvc.perform(multipart("/api/v1/sanctions/import")
                        .file(file)
                        .with(csrf()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.imported").value(1))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("sikeresen")));
    }
}
