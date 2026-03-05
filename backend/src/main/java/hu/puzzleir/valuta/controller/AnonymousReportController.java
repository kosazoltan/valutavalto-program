package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.AnonymousReport;
import hu.puzzleir.valuta.service.AnonymousReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/anonymous-reports")
@RequiredArgsConstructor
public class AnonymousReportController {

    private final AnonymousReportService service;

    @GetMapping
    public ResponseEntity<List<AnonymousReport>> list() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AnonymousReport> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping
    public ResponseEntity<AnonymousReport> create(@Valid @RequestBody AnonymousReport entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PostMapping("/{id}/assign")
    public ResponseEntity<AnonymousReport> assign(@PathVariable UUID id, @RequestParam Long assignedToId) {
        return ResponseEntity.ok(service.assign(id, assignedToId));
    }

    @PostMapping("/{id}/resolve")
    public ResponseEntity<AnonymousReport> resolve(@PathVariable UUID id, @RequestParam String resolution) {
        return ResponseEntity.ok(service.resolve(id, resolution));
    }
}
