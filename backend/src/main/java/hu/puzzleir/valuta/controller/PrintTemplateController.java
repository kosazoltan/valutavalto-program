package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.printtemplate.PrintTemplateDto;
import hu.puzzleir.valuta.dto.printtemplate.PrintTemplatePreviewRequest;
import hu.puzzleir.valuta.dto.printtemplate.PrintTemplateResponse;
import hu.puzzleir.valuta.service.PrintTemplateService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;
import java.util.UUID;

/**
 * Nyomtatási sablon controller — CRUD + előnézet.
 */
@RestController
@RequestMapping("/api/v1/print-templates")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class PrintTemplateController {

    private final PrintTemplateService printTemplateService;

    /**
     * Sablonok listája típus szerint.
     * GET /api/v1/print-templates?type=RECEIPT
     */
    @GetMapping
    public ResponseEntity<List<PrintTemplateResponse>> getTemplates(
            @RequestParam(required = false) String type) {
        if (type != null) {
            return ResponseEntity.ok(printTemplateService.getTemplatesByType(type));
        }
        return ResponseEntity.ok(printTemplateService.getDefaultTemplates());
    }

    /**
     * Sablon lekérdezés ID alapján.
     * GET /api/v1/print-templates/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<PrintTemplateResponse> getTemplate(@PathVariable UUID id) {
        return ResponseEntity.ok(printTemplateService.getTemplateById(id));
    }

    /**
     * Új sablon létrehozás.
     * POST /api/v1/print-templates
     */
    @PostMapping
    public ResponseEntity<PrintTemplateResponse> createTemplate(@Valid @RequestBody PrintTemplateDto dto) {
        return ResponseEntity.ok(printTemplateService.saveTemplate(dto));
    }

    /**
     * Sablon frissítés.
     * PUT /api/v1/print-templates/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<PrintTemplateResponse> updateTemplate(
            @PathVariable UUID id, @Valid @RequestBody PrintTemplateDto dto) {
        return ResponseEntity.ok(printTemplateService.updateTemplate(id, dto));
    }

    /**
     * Sablon előnézet — placeholder csere tesztadatokkal.
     * POST /api/v1/print-templates/{id}/preview
     */
    @PostMapping("/{id}/preview")
    public ResponseEntity<String> previewTemplate(
            @PathVariable UUID id, @Valid @RequestBody PrintTemplatePreviewRequest request) {
        String rendered = printTemplateService.previewTemplate(id, request.getData());
        return ResponseEntity.ok(rendered);
    }
}
