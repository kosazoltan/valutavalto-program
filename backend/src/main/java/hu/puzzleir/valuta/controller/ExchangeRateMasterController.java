package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ExchangeRateDistribution;
import hu.puzzleir.valuta.entity.ExchangeRateMaster;
import hu.puzzleir.valuta.entity.ExchangeRateMaster.MasterRateStatus;
import hu.puzzleir.valuta.service.ExchangeRateMasterService;
import hu.puzzleir.valuta.service.ExchangeRateMasterService.CreateMasterRateRequest;
import hu.puzzleir.valuta.service.ExchangeRateMasterService.PendingPrintObligation;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Árfolyam törzs controller.
 *
 * A főértéktáros által kezelt központi árfolyam adatbázis API-ja.
 * Támogatja az árfolyamok létrehozását, jóváhagyását, publikálását
 * és automatikus elosztását a pénztáraknak.
 *
 * Legacy: ARFREG + ARFTMK + SETRATE modulok REST API megfelelője
 */
@RestController
@RequestMapping("/api/v1/exchange-rate-master")
@RequiredArgsConstructor
public class ExchangeRateMasterController {

    private final ExchangeRateMasterService masterService;

    // ============ TÖRZS ÁRFOLYAM CRUD ============

    /**
     * Összes törzs árfolyam lekérése.
     * GET /api/v1/exchange-rate-master
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<ExchangeRateMaster>> getAllMasterRates() {
        return ResponseEntity.ok(masterService.getAllMasterRates());
    }

    /**
     * Aktív, publikált törzs árfolyamok lekérése.
     * GET /api/v1/exchange-rate-master/active
     */
    @GetMapping("/active")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<ExchangeRateMaster>> getActivePublished() {
        return ResponseEntity.ok(masterService.getActivePublishedRates());
    }

    /**
     * Törzs árfolyamok státusz szerint.
     * GET /api/v1/exchange-rate-master/status/{status}
     */
    @GetMapping("/status/{status}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<ExchangeRateMaster>> getByStatus(
            @PathVariable MasterRateStatus status) {
        return ResponseEntity.ok(masterService.getMasterRatesByStatus(status));
    }

    /**
     * Új törzs árfolyam létrehozása (DRAFT).
     * POST /api/v1/exchange-rate-master
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ExchangeRateMaster> createMasterRate(
            @Valid @RequestBody CreateMasterRateRequest request) {
        return ResponseEntity.ok(masterService.createMasterRate(request));
    }

    // ============ WORKFLOW ============

    /**
     * Törzs árfolyam jóváhagyása.
     * POST /api/v1/exchange-rate-master/{id}/approve
     */
    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ExchangeRateMaster> approveMasterRate(@PathVariable UUID id) {
        return ResponseEntity.ok(masterService.approveMasterRate(id));
    }

    /**
     * Törzs árfolyam publikálása és elosztása a pénztáraknak.
     * POST /api/v1/exchange-rate-master/{id}/publish
     *
     * @param id a törzs árfolyam ID
     * @param workgroupId opcionális munkacsoport ID (ha nincs, az összes pénztárnak)
     */
    @PostMapping("/{id}/publish")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ExchangeRateMaster> publishAndDistribute(
            @PathVariable UUID id,
            @RequestParam(required = false) UUID workgroupId) {
        return ResponseEntity.ok(masterService.publishAndDistribute(id, workgroupId));
    }

    /**
     * Törzs árfolyam visszavonása.
     * POST /api/v1/exchange-rate-master/{id}/revoke
     */
    @PostMapping("/{id}/revoke")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ExchangeRateMaster> revokeMasterRate(@PathVariable UUID id) {
        return ResponseEntity.ok(masterService.revokeMasterRate(id));
    }

    // ============ ELOSZTÁS MONITOROZÁS ============

    /**
     * Elosztás állapotának lekérdezése egy törzs árfolyamhoz.
     * GET /api/v1/exchange-rate-master/{id}/distribution
     */
    @GetMapping("/{id}/distribution")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<ExchangeRateDistribution>> getDistributionStatus(
            @PathVariable UUID id) {
        return ResponseEntity.ok(masterService.getDistributionStatus(id));
    }

    /**
     * Pénztár visszaigazolás regisztrálása.
     * POST /api/v1/exchange-rate-master/distribution/{distributionId}/acknowledge
     */
    @PostMapping("/distribution/{distributionId}/acknowledge")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<Void> acknowledgeDistribution(
            @PathVariable UUID distributionId,
            @Valid @RequestBody AcknowledgeRequest request) {
        masterService.acknowledgeDistribution(distributionId, request.printProofToken());
        return ResponseEntity.ok().build();
    }

    /**
     * Aktuális branch nyitott árfolyam-nyomtatási kötelezettségei.
     * GET /api/v1/exchange-rate-master/distribution/pending-print
     */
    @GetMapping("/distribution/pending-print")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<PendingPrintObligation>> getPendingPrintObligations() {
        return ResponseEntity.ok(masterService.getPendingPrintObligations());
    }

    public record AcknowledgeRequest(@NotBlank String printProofToken) {}
}
