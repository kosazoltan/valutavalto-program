package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.security.JwtAuthenticationFilter;
import hu.puzzleir.valuta.service.BookingExportService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * BookingExportController INTEGRÁCIÓS tesztek — @WebMvcTest.
 *
 * CSV export tesztek: napi és havi formátum.
 */
@WebMvcTest(
    controllers = BookingExportController.class,
    excludeFilters = @ComponentScan.Filter(
        type = FilterType.ASSIGNABLE_TYPE,
        classes = JwtAuthenticationFilter.class
    )
)
class BookingExportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private BookingExportService service;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    // =====================================================================
    // Napi CSV export: fejléc ellenőrzés
    // =====================================================================
    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("GET /booking/daily → CSV fejléc tartalmazza a kötelező oszlopokat")
    void testExportDaily_CSV_header() throws Exception {
        // Arrange — CSV fejléccel és 1 sor adattal
        String csvContent = "Dátum;Bizonylat;Típus;Valuta;Összeg;Árfolyam;HUF;Kezelési díj;Pénztáros\n" +
                "2026-01-15;V00001;BUY;EUR;500.00;400.50;200250;3000;Kiss Péter\n";
        byte[] csvBytes = csvContent.getBytes(StandardCharsets.UTF_8);

        when(service.exportDailyBooking(any(UUID.class), any())).thenReturn(csvBytes);

        UUID branchId = UUID.randomUUID();

        // Act
        MvcResult result = mockMvc.perform(get("/api/v1/booking/daily")
                        .param("branchId", branchId.toString())
                        .param("date", "2026-01-15"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("konyveles-napi")))
                .andExpect(content().contentTypeCompatibleWith("text/csv"))
                .andReturn();

        // Assert — CSV tartalom ellenőrzés
        String body = result.getResponse().getContentAsString();
        assertThat(body).contains("Dátum");
        assertThat(body).contains("Bizonylat");
        assertThat(body).contains("Típus");
        assertThat(body).contains("Valuta");
    }

    // =====================================================================
    // Havi CSV export: UTF-8 BOM
    // =====================================================================
    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("GET /booking/monthly → CSV UTF-8 BOM prefix")
    void testExportMonthly_CSV_UTF8BOM() throws Exception {
        // Arrange — CSV UTF-8 BOM-mal (Excel-barát magyar)
        byte[] UTF8_BOM = new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};
        String csvContent = "Dátum;Bizonylat;Típus;Valuta;Összeg;Árfolyam;HUF\n";
        byte[] csvWithBom = new byte[UTF8_BOM.length + csvContent.getBytes(StandardCharsets.UTF_8).length];
        System.arraycopy(UTF8_BOM, 0, csvWithBom, 0, UTF8_BOM.length);
        System.arraycopy(csvContent.getBytes(StandardCharsets.UTF_8), 0, csvWithBom, UTF8_BOM.length,
                csvContent.getBytes(StandardCharsets.UTF_8).length);

        when(service.exportMonthlyBooking(any(UUID.class), eq("2026-01"))).thenReturn(csvWithBom);

        UUID branchId = UUID.randomUUID();

        // Act
        MvcResult result = mockMvc.perform(get("/api/v1/booking/monthly")
                        .param("branchId", branchId.toString())
                        .param("month", "2026-01"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("konyveles-havi")))
                .andReturn();

        // Assert — UTF-8 BOM ellenőrzés (első 3 byte)
        byte[] responseBytes = result.getResponse().getContentAsByteArray();
        assertThat(responseBytes.length).isGreaterThan(3);
        assertThat(responseBytes[0]).isEqualTo((byte) 0xEF);
        assertThat(responseBytes[1]).isEqualTo((byte) 0xBB);
        assertThat(responseBytes[2]).isEqualTo((byte) 0xBF);
    }
}
