package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.storno.StornoApprovalDto;
import hu.puzzleir.valuta.dto.storno.StornoCheckResultDto;
import hu.puzzleir.valuta.dto.storno.StornoRequestDto;
import hu.puzzleir.valuta.dto.transaction.TransactionDto;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.mapper.TransactionMapper;
import hu.puzzleir.valuta.service.StornoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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
     * GET /api/v1/stornos/check/{transactionId}?workerId=
     */
    @GetMapping("/check/{transactionId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<StornoCheckResultDto> checkStorno(
            @PathVariable Long transactionId,
            @RequestParam Long workerId) {
        StornoCheckResultDto result = stornoService.checkStorno(transactionId, workerId);
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
            @RequestParam Long workerId,
            @RequestParam String reason) {
        StornoApprovalDto result = stornoService.requestApproval(transactionId, workerId, reason);
        return ResponseEntity.ok(result);
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
            @RequestParam Long approvedByWorkerId,
            @RequestParam boolean approved,
            @RequestParam(required = false) String reason) {
        StornoApprovalDto result = stornoService.approve(approvalId, approvedByWorkerId, approved, reason);
        return ResponseEntity.ok(result);
    }

    /**
     * Sztornó végrehajtása
     *
     * POST /api/v1/stornos/execute?workerId=
     */
    @PostMapping("/execute")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransactionDto> executeStorno(
            @Valid @RequestBody StornoRequestDto request,
            @RequestParam Long workerId) {
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
            @RequestParam Long workerId,
            @RequestParam String reason) {
        Transaction transaction = stornoService.executePosStorno(posTransactionId, workerId, reason);
        return ResponseEntity.ok(transactionMapper.toDto(transaction));
    }
}
