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
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.ScannedDocumentImageRepository;
import hu.puzzleir.valuta.repository.ScannedDocumentRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Dokumentum szkenner szolgáltatás.
 * Frontend upload-ot kezel — nem hardware scannert közvetlenül.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentScannerService {

    private static final Set<String> ALLOWED_MIME_TYPES = Set.of(
            "image/jpeg",
            "image/png",
            "application/pdf"
    );

    /** FS-5: képpár-feltöltésnél engedélyezett MIME típusok (okmány-fénykép — PDF nem). */
    private static final Set<String> PAIR_MIME_TYPES = Set.of("image/jpeg", "image/png");

    private final ScannedDocumentRepository scannedDocumentRepository;
    private final CustomerRepository customerRepository;
    private final TransactionRepository transactionRepository;
    private final SystemParameterService systemParameterService;
    private final ScannedDocumentImageRepository scannedDocumentImageRepository;

    @Value("${document.scanner.max-size-bytes:10485760}")
    private long maxFileSizeBytes;

    @Value("${document.scanner.provider-active:true}")
    private boolean providerActive;

    /**
     * Dokumentum feltöltés és mentés.
     */
    @Transactional(rollbackFor = Exception.class)
    public ScannedDocumentDto saveScannedDocument(MultipartFile file, DocumentScanUploadRequest request) {
        if (!providerActive) {
            throw new BusinessException(
                    "A dokumentum-szkenner provider jelenleg inaktív",
                    "SCANNER_PROVIDER_INACTIVE",
                    HttpStatus.CONFLICT
            );
        }

        if (file == null || file.isEmpty()) {
            throw new ValidationException("A fájl kötelező");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_MIME_TYPES.contains(contentType.toLowerCase())) {
            throw new ValidationException("Nem támogatott fájl típus");
        }

        if (file.getSize() > maxFileSizeBytes) {
            throw new ValidationException("A fájl mérete túl nagy");
        }

        String fileName = sanitizeFileName(file.getOriginalFilename());
        String storagePath = "documents/" + UUID.randomUUID() + "/" + fileName;

        ScannedDocumentType type;
        try {
            type = ScannedDocumentType.valueOf(request.getDocumentType());
        } catch (IllegalArgumentException ex) {
            throw new ValidationException("Érvénytelen dokumentum típus");
        }

        ScannedDocument doc = ScannedDocument.builder()
                .customerId(request.getCustomerId())
                .transactionId(request.getTransactionId())
                .documentType(type)
                .fileName(fileName)
                .mimeType(contentType)
                .fileSizeBytes(file.getSize())
                .storagePath(storagePath)
                .scannedBy(getCurrentWorkerId())
                .scannedAt(LocalDateTime.now())
                .notes(request.getNotes())
                .validUntil(resolveValidUntil(type))
                .build();

        doc = scannedDocumentRepository.save(doc);
        log.info("Dokumentum feltöltve: id={}, customerId={}, transactionId={}, type={}",
                doc.getId(), doc.getCustomerId(), doc.getTransactionId(), doc.getDocumentType());
        return toDto(doc);
    }

    /**
     * FS-5: Okmány elő/hátlap képpár mentése.
     * A képbájtok ténylegesen perzisztálódnak a scanned_document_image táblába (full-res + thumbnail).
     * CSAK image/jpeg és image/png; PDF nem megengedett (a pair-upload okmány-fényképekhez való).
     * Minden validáció ELŐBB történik, perzisztálás csak utána (fail-closed).
     */
    @Transactional(rollbackFor = Exception.class)
    public ScannedDocumentDto saveScannedDocumentPair(MultipartFile front, MultipartFile back,
            DocumentScanUploadRequest request) {
        if (!providerActive) {
            throw new BusinessException(
                    "A dokumentum-szkenner provider jelenleg inaktív",
                    "SCANNER_PROVIDER_INACTIVE",
                    HttpStatus.CONFLICT
            );
        }

        // 1) MINDEN validáció ELŐBB, perzisztálás csak utána.
        validatePairFile(front, "előlap");
        validatePairFile(back, "hátlap");
        if (front.getSize() + back.getSize() > maxFileSizeBytes * 2L) {
            throw new ValidationException("A képpár együttes mérete túl nagy");
        }
        if (request.getCustomerId() == null && request.getTransactionId() == null) {
            throw new ValidationException("Okmány-képpárhoz ügyfél vagy tranzakció megadása kötelező");
        }
        if (request.getCustomerId() != null) {
            requireCustomerInCurrentCompany(request.getCustomerId());
        }
        if (request.getTransactionId() != null) {
            requireTransactionInCurrentCompany(request.getTransactionId());
        }
        ScannedDocumentType type;
        try {
            type = ScannedDocumentType.valueOf(request.getDocumentType());
        } catch (IllegalArgumentException ex) {
            throw new ValidationException("Érvénytelen dokumentum típus");
        }

        byte[] frontBytes = readBytes(front);
        byte[] backBytes = readBytes(back);
        byte[] frontThumb = createThumbnail(frontBytes);
        byte[] backThumb = createThumbnail(backBytes);

        ScannedDocument doc = ScannedDocument.builder()
                .customerId(request.getCustomerId())
                .transactionId(request.getTransactionId())
                .documentType(type)
                .fileName(sanitizeFileName(front.getOriginalFilename()))
                .mimeType(front.getContentType())
                .fileSizeBytes(front.getSize() + back.getSize())
                .storagePath(null)
                .scannedBy(getCurrentWorkerId())
                .scannedAt(LocalDateTime.now())
                .notes(request.getNotes())
                .validUntil(resolveValidUntil(type))
                .build();
        doc = scannedDocumentRepository.save(doc);
        scannedDocumentImageRepository.save(
                buildImage(doc.getId(), DocumentSide.FRONT, front, frontBytes, frontThumb));
        scannedDocumentImageRepository.save(
                buildImage(doc.getId(), DocumentSide.BACK, back, backBytes, backThumb));
        log.info("Okmány-képpár mentve: id={}, customerId={}, transactionId={}, type={}",
                doc.getId(), doc.getCustomerId(), doc.getTransactionId(), doc.getDocumentType());
        return toDto(doc, true, true);
    }

    /**
     * FS-5: Thumbnail kiszolgálása (grant NÉLKÜL — ez a „szabad kis nézet").
     * A thumbnail a mentéskor generált ≤256px-es JPEG; NEM a full-res bájtok.
     * Tenant-assert MINDEN kiszolgálás előtt (assertDocumentParentInCurrentCompany).
     */
    @Transactional(readOnly = true)
    public ImagePayload getThumbnail(UUID documentId, DocumentSide side) {
        ScannedDocument doc = scannedDocumentRepository.findById(documentId)
                .filter(d -> !Boolean.TRUE.equals(d.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Dokumentum nem található: " + documentId));
        assertDocumentParentInCurrentCompany(doc);
        ScannedDocumentImage img = scannedDocumentImageRepository
                .findByScannedDocumentIdAndSide(documentId, side)
                .orElseThrow(() -> new ResourceNotFoundException("Okmánykép nem található"));
        if (img.getThumbnailData() == null) {
            throw new ResourceNotFoundException("Okmánykép nem található");
        }
        return new ImagePayload(img.getThumbnailMimeType(), img.getThumbnailData());
    }

    /** FS-5: Egyszerű kiszolgálási rekord (mime + bájt). */
    public record ImagePayload(String mimeType, byte[] data) {}

    /**
     * Ügyfélhez tartozó dokumentumok lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<ScannedDocumentDto> getCustomerDocuments(Long customerId) {
        // IDOR-fix (F-2): a ScannedDocument csak customerId-t hordoz, a tenancy a szülő
        // Customer-en van. Más cég ügyfeléhez tartozó (vagy nem létező) customerId esetén
        // ResourceNotFoundException — így az okmány-PII nem szivárog id-enumerációval.
        requireCustomerInCurrentCompany(customerId);
        List<ScannedDocumentDto> dtos = scannedDocumentRepository
                .findByCustomerIdAndIsDeletedFalseOrderByScannedAtDesc(customerId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
        enrichWithSides(dtos);
        return dtos;
    }

    /**
     * Tranzakcióhoz tartozó dokumentumok lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<ScannedDocumentDto> getTransactionDocuments(Long transactionId) {
        // IDOR-fix (F-2): a tenancy a szülő Transaction-ön van — cég-szűrt lookup, hogy
        // más cég tranzakciójához tartozó okmányok ne legyenek listázhatók (CVSS 8.2, PII).
        requireTransactionInCurrentCompany(transactionId);
        List<ScannedDocumentDto> dtos = scannedDocumentRepository
                .findByTransactionIdAndIsDeletedFalseOrderByScannedAtDesc(transactionId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
        enrichWithSides(dtos);
        return dtos;
    }

    /**
     * Dokumentum soft delete.
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteDocument(UUID documentId) {
        ScannedDocument doc = scannedDocumentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Dokumentum nem található: " + documentId));

        // IDOR-fix (F-2): a ScannedDocument-en nincs companyId, a tenancy a szülőn (customer/
        // transaction). A törlés előtt a dokumentum customerId/transactionId-ján át validáljuk,
        // hogy a szülő a hívó cégéhez tartozik-e — különben cross-tenant törlés lenne lehetséges.
        // Cross-tenant (vagy árva, egyik szülő-id nélküli) dokumentum → ResourceNotFoundException.
        assertDocumentParentInCurrentCompany(doc);

        doc.setIsDeleted(true);
        doc.setDeletedAt(LocalDateTime.now());
        scannedDocumentRepository.save(doc);
        log.info("Dokumentum törölve (soft delete): id={}", documentId);
    }

    // ============ HELPERS ============

    /**
     * IDOR-fix (F-2): a megadott ügyfél a hívó cégéhez tartozik-e. Cross-tenant vagy nem
     * létező ügyfél esetén ResourceNotFoundException (azonos válasz → nincs enumeráció).
     */
    private void requireCustomerInCurrentCompany(Long customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (customerId == null || !customerRepository.existsByIdAndCompany_Id(customerId, companyId)) {
            throw new ResourceNotFoundException("Ügyfél nem található: " + customerId);
        }
    }

    /**
     * IDOR-fix (F-2): a megadott tranzakció a hívó cégéhez tartozik-e. Cross-tenant vagy nem
     * létező tranzakció esetén ResourceNotFoundException.
     */
    private void requireTransactionInCurrentCompany(Long transactionId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (transactionId == null
                || transactionRepository.findByIdAndCompanyId(transactionId, companyId).isEmpty()) {
            throw new ResourceNotFoundException("Tranzakció nem található: " + transactionId);
        }
    }

    /**
     * IDOR-fix (F-2): a dokumentum szülője (customer és/vagy transaction) a hívó cégéhez
     * tartozik-e. Legalább az egyik szülőnek léteznie kell és a cég-ellenőrzésen át kell mennie;
     * ha a dokumentumnak nincs egyetlen cég-validálható szülője sem, cross-tenant törlés-kísérletként
     * ResourceNotFoundException dobódik (fail-closed).
     */
    private void assertDocumentParentInCurrentCompany(ScannedDocument doc) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        boolean ownedViaCustomer = doc.getCustomerId() != null
                && customerRepository.existsByIdAndCompany_Id(doc.getCustomerId(), companyId);
        boolean ownedViaTransaction = doc.getTransactionId() != null
                && transactionRepository.findByIdAndCompanyId(doc.getTransactionId(), companyId).isPresent();
        if (!ownedViaCustomer && !ownedViaTransaction) {
            throw new ResourceNotFoundException("Dokumentum nem található: " + doc.getId());
        }
    }

    private Long getCurrentWorkerId() {
        try {
            return SecurityUtils.getCurrentWorkerId();
        } catch (Exception e) {
            return null;
        }
    }

    private String sanitizeFileName(String originalName) {
        String baseName = originalName == null ? "unnamed" : originalName;
        String sanitized = baseName
                .replaceAll("[/\\\\]", "_")
                .replaceAll("\\.\\.", "_")
                .replaceAll("[^a-zA-Z0-9._-]", "_");

        if (sanitized.isBlank()) {
            sanitized = "unnamed";
        }

        if (sanitized.length() > 120) {
            sanitized = sanitized.substring(sanitized.length() - 120);
        }

        return sanitized;
    }

    private ScannedDocumentDto toDto(ScannedDocument d) {
        return toDto(d, false, false);
    }

    /** FS-5: toDto oldal-információval (pair-save válaszban true/true). */
    private ScannedDocumentDto toDto(ScannedDocument d, boolean hasFront, boolean hasBack) {
        return ScannedDocumentDto.builder()
                .id(d.getId())
                .customerId(d.getCustomerId())
                .transactionId(d.getTransactionId())
                .documentType(d.getDocumentType().name())
                .fileName(d.getFileName())
                .mimeType(d.getMimeType())
                .fileSizeBytes(d.getFileSizeBytes())
                .storagePath(d.getStoragePath())
                .scannedBy(d.getScannedBy())
                .scannedAt(d.getScannedAt())
                .notes(d.getNotes())
                .validUntil(d.getValidUntil())
                .hasFrontImage(hasFront)
                .hasBackImage(hasBack)
                .build();
    }

    /**
     * FS-5: DTO-lista oldal-információval való dúsítása batch query-vel (N+1 tilos).
     * A findSidesByDocumentIds CSAK a documentId+side projektálja — bájtok nem érintettek.
     */
    private void enrichWithSides(List<ScannedDocumentDto> dtos) {
        if (dtos.isEmpty()) {
            return;
        }
        List<UUID> docIds = dtos.stream().map(ScannedDocumentDto::getId).collect(Collectors.toList());
        Map<UUID, Set<DocumentSide>> sidesByDocId = scannedDocumentImageRepository
                .findSidesByDocumentIds(docIds)
                .stream()
                .collect(Collectors.groupingBy(
                        ScannedDocumentImageRepository.DocumentSideView::getDocumentId,
                        Collectors.mapping(
                                ScannedDocumentImageRepository.DocumentSideView::getSide,
                                Collectors.toSet())));
        for (ScannedDocumentDto dto : dtos) {
            Set<DocumentSide> sides = sidesByDocId.getOrDefault(dto.getId(), Set.of());
            dto.setHasFrontImage(sides.contains(DocumentSide.FRONT));
            dto.setHasBackImage(sides.contains(DocumentSide.BACK));
        }
    }

    /** FS-5: Képpár-fájl validáció — kötelező, CSAK image/jpeg|image/png, méretkorlát. */
    private void validatePairFile(MultipartFile f, String label) {
        if (f == null || f.isEmpty()) {
            throw new ValidationException("A(z) " + label + " kép kötelező");
        }
        String ct = f.getContentType();
        if (ct == null || !PAIR_MIME_TYPES.contains(ct.toLowerCase())) {
            throw new ValidationException("Nem támogatott fájl típus (" + label + "): csak JPEG/PNG");
        }
        if (f.getSize() > maxFileSizeBytes) {
            throw new ValidationException("A fájl mérete túl nagy (" + label + ")");
        }
    }

    private byte[] readBytes(MultipartFile f) {
        try {
            return f.getBytes();
        } catch (IOException e) {
            throw new ValidationException("A fájl nem olvasható");
        }
    }

    /**
     * FS-5: 256px-es JPEG thumbnail generálása; PNG-alfa fehér háttérre lapítva.
     * Nem dekódolható kép → ValidationException. Headless szerveren működik (ImageIO, nincs display szükség).
     */
    private byte[] createThumbnail(byte[] imageBytes) {
        return ImageThumbnailUtil.createThumbnail(imageBytes);
    }

    private ScannedDocumentImage buildImage(UUID docId, DocumentSide side, MultipartFile f,
            byte[] bytes, byte[] thumb) {
        return ScannedDocumentImage.builder()
                .scannedDocumentId(docId)
                .side(side)
                .mimeType(f.getContentType())
                .fileSizeBytes((long) bytes.length)
                .fileData(bytes)
                .thumbnailData(thumb)
                .thumbnailMimeType("image/jpeg")
                .build();
    }

    /** FS-6: cégjegyzék-scanhez lejárat; más típus érvényessége a Customer okmány-mezőin él. */
    private LocalDate resolveValidUntil(ScannedDocumentType type) {
        if (type != ScannedDocumentType.COMPANY_REGISTRY) {
            return null;
        }
        int days = 30;
        try {
            if (systemParameterService != null) {
                days = Integer.parseInt(
                        systemParameterService.getValue("COMPANY_DOC_VALIDITY_DAYS", "30").trim());
            }
        } catch (Exception e) {
            log.warn("COMPANY_DOC_VALIDITY_DAYS nem értelmezhető, default 30 nap: {}", e.getMessage());
        }
        if (days < 1) {
            days = 30;
        }
        return LocalDate.now().plusDays(days);
    }
}
