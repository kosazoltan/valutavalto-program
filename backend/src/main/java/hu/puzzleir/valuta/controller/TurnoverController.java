package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TurnoverService;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.UUID;

/**
 * Forgalom összesítő REST végpontok.
 */
@PreAuthorize("hasAnyRole('FOERTEKTAR', 'UGYVEZETO', 'BELSO_ELLENOR', 'PENZUGYI_VEZETO')")
@RestController
@RequestMapping("/api/v1/turnover")
@RequiredArgsConstructor
@Validated
public class TurnoverController {

    private final TurnoverService turnoverService;

    @GetMapping("/daily")
    public ResponseEntity<TurnoverReportDto> daily(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(turnoverService.getDailyTurnover(branchId, date));
    }

    @GetMapping("/weekly")
    public ResponseEntity<TurnoverReportDto> weekly(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        return ResponseEntity.ok(turnoverService.getWeeklyTurnover(branchId, weekStart));
    }

    @GetMapping("/monthly")
    public ResponseEntity<TurnoverReportDto> monthly(
            @RequestParam UUID branchId,
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(turnoverService.getMonthlyTurnover(branchId, YearMonth.of(year, month)));
    }

    @GetMapping("/yearly")
    public ResponseEntity<TurnoverReportDto> yearly(
            @RequestParam UUID branchId,
            @RequestParam int year) {
        return ResponseEntity.ok(turnoverService.getYearlyTurnover(branchId, year));
    }

    @GetMapping("/company")
    public ResponseEntity<TurnoverReportDto> company(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        // IDOR-fix (audit 2026-05-17): a companyId SecurityUtils-ből,
        // SOHA nem kliens-küldött @RequestParam-ból
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        return ResponseEntity.ok(turnoverService.getCompanyTurnover(currentCompanyId, from, to));
    }

    /**
     * FK-045 FR-9: egy értéktári terület (vault_territory) összes pénztárának összesített forgalma.
     * A companyId SecurityUtils-ből (NEM kliens-param) — multi-tenant izoláció; a service a
     * vaultTerritoryId cég-hovatartozását is ellenőrzi (idegen tenant területe → 404).
     */
    @GetMapping("/territory")
    public ResponseEntity<TurnoverReportDto> territory(
            @RequestParam @NotNull Integer vaultTerritoryId,
            @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        return ResponseEntity.ok(
            turnoverService.getVaultTerritoryTurnover(currentCompanyId, vaultTerritoryId, from, to));
    }
}
