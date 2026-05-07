package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.worker.WorkerAttendanceDto;
import hu.puzzleir.valuta.dto.worker.WorkerBreakDto;
import hu.puzzleir.valuta.service.WorkerManagementService;
import hu.puzzleir.valuta.service.WorkerService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.Map;

/**
 * PĂ©nztĂˇros kezelĂ©s kiegĂ©szĂ­tĹ‘ controller â€” jelenlĂ©t, szĂĽnet, jelszĂł reset.
 * Az alap CRUD a WorkerController-ben van.
 */
@RestController
@RequestMapping("/api/v1/worker-management")
@RequiredArgsConstructor
public class WorkerManagementController {

    private final WorkerManagementService workerManagementService;

    /**
     * GET /api/v1/workers/{id}/attendance
     * JelenlĂ©t naplĂł.
     */
    @GetMapping("/{id}/attendance")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Page<WorkerAttendanceDto>> getAttendance(
            @PathVariable Long id,
            Pageable pageable) {
        return ResponseEntity.ok(workerManagementService.getAttendance(id, pageable));
    }

    /**
     * POST /api/v1/workers/{id}/reset-password
     * JelszĂł reset.
     */
    @PostMapping("/{id}/reset-password")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Void> resetPassword(
            @PathVariable Long id,
            @Valid @RequestBody Map<String, String> body) {
        String newPassword = body.get("newPassword");
        if (newPassword == null || newPassword.isBlank()) {
            return ResponseEntity.badRequest().build();
        }
        if (newPassword.length() < 8 || newPassword.length() > 128) {
            return ResponseEntity.badRequest().build();
        }
        workerManagementService.resetPassword(id, newPassword);
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/v1/workers/{id}/break-start
     * SzĂĽnet indĂ­tĂˇs.
     */
    @PostMapping("/{id}/break-start")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<WorkerBreakDto> startBreak(
            @PathVariable Long id,
            @Valid @RequestBody(required = false) Map<String, String> body) {
        String reason = body != null ? body.get("reason") : null;
        return ResponseEntity.ok(workerManagementService.startBreak(id, reason));
    }

    /**
     * POST /api/v1/workers/{id}/break-end
     * SzĂĽnet befejezĂ©s.
     */
    @PostMapping("/{id}/break-end")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<WorkerBreakDto> endBreak(@PathVariable Long id) {
        return ResponseEntity.ok(workerManagementService.endBreak(id));
    }
}
