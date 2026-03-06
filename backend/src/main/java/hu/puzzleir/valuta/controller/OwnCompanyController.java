package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.OwnCompany;
import hu.puzzleir.valuta.service.OwnCompanyService;
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
@RequestMapping("/api/v1/own-companies")
@RequiredArgsConstructor
public class OwnCompanyController {

    private final OwnCompanyService service;

    @GetMapping
    public ResponseEntity<List<OwnCompany>> list() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/active")
    public ResponseEntity<List<OwnCompany>> listActive() {
        return ResponseEntity.ok(service.listActive());
    }

    @GetMapping("/{id}")
    public ResponseEntity<OwnCompany> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping
    public ResponseEntity<OwnCompany> create(@Valid @RequestBody OwnCompany entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OwnCompany> update(@PathVariable UUID id, @Valid @RequestBody OwnCompany entity) {
        return ResponseEntity.ok(service.update(id, entity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
