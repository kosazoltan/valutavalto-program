package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDraftRequest;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigListDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigLiveDto;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeePublishRequest;
import hu.puzzleir.valuta.service.BranchHandlingFeeConfigService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * FK-096 — iroda-szintű kezelési díj konfiguráció REST végpontok (D11).
 *
 * <p>RBAC (D10): write/publish/admin-read = {@code UGYVEZETO}/{@code FOERTEKTAR}/{@code ADMIN}
 * (osztály-szint); az {@code /own} és {@code /{branchId}/live} hitelesített szinten elérhető,
 * a saját-iroda guard a service-ben él (FR-13: idegen iroda → 404).</p>
 *
 * <p>A controller NEM tartalmaz díjszámítást — csak mapel és delegál (D1).</p>
 */
@RestController
@RequestMapping("/api/v1/branch-fee-config")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('UGYVEZETO','FOERTEKTAR','ADMIN')")
public class BranchFeeConfigController {

    private final BranchHandlingFeeConfigService service;

    @GetMapping
    public ResponseEntity<BranchFeeConfigListDto> list() {
        return ResponseEntity.ok(service.listForCompany());
    }

    @PostMapping("/{branchId}/draft")
    public ResponseEntity<BranchFeeConfigDto> saveDraft(
            @PathVariable UUID branchId,
            @Valid @RequestBody BranchFeeConfigDraftRequest request) {
        return ResponseEntity.ok(service.saveDraft(branchId, request));
    }

    /**
     * D8/N11: az expectedVersion a TÖRZSBEN utazik; 0 legitim első publikálás (B2),
     * null → 400 (@Valid), elavult → 409.
     */
    @PostMapping("/{branchId}/publish")
    public ResponseEntity<BranchFeeConfigDto> publish(
            @PathVariable UUID branchId,
            @Valid @RequestBody BranchFeePublishRequest body) {
        return ResponseEntity.ok(service.publish(branchId, body.getExpectedVersion()));
    }

    /** Saját iroda éles konfigurációja — JWT-alapú (D12: a penztar-szinkron ezt használja). */
    @GetMapping("/own")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<BranchFeeConfigLiveDto> own() {
        return ResponseEntity.ok(service.getOwnLive());
    }

    /** Éles konfiguráció — CSAK a saját irodára; idegen iroda → 404 (C3). */
    @GetMapping("/{branchId}/live")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<BranchFeeConfigLiveDto> live(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.getLiveForBranch(branchId));
    }
}
