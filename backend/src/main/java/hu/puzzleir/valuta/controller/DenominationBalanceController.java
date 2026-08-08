package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.denomination.DenominationBalanceDto;
import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
import hu.puzzleir.valuta.service.DenominationBalanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Pénztárgép címlet egyenleg controller.
 *
 * Címlet darabszám kezelése pénztárgép szinten.
 */
@RestController
@RequestMapping("/api/v1/cash-desks")
@RequiredArgsConstructor
public class DenominationBalanceController {

    private final DenominationBalanceService denominationBalanceService;

    /**
     * Pénztárgép összes címletének lekérése
     *
     * GET /api/v1/cash-desks/{cashDeskId}/denominations
     */
    @GetMapping("/{cashDeskId}/denominations")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<DenominationBalanceDto>> getCashDeskDenominations(
            @PathVariable UUID cashDeskId) {
        List<DenominationBalanceDto> result = denominationBalanceService.getCashDeskDenominations(cashDeskId);
        return ResponseEntity.ok(result);
    }

    /**
     * Pénztárgép adott valutájú címletei
     *
     * GET /api/v1/cash-desks/{cashDeskId}/denominations/currency/{currencyId}
     */
    @GetMapping("/{cashDeskId}/denominations/currency/{currencyId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<DenominationBalanceDto>> getCashDeskDenominationsByCurrency(
            @PathVariable UUID cashDeskId,
            @PathVariable Long currencyId) {
        List<DenominationBalanceDto> result = denominationBalanceService.getCashDeskDenominationsByCurrency(cashDeskId, currencyId);
        return ResponseEntity.ok(result);
    }

    /**
     * Címlet darabszám frissítése
     *
     * PUT /api/v1/cash-desks/{cashDeskId}/denominations/{denominationId}?quantity=
     */
    @PutMapping("/{cashDeskId}/denominations/{denominationId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR')")
    public ResponseEntity<DenominationBalanceDto> updateQuantity(
            @PathVariable UUID cashDeskId,
            @PathVariable Long denominationId,
            @RequestParam int quantity) {
        DenominationBalanceDto result = denominationBalanceService.updateQuantity(cashDeskId, denominationId, quantity);
        return ResponseEntity.ok(result);
    }

    /**
     * Batch címlet frissítés
     *
     * POST /api/v1/cash-desks/{cashDeskId}/denominations/batch
     */
    @PostMapping("/{cashDeskId}/denominations/batch")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR')")
    public ResponseEntity<List<DenominationBalanceDto>> batchUpdate(
            @PathVariable UUID cashDeskId,
            @Valid @RequestBody List<DenominationQuantityUpdateRequestDto> updates) {
        List<DenominationBalanceDto> result = denominationBalanceService.batchUpdate(cashDeskId, updates);
        return ResponseEntity.ok(result);
    }

    /**
     * Adott valuta teljes értéke a címletekből
     *
     * GET /api/v1/cash-desks/{cashDeskId}/denominations/currency/{currencyId}/total
     */
    @GetMapping("/{cashDeskId}/denominations/currency/{currencyId}/total")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<BigDecimal> calculateTotal(
            @PathVariable UUID cashDeskId,
            @PathVariable Long currencyId) {
        BigDecimal total = denominationBalanceService.calculateTotal(cashDeskId, currencyId);
        return ResponseEntity.ok(total);
    }
}
