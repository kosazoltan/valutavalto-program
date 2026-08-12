package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.AverageRateReportResponse;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditEventService;
import hu.puzzleir.valuta.service.AverageRateReportExcelService;
import hu.puzzleir.valuta.service.AverageRateReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Átlag árfolyam riport REST endpoint — legacy ATLAGARF parity (Sprint A P2.5).
 *
 * <p>FK-049: csak a Főértéktáros ({@code FOERTEKTAR}), Ügyvezető ({@code UGYVEZETO}) és Belső
 * ellenőr ({@code BELSO_ELLENOR}) kanonikus szerepkör, valamint a legacy {@code MANAGER} /
 * {@code SUPERVISOR} / {@code ADMIN} érheti el. (Az irodavezető / területi vezető / pénzügyi
 * vezető NEM — a korábbi négy fantom szerepkör-név sem engedett be senkit, csak megtévesztő volt.)</p>
 */
@RestController
@RequestMapping("/api/v1/reports/average-rate")
@RequiredArgsConstructor
public class AverageRateReportController {

    private final AverageRateReportService service;
    private final AverageRateReportExcelService excelService;
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
    @PreAuthorize("hasAnyRole('MANAGER','SUPERVISOR','ADMIN','FOERTEKTAR','UGYVEZETO','BELSO_ELLENOR')")
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

    /**
     * FK-027 (FR-8): az átlag árfolyam pivot riport Excel exportja (legacy Atlagarfolyam.xls).
     *
     * <p>GET /api/v1/reports/average-rate/export — MINDIG a teljes 9-oszlopcsoportos struktúra
     * (8 terület + összesítő), 22 valuta-sorral; csak a dátum-intervallum szűr (nincs branchId).
     * Audit: action=EXPORT (FR-9).</p>
     */
    @GetMapping("/export")
    @PreAuthorize("hasAnyRole('MANAGER','SUPERVISOR','ADMIN','FOERTEKTAR','UGYVEZETO','BELSO_ELLENOR')")
    public ResponseEntity<byte[]> export(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to
    ) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        byte[] xlsx = excelService.generate(companyId, from, to);
        auditAccess("EXPORT", from, to, null);
        String filename = "atlag_arfolyam_" + from + "_" + to + ".xlsx";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType(
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(xlsx);
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
}
