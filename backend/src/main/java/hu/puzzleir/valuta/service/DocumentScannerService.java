package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.entity.ScannedDocument;
import hu.puzzleir.valuta.entity.ScannedDocumentType;
import hu.puzzleir.valuta.repository.ScannedDocumentRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;
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

    private final ScannedDocumentRepository scannedDocumentRepository;

    /**
     * Dokumentum feltöltés és mentés.
     */
    @Transactional
    public ScannedDocumentDto saveScannedDocument(
            MultipartFile file,
            UUID customerId,
            UUID transactionId,
            String documentType,
            String notes) {

        String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "unnamed";
        String storagePath = "documents/" + UUID.randomUUID() + "/" + fileName;

        ScannedDocument doc = ScannedDocument.builder()
                .customerId(customerId)
                .transactionId(transactionId)
                .documentType(ScannedDocumentType.valueOf(documentType != null ? documentType : "OTHER"))
                .fileName(fileName)
                .mimeType(file.getContentType())
                .fileSizeBytes(file.getSize())
                .storagePath(storagePath)
                .scannedBy(getCurrentWorkerId())
                .scannedAt(LocalDateTime.now())
                .notes(notes)
                .build();

        doc = scannedDocumentRepository.save(doc);
        log.info("Dokumentum feltöltve: id={}, file={}, customer={}", doc.getId(), fileName, customerId);
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
