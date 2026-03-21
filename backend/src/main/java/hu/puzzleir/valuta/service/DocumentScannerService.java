package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.document.DocumentScanUploadRequest;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.entity.ScannedDocument;
import hu.puzzleir.valuta.entity.ScannedDocumentType;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ScannedDocumentRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

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

    @Value("${document.scanner.max-size-bytes:10485760}")
    private long maxFileSizeBytes;

    @Value("${document.scanner.provider-active:true}")
    private boolean providerActive;

    /**
     * Dokumentum feltöltés és mentés.
     */
    @Transactional
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
    public List<ScannedDocumentDto> getCustomerDocuments(UUID customerId) {
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
    public List<ScannedDocumentDto> getTransactionDocuments(UUID transactionId) {
        return scannedDocumentRepository
                .findByTransactionIdAndIsDeletedFalseOrderByScannedAtDesc(transactionId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Dokumentum soft delete.
     */
    @Transactional
    public void deleteDocument(UUID documentId) {
        ScannedDocument doc = scannedDocumentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("Dokumentum nem található: " + documentId));

        doc.setIsDeleted(true);
        doc.setDeletedAt(LocalDateTime.now());
        scannedDocumentRepository.save(doc);
        log.info("Dokumentum törölve (soft delete): id={}", documentId);
    }

    // ============ HELPERS ============

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
                .build();
    }
}
