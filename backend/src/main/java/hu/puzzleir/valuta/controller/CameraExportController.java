package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.CameraExportRequest;
import hu.puzzleir.valuta.entity.CameraExportStatus;
import hu.puzzleir.valuta.entity.ChainOfCustodyRecord;
import hu.puzzleir.valuta.service.CameraExportService;
import hu.puzzleir.valuta.service.CameraHashChainService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Kamera export + hash-chain + chain-of-custody REST controller.
 *
 * Jogosultság:
 * - Export kérelem: VIDEO_EXPORT, COMPLIANCE_OFFICER, REGIONAL_MANAGER
 * - Export jóváhagyás: VIDEO_EXPORT_APPROVE, MAIN_TREASURY, SYSTEM_ADMIN
 * - Integritás ellenőrzés: VIDEO_VIEW_LOCAL, COMPLIANCE_OFFICER, IT_ADMIN
 */
@RestController
@RequestMapping({"/api/v1/camera/export", "/api/camera/export"})
@RequiredArgsConstructor
public class CameraExportController {

    private final CameraExportService exportService;
    private final CameraHashChainService hashChainService;

    // === Export kérelem ===

    @PostMapping("/request")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT', 'COMPLIANCE_OFFICER', 'REGIONAL_MANAGER', 'SYSTEM_ADMIN')")
    public ResponseEntity<CameraExportRequest> createRequest(
            @RequestParam UUID branchId,
            @RequestParam(required = false) String cameraId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @RequestParam String reason,
            @RequestParam(required = false) String referenceNumber) {
        return ResponseEntity.ok(exportService.createExportRequest(branchId, cameraId, from, to, reason, referenceNumber));
    }

    // === Jóváhagyás / elutasítás (4-eyes) ===

    @PostMapping("/{requestId}/approve")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT_APPROVE', 'MAIN_TREASURY', 'SYSTEM_ADMIN')")
    public ResponseEntity<CameraExportRequest> approve(@PathVariable UUID requestId) {
        return ResponseEntity.ok(exportService.approveExport(requestId));
    }

    @PostMapping("/{requestId}/reject")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT_APPROVE', 'MAIN_TREASURY', 'SYSTEM_ADMIN')")
    public ResponseEntity<CameraExportRequest> reject(
            @PathVariable UUID requestId,
            @RequestParam String reason) {
        return ResponseEntity.ok(exportService.rejectExport(requestId, reason));
    }

    // === Export végrehajtás ===

    @PostMapping("/{requestId}/execute")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT', 'SYSTEM_ADMIN')")
    public ResponseEntity<CameraExportRequest> execute(@PathVariable UUID requestId) {
        CameraExportRequest request = exportService.executeExport(requestId);
        HttpStatus status = request.getStatus() == CameraExportStatus.COMPLETED
                ? HttpStatus.OK
                : HttpStatus.SERVICE_UNAVAILABLE;
        return ResponseEntity.status(status).body(request);
    }

    // === Lekérdezések ===

    @GetMapping("/{requestId}")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT', 'VIDEO_EXPORT_APPROVE', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN')")
    public ResponseEntity<CameraExportRequest> getById(@PathVariable UUID requestId) {
        return ResponseEntity.ok(exportService.getRequest(requestId));
    }

    @GetMapping("/pending")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT_APPROVE', 'MAIN_TREASURY', 'SYSTEM_ADMIN')")
    public ResponseEntity<List<CameraExportRequest>> getPending() {
        return ResponseEntity.ok(exportService.getPendingRequests());
    }

    @GetMapping("/branch/{branchId}")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT', 'VIDEO_EXPORT_APPROVE', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN')")
    public ResponseEntity<List<CameraExportRequest>> getByBranch(@PathVariable UUID branchId) {
        return ResponseEntity.ok(exportService.getRequestsByBranch(branchId));
    }

    // === Chain of Custody ===

    @GetMapping("/{requestId}/custody")
    @PreAuthorize("hasAnyAuthority('VIDEO_EXPORT', 'VIDEO_EXPORT_APPROVE', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN')")
    public ResponseEntity<List<ChainOfCustodyRecord>> getCustody(@PathVariable UUID requestId) {
        return ResponseEntity.ok(exportService.getCustodyHistory(requestId));
    }

    // === Hash-chain integritás ===

    @PostMapping("/verify-chain")
    @PreAuthorize("hasAnyAuthority('VIDEO_VIEW_LOCAL', 'COMPLIANCE_OFFICER', 'IT_ADMIN', 'SYSTEM_ADMIN')")
    public ResponseEntity<Map<String, Object>> verifyChain(
            @RequestParam UUID branchId,
            @RequestParam String cameraId) {
        boolean intact = hashChainService.verifyChain(branchId, cameraId);
        return ResponseEntity.ok(Map.of(
            "branchId", branchId,
            "cameraId", cameraId,
            "chainIntact", intact,
            "verifiedAt", LocalDateTime.now().toString()
        ));
    }
}
