package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.transfer.*;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.TransferService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transfers")
@RequiredArgsConstructor
public class TransferController {

    private final TransferService transferService;

    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDto> create(@Valid @RequestBody CreateTransferDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED).body(transferService.create(dto, workerId));
    }

    @PostMapping("/{id}/receive")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDto> receive(@PathVariable Long id, @Valid @RequestBody ReceiveTransferDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(transferService.receive(id, dto, workerId));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDto> reject(@PathVariable Long id, @RequestParam String reason, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(transferService.reject(id, reason, workerId));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> cancel(@PathVariable Long id) {
        transferService.cancel(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}")
    public ResponseEntity<TransferDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(transferService.getById(id));
    }

    @GetMapping("/number/{transferNumber}")
    public ResponseEntity<TransferDto> getByTransferNumber(@PathVariable String transferNumber) {
        return ResponseEntity.ok(transferService.getByTransferNumber(transferNumber));
    }

    @GetMapping("/pending")
    public ResponseEntity<List<TransferDto>> getPending() {
        return ResponseEntity.ok(transferService.getPending());
    }

    @GetMapping("/outgoing")
    public ResponseEntity<List<TransferDto>> getOutgoing(Authentication auth) {
        UUID branchId = getBranchId(auth);
        return ResponseEntity.ok(transferService.getOutgoing(branchId));
    }

    @GetMapping("/incoming")
    public ResponseEntity<List<TransferDto>> getIncoming(Authentication auth) {
        UUID branchId = getBranchId(auth);
        return ResponseEntity.ok(transferService.getIncoming(branchId));
    }

    @GetMapping
    public ResponseEntity<Page<TransferDto>> search(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) Transfer.TransferStatus status,
            @RequestParam(required = false) Transfer.TransferType type,
            Pageable pageable) {
        return ResponseEntity.ok(transferService.search(branchId, startDate, endDate, status, type, pageable));
    }

    @GetMapping("/pending/count")
    public ResponseEntity<Long> countPending(Authentication auth) {
        UUID branchId = getBranchId(auth);
        return ResponseEntity.ok(transferService.countPending(branchId));
    }

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }

    private UUID getBranchId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getBranchId();
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }
}
