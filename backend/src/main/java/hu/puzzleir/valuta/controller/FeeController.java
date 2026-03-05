package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.FeeDiscount;
import hu.puzzleir.valuta.entity.FeeRate;
import hu.puzzleir.valuta.entity.FeeType;
import hu.puzzleir.valuta.service.FeeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
    public ResponseEntity<List<FeeType>> listTypes() {
        return ResponseEntity.ok(service.listTypes());
    }

    @PostMapping("/types")
    public ResponseEntity<FeeType> createType(@RequestBody FeeType entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createType(entity));
    }

    @PutMapping("/types/{id}")
    public ResponseEntity<FeeType> updateType(@PathVariable UUID id, @RequestBody FeeType entity) {
        return ResponseEntity.ok(service.updateType(id, entity));
    }

    @DeleteMapping("/types/{id}")
    public ResponseEntity<Void> deleteType(@PathVariable UUID id) {
        service.deleteType(id);
        return ResponseEntity.noContent().build();
    }

    // --- FeeRate ---

    @GetMapping("/rates")
    public ResponseEntity<List<FeeRate>> listRates() {
        return ResponseEntity.ok(service.listRates());
    }

    @PostMapping("/rates")
    public ResponseEntity<FeeRate> createRate(@RequestBody FeeRate entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createRate(entity));
    }

    @PutMapping("/rates/{id}")
    public ResponseEntity<FeeRate> updateRate(@PathVariable UUID id, @RequestBody FeeRate entity) {
        return ResponseEntity.ok(service.updateRate(id, entity));
    }

    @DeleteMapping("/rates/{id}")
    public ResponseEntity<Void> deleteRate(@PathVariable UUID id) {
        service.deleteRate(id);
        return ResponseEntity.noContent().build();
    }

    // --- FeeDiscount ---

    @GetMapping("/discounts")
    public ResponseEntity<List<FeeDiscount>> listDiscounts() {
        return ResponseEntity.ok(service.listDiscounts());
    }

    @PostMapping("/discounts")
    public ResponseEntity<FeeDiscount> createDiscount(@RequestBody FeeDiscount entity) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createDiscount(entity));
    }

    @PutMapping("/discounts/{id}")
    public ResponseEntity<FeeDiscount> updateDiscount(@PathVariable UUID id, @RequestBody FeeDiscount entity) {
        return ResponseEntity.ok(service.updateDiscount(id, entity));
    }

    @DeleteMapping("/discounts/{id}")
    public ResponseEntity<Void> deleteDiscount(@PathVariable UUID id) {
        service.deleteDiscount(id);
        return ResponseEntity.noContent().build();
    }
}
