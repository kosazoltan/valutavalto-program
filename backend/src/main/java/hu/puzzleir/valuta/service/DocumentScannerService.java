package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.document.DocumentScanUploadRequest;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.entity.ScannedDocument;
import hu.puzzleir.valuta.entity.ScannedDocumentType;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CustomerRepository;
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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
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

    private final ScannedDocumentRepository scannedDocumentRepository;
    private final CustomerRepository customerRepository;
    private final TransactionRepository transactionRepository;
    private final SystemParameterService systemParameterService;

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
     * Ügyfélhez tartozó dokumentumok lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<ScannedDocumentDto> getCustomerDocuments(Long customerId) {
        // IDOR-fix (F-2): a ScannedDocument csak customerId-t hordoz, a tenancy a szülő
        // Customer-en van. Más cég ügyfeléhez tartozó (vagy nem létező) customerId esetén
        // ResourceNotFoundException — így az okmány-PII nem szivárog id-enumerációval.
        requireCustomerInCurrentCompany(customerId);
        return scannedDocumentRepository
                .findByCustomerIdAndIsDeletedFalseOrderByScannedAtDesc(customerId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Tranzakcióhoz tartozó dokumentumok lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<ScannedDocumentDto> getTransactionDocuments(Long transactionId) {
        // IDOR-fix (F-2): a tenancy a szülő Transaction-ön van — cég-szűrt lookup, hogy
        // más cég tranzakciójához tartozó okmányok ne legyenek listázhatók (CVSS 8.2, PII).
        requireTransactionInCurrentCompany(transactionId);
        return scannedDocumentRepository
                .findByTransactionIdAndIsDeletedFalseOrderByScannedAtDesc(transactionId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
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
