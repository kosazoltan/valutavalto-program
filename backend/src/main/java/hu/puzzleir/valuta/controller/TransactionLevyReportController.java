package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.levy.TransactionLevyReportDto;
import hu.puzzleir.valuta.service.TransactionLevyReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;

/**
 * FK-099 — tranzakciós illeték riport végpont. Company a JWT-ből
 * (SecurityUtils), a kliens companyId-t nem küldhet. WU1: metódusok megvannak,
 * az osztály-szintű @PreAuthorize("isAuthenticated()") a WU6-ban kerül rá
 * (az a viselkedés, amit a TransactionLevyControllerSecurityTest tesztel).
 */
@RestController
@RequestMapping("/api/v1/reports/transaction-levy")
@RequiredArgsConstructor
public class TransactionLevyReportController {

    private final TransactionLevyReportService reportService;

    @GetMapping
    public ResponseEntity<TransactionLevyReportDto> report(
            @RequestParam(required = false) UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(reportService.getReport(branchId, from, to));
    }
}
