package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.CashFlowReportDto;
import hu.puzzleir.valuta.service.CashFlowReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

/**
 * FKH-030: Pénzforgalom riport — Bank/Terület/Pénztár felé irányuló pénzmozgások
 * bizonylatonkénti listája tetszőleges dátumtartományra.
 *
 * <p>Az RBAC-kör a {@code HufDaybookController} mintáját követi. A terület-szűrést
 * (FR-9) a szolgáltatás BELSŐLEG alkalmazza az
 * {@code AccessScopeService.vaultRegionBranchScopeOrNull()} segítségével — a kliens
 * SOHA nem küldi a scope-ot, így nem is tágíthatja.</p>
 */
@RestController
@RequestMapping("/api/v1/reports/cash-flow")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
@Tag(name = "Pénzforgalom riport", description = "FKH-030 — Transfer + Shipment pénzmozgások tartományra")
public class CashFlowReportController {

    private final CashFlowReportService cashFlowReportService;

    @GetMapping
    @Operation(summary = "Pénzforgalom riport lekérdezése dátumtartományra")
    public ResponseEntity<CashFlowReportDto> getReport(
            @RequestParam("from") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam("to") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(cashFlowReportService.getReport(from, to));
    }
}
