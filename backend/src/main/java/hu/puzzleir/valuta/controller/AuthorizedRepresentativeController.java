package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.AuthorizationLog;
import hu.puzzleir.valuta.entity.AuthorizedRepresentative;
import hu.puzzleir.valuta.service.AuthorizedRepresentativeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Meghatalmazott képviselő controller.
 */
@RestController
@RequestMapping("/api/v1/authorized-representatives")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
public class AuthorizedRepresentativeController {

    private final AuthorizedRepresentativeService service;

    /**
     * Meghatalmazottak listázása, opcionálisan ügyfél szerint szűrve.
     * GET /api/v1/authorized-representatives?customerId=123
     */
    @GetMapping
    public ResponseEntity<List<AuthorizedRepresentative>> findAll(
            @RequestParam(required = false) Long customerId) {
        return ResponseEntity.ok(service.findAll(customerId));
    }

    /**
     * Meghatalmazott lekérése ID alapján.
     * GET /api/v1/authorized-representatives/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<AuthorizedRepresentative> findById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    /**
     * Új meghatalmazott létrehozása.
     * POST /api/v1/authorized-representatives
     */
    @PostMapping
    public ResponseEntity<AuthorizedRepresentative> create(
            @Valid @RequestBody AuthorizedRepresentative representative) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(representative));
    }

    /**
     * Meghatalmazott frissítése.
     * PUT /api/v1/authorized-representatives/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<AuthorizedRepresentative> update(
            @PathVariable UUID id,
            @Valid @RequestBody AuthorizedRepresentative representative) {
        return ResponseEntity.ok(service.update(id, representative));
    }

    /**
     * Meghatalmazott törlése.
     * DELETE /api/v1/authorized-representatives/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Tranzakció naplózása meghatalmazotthoz.
     * POST /api/v1/authorized-representatives/record-transaction
     */
    @PostMapping("/record-transaction")
    public ResponseEntity<AuthorizationLog> recordTransaction(
            @RequestParam UUID representativeId,
            @RequestParam(required = false) Long transactionId,
            @RequestParam String action) {
        return ResponseEntity.ok(service.recordTransaction(representativeId, transactionId, action));
    }
}
