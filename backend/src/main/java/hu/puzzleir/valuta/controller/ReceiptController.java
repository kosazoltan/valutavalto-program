package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Receipt;
import hu.puzzleir.valuta.service.ReceiptService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/receipts")
@RequiredArgsConstructor
public class ReceiptController {

    private final ReceiptService service;

    @GetMapping
    public ResponseEntity<List<Receipt>> list(@RequestParam(required = false) UUID transactionId) {
        return ResponseEntity.ok(service.list(transactionId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Receipt> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping("/{id}/print")
    public ResponseEntity<Receipt> print(@PathVariable UUID id) {
        return ResponseEntity.ok(service.print(id));
    }
}
