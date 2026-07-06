package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.config.CreateValueBandConfigRequest;
import hu.puzzleir.valuta.entity.ValueBandConfig;
import hu.puzzleir.valuta.service.ValueBandService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/value-bands")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class ValueBandController {

    private final ValueBandService valueBandService;

    @GetMapping
    public ResponseEntity<List<ValueBandConfig>> list() {
        return ResponseEntity.ok(valueBandService.listAll());
    }

    @GetMapping("/effective")
    public ResponseEntity<ValueBandService.ValueBands> effective() {
        return ResponseEntity.ok(valueBandService.getEffectiveBands());
    }

    @PostMapping
    public ResponseEntity<ValueBandConfig> create(@Valid @RequestBody CreateValueBandConfigRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(valueBandService.create(req));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ValueBandConfig> update(@PathVariable UUID id,
                                                  @Valid @RequestBody CreateValueBandConfigRequest req) {
        return ResponseEntity.ok(valueBandService.update(id, req));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        valueBandService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
