package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.PosHandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.service.AuditEventService;
import hu.puzzleir.valuta.service.PosHandlingFeeDailySummaryService;
import hu.puzzleir.valuta.service.ReportExportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.UUID;

/** FK-059: daily POS net and handling-fee report endpoints. */
@RestController
@RequestMapping("/api/v1/handling-fees")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
@Slf4j
public class PosHandlingFeeDailySummaryController {

    private final PosHandlingFeeDailySummaryService service;
    private final ReportExportService reportExportService;
    private final AuditEventService auditEventService;

    @GetMapping("/pos-daily-summary")
    public ResponseEntity<PosHandlingFeeDailySummaryDto> dailySummary(
            @RequestParam(required = false) UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getDailySummary(branchId, startDate, endDate));
    }

    @GetMapping("/pos-daily-summary/csv")
    public ResponseEntity<byte[]> dailySummaryCsv(
            @RequestParam(required = false) UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        PosHandlingFeeDailySummaryDto report = service.getDailySummary(branchId, startDate, endDate);
        byte[] bom = reportExportService.getBom();
        byte[] csv = reportExportService.exportPosHandlingFeeDailySummaryCsv(report)
                .getBytes(StandardCharsets.UTF_8);
        byte[] body = new byte[bom.length + csv.length];
        System.arraycopy(bom, 0, body, 0, bom.length);
        System.arraycopy(csv, 0, body, bom.length, csv.length);
        String filename = "kezelesi-dij-pos-napi-" + startDate + "-" + endDate + ".csv";
        auditExport(startDate, endDate, branchId);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(body);
    }

    private void auditExport(LocalDate startDate, LocalDate endDate, UUID branchId) {
        try {
            auditEventService.appendEvent(AuditEventService.AuditEventRequest.builder()
                    .eventType("POS_HANDLING_FEE_DAILY_SUMMARY_EXPORT")
                    .action("EXPORT")
                    .entityType("PosHandlingFeeDailySummary")
                    .afterStateJson(String.format(
                            "{\"startDate\":\"%s\",\"endDate\":\"%s\",\"branchId\":%s}",
                            startDate,
                            endDate,
                            branchId == null ? "null" : "\"" + branchId + "\""))
                    .build());
        } catch (Exception e) {
            log.warn("FK-059 CSV export audit failed", e);
        }
    }
}
