package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.service.SealTrackingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/seal-tracking")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
public class SealTrackingController {

    private final SealTrackingService sealTrackingService;

    @PostMapping("/seal")
    public ResponseEntity<SealTracking> seal(
            @RequestParam String transferType,
            @RequestParam Long transferId,
            @RequestParam String sealNumber) {
        return ResponseEntity.ok(sealTrackingService.seal(transferType, transferId, sealNumber));
    }

    @PostMapping("/start-transit")
    public ResponseEntity<SealTracking> startTransit(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        return ResponseEntity.ok(sealTrackingService.startTransit(transferType, transferId));
    }

    @PostMapping("/confirm-arrival")
    public ResponseEntity<SealTracking> confirmArrival(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        return ResponseEntity.ok(sealTrackingService.confirmArrival(transferType, transferId));
    }

    @PostMapping("/open")
    public ResponseEntity<SealTracking> openSeal(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        return ResponseEntity.ok(sealTrackingService.openSeal(transferType, transferId));
    }

    @GetMapping("/active")
    public ResponseEntity<List<SealTracking>> getActive() {
        return ResponseEntity.ok(sealTrackingService.getActiveTransits());
    }

    @GetMapping("/by-seal/{sealNumber}")
    public ResponseEntity<SealTracking> getBySealNumber(@PathVariable String sealNumber) {
        Optional<SealTracking> result = sealTrackingService.getBySealNumber(sealNumber);
        return result.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-transfer")
    public ResponseEntity<SealTracking> getByTransfer(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        Optional<SealTracking> result = sealTrackingService.getByTransfer(transferType, transferId);
        return result.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/validate")
    public ResponseEntity<Boolean> validateIntegrity(
            @RequestParam String transferType,
            @RequestParam Long transferId,
            @RequestParam String expectedSealNumber) {
        boolean valid = sealTrackingService.validateSealIntegrity(transferType, transferId, expectedSealNumber);
        return ResponseEntity.ok(valid);
    }
}
