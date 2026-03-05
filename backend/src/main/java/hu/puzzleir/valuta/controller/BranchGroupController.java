package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.BranchGroup;
import hu.puzzleir.valuta.service.BranchGroupService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/branch-groups")
@RequiredArgsConstructor
public class BranchGroupController {

    private final BranchGroupService service;

    @GetMapping
    public ResponseEntity<List<BranchGroup>> list() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/active")
    public ResponseEntity<List<BranchGroup>> listActive() {
        return ResponseEntity.ok(service.listActive());
    }

    @GetMapping("/roots")
    public ResponseEntity<List<BranchGroup>> listRoots() {
        return ResponseEntity.ok(service.listRoots());
    }

    @GetMapping("/{id}")
    public ResponseEntity<BranchGroup> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping
    public ResponseEntity<BranchGroup> create(@RequestBody BranchGroup entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(entity));
    }

    @PutMapping("/{id}")
    public ResponseEntity<BranchGroup> update(@PathVariable UUID id, @RequestBody BranchGroup entity) {
        return ResponseEntity.ok(service.update(id, entity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
