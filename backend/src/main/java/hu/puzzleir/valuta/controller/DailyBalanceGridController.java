package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.DailyBalanceGridRowDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.DailyBalanceGridService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * FK-047: Napi ellenőrző lista grid REST endpoint (read-only).
 *
 * <p>A {@code daily_balance} tábla (FK-046) pénztári adatait szolgálja ki valutánkénti
 * bontásban, scope-szűréssel (teljes cég / terület / pénztár) + dátummal. RBAC (FK-047 §3):
 * Főértéktáros / Ügyvezető / Belső ellenőr kanonikus + legacy MANAGER / SUPERVISOR / ADMIN —
 * az {@code AverageRateReportController} bevált mintája szerint (fantom role-név nélkül).</p>
 */
@RestController
@RequestMapping("/api/v1/reports/daily-balance-grid")
@RequiredArgsConstructor
public class DailyBalanceGridController {

    private final DailyBalanceGridService service;
    private final AuditLogService auditLogService;

    /**
     * Valutánkénti összesített napi mérleg-sorok.
     *
     * @param date             a mérleg napja (ISO)
     * @param branchId         opcionális pénztár-szűrő
     * @param vaultTerritoryId opcionális terület-szűrő (csak branchId nélkül értelmezett)
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','SUPERVISOR','ADMIN','FOERTEKTAR','UGYVEZETO','BELSO_ELLENOR')")
    public ResponseEntity<List<DailyBalanceGridRowDto>> getGrid(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) Integer vaultTerritoryId
    ) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<DailyBalanceGridRowDto> rows = service.getGrid(
                companyId, date, branchId, vaultTerritoryId);
        auditLogService.log(
                "DAILY_BALANCE_GRID_READ",
                String.format("{\"KAT\":\"EXT\",\"date\":\"%s\",\"branchId\":%s,\"vaultTerritoryId\":%s}",
                        date, jsonStringOrNull(branchId), jsonStringOrNull(vaultTerritoryId)),
                (String) null);
        return ResponseEntity.ok(rows);
    }

    private static String jsonStringOrNull(Object value) {
        return value == null ? "null" : "\"" + value + "\"";
    }
}
