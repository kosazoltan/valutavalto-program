package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterStornoRequest;
import hu.puzzleir.valuta.service.CashRegisterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Pénztárgép controller.
 * NAV online pénztárgép integráció endpointok.
 */
@RestController
@RequestMapping("/api/v1/cash-register")
@RequiredArgsConstructor
public class CashRegisterController {

    private final CashRegisterService cashRegisterService;

    @PostMapping("/open")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> openDay(@RequestParam UUID branchId) {
        return ResponseEntity.ok(cashRegisterService.openDay(branchId));
    }

    @PostMapping("/close")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> closeDay(@RequestParam UUID branchId) {
        return ResponseEntity.ok(cashRegisterService.closeDay(branchId));
    }

    @PostMapping("/receipt")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CashRegisterEventDto> printReceipt(
            @Valid @RequestBody CashRegisterReceiptRequest request) {
        return ResponseEntity.ok(cashRegisterService.printReceipt(request));
    }

    @PostMapping("/storno")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> printStorno(
            @Valid @RequestBody CashRegisterStornoRequest request) {
        return ResponseEntity.ok(cashRegisterService.printStorno(request));
    }

    @GetMapping("/x-report/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> getXReport(@PathVariable UUID branchId) {
        return ResponseEntity.ok(cashRegisterService.getXReport(branchId));
    }

    @GetMapping("/events/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CashRegisterEventDto>> getDailyEvents(
            @PathVariable UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate effectiveDate = date != null ? date : LocalDate.now();
        return ResponseEntity.ok(cashRegisterService.getDailyEvents(branchId, effectiveDate));
    }
}
