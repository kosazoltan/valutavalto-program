package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.HandoverSheet;
import hu.puzzleir.valuta.service.HandoverSheetService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/handover-sheets")
@RequiredArgsConstructor
public class HandoverSheetController {

    private final HandoverSheetService service;

    @GetMapping
    public ResponseEntity<List<HandoverSheet>> list() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<HandoverSheet> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping("/generate")
    public ResponseEntity<HandoverSheet> generate(@Valid @RequestBody HandoverSheet entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.generate(entity));
    }

    @PostMapping("/{id}/print")
    public ResponseEntity<HandoverSheet> print(@PathVariable UUID id) {
        return ResponseEntity.ok(service.print(id));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<HandoverSheet> complete(@PathVariable UUID id) {
        return ResponseEntity.ok(service.complete(id));
    }
}
