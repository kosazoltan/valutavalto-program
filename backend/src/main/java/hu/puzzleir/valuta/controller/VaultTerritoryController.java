package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ertektar.VaultTerritoryRequestDto;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.service.VaultTerritoryService;
import hu.puzzleir.valuta.service.WacService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Ertektari terulet controller.
 *
 * Endpointok:
 * - GET /api/v1/territories                      -> lista
 * - GET /api/v1/territories/{id}/profit?from=&to= -> teruleti profit (WAC-bol)
 * - POST /api/v1/territories                     -> uj terulet letrehozasa (admin)
 * - GET /api/v1/territories/{id}                 -> egy terulet adatai
 */
@RestController
@RequestMapping("/api/v1/territories")
@RequiredArgsConstructor
public class VaultTerritoryController {

    private final VaultTerritoryService vaultTerritoryService;
    private final WacService wacService;

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<VaultTerritory>> list() {
        return ResponseEntity.ok(vaultTerritoryService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<VaultTerritory> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(vaultTerritoryService.getById(id));
    }

    /**
     * Uj ertektari terulet letrehozasa.
     * Csak ADMIN / UGYVEZETO / FOERTEKTAR hozhat letre uj teruletet.
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'UGYVEZETO', 'FOERTEKTAR')")
    public ResponseEntity<VaultTerritory> create(@Valid @RequestBody VaultTerritoryRequestDto request) {
        VaultTerritory created = vaultTerritoryService.create(request);
        return ResponseEntity.status(201).body(created);
    }

    @GetMapping("/{id}/profit")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<WacService.ProfitSummary> territoryProfit(
            @PathVariable Integer id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(wacService.getTerritoryProfitSummary(id, from, to));
    }
}