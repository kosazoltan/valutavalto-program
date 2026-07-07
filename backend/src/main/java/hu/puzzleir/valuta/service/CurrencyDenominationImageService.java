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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * FS-9 S1: valuta-címletkép service — center feltöltés (upsert), cég-scope-olt meta-lista,
 * kép/thumbnail bájt-kiszolgálás (pénztár sync-fetch), soft inaktiválás.
 * MINDEN lekérdezés companyId-szűrt (invariáns #1); a cég a SecurityContextből jön.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CurrencyDenominationImageService {

    private static final Set<String> ALLOWED_MIME_TYPES = Set.of("image/jpeg", "image/png");

    private final CurrencyDenominationImageRepository imageRepository;
    private final CurrencyRepository currencyRepository;

    @Value("${currency.denomination.image.max-size-bytes:5242880}")
    private long maxFileSizeBytes;

    /** Egyszerű kiszolgálási rekord (mime + bájt) — FS-5 ImagePayload-minta. */
    public record ImagePayload(String mimeType, byte[] data) {
    }

    @Transactional(rollbackFor = Exception.class)
    public CurrencyDenominationImageDto upload(
            Long currencyId,
            BigDecimal faceValue,
            DenominationType denominationType,
            DocumentSide side,
            MultipartFile file) {
        // 1) MINDEN validáció ELŐBB, perzisztálás csak utána (fail-closed).
        if (currencyId == null || denominationType == null || side == null) {
            throw new ValidationException("Valuta, címlet-típus és oldal megadása kötelező");
        }
        if (faceValue == null || faceValue.signum() <= 0) {
            throw new ValidationException("Érvénytelen címletérték");
        }
        validateFile(file);
        if (!currencyRepository.existsById(currencyId)) {
            throw new ResourceNotFoundException("Valuta nem található: " + currencyId);
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        byte[] bytes = readBytes(file);
        byte[] thumb = ImageThumbnailUtil.createThumbnail(bytes); // dekódolás-validáció is
        String workerCode = SecurityUtils.getCurrentWorkerCode();

        // 2) Upsert: (cég, valuta, címlet, típus, oldal) kulcsra 1 sor.
        CurrencyDenominationImage entity = imageRepository
                .findByCompanyIdAndCurrencyIdAndFaceValueAndDenominationTypeAndSide(
                        companyId, currencyId, faceValue, denominationType, side)
                .orElseGet(() -> CurrencyDenominationImage.builder()
                        .companyId(companyId)
                        .currencyId(currencyId)
                        .faceValue(faceValue)
                        .denominationType(denominationType)
                        .side(side)
                        .build());
        entity.setMimeType(file.getContentType());
        entity.setFileSizeBytes((long) bytes.length);
        entity.setFileData(bytes);
        entity.setThumbnailData(thumb);
        entity.setThumbnailMimeType("image/jpeg");
        entity.setActive(true);
        entity.setCreatedByWorkerCode(workerCode);
        entity = imageRepository.save(entity);
        log.info("Címletkép mentve: id={}, currencyId={}, faceValue={}, type={}, side={}",
                entity.getId(), currencyId, faceValue, denominationType, side);
        return toDto(entity);
    }

    @Transactional(readOnly = true)
    public List<CurrencyDenominationImageDto> list(Long currencyId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<CurrencyDenominationImageRepository.MetaView> rows = currencyId == null
                ? imageRepository.findByCompanyIdOrderByCurrencyIdAscFaceValueDescSideAsc(companyId)
                : imageRepository.findByCompanyIdAndCurrencyIdOrderByFaceValueDescSideAsc(companyId, currencyId);
        return rows.stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public ImagePayload getImage(UUID id) {
        CurrencyDenominationImage img = requireInCurrentCompany(id);
        return new ImagePayload(img.getMimeType(), img.getFileData());
    }

    @Transactional(readOnly = true)
    public ImagePayload getThumbnail(UUID id) {
        CurrencyDenominationImage img = requireInCurrentCompany(id);
        if (img.getThumbnailData() == null) {
            throw new ResourceNotFoundException("Címletkép-thumbnail nem található");
        }
        return new ImagePayload(img.getThumbnailMimeType(), img.getThumbnailData());
    }

    @Transactional(rollbackFor = Exception.class)
    public CurrencyDenominationImageDto setActive(UUID id, boolean active) {
        CurrencyDenominationImage img = requireInCurrentCompany(id);
        img.setActive(active);
        return toDto(imageRepository.save(img));
    }

    /** Cég-scope-olt betöltés — cross-tenant/nem létező id-ra AZONOS 404 (nincs enumeráció). */
    private CurrencyDenominationImage requireInCurrentCompany(UUID id) {
        return imageRepository.findByIdAndCompanyId(id, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Címletkép nem található: " + id));
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ValidationException("A fájl kötelező");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_MIME_TYPES.contains(contentType.toLowerCase())) {
            throw new ValidationException("Nem támogatott fájl típus: csak JPEG/PNG");
        }
        if (file.getSize() > maxFileSizeBytes) {
            throw new ValidationException("A fájl mérete túl nagy");
        }
    }

    private byte[] readBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new ValidationException("A fájl nem olvasható");
        }
    }

    private CurrencyDenominationImageDto toDto(CurrencyDenominationImage entity) {
        return CurrencyDenominationImageDto.builder()
                .id(entity.getId())
                .currencyId(entity.getCurrencyId())
                .faceValue(entity.getFaceValue())
                .denominationType(entity.getDenominationType().name())
                .side(entity.getSide().name())
                .mimeType(entity.getMimeType())
                .fileSizeBytes(entity.getFileSizeBytes())
                .active(entity.getActive())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    private CurrencyDenominationImageDto toDto(CurrencyDenominationImageRepository.MetaView view) {
        return CurrencyDenominationImageDto.builder()
                .id(view.getId())
                .currencyId(view.getCurrencyId())
                .faceValue(view.getFaceValue())
                .denominationType(view.getDenominationType().name())
                .side(view.getSide().name())
                .mimeType(view.getMimeType())
                .fileSizeBytes(view.getFileSizeBytes())
                .active(view.getActive())
                .createdAt(view.getCreatedAt())
                .updatedAt(view.getUpdatedAt())
                .build();
    }
}
