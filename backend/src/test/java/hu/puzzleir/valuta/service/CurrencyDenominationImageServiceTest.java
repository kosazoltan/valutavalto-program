package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.currency.CurrencyDenominationImageDto;
import hu.puzzleir.valuta.entity.CurrencyDenominationImage;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.DocumentSide;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyDenominationImageRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.same;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CurrencyDenominationImageServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID IMAGE_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    @Mock
    private CurrencyDenominationImageRepository imageRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    private CurrencyDenominationImageService service;

    @BeforeEach
    void setUp() {
        service = new CurrencyDenominationImageService(imageRepository, currencyRepository);
        ReflectionTestUtils.setField(service, "maxFileSizeBytes", 1024L);
    }

    @Test
    @DisplayName("upload: sikeres mentés SecurityContext companyId-val, thumbnail-lel")
    void upload_success() throws IOException {
        byte[] png = tinyPng();
        MockMultipartFile file = new MockMultipartFile("file", "500-front.png", "image/png", png);
        when(currencyRepository.existsById(1L)).thenReturn(true);
        when(imageRepository.findByCompanyIdAndCurrencyIdAndFaceValueAndDenominationTypeAndSide(
                COMPANY_ID, 1L, new BigDecimal("500"), DenominationType.BANKNOTE, DocumentSide.FRONT))
                .thenReturn(Optional.empty());
        when(imageRepository.save(any(CurrencyDenominationImage.class))).thenAnswer(invocation -> {
            CurrencyDenominationImage image = invocation.getArgument(0);
            image.setId(IMAGE_ID);
            image.setCreatedAt(LocalDateTime.now());
            return image;
        });

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            CurrencyDenominationImageDto result = service.upload(
                    1L, new BigDecimal("500"), DenominationType.BANKNOTE, DocumentSide.FRONT, file);

            assertThat(result.getId()).isEqualTo(IMAGE_ID);
        }

        ArgumentCaptor<CurrencyDenominationImage> captor = ArgumentCaptor.forClass(CurrencyDenominationImage.class);
        verify(imageRepository).save(captor.capture());
        CurrencyDenominationImage saved = captor.getValue();
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getCurrencyId()).isEqualTo(1L);
        assertThat(saved.getFaceValue()).isEqualByComparingTo("500");
        assertThat(saved.getDenominationType()).isEqualTo(DenominationType.BANKNOTE);
        assertThat(saved.getSide()).isEqualTo(DocumentSide.FRONT);
        assertThat(saved.getFileData()).isEqualTo(png);
        assertThat(saved.getThumbnailData()).isNotEmpty();
        assertThat(saved.getThumbnailMimeType()).isEqualTo("image/jpeg");
        assertThat(saved.getActive()).isTrue();
        assertThat(saved.getCreatedByWorkerCode()).isEqualTo("W-001");
    }

    @Test
    @DisplayName("upload: upsert meglévő sort ír felül és újraaktivál")
    void upload_upsert_replacesExistingRow() throws IOException {
        UUID existingId = UUID.randomUUID();
        byte[] png = tinyPng();
        MockMultipartFile file = new MockMultipartFile("file", "coin.png", "image/png", png);
        CurrencyDenominationImage existing = image();
        existing.setId(existingId);
        existing.setFileData("old".getBytes());
        existing.setActive(false);
        when(currencyRepository.existsById(1L)).thenReturn(true);
        when(imageRepository.findByCompanyIdAndCurrencyIdAndFaceValueAndDenominationTypeAndSide(
                COMPANY_ID, 1L, new BigDecimal("100"), DenominationType.COIN, DocumentSide.BACK))
                .thenReturn(Optional.of(existing));
        when(imageRepository.save(any(CurrencyDenominationImage.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            service.upload(1L, new BigDecimal("100"), DenominationType.COIN, DocumentSide.BACK, file);
        }

        verify(imageRepository).save(same(existing));
        verify(imageRepository, never()).saveAll(any());
        assertThat(existing.getId()).isEqualTo(existingId);
        assertThat(existing.getFileData()).isEqualTo(png);
        assertThat(existing.getActive()).isTrue();
    }

    @Test
    @DisplayName("upload: PDF elutasítva, mentés nélkül")
    void upload_rejectsPdf() {
        MockMultipartFile file = new MockMultipartFile("file", "x.pdf", "application/pdf", "abc".getBytes());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            assertThatThrownBy(() -> service.upload(
                    1L, BigDecimal.ONE, DenominationType.BANKNOTE, DocumentSide.FRONT, file))
                    .isInstanceOf(ValidationException.class);
        }

        verify(imageRepository, never()).save(any());
    }

    @Test
    @DisplayName("upload: túlméretes kép elutasítva, mentés nélkül")
    void upload_rejectsOversize() {
        ReflectionTestUtils.setField(service, "maxFileSizeBytes", 8L);
        MockMultipartFile file = new MockMultipartFile("file", "x.png", "image/png", new byte[9]);

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            assertThatThrownBy(() -> service.upload(
                    1L, BigDecimal.ONE, DenominationType.BANKNOTE, DocumentSide.FRONT, file))
                    .isInstanceOf(ValidationException.class);
        }

        verify(imageRepository, never()).save(any());
    }

    @Test
    @DisplayName("upload: ismeretlen valuta 404, mentés nélkül")
    void upload_unknownCurrency() throws IOException {
        MockMultipartFile file = new MockMultipartFile("file", "x.png", "image/png", tinyPng());
        when(currencyRepository.existsById(1L)).thenReturn(false);

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            assertThatThrownBy(() -> service.upload(
                    1L, BigDecimal.ONE, DenominationType.BANKNOTE, DocumentSide.FRONT, file))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        verify(imageRepository, never()).save(any());
    }

    @Test
    @DisplayName("upload: nem pozitív címletérték elutasítva")
    void upload_rejectsNonPositiveFaceValue() throws IOException {
        MockMultipartFile file = new MockMultipartFile("file", "x.png", "image/png", tinyPng());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            assertThatThrownBy(() -> service.upload(
                    1L, BigDecimal.ZERO, DenominationType.BANKNOTE, DocumentSide.FRONT, file))
                    .isInstanceOf(ValidationException.class);
        }

        verify(imageRepository, never()).save(any());
    }

    @Test
    @DisplayName("list: mindig az aktuális cégre scope-ol")
    void list_scopesToCurrentCompany() {
        CurrencyDenominationImageRepository.MetaView view = metaView(1L);
        when(imageRepository.findByCompanyIdOrderByCurrencyIdAscFaceValueDescSideAsc(COMPANY_ID))
                .thenReturn(List.of(view));
        when(imageRepository.findByCompanyIdAndCurrencyIdOrderByFaceValueDescSideAsc(COMPANY_ID, 1L))
                .thenReturn(List.of(view));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThat(service.list(null)).hasSize(1);
            assertThat(service.list(1L)).hasSize(1);
        }

        verify(imageRepository).findByCompanyIdOrderByCurrencyIdAscFaceValueDescSideAsc(COMPANY_ID);
        verify(imageRepository).findByCompanyIdAndCurrencyIdOrderByFaceValueDescSideAsc(COMPANY_ID, 1L);
    }

    @Test
    @DisplayName("getImage: idegen cég / nem létező id azonos 404")
    void getImage_crossTenant_notFound() {
        when(imageRepository.findByIdAndCompanyId(IMAGE_ID, COMPANY_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.getImage(IMAGE_ID)).isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("getImage: mime és bájt visszaadva")
    void getImage_success() {
        CurrencyDenominationImage image = image();
        byte[] bytes = "full".getBytes();
        image.setFileData(bytes);
        image.setMimeType("image/jpeg");
        when(imageRepository.findByIdAndCompanyId(IMAGE_ID, COMPANY_ID)).thenReturn(Optional.of(image));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            CurrencyDenominationImageService.ImagePayload payload = service.getImage(IMAGE_ID);

            assertThat(payload.mimeType()).isEqualTo("image/jpeg");
            assertThat(payload.data()).isEqualTo(bytes);
        }
    }

    @Test
    @DisplayName("getThumbnail: hiányzó thumbnail 404")
    void getThumbnail_missingThumbnail_notFound() {
        CurrencyDenominationImage image = image();
        image.setThumbnailData(null);
        when(imageRepository.findByIdAndCompanyId(IMAGE_ID, COMPANY_ID)).thenReturn(Optional.of(image));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.getThumbnail(IMAGE_ID)).isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("setActive: cég-scope-olt lookup után inaktivál")
    void setActive_deactivates() {
        CurrencyDenominationImage image = image();
        image.setActive(true);
        when(imageRepository.findByIdAndCompanyId(IMAGE_ID, COMPANY_ID)).thenReturn(Optional.of(image));
        when(imageRepository.save(any(CurrencyDenominationImage.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            CurrencyDenominationImageDto dto = service.setActive(IMAGE_ID, false);

            assertThat(dto.getActive()).isFalse();
        }

        verify(imageRepository).save(same(image));
        assertThat(image.getActive()).isFalse();
    }

    @Test
    @DisplayName("setActive: idegen cég képére 404 — cross-tenant IDOR az ÍRÓ útvonalon")
    void setActive_crossTenant_notFound_noSave() {
        when(imageRepository.findByIdAndCompanyId(IMAGE_ID, COMPANY_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.setActive(IMAGE_ID, false))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        verify(imageRepository, never()).save(any());
    }

    @Test
    @DisplayName("upload: nem dekódolható kép → ValidationException, save SOHA")
    void upload_nonDecodableImage_failClosed() {
        org.springframework.mock.web.MockMultipartFile file =
                new org.springframework.mock.web.MockMultipartFile(
                        "file", "fake.png", "image/png", "not-an-image".getBytes());
        when(currencyRepository.existsById(1L)).thenReturn(true);

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            assertThatThrownBy(() -> service.upload(1L, new BigDecimal("500"),
                    DenominationType.BANKNOTE, DocumentSide.FRONT, file))
                    .isInstanceOf(ValidationException.class);
        }

        verify(imageRepository, never()).save(any());
    }

    private static byte[] tinyPng() throws IOException {
        BufferedImage img = new BufferedImage(4, 4, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(img, "png", out);
        return out.toByteArray();
    }

    private static CurrencyDenominationImage image() {
        return CurrencyDenominationImage.builder()
                .id(IMAGE_ID)
                .companyId(COMPANY_ID)
                .currencyId(1L)
                .faceValue(new BigDecimal("500"))
                .denominationType(DenominationType.BANKNOTE)
                .side(DocumentSide.FRONT)
                .mimeType("image/png")
                .fileSizeBytes(4L)
                .fileData("full".getBytes())
                .thumbnailData("thumb".getBytes())
                .thumbnailMimeType("image/jpeg")
                .active(true)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    private static CurrencyDenominationImageRepository.MetaView metaView(Long currencyId) {
        return new CurrencyDenominationImageRepository.MetaView() {
            @Override
            public UUID getId() {
                return IMAGE_ID;
            }

            @Override
            public Long getCurrencyId() {
                return currencyId;
            }

            @Override
            public BigDecimal getFaceValue() {
                return new BigDecimal("500");
            }

            @Override
            public DenominationType getDenominationType() {
                return DenominationType.BANKNOTE;
            }

            @Override
            public DocumentSide getSide() {
                return DocumentSide.FRONT;
            }

            @Override
            public String getMimeType() {
                return "image/png";
            }

            @Override
            public Long getFileSizeBytes() {
                return 123L;
            }

            @Override
            public Boolean getActive() {
                return true;
            }

            @Override
            public LocalDateTime getCreatedAt() {
                return LocalDateTime.now();
            }

            @Override
            public LocalDateTime getUpdatedAt() {
                return LocalDateTime.now();
            }
        };
    }
}
