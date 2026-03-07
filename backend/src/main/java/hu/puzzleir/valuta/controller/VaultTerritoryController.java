package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.service.VaultTerritoryService;
import hu.puzzleir.valuta.service.WacService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Értéktári terület controller.
 *
 * Endpointok:
 * - GET /api/v1/territories                      → lista
 * - GET /api/v1/territories/{id}/profit?from=&to= → területi profit (WAC-ból)
 */
@RestController
@RequestMapping("/api/v1/territories")
@RequiredArgsConstructor
public class VaultTerritoryController {

    private final VaultTerritoryService vaultTerritoryService;
    private final WacService wacService;

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<VaultTerritory>> list() {
        return ResponseEntity.ok(vaultTerritoryService.getAll());
    }

    @GetMapping("/{id}/profit")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<WacService.ProfitSummary> territoryProfit(
            @PathVariable Integer id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(wacService.getTerritoryProfitSummary(id, from, to));
    }
}
