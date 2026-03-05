package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.OrganizationalSystemParameter;
import hu.puzzleir.valuta.service.OrganizationalSystemParameterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Szervezeti rendszerparaméter controller — szervezet-specifikus beállítások.
 */
@RestController
@RequestMapping("/api/v1/organizational-system-parameters")
@RequiredArgsConstructor
public class OrganizationalSystemParameterController {

    private final OrganizationalSystemParameterService service;

    @GetMapping
    public ResponseEntity<List<OrganizationalSystemParameter>> getAll(
            @RequestParam(required = false) UUID organizationId) {
        return ResponseEntity.ok(service.findAll(organizationId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<OrganizationalSystemParameter> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PostMapping
    public ResponseEntity<OrganizationalSystemParameter> create(@RequestBody OrganizationalSystemParameter entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrganizationalSystemParameter> update(
            @PathVariable UUID id,
            @RequestBody OrganizationalSystemParameter entity) {
        return ResponseEntity.ok(service.update(id, entity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
