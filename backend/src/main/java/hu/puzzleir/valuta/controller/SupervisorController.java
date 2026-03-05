package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.supervisor.*;
import hu.puzzleir.valuta.service.SupervisorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Supervisor mód controller — autentikáció, felülbírálások, rendszerparaméterek.
 */
@RestController
@RequestMapping("/api/v1/supervisor")
@RequiredArgsConstructor
public class SupervisorController {

    private final SupervisorService supervisorService;

    /**
     * POST /api/v1/supervisor/authenticate
     * Supervisor jelszó ellenőrzés.
     */
    @PostMapping("/authenticate")
    public ResponseEntity<Map<String, Boolean>> authenticate(
            @Valid @RequestBody SupervisorAuthRequest request) {
        boolean ok = supervisorService.authenticate(request.getPassword());
        return ResponseEntity.ok(Map.of("authenticated", ok));
    }

    /**
     * GET /api/v1/supervisor/params
     * Rendszer paraméterek (readonly).
     */
    @GetMapping("/params")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<SystemParamDto>> getParams() {
        return ResponseEntity.ok(supervisorService.getSystemParams());
    }

    /**
     * POST /api/v1/supervisor/override-rate
     * Árfolyam felülbírálat.
     */
    @PostMapping("/override-rate")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> overrideRate(
            @Valid @RequestBody OverrideRateRequest request) {
        supervisorService.overrideRate(
                request.getBranchId(),
                request.getCurrency(),
                request.getNewBuyRate(),
                request.getNewSellRate(),
                request.getReason());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/v1/supervisor/override-fee
     * Kezelési díj felülbírálat.
     */
    @PostMapping("/override-fee")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> overrideFee(
            @Valid @RequestBody OverrideFeeRequest request) {
        supervisorService.overrideFee(
                request.getTransactionId(),
                request.getNewFee(),
                request.getReason());
        return ResponseEntity.ok().build();
    }
}
