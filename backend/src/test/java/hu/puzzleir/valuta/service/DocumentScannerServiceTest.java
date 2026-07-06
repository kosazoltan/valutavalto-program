package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.document.DocumentScanUploadRequest;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.entity.ScannedDocument;
import hu.puzzleir.valuta.entity.ScannedDocumentType;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ScannedDocumentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DocumentScannerServiceTest {

    @Mock
    private ScannedDocumentRepository scannedDocumentRepository;
    @Mock
    private hu.puzzleir.valuta.repository.CustomerRepository customerRepository;
    @Mock
    private hu.puzzleir.valuta.repository.TransactionRepository transactionRepository;
    @Mock
    private SystemParameterService systemParameterService;

    private DocumentScannerService service;

    @BeforeEach
    void setUp() {
        service = new DocumentScannerService(scannedDocumentRepository, customerRepository, transactionRepository,
                systemParameterService);
        ReflectionTestUtils.setField(service, "maxFileSizeBytes", 1024L);
        ReflectionTestUtils.setField(service, "providerActive", true);
    }

    @Test
    @DisplayName("Pozitív mentés: sanitize + mime/size valid + mentés")
    void saveScannedDocument_success() {
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                .documentType("ID_CARD")
                .notes("ok")
                .build();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "..\\evil/ok kép.png",
                "image/png",
                "abc".getBytes()
        );

        when(scannedDocumentRepository.save(any())).thenAnswer(invocation -> {
            ScannedDocument doc = invocation.getArgument(0);
            doc.setId(UUID.randomUUID());
            return doc;
        });

        ScannedDocumentDto result = service.saveScannedDocument(file, request);

        assertThat(result.getId()).isNotNull();
        assertThat(result.getFileName()).doesNotContain("/").doesNotContain("\\").doesNotContain("..");
        assertThat(result.getDocumentType()).isEqualTo("ID_CARD");

        ArgumentCaptor<ScannedDocument> captor = ArgumentCaptor.forClass(ScannedDocument.class);
        verify(scannedDocumentRepository).save(captor.capture());
        assertThat(captor.getValue().getMimeType()).isEqualTo("image/png");
        assertThat(captor.getValue().getDocumentType()).isEqualTo(ScannedDocumentType.ID_CARD);
    }

    @Test
    @DisplayName("COMPANY_REGISTRY feltöltés: COMPANY_DOC_VALIDITY_DAYS default 30 nappal validUntil-t állít")
    void saveScannedDocument_companyRegistry_defaultThirtyDays() {
        when(systemParameterService.getValue("COMPANY_DOC_VALIDITY_DAYS", "30")).thenReturn("30");
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                .documentType("COMPANY_REGISTRY")
                .build();
        MockMultipartFile file = new MockMultipartFile("file", "cegjegyzek.pdf", "application/pdf", "abc".getBytes());
        when(scannedDocumentRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        service.saveScannedDocument(file, request);

        ArgumentCaptor<ScannedDocument> captor = ArgumentCaptor.forClass(ScannedDocument.class);
        verify(scannedDocumentRepository).save(captor.capture());
        assertThat(captor.getValue().getValidUntil()).isEqualTo(LocalDate.now().plusDays(30));
    }

    @Test
    @DisplayName("COMPANY_REGISTRY feltöltés: konfigurált 10 napos validUntil")
    void saveScannedDocument_companyRegistry_configuredTenDays() {
        when(systemParameterService.getValue("COMPANY_DOC_VALIDITY_DAYS", "30")).thenReturn("10");
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                .documentType("COMPANY_REGISTRY")
                .build();
        MockMultipartFile file = new MockMultipartFile("file", "cegjegyzek.pdf", "application/pdf", "abc".getBytes());
        when(scannedDocumentRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        ScannedDocumentDto result = service.saveScannedDocument(file, request);

        ArgumentCaptor<ScannedDocument> captor = ArgumentCaptor.forClass(ScannedDocument.class);
        verify(scannedDocumentRepository).save(captor.capture());
        assertThat(captor.getValue().getValidUntil()).isEqualTo(LocalDate.now().plusDays(10));
        assertThat(result.getValidUntil()).isEqualTo(LocalDate.now().plusDays(10));
    }

    @Test
    @DisplayName("COMPANY_REGISTRY feltöltés: hibás paraméter esetén 30 nap fallback")
    void saveScannedDocument_companyRegistry_invalidParamFallsBackToThirtyDays() {
        when(systemParameterService.getValue("COMPANY_DOC_VALIDITY_DAYS", "30")).thenReturn("abc");
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                .documentType("COMPANY_REGISTRY")
                .build();
        MockMultipartFile file = new MockMultipartFile("file", "cegjegyzek.pdf", "application/pdf", "abc".getBytes());
        when(scannedDocumentRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        service.saveScannedDocument(file, request);

        ArgumentCaptor<ScannedDocument> captor = ArgumentCaptor.forClass(ScannedDocument.class);
        verify(scannedDocumentRepository).save(captor.capture());
        assertThat(captor.getValue().getValidUntil()).isEqualTo(LocalDate.now().plusDays(30));
    }

    @Test
    @DisplayName("ID_CARD feltöltés: validUntil null, érvényessége a Customer mezőkön él")
    void saveScannedDocument_idCard_validUntilNull() {
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                .documentType("ID_CARD")
                .build();
        MockMultipartFile file = new MockMultipartFile("file", "okmany.png", "image/png", "abc".getBytes());
        when(scannedDocumentRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        service.saveScannedDocument(file, request);

        ArgumentCaptor<ScannedDocument> captor = ArgumentCaptor.forClass(ScannedDocument.class);
        verify(scannedDocumentRepository).save(captor.capture());
        assertThat(captor.getValue().getValidUntil()).isNull();
    }

    @Test
    @DisplayName("Érvénytelen mime esetén 400 ValidationException")
    void saveScannedDocument_invalidMime() {
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder().documentType("OTHER").build();
        MockMultipartFile file = new MockMultipartFile("file", "x.exe", "application/x-msdownload", "abc".getBytes());

        assertThatThrownBy(() -> service.saveScannedDocument(file, request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nem támogatott fájl típus");

        verify(scannedDocumentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Túlméretes fájl esetén 400 ValidationException")
    void saveScannedDocument_oversize() {
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder().documentType("OTHER").build();
        byte[] tooBig = new byte[1025];
        MockMultipartFile file = new MockMultipartFile("file", "x.png", "image/png", tooBig);

        assertThatThrownBy(() -> service.saveScannedDocument(file, request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("mérete túl nagy");

        verify(scannedDocumentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Provider inaktív esetén 409 SCANNER_PROVIDER_INACTIVE")
    void saveScannedDocument_providerInactive() {
        ReflectionTestUtils.setField(service, "providerActive", false);

        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder().documentType("OTHER").build();
        MockMultipartFile file = new MockMultipartFile("file", "x.png", "image/png", "abc".getBytes());

        assertThatThrownBy(() -> service.saveScannedDocument(file, request))
                .isInstanceOfSatisfying(BusinessException.class, ex -> {
                    assertThat(ex.getErrorCode()).isEqualTo("SCANNER_PROVIDER_INACTIVE");
                    assertThat(ex.getHttpStatus().value()).isEqualTo(409);
                });
    }

    @Test
    @DisplayName("Nem létező dokumentum törlésénél 404")
    void deleteDocument_notFound() {
        UUID id = UUID.randomUUID();
        when(scannedDocumentRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.deleteDocument(id))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Dokumentum nem található");
    }
}
