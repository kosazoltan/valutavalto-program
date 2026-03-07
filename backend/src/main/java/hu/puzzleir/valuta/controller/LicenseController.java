package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.license.LicenseActivateRequest;
import hu.puzzleir.valuta.dto.license.LicenseResponse;
import hu.puzzleir.valuta.dto.license.LicenseStatusResponse;
import hu.puzzleir.valuta.service.LicenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

/**
 * Licenc controller — státusz, aktuális licenc, aktiválás.
 */
@RestController
@RequestMapping("/api/v1/license")
@RequiredArgsConstructor
public class LicenseController {

    private final LicenseService licenseService;

    /**
     * Licenc státusz lekérdezés.
     * GET /api/v1/license/status
     */
    @GetMapping("/status")
    public ResponseEntity<LicenseStatusResponse> getStatus() {
        return ResponseEntity.ok(licenseService.validateLicense());
    }

    /**
     * Aktuális aktív licenc.
     * GET /api/v1/license/current
     */
    @GetMapping("/current")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<LicenseResponse> getCurrentLicense() {
        return ResponseEntity.ok(licenseService.getCurrentLicense());
    }

    /**
     * Licenc aktiválás kulccsal.
     * POST /api/v1/license/activate
     */
    @PostMapping("/activate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<LicenseResponse> activateLicense(@Valid @RequestBody LicenseActivateRequest request) {
        return ResponseEntity.ok(licenseService.activateLicense(request.getLicenseKey()));
    }
}
