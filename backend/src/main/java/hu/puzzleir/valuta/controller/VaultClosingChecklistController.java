package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.vaultchecklist.CompleteChecklistRequest;
import hu.puzzleir.valuta.dto.vaultchecklist.UpdateChecklistItemsRequest;
import hu.puzzleir.valuta.dto.vaultchecklist.VaultClosingChecklistDto;
import hu.puzzleir.valuta.service.VaultClosingChecklistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Értéktári zárás-előtti ellenőrzőlista REST endpointok.
 *
 * <p>FR-ZARUI-16..26 (b2-zaras-kepernyok-bizonylatok.md)</p>
 *
 * <pre>
 * GET  /api/v1/vault-closing-checklist?branchId=&amp;date=  — betölt vagy létrehoz
 * PUT  /api/v1/vault-closing-checklist?branchId=&amp;date=  — 9 tétel mentése
 * POST /api/v1/vault-closing-checklist/complete?branchId=&amp;date= — zárás véglegesítése (FR-ZARUI-26)
 * </pre>
 *
 * <p>Jogosultság: CASHIER..ADMIN olvas/ír/véglegesít (az értéktáros végzi a zárást).</p>
 */
@RestController
@RequestMapping("/api/v1/vault-closing-checklist")
@RequiredArgsConstructor
public class VaultClosingChecklistController {

    private final VaultClosingChecklistService checklistService;

    /**
     * Checklist lekérése (idempotens — ha nem létezik, létrehozza).
     *
     * @param branchId    pénztár UUID
     * @param date        zárás dátuma (ISO: yyyy-MM-dd)
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<VaultClosingChecklistDto> getOrCreate(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(checklistService.getOrCreate(branchId, date));
    }

    /**
     * 9 checkbox-tétel mentése (FR-ZARUI-17..25).
     *
     * @param branchId    pénztár UUID
     * @param date        zárás dátuma
     * @param req         item_1..item_9 boolean értékek
     */
    @PutMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<VaultClosingChecklistDto> updateItems(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody UpdateChecklistItemsRequest req) {
        return ResponseEntity.ok(checklistService.updateItems(branchId, date, req));
    }

    /**
     * Zárás véglegesítése — FR-ZARUI-26 ellenőrző személy neve + beosztása kötelező.
     *
     * @param branchId    pénztár UUID
     * @param date        zárás dátuma
     * @param req         auditorName + auditorRole
     */
    @PostMapping("/complete")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<VaultClosingChecklistDto> complete(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @Valid @RequestBody CompleteChecklistRequest req) {
        return ResponseEntity.ok(checklistService.complete(branchId, date, req));
    }
}
