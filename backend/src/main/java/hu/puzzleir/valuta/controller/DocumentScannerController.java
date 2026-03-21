package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.document.DocumentScanUploadRequest;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.service.DocumentScannerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Dokumentum szkenner controller.
 * Dokumentum feltöltés (multipart/form-data) és lekérdezés.
 */
@RestController
@RequestMapping("/api/v1/scanned-documents")
@RequiredArgsConstructor
public class DocumentScannerController {

    private final DocumentScannerService documentScannerService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ScannedDocumentDto> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @Valid @ModelAttribute DocumentScanUploadRequest request) {
        return ResponseEntity.ok(documentScannerService.saveScannedDocument(file, request));
    }

    @GetMapping("/customer/{customerId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ScannedDocumentDto>> getCustomerDocuments(@PathVariable UUID customerId) {
        return ResponseEntity.ok(documentScannerService.getCustomerDocuments(customerId));
    }

    @GetMapping("/transaction/{transactionId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ScannedDocumentDto>> getTransactionDocuments(@PathVariable UUID transactionId) {
        return ResponseEntity.ok(documentScannerService.getTransactionDocuments(transactionId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deleteDocument(@PathVariable UUID id) {
        documentScannerService.deleteDocument(id);
        return ResponseEntity.noContent().build();
    }
}
