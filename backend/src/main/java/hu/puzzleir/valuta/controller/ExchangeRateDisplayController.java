package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.ExchangeRateDisplay;
import hu.puzzleir.valuta.service.ExchangeRateDisplayService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Árfolyam kijelző controller — kijelző konfigurációk és aktuális árfolyamok.
 */
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/exchange-rate-display")
@RequiredArgsConstructor
public class ExchangeRateDisplayController {

    private final ExchangeRateDisplayService service;

    @GetMapping
    public ResponseEntity<List<ExchangeRateDisplay>> getAll() {
        return ResponseEntity.ok(service.findAll());
    }

    @GetMapping("/{displayId}/current-rates")
    public ResponseEntity<Map<String, Object>> getCurrentRates(@PathVariable UUID displayId) {
        return ResponseEntity.ok(service.getCurrentRates(displayId));
    }

    @PostMapping("/{displayId}/update")
    public ResponseEntity<ExchangeRateDisplay> update(
            @PathVariable UUID displayId,
            @Valid @RequestBody ExchangeRateDisplay entity) {
        return ResponseEntity.ok(service.update(displayId, entity));
    }
}
