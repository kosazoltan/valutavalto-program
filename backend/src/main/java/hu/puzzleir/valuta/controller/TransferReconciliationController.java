package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.central.TransferReconciliationResultDto;
import hu.puzzleir.valuta.service.TransferReconciliationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

/**
 * FK-003: Pénztárak közötti pénzmozgások egyeztetése (Beérkezett adatok menü).
 *
 * <p>KIZÁRÓLAG a főértéktári szerepkör (FOERTEKTAR) — illetve a rendszergazda (ADMIN) —
 * érheti el. Értéktári és pénztári felhasználók NEM látják ezt a nézetet (FK-003 §6).</p>
 *
 * <p>Az ellenőrzést a felhasználó manuálisan indítja (POST), nem fut automatikusan.
 * A művelet mellékhatása: eltérés esetén idempotens értesítés az érintett értéktárnak.</p>
 */
@RestController
@RequestMapping("/api/v1/central/transfer-reconciliation")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasAnyRole('FOERTEKTAR', 'ADMIN')")
public class TransferReconciliationController {

    private final TransferReconciliationService transferReconciliationService;

    @PostMapping("/run")
    public ResponseEntity<TransferReconciliationResultDto> run(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        log.info("POST /api/v1/central/transfer-reconciliation/run {} .. {}", startDate, endDate);
        return ResponseEntity.ok(transferReconciliationService.reconcile(startDate, endDate));
    }
}
