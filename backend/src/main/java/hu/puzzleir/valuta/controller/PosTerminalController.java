package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.PosTerminal;
import hu.puzzleir.valuta.service.PosTerminalService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * POS terminál controller — kártyás terminálok kezelése.
 */
@RestController
@RequestMapping("/api/v1/pos-terminal")
@RequiredArgsConstructor
public class PosTerminalController {

    private final PosTerminalService service;

    @GetMapping
    public ResponseEntity<List<PosTerminal>> getAll() {
        return ResponseEntity.ok(service.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<PosTerminal> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PostMapping("/process-transaction")
    public ResponseEntity<Map<String, Object>> processTransaction(
            @RequestParam String terminalId,
            @RequestParam BigDecimal amount,
            @RequestParam String currency) {
        return ResponseEntity.ok(service.processTransaction(terminalId, amount, currency));
    }
}
