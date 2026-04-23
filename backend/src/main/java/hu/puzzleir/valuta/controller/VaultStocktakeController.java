package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.VaultStocktakeItem;
import hu.puzzleir.valuta.entity.VaultStocktakeSession;
import hu.puzzleir.valuta.service.VaultStocktakeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Ertektar leltar (stocktake) REST kontroller - Sprint 7.1
 */
@RestController
@RequestMapping("/api/v1/vault-stocktake")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
public class VaultStocktakeController {

    private final VaultStocktakeService service;

    /** Uj leltar session. */
    @PostMapping
    public ResponseEntity<VaultStocktakeSession> createSession(
            @RequestBody CreateSessionRequest req) {
        return ResponseEntity.ok(service.createSession(req.branchId, req.territoryId, req.sessionName, req.note));
    }

    /** Ossz session listaja. */
    @GetMapping
    public ResponseEntity<List<VaultStocktakeSession>> list() {
        return ResponseEntity.ok(service.listSessions());
    }

    /** Egy session reszletesen (itemekkel). */
    @GetMapping("/{id}")
    public ResponseEntity<VaultStocktakeSession> get(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getSession(id));
    }

    /** Item actualQuantity felvetel. */
    @PostMapping("/items/{itemId}/count")
    public ResponseEntity<VaultStocktakeItem> countItem(
            @PathVariable UUID itemId,
            @RequestBody CountItemRequest req) {
        return ResponseEntity.ok(service.setItemActual(itemId, req.actualQuantity, req.note));
    }

    /** Session REVIEW-ba. */
    @PostMapping("/{id}/review")
    public ResponseEntity<VaultStocktakeSession> review(@PathVariable UUID id) {
        return ResponseEntity.ok(service.moveToReview(id));
    }

    /** Session CLOSE (csak FOERTEKTAR+ jog). */
    @PostMapping("/{id}/close")
    public ResponseEntity<VaultStocktakeSession> close(@PathVariable UUID id) {
        return ResponseEntity.ok(service.closeSession(id));
    }

    /** Session CANCEL. */
    @PostMapping("/{id}/cancel")
    public ResponseEntity<VaultStocktakeSession> cancel(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> body) {
        String reason = body != null ? body.getOrDefault("reason", "") : "";
        return ResponseEntity.ok(service.cancelSession(id, reason));
    }

    /** Session sumary + discrepancy details. */
    @GetMapping("/{id}/summary")
    public ResponseEntity<VaultStocktakeService.StocktakeSummary> summary(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getSummary(id));
    }

    /** Request DTO: createSession. */
    public static class CreateSessionRequest {
        public UUID branchId;
        public Integer territoryId;
        public String sessionName;
        public String note;
    }

    /** Request DTO: countItem. */
    public static class CountItemRequest {
        public Integer actualQuantity;
        public String note;
    }
}