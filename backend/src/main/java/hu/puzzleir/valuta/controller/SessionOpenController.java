package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.session.SessionDataDto;
import hu.puzzleir.valuta.dto.session.SessionOpenRequestDto;
import hu.puzzleir.valuta.service.SessionOpenService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Pénztárnyitás controller.
 */
@RestController
@RequestMapping("/api/v1/sessions")
@RequiredArgsConstructor
public class SessionOpenController {

    private final SessionOpenService sessionOpenService;

    /**
     * Pénztár megnyitása
     *
     * POST /api/v1/sessions/open
     */
    @PostMapping("/open")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<SessionDataDto> openSession(@Valid @RequestBody SessionOpenRequestDto request) {
        SessionDataDto result = sessionOpenService.openSession(
                request.getWorkerId(),
                request.getBranchId()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * Nyitó készlet lekérése
     *
     * GET /api/v1/sessions/opening-balance/{sessionId}
     */
    @GetMapping("/opening-balance/{sessionId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, BigDecimal>> getOpeningBalance(@PathVariable Long sessionId) {
        return ResponseEntity.ok(sessionOpenService.getOpeningBalance(sessionId));
    }

    /**
     * Nyitás validáció — figyelmeztetések
     *
     * GET /api/v1/sessions/validate-open/{branchId}
     */
    @GetMapping("/validate-open/{branchId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<String>> validateSessionOpen(@PathVariable UUID branchId) {
        return ResponseEntity.ok(sessionOpenService.validateSessionOpen(branchId));
    }
}
