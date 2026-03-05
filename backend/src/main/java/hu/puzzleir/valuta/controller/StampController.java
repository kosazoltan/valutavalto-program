package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.stamp.*;
import hu.puzzleir.valuta.service.StampService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Matrica pénztár controller — készlet, felvétel, hozzárendelés.
 */
@RestController
@RequestMapping("/api/v1/stamps")
@RequiredArgsConstructor
public class StampController {

    private final StampService stampService;

    /**
     * GET /api/v1/stamps/inventory
     * Matrica készlet.
     */
    @GetMapping("/inventory")
    public ResponseEntity<List<StampBatchDto>> getInventory() {
        return ResponseEntity.ok(stampService.getInventory());
    }

    /**
     * POST /api/v1/stamps/receive
     * Új batch felvétel.
     */
    @PostMapping("/receive")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<StampBatchDto> receiveBatch(
            @Valid @RequestBody CreateStampBatchRequest request) {
        StampBatchDto created = stampService.receiveBatch(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * POST /api/v1/stamps/assign
     * Matrica hozzárendelés.
     */
    @PostMapping("/assign")
    public ResponseEntity<StampAssignmentDto> assignStamp(
            @Valid @RequestBody AssignStampRequest request) {
        return ResponseEntity.ok(stampService.assignStamp(request));
    }

    /**
     * GET /api/v1/stamps/used
     * Felhasznált matricák.
     */
    @GetMapping("/used")
    public ResponseEntity<List<StampAssignmentDto>> getUsedStamps() {
        return ResponseEntity.ok(stampService.getUsedStamps());
    }
}
