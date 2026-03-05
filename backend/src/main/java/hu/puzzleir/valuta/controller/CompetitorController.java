package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Competitor;
import hu.puzzleir.valuta.service.CompetitorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Versenytárs controller — versenytársak nyilvántartása.
 */
@RestController
@RequestMapping("/api/v1/competitors")
@RequiredArgsConstructor
public class CompetitorController {

    private final CompetitorService service;

    @GetMapping
    public ResponseEntity<List<Competitor>> getAll() {
        return ResponseEntity.ok(service.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Competitor> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PostMapping
    public ResponseEntity<Competitor> create(@RequestBody Competitor entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Competitor> update(@PathVariable UUID id, @RequestBody Competitor entity) {
        return ResponseEntity.ok(service.update(id, entity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
