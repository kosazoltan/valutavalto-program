package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.storno.StornoApprovalDto;
import hu.puzzleir.valuta.dto.storno.StornoCheckResultDto;
import hu.puzzleir.valuta.dto.storno.StornoPinApprovalRequestDto;
import hu.puzzleir.valuta.dto.storno.StornoRequestDto;
import hu.puzzleir.valuta.dto.transaction.TransactionDto;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.service.StornoService;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Sztornó controller.
 *
 * Sztornó ellenőrzés, jóváhagyás kérés/kezelés, végrehajtás.
 */
@RestController
@RequestMapping("/api/v1/stornos")
@RequiredArgsConstructor
public class StornoController {

    private final StornoService stornoService;
    private final TransactionMapper transactionMapper;

    /**
     * Sztornó ellenőrzés - szükséges-e jóváhagyás?
     *
     * GET /api/v1/stornos/check/{transactionIdOrReceipt}?workerId=
     *
     * PR #115 fix: elfogad Long id-t VAGY receipt_number string-et (pl. "V017100005").
     * A frontend és Penztar-client a tx.receiptNumber || tx.id fallback-et használja.
     */
    @GetMapping("/check/{transactionIdOrReceipt}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<StornoCheckResultDto> checkStorno(
            @PathVariable String transactionIdOrReceipt) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        StornoCheckResultDto result = stornoService.checkStorno(transactionIdOrReceipt, workerId);
        return ResponseEntity.ok(result);
    }

    /**
     * Sztornó jóváhagyás kérése
     *
     * POST /api/v1/stornos/request-approval?transactionId=&workerId=&reason=
     */
    @PostMapping("/request-approval")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<StornoApprovalDto> requestApproval(
            @RequestParam Long transactionId,
            @RequestParam String reason) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        StornoApprovalDto result = stornoService.requestApproval(transactionId, workerId, reason);
        return ResponseEntity.ok(result);
    }

    /**
     * Függő (PENDING) sztornó-jóváhagyási kérések listája — supervisor jóváhagyó-lista.
     * Branch-izolált (a hívó security-contextje szerint).
     *
     * GET /api/v1/stornos/approvals/pending
     */
    @GetMapping("/approvals/pending")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<StornoApprovalDto>> getPendingStornoApprovals() {
        return ResponseEntity.ok(stornoService.getPendingApprovals());
    }

    /**
     * Sztornó jóváhagyása/elutasítása
     *
     * POST /api/v1/stornos/approve/{approvalId}?approvedByWorkerId=&approved=&reason=
     */
    @PostMapping("/approve/{approvalId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<StornoApprovalDto> approve(
            @PathVariable UUID approvalId,
            @RequestParam boolean approved,
            @RequestParam(required = false) String reason) {
        Long approvedByWorkerId = SecurityUtils.getCurrentWorkerId();
        StornoApprovalDto result = stornoService.approve(approvalId, approvedByWorkerId, approved, reason);
        return ResponseEntity.ok(result);
    }

    /**
     * Sztornó jóváhagyása TELEFONOS supervisor-PIN-nel — egyszemélyes iroda flow.
     *
     * <p>A pénztáros (CASHIER) sessionjéből hívható: a supervisor telefonon bediktálja a
     * PIN-jét, a pénztáros beírja. A StornoService validál (4-szem KEMÉNYEN + szerepkör +
     * cég + PIN lockout/audit) — az AmlApprovalController.verify-approver mintája.</p>
     *
     * POST /api/v1/stornos/approve-by-pin
     * Body: { approvalId, approverWorkerId, pin, approved, reason? } — a PIN szándékosan
     * BODY-ban megy, nem query-paramban (a query string access-logba kerülne).
     */
    @PostMapping("/approve-by-pin")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<StornoApprovalDto> approveByPin(
            @Valid @RequestBody StornoPinApprovalRequestDto body,
            jakarta.servlet.http.HttpServletRequest request) {
        String ip = extractClientIp(request);
        String ua = request.getHeader("User-Agent");
        StornoApprovalDto result = stornoService.approveByPin(
                body.getApprovalId(), body.getApproverWorkerId(), body.getPin(),
                Boolean.TRUE.equals(body.getApproved()), body.getReason(), ip, ua);
        return ResponseEntity.ok(result);
    }

    private String extractClientIp(jakarta.servlet.http.HttpServletRequest req) {
        String fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            return fwd.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }

    /**
     * Sztornó végrehajtása
     *
     * POST /api/v1/stornos/execute?workerId=
     */
    @PostMapping("/execute")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeStorno(
            @Valid @RequestBody StornoRequestDto request) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        Transaction transaction = stornoService.executeStorno(request, workerId);
        return ResponseEntity.ok(transactionMapper.toDto(transaction));
    }

    /**
     * POS sztornó végrehajtása
     *
     * POST /api/v1/stornos/pos?posTransactionId=&workerId=&reason=
     */
    @PostMapping("/pos")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executePosStorno(
            @RequestParam String posTransactionId,
            @RequestParam String reason) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        Transaction transaction = stornoService.executePosStorno(posTransactionId, workerId, reason);
        return ResponseEntity.ok(transactionMapper.toDto(transaction));
    }
}
