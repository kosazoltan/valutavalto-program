package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.circular.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.CircularService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Körlevél controller.
 *
 * Legacy: ERTEKTAR — korlev.dll
 */
@RestController
@RequestMapping("/api/v1/circulars")
@RequiredArgsConstructor
public class CircularController {

    private final CircularService circularService;

    @GetMapping
    public ResponseEntity<List<CircularDto>> findAll() {
        return ResponseEntity.ok(circularService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<CircularDto> findById(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.findById(id));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CircularDto> create(
            @Valid @RequestBody CreateCircularDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(circularService.create(dto, workerId));
    }

    @PostMapping("/{id}/acknowledge")
    public ResponseEntity<CircularDto> acknowledge(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.acknowledge(id));
    }

    @GetMapping("/unacknowledged")
    public ResponseEntity<List<CircularDto>> findUnacknowledged() {
        return ResponseEntity.ok(circularService.findUnacknowledged());
    }

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }
}
