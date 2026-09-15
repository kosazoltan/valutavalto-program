package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.central.ReceivedBankTurnoverDto;
import hu.puzzleir.valuta.service.central.ReceivedBankTurnoverService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;

/**
 * FK-114: period bank turnover tab of "Beerkezett adatok". Read-only; does not
 * touch the reconciliation or denomination tabs.
 *
 * <p>RBAC matches the hosting page (FOERTEKTAR / BELSO_ELLENOR / ADMIN).</p>
 */
@RestController
@RequestMapping("/api/v1/central/received-data")
@RequiredArgsConstructor
@Slf4j
public class ReceivedBankTurnoverController {

    private final ReceivedBankTurnoverService receivedBankTurnoverService;

    @GetMapping("/bank-turnover")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<ReceivedBankTurnoverDto> bankTurnover(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) Integer vaultTerritoryId) {
        log.info("GET /api/v1/central/received-data/bank-turnover from={}, to={}, branchId={}, vaultTerritoryId={}",
                fromDate, toDate, branchId, vaultTerritoryId);
        return ResponseEntity.ok(receivedBankTurnoverService.load(fromDate, toDate, branchId, vaultTerritoryId));
    }
}
