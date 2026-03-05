package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Organization;
import hu.puzzleir.valuta.service.OrganizationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/organizations")
@RequiredArgsConstructor
public class OrganizationController {

    private final OrganizationService service;

    @GetMapping
    public ResponseEntity<List<Organization>> list() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/active")
    public ResponseEntity<List<Organization>> listActive() {
        return ResponseEntity.ok(service.listActive());
    }

    @GetMapping("/root")
    public ResponseEntity<List<Organization>> listRoots() {
        return ResponseEntity.ok(service.listRoots());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Organization> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping
    public ResponseEntity<Organization> create(@RequestBody Organization entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Organization> update(@PathVariable UUID id, @RequestBody Organization entity) {
        return ResponseEntity.ok(service.update(id, entity));
    }

    @PostMapping("/{id}/archive")
    public ResponseEntity<Organization> archive(@PathVariable UUID id) {
        return ResponseEntity.ok(service.archive(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
