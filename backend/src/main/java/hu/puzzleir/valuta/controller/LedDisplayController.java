package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.led.*;
import hu.puzzleir.valuta.service.LedDisplayService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * LED kijelző controller.
 * Árfolyam tábla + futó szöveg + konfiguráció kezelés + tartalom lekérdezés.
 */
@RestController
@RequestMapping("/api/v1/led")
@RequiredArgsConstructor
public class LedDisplayController {

    private final LedDisplayService ledDisplayService;

    // ============ DISPLAY CONTROL ============

    @PostMapping("/rate-board/update")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayDto> updateRateBoard(@RequestParam UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.updateRateBoard(branchId));
    }

    @PostMapping("/scrolling-text")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayDto> updateScrollingText(
            @RequestParam UUID branchId,
            @Valid @RequestBody UpdateScrollingTextDto dto) {
        return ResponseEntity.ok(ledDisplayService.updateScrollingText(branchId, dto.getText()));
    }

    @GetMapping("/status")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<LedDisplayDto>> getStatus(@RequestParam UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getStatus(branchId));
    }

    // ============ DISPLAY UPDATE (Batch 8A spec) ============

    @PostMapping("/update/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayDto> updateDisplay(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.updateRateBoard(branchId));
    }

    // ============ CONFIG ============

    @GetMapping("/config/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayConfigDto> getDisplayConfig(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getDisplayConfig(branchId));
    }

    @PutMapping("/config")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayConfigDto> saveDisplayConfig(
            @Valid @RequestBody SaveLedDisplayConfigRequest request) {
        return ResponseEntity.ok(ledDisplayService.saveDisplayConfig(request));
    }

    // ============ CONTENT ============

    @GetMapping("/content/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<LedDisplayLineDto>> getDisplayContent(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getDisplayContent(branchId));
    }
}
