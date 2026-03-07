package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.config.ConfigBundleDto;
import hu.puzzleir.valuta.dto.config.ImportResultDto;
import hu.puzzleir.valuta.service.ConfigExportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.Map;
import java.util.UUID;

/**
 * Konfiguráció export/import REST controller.
 */
@RestController
@RequestMapping("/api/v1/config")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class ConfigExportController {

    private final ConfigExportService configExportService;

    /**
     * Fiók konfigurációjának exportálása.
     * GET /api/v1/config/export/{branchId}
     */
    @GetMapping("/export/{branchId}")
    public ResponseEntity<ConfigBundleDto> exportConfig(@PathVariable UUID branchId) {
        return ResponseEntity.ok(configExportService.exportConfig(branchId));
    }

    /**
     * Konfiguráció importálása egy fiókba.
     * POST /api/v1/config/import/{branchId}
     */
    @PostMapping("/import/{branchId}")
    public ResponseEntity<ImportResultDto> importConfig(
            @PathVariable UUID branchId,
            @Valid @RequestBody ConfigBundleDto bundle) {
        return ResponseEntity.ok(configExportService.importConfig(branchId, bundle));
    }

    /**
     * Összes fiók konfigurációjának exportálása.
     * GET /api/v1/config/export-all
     */
    @GetMapping("/export-all")
    public ResponseEntity<Map<UUID, ConfigBundleDto>> exportAll() {
        return ResponseEntity.ok(configExportService.exportAllBranches());
    }
}
