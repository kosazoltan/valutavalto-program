package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.auth.VaultWorkerCreateRequestDto;
import hu.puzzleir.valuta.dto.auth.VaultWorkerOptionDto;
import hu.puzzleir.valuta.service.VaultWorkerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * FK-ÉRTÉKTÁR (V285, 2026-06-02): értéktári személyes dolgozók szűkített kezelése.
 *
 * <p>NEM a teljes admin worker CRUD — csak a saját értéktárba (branch) történő felvétel + listázás
 * (audit P1). A company + branch a SecurityContextből; a kliens nem választhat tetszőleges
 * céget/irodát/szerepkört.</p>
 */
@RestController
@RequestMapping("/api/v1/vault-workers")
@RequiredArgsConstructor
public class VaultWorkerController {

    private final VaultWorkerService vaultWorkerService;

    /** A saját értéktár személyes (ertektar) workerei — a felvételi képernyő listájához. */
    @GetMapping
    @PreAuthorize("hasAnyRole('ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO', 'ADMIN')")
    public ResponseEntity<List<VaultWorkerOptionDto>> list() {
        return ResponseEntity.ok(vaultWorkerService.listVaultWorkers());
    }

    /** Új személyes értéktári dolgozó felvétele a saját értéktárba (név + jelszó). */
    @PostMapping
    @PreAuthorize("hasAnyRole('ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO', 'ADMIN')")
    public ResponseEntity<VaultWorkerOptionDto> create(
            @Valid @RequestBody VaultWorkerCreateRequestDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(vaultWorkerService.createVaultWorker(dto));
    }
}
