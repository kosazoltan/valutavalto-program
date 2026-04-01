package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.vatrefund.CreateVatRefundRequest;
import hu.puzzleir.valuta.dto.vatrefund.VatRefundTransactionDto;
import hu.puzzleir.valuta.service.VatRefundService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * ÁFA visszatérítés REST controller.
 *
 * Endpoint-ok:
 *   POST   /api/v1/vat-refund           — új tranzakció
 *   GET    /api/v1/vat-refund/{id}      — egy tranzakció
 *   GET    /api/v1/vat-refund           — lista (opcionális from/to szűrő)
 *   GET    /api/v1/vat-refund/daily     — napi lista
 *   POST   /api/v1/vat-refund/{id}/reverse — sztornó
 */
@RestController
@RequestMapping("/api/v1/vat-refund")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('WORKER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
public class VatRefundController {

    private final VatRefundService vatRefundService;

    /**
     * Új ÁFA visszatérítés tranzakció létrehozása.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('WORKER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<VatRefundTransactionDto> create(
            @Valid @RequestBody CreateVatRefundRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(vatRefundService.createVatRefund(request));
    }

    /**
     * Egy tranzakció lekérése ID alapján.
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('WORKER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<VatRefundTransactionDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(vatRefundService.getById(id));
    }

    /**
     * Tranzakciók listája (opcionális dátum szűrővel).
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('WORKER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<VatRefundTransactionDto>> getList(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(vatRefundService.getTransactions(from, to));
    }

    /**
     * Napi tranzakciók.
     */
    @GetMapping("/daily")
    @PreAuthorize("hasAnyRole('WORKER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<VatRefundTransactionDto>> getDaily(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(vatRefundService.getDailyTransactions(date));
    }

    /**
     * Tranzakció sztornózása.
     */
    @PostMapping("/{id}/reverse")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<VatRefundTransactionDto> reverse(@PathVariable Long id) {
        return ResponseEntity.ok(vatRefundService.reverseVatRefund(id));
    }
}
