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
 *
 * V38: Árfolyam tábla + futó szöveg + konfiguráció kezelés + tartalom lekérdezés.
 * V98: RS-232 soros port közvetlen vezérlés (COM port).
 */
@RestController
@RequiredArgsConstructor
public class LedDisplayController {

    private final LedDisplayService ledDisplayService;

    // ============ V38: DISPLAY CONTROL ============

    @PostMapping("/api/v1/led/rate-board/update")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayDto> updateRateBoard(@RequestParam UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.updateRateBoard(branchId));
    }

    @PostMapping("/api/v1/led/scrolling-text")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayDto> updateScrollingText(
            @RequestParam UUID branchId,
            @Valid @RequestBody UpdateScrollingTextDto dto) {
        return ResponseEntity.ok(ledDisplayService.updateScrollingText(branchId, dto.getText()));
    }

    @GetMapping("/api/v1/led/status")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<LedDisplayDto>> getStatus(@RequestParam UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getStatus(branchId));
    }

    @PostMapping("/api/v1/led/update/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayDto> updateDisplay(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.updateRateBoard(branchId));
    }

    @GetMapping("/api/v1/led/config/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayConfigDto> getDisplayConfig(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getDisplayConfig(branchId));
    }

    @PutMapping("/api/v1/led/config")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<LedDisplayConfigDto> saveDisplayConfig(
            @Valid @RequestBody SaveLedDisplayConfigRequest request) {
        return ResponseEntity.ok(ledDisplayService.saveDisplayConfig(request));
    }

    @GetMapping("/api/v1/led/content/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<LedDisplayLineDto>> getDisplayContent(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getDisplayContent(branchId));
    }

    // ============ V98: SOROS PORT (RS-232) VEZÉRLÉS ============

    /**
     * Azonnali frissítés egy iroda LED kijelzőjén (soros port).
     */
    @PostMapping("/api/v1/led-display/refresh/{branchId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
    public ResponseEntity<Void> refresh(@PathVariable UUID branchId) {
        ledDisplayService.refreshDisplay(branchId);
        return ResponseEntity.ok().build();
    }

    /**
     * Összes aktív iroda LED kijelzőjének azonnali frissítése.
     */
    @PostMapping("/api/v1/led-display/refresh-all")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
    public ResponseEntity<Void> refreshAll() {
        ledDisplayService.refreshAllActive();
        return ResponseEntity.ok().build();
    }

    /**
     * Soros port konfiguráció lekérdezése.
     */
    @GetMapping("/api/v1/led-display/config/{branchId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
    public ResponseEntity<LedDisplayConfigDto> getConfig(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getConfig(branchId));
    }

    /**
     * Soros port konfiguráció frissítése.
     */
    @PutMapping("/api/v1/led-display/config/{branchId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
    public ResponseEntity<LedDisplayConfigDto> updateConfig(
            @PathVariable UUID branchId,
            @RequestBody LedDisplayConfigDto dto) {
        return ResponseEntity.ok(ledDisplayService.updateConfig(branchId, dto));
    }

    /**
     * Fizikai LED státusz egy irodához.
     */
    @GetMapping("/api/v1/led-display/status/{branchId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
    public ResponseEntity<LedDisplayStatusDto> getSerialStatus(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getSerialStatus(branchId));
    }

    /**
     * Összes iroda fizikai LED státusza.
     */
    @GetMapping("/api/v1/led-display/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
    public ResponseEntity<List<LedDisplayStatusDto>> getAllStatuses() {
        return ResponseEntity.ok(ledDisplayService.getAllStatuses());
    }

    /**
     * Egyéni szöveg küldése soros porton.
     */
    @PostMapping("/api/v1/led-display/text/{branchId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
    public ResponseEntity<Void> sendText(
            @PathVariable UUID branchId,
            @RequestBody String text) {
        ledDisplayService.sendCustomText(branchId, text);
        return ResponseEntity.ok().build();
    }
}
