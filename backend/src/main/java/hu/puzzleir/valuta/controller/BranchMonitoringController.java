package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.dto.monitoring.HeartbeatRequest;
import hu.puzzleir.valuta.service.BranchMonitoringService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Fiók monitoring controller — locserver központi szerver.
 * Heartbeat fogadás, online/offline fiókok, dashboard.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/monitoring")
@RequiredArgsConstructor
public class BranchMonitoringController {

    private final BranchMonitoringService branchMonitoringService;

    /**
     * Heartbeat fogadás fióktól.
     * POST /api/v1/monitoring/heartbeat
     */
    @PostMapping("/heartbeat")
    public ResponseEntity<Void> heartbeat(@Valid @RequestBody HeartbeatRequest request) {
        branchMonitoringService.updateHeartbeat(request.getBranchId());
        return ResponseEntity.ok().build();
    }

    /**
     * Online fiókok listája.
     * GET /api/v1/monitoring/online
     */
    @GetMapping("/online")
    public ResponseEntity<List<BranchStatusResponse>> getOnlineBranches() {
        return ResponseEntity.ok(branchMonitoringService.getOnlineBranches());
    }

    /**
     * Offline fiókok listája.
     * GET /api/v1/monitoring/offline?minutes=5
     */
    @GetMapping("/offline")
    public ResponseEntity<List<BranchStatusResponse>> getOfflineBranches(
            @RequestParam(defaultValue = "5") int minutes) {
        return ResponseEntity.ok(branchMonitoringService.getOfflineBranches(minutes));
    }

    /**
     * Összes fiók dashboard nézete.
     * GET /api/v1/monitoring/dashboard
     */
    @GetMapping("/dashboard")
    public ResponseEntity<Map<UUID, BranchStatusResponse>> getDashboard() {
        return ResponseEntity.ok(branchMonitoringService.getBranchDashboard());
    }
}
