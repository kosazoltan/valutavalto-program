package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.central.ReceivedStornoDto;
import hu.puzzleir.valuta.service.central.ReceivedStornoService;
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
 * FK-115: storno tab of "Beerkezett adatok". Read-only; does not touch the other tabs.
 */
@RestController
@RequestMapping("/api/v1/central/received-data")
@RequiredArgsConstructor
@Slf4j
public class ReceivedStornoController {

    private final ReceivedStornoService receivedStornoService;

    @GetMapping("/storno")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<ReceivedStornoDto> storno(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) Integer vaultTerritoryId) {
        log.info("GET /api/v1/central/received-data/storno from={}, to={}, branchId={}, vaultTerritoryId={}",
                fromDate, toDate, branchId, vaultTerritoryId);
        return ResponseEntity.ok(receivedStornoService.load(fromDate, toDate, branchId, vaultTerritoryId));
    }
}
