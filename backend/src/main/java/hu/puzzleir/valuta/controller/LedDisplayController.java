package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.led.LedDisplayDto;
import hu.puzzleir.valuta.dto.led.UpdateScrollingTextDto;
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
 * Placeholder — a fizikai LED vezérlés (RS-232 / USB) későbbi fejlesztés.
 */
@RestController
@RequestMapping("/api/v1/led")
@RequiredArgsConstructor
public class LedDisplayController {

    private final LedDisplayService ledDisplayService;

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
}
