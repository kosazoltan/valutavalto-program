package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.currency.CurrencyDenominationImageDto;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.DocumentSide;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.CurrencyDenominationImageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class CurrencyDenominationImageControllerTest {

    private MockMvc mockMvc;

    @Mock
    private CurrencyDenominationImageService service;

    @InjectMocks
    private CurrencyDenominationImageController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("upload: multipart kérés enumokra parse-olva delegál")
    void upload_delegates() throws Exception {
        UUID id = UUID.randomUUID();
        when(service.upload(eq(1L), eq(new BigDecimal("500")), eq(DenominationType.BANKNOTE),
                eq(DocumentSide.FRONT), ArgumentMatchers.any()))
                .thenReturn(CurrencyDenominationImageDto.builder().id(id).build());
        MockMultipartFile file = new MockMultipartFile("file", "500.png", "image/png", "abc".getBytes());

        mockMvc.perform(multipart("/api/v1/currency-denomination-images/upload")
                        .file(file)
                        .param("currencyId", "1")
                        .param("faceValue", "500")
                        .param("denominationType", "BANKNOTE")
                        .param("side", "FRONT"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id.toString()));

        verify(service).upload(eq(1L), eq(new BigDecimal("500")), eq(DenominationType.BANKNOTE),
                eq(DocumentSide.FRONT), ArgumentMatchers.any());
    }

    @Test
    @DisplayName("upload: hibás oldal 400 VALIDATION_FAILED")
    void upload_invalidSide_badRequest() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "500.png", "image/png", "abc".getBytes());

        mockMvc.perform(multipart("/api/v1/currency-denomination-images/upload")
                        .file(file)
                        .param("currencyId", "1")
                        .param("faceValue", "500")
                        .param("denominationType", "BANKNOTE")
                        .param("side", "SIDEWAYS"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("upload: hibás címlet-típus 400 VALIDATION_FAILED")
    void upload_invalidType_badRequest() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "500.png", "image/png", "abc".getBytes());

        mockMvc.perform(multipart("/api/v1/currency-denomination-images/upload")
                        .file(file)
                        .param("currencyId", "1")
                        .param("faceValue", "500")
                        .param("denominationType", "PAPER")
                        .param("side", "FRONT"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("list: currencyId opcionális szűrő")
    void list_optionalCurrencyFilter() throws Exception {
        CurrencyDenominationImageDto dto = CurrencyDenominationImageDto.builder().id(UUID.randomUUID()).build();
        when(service.list(null)).thenReturn(List.of(dto));
        when(service.list(1L)).thenReturn(List.of(dto));

        mockMvc.perform(get("/api/v1/currency-denomination-images"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(dto.getId().toString()));
        mockMvc.perform(get("/api/v1/currency-denomination-images").param("currencyId", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(dto.getId().toString()));

        verify(service).list(null);
        verify(service).list(1L);
    }

    @Test
    @DisplayName("getImage: bájtokat content-type-pal szolgál")
    void getImage_servesBytesWithContentType() throws Exception {
        UUID id = UUID.randomUUID();
        byte[] bytes = "img".getBytes();
        when(service.getImage(id)).thenReturn(new CurrencyDenominationImageService.ImagePayload("image/jpeg", bytes));

        mockMvc.perform(get("/api/v1/currency-denomination-images/{id}/image", id))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_JPEG_VALUE))
                .andExpect(content().bytes(bytes));
    }

    @Test
    @DisplayName("setActive: JSON active mezőt delegál")
    void setActive_delegates() throws Exception {
        UUID id = UUID.randomUUID();
        when(service.setActive(id, false)).thenReturn(CurrencyDenominationImageDto.builder()
                .id(id)
                .active(false)
                .build());

        mockMvc.perform(put("/api/v1/currency-denomination-images/{id}/active", id)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"active\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(false));

        verify(service).setActive(id, false);
    }
}
