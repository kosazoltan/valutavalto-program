package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterStornoRequest;
import hu.puzzleir.valuta.service.BranchService;
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
    private final BranchService branchService;

    @PostMapping("/open")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> openDay(@RequestParam UUID branchId) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        return ResponseEntity.ok(cashRegisterService.openDay(branchId));
    }

    @PostMapping("/close")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> closeDay(@RequestParam UUID branchId) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        return ResponseEntity.ok(cashRegisterService.closeDay(branchId));
    }

    @PostMapping("/receipt")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CashRegisterEventDto> printReceipt(
            @Valid @RequestBody CashRegisterReceiptRequest request) {
        branchService.findById(request.getBranchId()); // IDOR védelem: cég ellenőrzés
        return ResponseEntity.ok(cashRegisterService.printReceipt(request));
    }

    @PostMapping("/storno")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> printStorno(
            @Valid @RequestBody CashRegisterStornoRequest request) {
        branchService.findById(request.getBranchId()); // IDOR védelem: cég ellenőrzés
        return ResponseEntity.ok(cashRegisterService.printStorno(request));
    }

    @GetMapping("/x-report/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> getXReport(@PathVariable UUID branchId) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        return ResponseEntity.ok(cashRegisterService.getXReport(branchId));
    }

    @GetMapping("/z-report/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> generateZReport(
            @PathVariable UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        branchService.findById(branchId);
        return ResponseEntity.ok(cashRegisterService.generateZReport(branchId, date));
    }

    @GetMapping("/receipt-gaps/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<java.util.List<String>> validateReceiptGaps(
            @PathVariable UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        branchService.findById(branchId);
        return ResponseEntity.ok(cashRegisterService.validateReceiptSequenceContinuity(branchId, date));
    }

    @GetMapping("/events/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CashRegisterEventDto>> getDailyEvents(
            @PathVariable UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        LocalDate effectiveDate = date != null ? date : LocalDate.now();
        return ResponseEntity.ok(cashRegisterService.getDailyEvents(branchId, effectiveDate));
    }
}
