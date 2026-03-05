package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.ReportExtendedService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Kibővített riport controller — tranzakciós listák, díjösszesítők,
 * havi kimutatások, AML riportok.
 */
@RestController
@RequestMapping("/api/v1/reports-extended")
@RequiredArgsConstructor
public class ReportExtendedController {

    private final ReportExtendedService service;

    @GetMapping("/transaction-list")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getTransactionList(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getTransactionList(branchId, startDate, endDate));
    }

    @GetMapping("/receipt-list")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getReceiptList(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getReceiptList(branchId, startDate, endDate));
    }

    @GetMapping("/fee-summary")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getFeeSummary(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getFeeSummary(branchId, startDate, endDate));
    }

    @GetMapping("/monthly-inventory")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getMonthlyInventory(
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(service.getMonthlyInventory(year, month, branchId));
    }

    @GetMapping("/monthly-turnover")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getMonthlyTurnover(
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(service.getMonthlyTurnover(year, month, branchId));
    }

    @GetMapping("/monthly-transfers")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getMonthlyTransfers(
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(service.getMonthlyTransfers(year, month, branchId));
    }

    @GetMapping("/handling-cost")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getHandlingCost(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getHandlingCost(branchId, startDate, endDate));
    }

    @GetMapping("/daily-cash-desk")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getDailyCashDesk(
            @RequestParam(required = false) UUID cashDeskId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(service.getDailyCashDesk(cashDeskId, date));
    }

    @GetMapping("/current-cash-desk-status")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getCurrentCashDeskStatus(
            @RequestParam(required = false) UUID cashDeskId) {
        return ResponseEntity.ok(service.getCurrentCashDeskStatus(cashDeskId));
    }

    @GetMapping("/suspicious-transactions")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<Map<String, Object>>> getSuspiciousTransactions(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getSuspiciousTransactions(branchId, startDate, endDate));
    }

    @GetMapping("/card-transaction-fees")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> getCardTransactionFees(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getCardTransactionFees(branchId, startDate, endDate));
    }
}
