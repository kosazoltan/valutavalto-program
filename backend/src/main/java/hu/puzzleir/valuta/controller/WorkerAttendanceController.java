package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.worker.WorkerAttendanceDto;
import hu.puzzleir.valuta.service.WorkerAttendanceService;
import hu.puzzleir.valuta.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Jelenleti nyilvantartas REST API.
 * Legacy: jelenlet/ + idbeiro/ DLL
 *
 * H1 gap: Controller reteg a WorkerAttendance entity/repository fole.
 */
@RestController
@RequestMapping("/api/v1/attendance")
@RequiredArgsConstructor
public class WorkerAttendanceController {

    private final WorkerAttendanceService attendanceService;
    /** Audit P1.4 SSOT: trusted-proxy-aware kliens IP feloldas. */
    private final ClientIpResolver clientIpResolver;

    /**
     * Bejelentkezes rogzitese (automatikus — login utan hivhato).
     */
    @PostMapping("/login")
    public ResponseEntity<WorkerAttendanceDto> recordLogin(HttpServletRequest request) {
        // Audit P1.4: trusted-proxy-aware IP feloldas (ClientIpResolver SSOT).
        String ip = clientIpResolver.resolveClientIp(request);
        String userAgent = request.getHeader("User-Agent");
        return ResponseEntity.ok(attendanceService.recordLogin(ip, userAgent));
    }

    /**
     * Kijelentkezes rogzitese.
     */
    @PostMapping("/{id}/logout")
    public ResponseEntity<WorkerAttendanceDto> recordLogout(@PathVariable UUID id) {
        return ResponseEntity.ok(attendanceService.recordLogout(id));
    }

    /**
     * Sajat jelenleti naplo.
     */
    @GetMapping("/my")
    public ResponseEntity<Page<WorkerAttendanceDto>> getMyAttendance(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            Pageable pageable) {
        return ResponseEntity.ok(attendanceService.getMyAttendance(from, to, pageable));
    }

    /**
     * Dolgozo jelenleti naploja (supervisor/manager/admin).
     */
    @GetMapping("/worker/{workerId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Page<WorkerAttendanceDto>> getWorkerAttendance(
            @PathVariable Long workerId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            Pageable pageable) {
        return ResponseEntity.ok(attendanceService.getAttendanceByWorker(workerId, from, to, pageable));
    }
}
