package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Contribution;
import hu.puzzleir.valuta.service.ContributionService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Járulék controller — járulék kalkuláció és nyilvántartás.
 */
@RestController
@RequestMapping("/api/v1/contributions")
@RequiredArgsConstructor
public class ContributionController {

    private final ContributionService service;

    @GetMapping
    public ResponseEntity<List<Contribution>> getAll(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) String contributionType) {
        return ResponseEntity.ok(service.findAll(branchId, contributionType));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Contribution> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PostMapping("/calculate")
    public ResponseEntity<List<Contribution>> calculate(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodStart,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodEnd) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.calculate(branchId, periodStart, periodEnd));
    }

    @GetMapping("/period")
    public ResponseEntity<List<Contribution>> getByPeriod(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodStart,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate periodEnd) {
        return ResponseEntity.ok(service.findByPeriod(branchId, periodStart, periodEnd));
    }
}
