package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.central.ReceivedDenominationsDto;
import hu.puzzleir.valuta.service.central.ReceivedDenominationsService;
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
 * FK-111: closing-time denomination stock ("Keszletek, cimletek" tab of the
 * "Beerkezett adatok" page). Read-only; it does not touch the transfer reconciliation
 * flow that owns the page's default tab.
 *
 * <p>RBAC: the roles of the hosting page (FOERTEKTAR / BELSO_ELLENOR / ADMIN), declared
 * method-level as required by the ArchUnit {@code restControllersMustBeSecured} rule.</p>
 *
 * <p>The query runs on demand (user presses the button); nothing is fetched automatically.</p>
 */
@RestController
@RequestMapping("/api/v1/central/received-data")
@RequiredArgsConstructor
@Slf4j
public class ReceivedDenominationsController {

    private final ReceivedDenominationsService receivedDenominationsService;

    /**
     * GET /api/v1/central/received-data/denominations?date=&amp;branchId=
     *
     * @param branchId optional; when omitted the company's branches are aggregated.
     */
    @GetMapping("/denominations")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<ReceivedDenominationsDto> denominations(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) UUID branchId) {
        log.info("GET /api/v1/central/received-data/denominations date={}, branchId={}", date, branchId);
        return ResponseEntity.ok(receivedDenominationsService.load(date, branchId));
    }
}
