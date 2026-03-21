package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.service.DocumentScannerService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.UUID;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class DocumentScannerStubControllerTest {

    private MockMvc mockMvc;

    @Mock
    private DocumentScannerService documentScannerService;

    @InjectMocks
    private DocumentScannerStubController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("POST /scan 501 helyett belső mentésre delegál és 200")
    void scan_delegatesToService() throws Exception {
        UUID id = UUID.randomUUID();
        when(documentScannerService.saveScannedDocument(ArgumentMatchers.any(), ArgumentMatchers.any()))
                .thenReturn(ScannedDocumentDto.builder().id(id).documentType("OTHER").build());

        MockMultipartFile file = new MockMultipartFile("file", "ok.png", "image/png", "abc".getBytes());

        mockMvc.perform(multipart("/api/v1/document-scanner/scan")
                        .file(file)
                        .param("documentType", "OTHER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id.toString()));

        verify(documentScannerService).saveScannedDocument(ArgumentMatchers.any(), ArgumentMatchers.any());
    }

    @Test
    @DisplayName("POST /upload hibás documentType esetén 400 VALIDATION_FAILED")
    void upload_invalidDocumentType() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "ok.png", "image/png", "abc".getBytes());

        mockMvc.perform(multipart("/api/v1/document-scanner/upload")
                        .file(file)
                        .param("documentType", "INVALID"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_FAILED"));
    }

    @Test
    @DisplayName("POST /upload szolgáltatói inaktivitás esetén 409")
    void upload_providerInactiveMappedTo409() throws Exception {
        when(documentScannerService.saveScannedDocument(ArgumentMatchers.any(), ArgumentMatchers.any()))
                .thenThrow(new BusinessException("inactive", "SCANNER_PROVIDER_INACTIVE", HttpStatus.CONFLICT));

        MockMultipartFile file = new MockMultipartFile("file", "ok.png", "image/png", "abc".getBytes());

        mockMvc.perform(multipart("/api/v1/document-scanner/upload")
                        .file(file)
                        .param("documentType", "OTHER"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("SCANNER_PROVIDER_INACTIVE"));
    }

    @Test
    @DisplayName("POST /upload not found ág 404-re map-elve")
    void upload_notFoundMappedTo404() throws Exception {
        when(documentScannerService.saveScannedDocument(ArgumentMatchers.any(), ArgumentMatchers.any()))
                .thenThrow(new ResourceNotFoundException("customer not found"));

        MockMultipartFile file = new MockMultipartFile("file", "ok.png", "image/png", "abc".getBytes());

        mockMvc.perform(multipart("/api/v1/document-scanner/upload")
                        .file(file)
                        .param("documentType", "OTHER"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
    }
}
