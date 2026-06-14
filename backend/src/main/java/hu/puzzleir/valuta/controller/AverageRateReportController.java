package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.AverageRateReportDto;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditEventService;
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
    private final AuditEventService auditEventService;

    /**
     * FK-027: pivot átlag árfolyam riport (sorok = 22 valuta, oszlopcsoportok = 8 terület +
     * "EXCLUSIVE BEST CHANGE ZRT" összesítő, vagy 1 fiók). Vétel és Eladás mindig párhuzamosan.
     *
     * <p>GET /api/v1/reports/average-rate/pivot — additív végpont (a régi GET nem törik). Audit:
     * action=READ, entity_type='AverageRateReport' (FR-9).</p>
     *
     * @param branchId null = "Összes iroda" (9 oszlopcsoport); egyébként 1 fiók-oszlopcsoport
     */
    @GetMapping("/pivot")
    @PreAuthorize("hasAnyRole('MANAGER','TREASURY_MANAGER','MAIN_TREASURY','ADMIN',"
            + "'REGIONAL_MANAGER','SUPERVISOR','CASHIER_SUPERVISOR')")
    public ResponseEntity<AverageRateReportResponse> generatePivot(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId
    ) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        AverageRateReportResponse response = service.generatePivot(companyId, from, to, branchId);
        auditAccess("READ", from, to, branchId);
        return ResponseEntity.ok(response);
    }

    /** FR-9: read/export audit-esemény az AverageRateReport entitásra (hash-láncolt audit_log). */
    private void auditAccess(String action, LocalDate from, LocalDate to, UUID branchId) {
        try {
            auditEventService.appendEvent(AuditEventService.AuditEventRequest.builder()
                    .eventType("AVERAGE_RATE_REPORT_" + action)
                    .action(action)
                    .entityType("AverageRateReport")
                    .afterStateJson(String.format(
                            "{\"from\":\"%s\",\"to\":\"%s\",\"branchId\":%s}",
                            from, to, branchId == null ? "null" : "\"" + branchId + "\""))
                    .build());
        } catch (Exception ignored) {
            // Az audit-hiba NEM blokkolhatja a riport-olvasást (best-effort, mint a diagnostics-nál).
        }
    }

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
