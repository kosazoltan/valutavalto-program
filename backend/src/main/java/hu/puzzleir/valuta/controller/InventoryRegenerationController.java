package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.inventory.RegenerationResultDto;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.InventoryRegenerationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Készlet regenerálás controller.
 *
 * Legacy: regen.dll — készlet újraszámítás tranzakciók alapján.
 */
@RestController
@RequestMapping("/api/v1/inventory/regeneration")
@RequiredArgsConstructor
public class InventoryRegenerationController {

    private final InventoryRegenerationService regenerationService;

    @PostMapping("/run")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RegenerationResultDto> regenerate(
            @RequestParam UUID branchId,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(regenerationService.regenerate(branchId, workerId));
    }

    @GetMapping("/last")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RegenerationResultDto> getLastRegeneration(
            @RequestParam UUID branchId) {
        return ResponseEntity.ok(regenerationService.getLastRegeneration(branchId));
    }

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new hu.puzzleir.valuta.exception.ValidationException("Hitelesítés szükséges!");
    }
}
