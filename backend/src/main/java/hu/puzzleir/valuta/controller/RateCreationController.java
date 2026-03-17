package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ratecreation.BankRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.BranchListDTO;
import hu.puzzleir.valuta.dto.ratecreation.CompetitorRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import hu.puzzleir.valuta.dto.ratecreation.RateCreationResponseDTO;
import hu.puzzleir.valuta.dto.ratecreation.RateOverviewDTO;
import hu.puzzleir.valuta.dto.ratecreation.WorkgroupDetailDTO;
import hu.puzzleir.valuta.service.RateCreationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Árfolyam-készítés controller.
 * Bank és versenytárs árfolyamok kezelése, tervezet generálás, csoportos publikálás.
 */
@RestController
@RequestMapping("/api/v1/rate-creation")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
public class RateCreationController {

    private final RateCreationService rateCreationService;

    /**
     * Bank árfolyamok lekérése.
     * GET /api/v1/rate-creation/bank-rates
     */
    @GetMapping("/bank-rates")
    public ResponseEntity<List<BankRateDTO>> getBankRates() {
        return ResponseEntity.ok(rateCreationService.getBankRates());
    }

    /**
     * Versenytárs árfolyamok lekérése.
     * GET /api/v1/rate-creation/competitor-rates
     */
    @GetMapping("/competitor-rates")
    public ResponseEntity<List<CompetitorRateDTO>> getCompetitorRates() {
        return ResponseEntity.ok(rateCreationService.getCompetitorRates());
    }

    /**
     * Árfolyam-készítés előkészítése egy adott valutához.
     * GET /api/v1/rate-creation/prepare/{currencyId}
     *
     * Bank és versenytárs árfolyamokat gyűjt össze, statisztikát és
     * ajánlott rátákat számol a frontend árfolyam-szerkesztő felületéhez.
     */
    @GetMapping("/prepare/{currencyId}")
    public ResponseEntity<RateCreationResponseDTO> prepareRateCreation(
            @PathVariable Long currencyId) {
        return ResponseEntity.ok(rateCreationService.prepareRateCreation(currencyId));
    }

    /**
     * Árfolyam tervezet generálás — MNB + bank ráták alapján margin számolás.
     * POST /api/v1/rate-creation/prepare/all
     */
    @PostMapping("/prepare/all")
    public ResponseEntity<Map<String, Object>> prepareAllRates() {
        return ResponseEntity.ok(rateCreationService.prepareAllRates());
    }

    /**
     * Árfolyam áttekintő — ÖSSZES valuta egyszerre.
     * GET /api/v1/rate-creation/overview
     *
     * A főértéktáros áttekintő nézetéhez: minden aktív valuta jelenlegi
     * árfolyamokkal, MNB rátával, marginokkal és limit szintekkel.
     */
    @GetMapping("/overview")
    public ResponseEntity<RateOverviewDTO> getOverview() {
        return ResponseEntity.ok(rateCreationService.getRateOverview());
    }

    /**
     * Munkacsoport részletek — branch hozzárendelésekkel.
     * GET /api/v1/rate-creation/workgroups
     */
    @GetMapping("/workgroups")
    public ResponseEntity<List<WorkgroupDetailDTO>> getWorkgroupDetails() {
        return ResponseEntity.ok(rateCreationService.getWorkgroupDetails());
    }

    /**
     * Csoportos árfolyam publikálás.
     * POST /api/v1/rate-creation/publish-group-rate
     */
    @PostMapping("/publish-group-rate")
    public ResponseEntity<Void> publishGroupRate(@Valid @RequestBody GroupRateDTO groupRateDTO) {
        rateCreationService.publishGroupRate(groupRateDTO);
        return ResponseEntity.ok().build();
    }

    // ====== BRANCH MANAGEMENT ======

    /**
     * Összes aktív iroda lekérése, jelölve a munkacsoport-hozzárendelést.
     * GET /api/v1/rate-creation/branches?workgroupId={uuid}
     */
    @GetMapping("/branches")
    public ResponseEntity<List<BranchListDTO>> getBranches(@RequestParam UUID workgroupId) {
        return ResponseEntity.ok(rateCreationService.getAllBranchesForWorkgroup(workgroupId));
    }

    /**
     * Munkacsoport iroda-hozzárendelések beállítása (teljes csere).
     * POST /api/v1/rate-creation/workgroups/{workgroupId}/branches
     */
    @PostMapping("/workgroups/{workgroupId}/branches")
    public ResponseEntity<Void> updateWorkgroupBranches(
            @PathVariable UUID workgroupId,
            @RequestBody BranchAssignmentRequest request) {
        rateCreationService.updateWorkgroupBranches(workgroupId, request.getBranchIds());
        return ResponseEntity.ok().build();
    }

    /**
     * Munkacsoport limit határok frissítése.
     * PUT /api/v1/rate-creation/workgroups/{workgroupId}/limits
     */
    @PutMapping("/workgroups/{workgroupId}/limits")
    public ResponseEntity<Void> updateWorkgroupLimits(
            @PathVariable UUID workgroupId,
            @RequestBody LimitBoundaryRequest request) {
        rateCreationService.updateWorkgroupLimits(
                workgroupId,
                request.getLimit1Boundary(),
                request.getLimit2Boundary(),
                request.getLimit3Boundary());
        return ResponseEntity.ok().build();
    }

    @lombok.Data
    public static class BranchAssignmentRequest {
        private List<UUID> branchIds;
    }

    @lombok.Data
    public static class LimitBoundaryRequest {
        private BigDecimal limit1Boundary;
        private BigDecimal limit2Boundary;
        private BigDecimal limit3Boundary;
    }
}
