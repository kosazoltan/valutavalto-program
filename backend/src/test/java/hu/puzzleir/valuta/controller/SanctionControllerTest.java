package hu.puzzleir.valuta.controller;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningRequest;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.repository.SanctionEntryRepository;
import hu.puzzleir.valuta.service.SanctionScreeningService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Collections;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * SanctionScreeningController UNIT tesztek — standalone MockMvc.
 *
 * HTTP endpoint tesztek: ügyfél szűrés és XML import.
 */
@ExtendWith(MockitoExtension.class)
class SanctionControllerTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Mock
    private SanctionScreeningService screeningService;

    @Mock
    private SanctionEntryRepository sanctionEntryRepository;

    @InjectMocks
    private SanctionScreeningController controller;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    // =====================================================================
    // POST /screen → 200 OK
    // =====================================================================
    @Test
    @DisplayName("POST /sanctions/screen → 200 OK, CLEAR eredmény")
    void testScreen_200() throws Exception {
        // Arrange
        SanctionScreeningResult clearResult = SanctionScreeningResult.builder()
                .matched(false)
                .matches(Collections.emptyList())
                .riskLevel("CLEAR")
                .build();

        // Principal null → workerId = "unknown"; nationality null (7-arg overload, G4)
        when(screeningService.screenCustomer(
                eq("Kiss János"), eq("123456AB"), isNull(), isNull(),
                eq("unknown"), eq("unknown"), isNull()
        )).thenReturn(clearResult);

        SanctionScreeningRequest request = SanctionScreeningRequest.builder()
                .name("Kiss János")
                .documentNumber("123456AB")
                .build();

        // Act & Assert
        mockMvc.perform(post("/api/v1/sanctions/screen")
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
    @DisplayName("POST /sanctions/import → 201 CREATED, XML feldolgozva")
    void testImport_200() throws Exception {
        // Arrange — mock XML fájl
        String xmlContent = """
                <?xml version="1.0" encoding="UTF-8"?>
                <CONSOLIDATED_LIST>
                    <INDIVIDUAL>
                        <FIRST_NAME>Test</FIRST_NAME>
                        <SECOND_NAME>Person</SECOND_NAME>
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
                        .file(file))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.imported").value(1))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("sikeresen")));
    }
}
