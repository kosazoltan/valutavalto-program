package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashdesk.CashDeskBreakDto;
import hu.puzzleir.valuta.service.CashDeskBreakService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Pénztár szünet controller.
 *
 * Pénztárgép szüneteltetésének kezelése.
 */
@RestController
@RequestMapping("/api/v1/cash-desk-breaks")
@RequiredArgsConstructor
public class CashDeskBreakController {

    private final CashDeskBreakService cashDeskBreakService;

    /**
     * Szünetek listázása
     *
     * GET /api/v1/cash-desk-breaks?cashDeskId=
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CashDeskBreakDto>> listBreaks(
            @RequestParam(required = false) UUID cashDeskId) {
        List<CashDeskBreakDto> result = cashDeskBreakService.listBreaks(cashDeskId);
        return ResponseEntity.ok(result);
    }

    /**
     * Aktív szünet lekérése
     *
     * GET /api/v1/cash-desk-breaks/active/{cashDeskId}
     */
    @GetMapping("/active/{cashDeskId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashDeskBreakDto> getActiveBreak(@PathVariable UUID cashDeskId) {
        CashDeskBreakDto result = cashDeskBreakService.getActiveBreak(cashDeskId);
        return ResponseEntity.ok(result);
    }

    /**
     * Szünet indítása
     *
     * POST /api/v1/cash-desk-breaks/start?cashDeskId=&breakType=&reason=
     */
    @PostMapping("/start")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashDeskBreakDto> startBreak(
            @RequestParam UUID cashDeskId,
            @RequestParam String breakType,
            @RequestParam(required = false) String reason) {
        CashDeskBreakDto result = cashDeskBreakService.startBreak(cashDeskId, breakType, reason);
        return ResponseEntity.ok(result);
    }

    /**
     * Szünet befejezése
     *
     * POST /api/v1/cash-desk-breaks/{breakId}/end
     */
    @PostMapping("/{breakId}/end")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashDeskBreakDto> endBreak(@PathVariable UUID breakId) {
        CashDeskBreakDto result = cashDeskBreakService.endBreak(breakId);
        return ResponseEntity.ok(result);
    }
}
