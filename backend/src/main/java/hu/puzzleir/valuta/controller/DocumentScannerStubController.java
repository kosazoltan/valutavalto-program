package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.document.DocumentScanUploadRequest;
import hu.puzzleir.valuta.dto.document.ScannedDocumentDto;
import hu.puzzleir.valuta.service.DocumentScannerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

/**
 * Dokumentum szkenner kompatibilitási endpointok.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/document-scanner")
@Tag(name = "Dokumentum Szkenner", description = "Kompatibilitási route-ok a belső dokumentum feltöltő flow-ra kötve")
@RequiredArgsConstructor
@Slf4j
public class DocumentScannerStubController {

    private final DocumentScannerService documentScannerService;

    @PostMapping(value = "/scan", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Dokumentum szkennelés (kompatibilitási alias)")
    public ResponseEntity<ScannedDocumentDto> startScan(
            @RequestParam("file") MultipartFile file,
            @Valid @ModelAttribute DocumentScanUploadRequest request) {
        log.info("Dokumentum scan alias hívás érkezett");
        return ResponseEntity.ok(documentScannerService.saveScannedDocument(file, request));
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Beolvasott dokumentum kép feltöltése")
    public ResponseEntity<ScannedDocumentDto> uploadScannedDocument(
            @RequestParam("file") MultipartFile file,
            @Valid @ModelAttribute DocumentScanUploadRequest request) {
        log.info("Dokumentum upload kompatibilitási route hívás");
        return ResponseEntity.ok(documentScannerService.saveScannedDocument(file, request));
    }

    @GetMapping("/devices")
    @Operation(summary = "Elérhető szkennerek listázása")
    public ResponseEntity<Map<String, Object>> listDevices() {
        return ResponseEntity.ok(Map.of(
                "devices", java.util.Collections.emptyList(),
                "mode", "UPLOAD_BRIDGE",
                "message", "Hardver szkenner lista kliens oldalon érhető el; backend a feltöltött dokumentumot fogadja."
        ));
    }
}
