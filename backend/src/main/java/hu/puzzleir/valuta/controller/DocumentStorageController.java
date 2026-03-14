package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Document;
import hu.puzzleir.valuta.service.DocumentStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/documents")
@RequiredArgsConstructor
public class DocumentStorageController {

    private final DocumentStorageService service;

    @GetMapping
    public ResponseEntity<List<Document>> list(
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) UUID entityId) {
        return ResponseEntity.ok(service.list(entityType, entityId));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Document> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) UUID entityId) throws IOException {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.upload(file, entityType, entityId));
    }

    @GetMapping("/{id}/download")
    public ResponseEntity<byte[]> download(@PathVariable UUID id) {
        Document doc = service.getById(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + doc.getFileName() + "\"")
                .contentType(MediaType.parseMediaType(doc.getFileType() != null ? doc.getFileType() : "application/octet-stream"))
                .contentLength(doc.getFileSize() != null ? doc.getFileSize() : 0)
                .body(doc.getFileData());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
