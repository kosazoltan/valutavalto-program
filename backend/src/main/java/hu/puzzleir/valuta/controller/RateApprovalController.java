package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.rateapproval.RateApprovalDto;
import hu.puzzleir.valuta.dto.rateapproval.RejectRateChangeDto;
import hu.puzzleir.valuta.dto.rateapproval.RequestRateChangeDto;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.RateApprovalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Árfolyam engedélyezés controller.
 *
 * Legacy: ratectrl.dll — értéktár kontrollálja a pénztárak árfolyamait.
 */
@RestController
@RequestMapping("/api/v1/rate-approvals")
@RequiredArgsConstructor
public class RateApprovalController {

    private final RateApprovalService rateApprovalService;

    @PostMapping("/request")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RateApprovalDto> requestRateChange(
            @Valid @RequestBody RequestRateChangeDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(rateApprovalService.requestRateChange(dto, workerId));
    }

    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<RateApprovalDto> approveRateChange(
            @PathVariable UUID id,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(rateApprovalService.approveRateChange(id, workerId));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<RateApprovalDto> rejectRateChange(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) RejectRateChangeDto dto) {
        String reason = dto != null ? dto.getReason() : null;
        return ResponseEntity.ok(rateApprovalService.rejectRateChange(id, reason));
    }

    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<RateApprovalDto>> getPendingApprovals() {
        return ResponseEntity.ok(rateApprovalService.getPendingApprovals());
    }

    @GetMapping("/history")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<RateApprovalDto>> getApprovalHistory(
            @RequestParam UUID branchId) {
        return ResponseEntity.ok(rateApprovalService.getApprovalHistory(branchId));
    }

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }
}
