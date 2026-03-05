package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.WorkerCommission;
import hu.puzzleir.valuta.service.WorkerCommissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Pénztáros jutalék controller — jutalék elszámolás.
 */
@RestController
@RequestMapping("/api/v1/worker-commissions")
@RequiredArgsConstructor
public class WorkerCommissionController {

    private final WorkerCommissionService service;

    @GetMapping
    public ResponseEntity<List<WorkerCommission>> getAll(
            @RequestParam(required = false) Long workerId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodStart,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodEnd) {
        return ResponseEntity.ok(service.findAll(workerId, periodStart, periodEnd));
    }

    @GetMapping("/{id}")
    public ResponseEntity<WorkerCommission> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PostMapping("/calculate")
    public ResponseEntity<List<WorkerCommission>> calculate(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodStart,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodEnd) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.calculate(branchId, periodStart, periodEnd));
    }

    @GetMapping("/period")
    public ResponseEntity<List<WorkerCommission>> getByPeriod(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodStart,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodEnd) {
        return ResponseEntity.ok(service.findByPeriod(branchId, periodStart, periodEnd));
    }

    @GetMapping("/accounting-list")
    public ResponseEntity<List<Map<String, Object>>> getAccountingList(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodStart,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodEnd) {
        return ResponseEntity.ok(service.getAccountingList(branchId, periodStart, periodEnd));
    }
}
