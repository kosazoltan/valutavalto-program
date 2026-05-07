package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.SynchronizationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * Szinkronizációs controller — adatszinkronizáció fiókok között.
 */
@PreAuthorize("hasRole('ADMIN')")
@RestController
@RequestMapping("/api/v1/synchronization")
@RequiredArgsConstructor
public class SynchronizationController {

    private final SynchronizationService service;

    @PostMapping("/sync")
    public ResponseEntity<Map<String, Object>> sync(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) Long workerId) {
        Map<String, Object> result = service.sync(branchId, workerId);
        boolean success = Boolean.TRUE.equals(result.get("success"));
        return ResponseEntity.status(success ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE).body(result);
    }

    @GetMapping("/should-sync")
    public ResponseEntity<Boolean> shouldSync(
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(service.shouldSync(branchId));
    }
}
