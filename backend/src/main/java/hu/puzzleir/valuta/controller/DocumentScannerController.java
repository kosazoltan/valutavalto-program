package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.document.DocumentScanUploadRequest;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.entity.DocumentSide;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.service.DocumentScannerService;
import hu.puzzleir.valuta.service.DocumentViewGrantService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Locale;
import java.util.Map;
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
    private final DocumentViewGrantService documentViewGrantService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ScannedDocumentDto> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @Valid @ModelAttribute DocumentScanUploadRequest request) {
        return ResponseEntity.ok(documentScannerService.saveScannedDocument(file, request));
    }

    @GetMapping("/customer/{customerId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ScannedDocumentDto>> getCustomerDocuments(@PathVariable Long customerId) {
        return ResponseEntity.ok(documentScannerService.getCustomerDocuments(customerId));
    }

    @GetMapping("/transaction/{transactionId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ScannedDocumentDto>> getTransactionDocuments(@PathVariable Long transactionId) {
        return ResponseEntity.ok(documentScannerService.getTransactionDocuments(transactionId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deleteDocument(@PathVariable UUID id) {
        documentScannerService.deleteDocument(id);
        return ResponseEntity.noContent().build();
    }

    // ============ FS-5 SLICE 1: képpár-feltöltés + thumbnail ============

    @PostMapping(value = "/upload-pair", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ScannedDocumentDto> uploadDocumentPair(
            @RequestParam("front") MultipartFile front,
            @RequestParam("back") MultipartFile back,
            @Valid @ModelAttribute DocumentScanUploadRequest request) {
        return ResponseEntity.ok(documentScannerService.saveScannedDocumentPair(front, back, request));
    }

    @GetMapping("/{id}/image/{side}/thumbnail")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<byte[]> getThumbnail(@PathVariable UUID id, @PathVariable String side) {
        DocumentScannerService.ImagePayload p = documentScannerService.getThumbnail(id, parseSide(side));
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(p.mimeType()))
                .body(p.data());
    }

    // ============ FS-5 SLICE 2: nagyítás-engedély (törvényi) + full-res ============

    /** Body: { approverWorkerId, pin } — a supervisor-PIN-es nagyítás-engedély (FS-5, törvényi). */
    @PostMapping("/{id}/view-grant")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> issueViewGrant(@PathVariable UUID id,
            @RequestBody Map<String, Object> body, HttpServletRequest request) {
        Long approverWorkerId = toLong(body.get("approverWorkerId"));
        String pin = body.get("pin") instanceof String p ? p : null;
        if (approverWorkerId == null || pin == null || pin.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("ok", false, "error", "approverWorkerId + pin kötelező"));
        }
        documentViewGrantService.issueViewGrant(id, approverWorkerId, pin,
                extractClientIp(request), request.getHeader("User-Agent"));
        return ResponseEntity.ok(Map.of("ok", true));
    }

    @GetMapping("/{id}/image/{side}/full")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<byte[]> getFullImage(@PathVariable UUID id, @PathVariable String side) {
        DocumentScannerService.ImagePayload p = documentViewGrantService.serveFullImage(id, parseSide(side));
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(p.mimeType()))
                .body(p.data());
    }

    // ============ HELPERS ============

    private static DocumentSide parseSide(String side) {
        try {
            return DocumentSide.valueOf(side.toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new ValidationException("Érvénytelen oldal: " + side);
        }
    }

    /** Number vagy numerikus String → Long; minden más (vagy érvénytelen String) → null. */
    private static Long toLong(Object o) {
        if (o instanceof Number n) {
            return n.longValue();
        }
        if (o instanceof String s && !s.isBlank()) {
            try {
                return Long.parseLong(s.trim());
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    private String extractClientIp(HttpServletRequest req) {
        String fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            return fwd.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }
}
