package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.bankorder.BankOrderDto;
import hu.puzzleir.valuta.dto.bankorder.CreateBankOrderRequest;
import hu.puzzleir.valuta.entity.BankOrder;
import hu.puzzleir.valuta.service.BankOrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * E-B8 Banki rendelés REST endpointok (issue #279).
 *
 * <p>State machine workflow: PENDING → APPROVED → EXECUTED, vagy CANCELLED.</p>
 */
@RestController
@RequestMapping("/api/v1/bank-orders")
@RequiredArgsConstructor
public class BankOrderController {

    private final BankOrderService bankOrderService;

    /** Új rendelés (értéktáros / iroda). */
    @PostMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BankOrderDto> create(@Valid @RequestBody CreateBankOrderRequest req) {
        return ResponseEntity.ok(bankOrderService.create(req));
    }

    /** Jóváhagyás (ügyvezető). */
    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<BankOrderDto> approve(@PathVariable UUID id) {
        return ResponseEntity.ok(bankOrderService.approve(id));
    }

    /** Bank-átvétel rögzítése (értéktáros). */
    @PostMapping("/{id}/execute")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BankOrderDto> execute(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> body) {
        String bankReference = body != null ? body.get("bankReference") : null;
        return ResponseEntity.ok(bankOrderService.execute(id, bankReference));
    }

    /** Visszavonás indoklással. */
    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BankOrderDto> cancel(
            @PathVariable UUID id,
            @RequestBody Map<String, String> body) {
        String reason = body != null ? body.get("reason") : null;
        return ResponseEntity.ok(bankOrderService.cancel(id, reason));
    }

    /** Lapozható lista, status szerint szűrhető. */
    @GetMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Page<BankOrderDto>> list(
            @RequestParam(required = false) BankOrder.Status status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return ResponseEntity.ok(bankOrderService.list(status, page, size));
    }

    /** Egy konkrét rendelés. */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BankOrderDto> get(@PathVariable UUID id) {
        return ResponseEntity.ok(bankOrderService.get(id));
    }
}
