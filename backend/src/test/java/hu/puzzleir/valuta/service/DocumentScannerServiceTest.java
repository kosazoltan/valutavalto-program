package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.document.DocumentScanUploadRequest;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.entity.DocumentSide;
import hu.puzzleir.valuta.entity.ScannedDocument;
import hu.puzzleir.valuta.entity.ScannedDocumentImage;
import hu.puzzleir.valuta.entity.ScannedDocumentType;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ScannedDocumentImageRepository;
import hu.puzzleir.valuta.repository.ScannedDocumentRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
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
    @Mock
    private ScannedDocumentImageRepository scannedDocumentImageRepository;

    private DocumentScannerService service;

    @BeforeEach
    void setUp() {
        service = new DocumentScannerService(scannedDocumentRepository, customerRepository, transactionRepository,
                systemParameterService, scannedDocumentImageRepository);
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

    // ============ FS-5 SLICE 1: Pair-mentés + thumbnail ============

    /** 1x1 px valid PNG (ImageIO-olvasható) — thumbnail-generáláshoz valós képbájt kell. */
    private static byte[] tinyPng() {
        try {
            java.awt.image.BufferedImage img =
                    new java.awt.image.BufferedImage(1, 1, java.awt.image.BufferedImage.TYPE_INT_RGB);
            java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
            javax.imageio.ImageIO.write(img, "png", out);
            return out.toByteArray();
        } catch (java.io.IOException e) {
            throw new java.io.UncheckedIOException(e);
        }
    }

    @Test
    @DisplayName("Pair-mentés: 1 ScannedDocument + FRONT és BACK image sor thumbnail-lel")
    void saveScannedDocumentPair_success() {
        try (MockedStatic<SecurityUtils> ms = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            UUID companyId = UUID.randomUUID();
            ms.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            ms.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);

            when(customerRepository.existsByIdAndCompany_Id(any(), any())).thenReturn(true);
            DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                    .documentType("ID_CARD").customerId(5L).build();
            MockMultipartFile front = new MockMultipartFile("front", "elolap.png", "image/png", tinyPng());
            MockMultipartFile back = new MockMultipartFile("back", "hatlap.png", "image/png", tinyPng());
            when(scannedDocumentRepository.save(any())).thenAnswer(inv -> {
                ScannedDocument d = inv.getArgument(0);
                d.setId(UUID.randomUUID());
                return d;
            });
            when(scannedDocumentImageRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            ScannedDocumentDto dto = service.saveScannedDocumentPair(front, back, request);

            assertThat(dto.getId()).isNotNull();
            assertThat(dto.getHasFrontImage()).isTrue();
            assertThat(dto.getHasBackImage()).isTrue();
            ArgumentCaptor<ScannedDocumentImage> imgCaptor = ArgumentCaptor.forClass(ScannedDocumentImage.class);
            verify(scannedDocumentImageRepository, times(2)).save(imgCaptor.capture());
            assertThat(imgCaptor.getAllValues()).extracting(ScannedDocumentImage::getSide)
                    .containsExactlyInAnyOrder(DocumentSide.FRONT, DocumentSide.BACK);
            assertThat(imgCaptor.getAllValues()).allSatisfy(img -> {
                assertThat(img.getFileData()).isNotEmpty();
                assertThat(img.getThumbnailData()).isNotEmpty();
                assertThat(img.getThumbnailMimeType()).isEqualTo("image/jpeg");
                assertThat(img.getScannedDocumentId()).isNotNull();
            });
        }
    }

    @Test
    @DisplayName("Pair-mentés PDF-fel → ValidationException (pair csak kép lehet)")
    void saveScannedDocumentPair_pdfRejected() {
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                .documentType("ID_CARD").customerId(5L).build();
        MockMultipartFile front = new MockMultipartFile("front", "elolap.pdf", "application/pdf", "abc".getBytes());
        MockMultipartFile back = new MockMultipartFile("back", "hatlap.png", "image/png", tinyPng());

        assertThatThrownBy(() -> service.saveScannedDocumentPair(front, back, request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Nem támogatott fájl típus");

        verify(scannedDocumentRepository, never()).save(any());
        verify(scannedDocumentImageRepository, never()).save(any());
    }

    @Test
    @DisplayName("Pair-mentés szülő (customerId/transactionId) nélkül → ValidationException")
    void saveScannedDocumentPair_parentRequired() {
        DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                .documentType("ID_CARD").build();
        MockMultipartFile front = new MockMultipartFile("front", "elolap.png", "image/png", tinyPng());
        MockMultipartFile back = new MockMultipartFile("back", "hatlap.png", "image/png", tinyPng());

        assertThatThrownBy(() -> service.saveScannedDocumentPair(front, back, request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("ügyfél vagy tranzakció");

        verify(scannedDocumentRepository, never()).save(any());
        verify(scannedDocumentImageRepository, never()).save(any());
    }

    @Test
    @DisplayName("Pair-mentés idegen cég ügyfelével → ResourceNotFoundException (tenant-gát)")
    void saveScannedDocumentPair_crossTenantCustomer() {
        try (MockedStatic<SecurityUtils> ms = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            UUID companyId = UUID.randomUUID();
            ms.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            when(customerRepository.existsByIdAndCompany_Id(any(), any())).thenReturn(false);
            DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                    .documentType("ID_CARD").customerId(5L).build();
            MockMultipartFile front = new MockMultipartFile("front", "elolap.png", "image/png", tinyPng());
            MockMultipartFile back = new MockMultipartFile("back", "hatlap.png", "image/png", tinyPng());

            assertThatThrownBy(() -> service.saveScannedDocumentPair(front, back, request))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Ügyfél nem található");

            verify(scannedDocumentRepository, never()).save(any());
            verify(scannedDocumentImageRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("Pair-mentés túl nagy forrás-felbontással → ValidationException (decompression-bomb védelem)")
    void saveScannedDocumentPair_oversizedSourceRejected() throws Exception {
        try (MockedStatic<SecurityUtils> ms = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            ms.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());
            ms.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            when(customerRepository.existsByIdAndCompany_Id(any(), any())).thenReturn(true);
            ReflectionTestUtils.setField(service, "maxFileSizeBytes", 10_485_760L);
            java.awt.image.BufferedImage huge =
                    new java.awt.image.BufferedImage(8001, 10, java.awt.image.BufferedImage.TYPE_INT_RGB);
            java.io.ByteArrayOutputStream bo = new java.io.ByteArrayOutputStream();
            javax.imageio.ImageIO.write(huge, "png", bo);
            byte[] hugePng = bo.toByteArray();
            DocumentScanUploadRequest request = DocumentScanUploadRequest.builder()
                    .documentType("ID_CARD").customerId(5L).build();
            MockMultipartFile front = new MockMultipartFile("front", "f.png", "image/png", hugePng);
            MockMultipartFile back = new MockMultipartFile("back", "b.png", "image/png", hugePng);

            assertThatThrownBy(() -> service.saveScannedDocumentPair(front, back, request))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("felbontása");

            verify(scannedDocumentImageRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("getCustomerDocuments: enrichWithSides batch-dúsítás FRONT-only → hasFront=true, hasBack=false")
    void getCustomerDocuments_enrichWithSides() {
        try (MockedStatic<SecurityUtils> ms = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            ms.when(SecurityUtils::getCurrentCompanyId).thenReturn(UUID.randomUUID());
            when(customerRepository.existsByIdAndCompany_Id(any(), any())).thenReturn(true);
            UUID docId = UUID.randomUUID();
            ScannedDocument doc = ScannedDocument.builder()
                    .id(docId).customerId(5L).documentType(ScannedDocumentType.ID_CARD)
                    .fileName("f.png").scannedAt(java.time.LocalDateTime.now()).build();
            when(scannedDocumentRepository.findByCustomerIdAndIsDeletedFalseOrderByScannedAtDesc(5L))
                    .thenReturn(List.of(doc));
            ScannedDocumentImageRepository.DocumentSideView view =
                    new ScannedDocumentImageRepository.DocumentSideView() {
                        @Override public UUID getDocumentId() { return docId; }
                        @Override public DocumentSide getSide() { return DocumentSide.FRONT; }
                    };
            when(scannedDocumentImageRepository.findSidesByDocumentIds(anyList()))
                    .thenReturn(List.of(view));

            List<ScannedDocumentDto> result = service.getCustomerDocuments(5L);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getId()).isEqualTo(docId);
            assertThat(result.get(0).getHasFrontImage()).isTrue();
            assertThat(result.get(0).getHasBackImage()).isFalse();
        }
    }
}
