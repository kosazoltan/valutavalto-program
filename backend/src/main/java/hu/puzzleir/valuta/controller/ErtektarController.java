package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ertektar.*;
import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.service.BranchMonitoringService;
import hu.puzzleir.valuta.service.ConsolidatedReportService;
import hu.puzzleir.valuta.service.VaultCollectionService;
import hu.puzzleir.valuta.service.VaultDistributionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Ertektar (Vault/Treasury) modul — egyseges REST API.
 * Begyujtes, szeosztas, konszolidalt riportok, alarendelt penztar monitoring.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/ertektar")
@RequiredArgsConstructor
public class ErtektarController {

    private final VaultCollectionService vaultCollectionService;
    private final VaultDistributionService vaultDistributionService;
    private final ConsolidatedReportService consolidatedReportService;
    private final BranchMonitoringService branchMonitoringService;

    // === BEGYUJTES (Collections) ===

    /**
     * Begyujtesi kerelmek listazasa.
     * GET /api/v1/ertektar/collections
     */
    @GetMapping("/collections")
    public ResponseEntity<List<CollectionResponseDto>> getCollections() {
        return ResponseEntity.ok(vaultCollectionService.getCollections());
    }

    /**
     * Uj begyujtesi kerelem letrehozasa.
     * POST /api/v1/ertektar/collections
     */
    @PostMapping("/collections")
    public ResponseEntity<CollectionResponseDto> createCollection(
            @Valid @RequestBody CollectionRequestDto request) {
        return ResponseEntity.ok(vaultCollectionService.createCollection(request));
    }

    /**
     * Begyujtes statusz frissitese.
     * PATCH /api/v1/ertektar/collections/{id}/status
     */
    @PatchMapping("/collections/{id}/status")
    public ResponseEntity<CollectionResponseDto> updateCollectionStatus(
            @PathVariable Long id,
            @RequestParam VaultOperationStatus status) {
        return ResponseEntity.ok(vaultCollectionService.updateStatus(id, status));
    }

    // === SZEOSZTAS (Distribution) ===

    /**
     * Szeosztasok listazasa.
     * GET /api/v1/ertektar/distribution
     */
    @GetMapping("/distribution")
    public ResponseEntity<List<DistributionResponseDto>> getDistributions() {
        return ResponseEntity.ok(vaultDistributionService.getDistributions());
    }

    /**
     * Batch szeosztas letrehozasa.
     * POST /api/v1/ertektar/distribution
     */
    @PostMapping("/distribution")
    public ResponseEntity<DistributionResponseDto> createDistribution(
            @Valid @RequestBody DistributionRequestDto request) {
        return ResponseEntity.ok(vaultDistributionService.createDistribution(request));
    }

    /**
     * Szeosztas statusz frissitese.
     * PATCH /api/v1/ertektar/distribution/{id}/status
     */
    @PatchMapping("/distribution/{id}/status")
    public ResponseEntity<DistributionResponseDto> updateDistributionStatus(
            @PathVariable Long id,
            @RequestParam VaultOperationStatus status) {
        return ResponseEntity.ok(vaultDistributionService.updateStatus(id, status));
    }

    // === KONSZOLIDALT RIPORTOK ===

    /**
     * Osszevont riport lekerdezese datumtartomany alapjan.
     * GET /api/v1/ertektar/reports/consolidated?from=2026-03-01&to=2026-03-15
     */
    @GetMapping("/reports/consolidated")
    public ResponseEntity<ConsolidatedReportResponseDto> getConsolidatedReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(consolidatedReportService.getConsolidatedReport(from, to));
    }

    // === ALARENDELT PENZTARAK MONITORING ===

    /**
     * Alarendelt penztarak statusza (az Ertektar Dashboard-hoz).
     * GET /api/v1/ertektar/branches
     */
    @GetMapping("/branches")
    public ResponseEntity<Map<UUID, BranchStatusResponse>> getBranches() {
        return ResponseEntity.ok(branchMonitoringService.getBranchDashboard());
    }
}
