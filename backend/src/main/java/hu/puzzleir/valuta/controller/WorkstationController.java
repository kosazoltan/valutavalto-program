package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Workstation;
import hu.puzzleir.valuta.service.WorkstationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workstations")
@RequiredArgsConstructor
public class WorkstationController {

    private final WorkstationService service;

    @GetMapping
    public ResponseEntity<List<Workstation>> list() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/active")
    public ResponseEntity<List<Workstation>> listActive() {
        return ResponseEntity.ok(service.listActive());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Workstation> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping
    public ResponseEntity<Workstation> create(@Valid @RequestBody Workstation entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Workstation> update(@PathVariable UUID id, @Valid @RequestBody Workstation entity) {
        return ResponseEntity.ok(service.update(id, entity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
