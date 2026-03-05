package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.CurrencyGroup;
import hu.puzzleir.valuta.service.CurrencyGroupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Valutacsoport controller — valuták logikai csoportosítása.
 */
@RestController
@RequestMapping("/api/v1/currency-groups")
@RequiredArgsConstructor
public class CurrencyGroupController {

    private final CurrencyGroupService service;

    @GetMapping
    public ResponseEntity<List<CurrencyGroup>> getAll() {
        return ResponseEntity.ok(service.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<CurrencyGroup> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PostMapping
    public ResponseEntity<CurrencyGroup> create(@Valid @RequestBody CurrencyGroup entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CurrencyGroup> update(@PathVariable UUID id, @Valid @RequestBody CurrencyGroup entity) {
        return ResponseEntity.ok(service.update(id, entity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
