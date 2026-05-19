package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.AverageRateReportDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AverageRateReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Átlag árfolyam riport REST endpoint — legacy ATLAGARF parity (Sprint A P2.5).
 *
 * <p>Csak főértéktáros / iroda-vezető / vezetői szerepkör érheti el.</p>
 */
@RestController
@RequestMapping("/api/v1/reports/average-rate")
@RequiredArgsConstructor
public class AverageRateReportController {

    private final AverageRateReportService service;

    /**
     * Súlyozott átlag árfolyam riport lekérdezés.
     *
     * @param from            időszak kezdete (YYYY-MM-DD)
     * @param to              időszak vége (YYYY-MM-DD, inclusive)
     * @param branchId        opcionális iroda-szűrő (null = összes iroda)
     * @param currencyId      opcionális valuta-szűrő
     * @param transactionType opcionális típus-szűrő (BUY / SELL / null=mind)
     * @return riport sorok valuta szerint
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','TREASURY_MANAGER','MAIN_TREASURY','ADMIN',"
            + "'REGIONAL_MANAGER','SUPERVISOR','CASHIER_SUPERVISOR')")
    public ResponseEntity<List<AverageRateReportDto>> generate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) Long currencyId,
            @RequestParam(required = false) String transactionType
    ) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return ResponseEntity.ok(
                service.generate(companyId, from, to, branchId, currencyId, transactionType));
    }
}
