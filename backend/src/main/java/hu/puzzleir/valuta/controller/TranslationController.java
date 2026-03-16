package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.translation.TranslationDto;
import hu.puzzleir.valuta.dto.translation.TranslationImportRequest;
import hu.puzzleir.valuta.entity.Translation;
import hu.puzzleir.valuta.service.TranslationService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.Map;

/**
 * Többnyelvűség (i18n) REST controller.
 */
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/translations")
@RequiredArgsConstructor
public class TranslationController {

    private final TranslationService translationService;

    /**
     * Összes fordítás lekérése adott nyelvre.
     * GET /api/v1/translations/{languageCode}
     */
    @GetMapping("/{languageCode}")
    public ResponseEntity<Map<String, String>> getTranslations(
            @PathVariable String languageCode) {
        return ResponseEntity.ok(translationService.getTranslations(languageCode));
    }

    /**
     * Fordítások lekérése modul szerint.
     * GET /api/v1/translations/{languageCode}/{module}
     */
    @GetMapping("/{languageCode}/{module}")
    public ResponseEntity<Map<String, String>> getTranslationsByModule(
            @PathVariable String languageCode,
            @PathVariable String module) {
        return ResponseEntity.ok(translationService.getTranslationsByModule(languageCode, module));
    }

    /**
     * Egyedi fordítás mentése.
     * POST /api/v1/translations
     */
    @PostMapping
    public ResponseEntity<TranslationDto> saveTranslation(@Valid @RequestBody TranslationDto dto) {
        Translation saved = translationService.saveTranslation(dto);
        TranslationDto response = TranslationDto.builder()
            .id(saved.getId())
            .languageCode(saved.getLanguageCode())
            .messageKey(saved.getMessageKey())
            .messageValue(saved.getMessageValue())
            .module(saved.getModule())
            .build();
        return ResponseEntity.ok(response);
    }

    /**
     * Tömeges fordítás import.
     * POST /api/v1/translations/import
     */
    @PostMapping("/import")
    public ResponseEntity<Map<String, Object>> importTranslations(
            @Valid @RequestBody TranslationImportRequest request) {
        int count = translationService.importTranslations(
            request.getLanguageCode(), request.getTranslations());
        return ResponseEntity.ok(Map.of(
            "imported", count,
            "languageCode", request.getLanguageCode()
        ));
    }
}
