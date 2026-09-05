package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.retroactiveclosing.OpenPastDayDto;
import hu.puzzleir.valuta.dto.retroactiveclosing.RetroactiveReconciliationDto;
import hu.puzzleir.valuta.service.RetroactiveClosingService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * FKH-050: user-initiated simplified RETROACTIVE closing of past open daily sessions.
 *
 * <p>NEW controller (D1): widening {@code EveningClosingController}'s class-level
 * role set would silently grant cashiers today's send endpoint. Here CASHIER is
 * included deliberately — the retroactive flow is a cashier-facing simplification —
 * and every endpoint is scope-guarded through {@code requireRetroactiveScope}
 * (own branch or vault-region scope, invariant #1).</p>
 */
@RestController
@RequestMapping("/api/v1/retroactive-closing")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
public class RetroactiveClosingController {

    private final RetroactiveClosingService retroactiveClosingService;

    /**
     * FR-1: the caller's open past days of one branch, oldest first (today excluded).
     *
     * GET /api/v1/retroactive-closing/{branchId}/open-days
     */
    @GetMapping("/{branchId}/open-days")
    public ResponseEntity<List<OpenPastDayDto>> listOpenPastDays(@PathVariable UUID branchId) {
        return ResponseEntity.ok(retroactiveClosingService.listOpenPastDays(branchId));
    }

    /**
     * FR-5/D6: reconciliation of the past day (expected from that day's
     * daily_balance, actual from the counted EVENING stock of that date).
     *
     * POST /api/v1/retroactive-closing/{branchId}/{date}/reconciliation
     */
    @PostMapping("/{branchId}/{date}/reconciliation")
    public ResponseEntity<RetroactiveReconciliationDto> reconcile(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(retroactiveClosingService.reconcile(branchId, date));
    }

    /**
     * FR-6/FR-7: closes the past day (oldest-first gate, reconciliation gate,
     * evening package of that date, retroactive audit stamp).
     *
     * POST /api/v1/retroactive-closing/{branchId}/{date}/close
     */
    @PostMapping("/{branchId}/{date}/close")
    public ResponseEntity<Map<String, Object>> close(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        var session = retroactiveClosingService.closeRetroactively(branchId, date);
        return ResponseEntity.ok(Map.of(
                "ok", true,
                "sessionDate", session.getSessionDate().toString(),
                "retroactiveClosedAt", session.getRetroactiveClosedAt() == null
                        ? "" : session.getRetroactiveClosedAt().toString()));
    }
}
