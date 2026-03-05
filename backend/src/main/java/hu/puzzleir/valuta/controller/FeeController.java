package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.FeeDiscount;
import hu.puzzleir.valuta.entity.FeeRate;
import hu.puzzleir.valuta.entity.FeeType;
import hu.puzzleir.valuta.service.FeeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/fees")
@RequiredArgsConstructor
public class FeeController {

    private final FeeService service;

    // --- FeeType ---

    @GetMapping("/types")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<FeeType>> listTypes() {
        return ResponseEntity.ok(service.listTypes());
    }

    @PostMapping("/types")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FeeType> createType(@Valid @RequestBody FeeType entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createType(entity));
    }

    @PutMapping("/types/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FeeType> updateType(@PathVariable UUID id, @Valid @RequestBody FeeType entity) {
        return ResponseEntity.ok(service.updateType(id, entity));
    }

    @DeleteMapping("/types/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deleteType(@PathVariable UUID id) {
        service.deleteType(id);
        return ResponseEntity.noContent().build();
    }

    // --- FeeRate ---

    @GetMapping("/rates")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<FeeRate>> listRates() {
        return ResponseEntity.ok(service.listRates());
    }

    @PostMapping("/rates")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FeeRate> createRate(@Valid @RequestBody FeeRate entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createRate(entity));
    }

    @PutMapping("/rates/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FeeRate> updateRate(@PathVariable UUID id, @Valid @RequestBody FeeRate entity) {
        return ResponseEntity.ok(service.updateRate(id, entity));
    }

    @DeleteMapping("/rates/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deleteRate(@PathVariable UUID id) {
        service.deleteRate(id);
        return ResponseEntity.noContent().build();
    }

    // --- FeeDiscount ---

    @GetMapping("/discounts")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<FeeDiscount>> listDiscounts() {
        return ResponseEntity.ok(service.listDiscounts());
    }

    @PostMapping("/discounts")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FeeDiscount> createDiscount(@Valid @RequestBody FeeDiscount entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createDiscount(entity));
    }

    @PutMapping("/discounts/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FeeDiscount> updateDiscount(@PathVariable UUID id, @Valid @RequestBody FeeDiscount entity) {
        return ResponseEntity.ok(service.updateDiscount(id, entity));
    }

    @DeleteMapping("/discounts/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> deleteDiscount(@PathVariable UUID id) {
        service.deleteDiscount(id);
        return ResponseEntity.noContent().build();
    }
}
