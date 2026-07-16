package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeDailySummaryDto;
import hu.puzzleir.valuta.service.HandlingFeeDailySummaryService;
import hu.puzzleir.valuta.service.ReportExportService;
import lombok.RequiredArgsConstructor;
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

/**
 * FK-053: napi készpénzes kezelési díj riport végpontok.
 * A class-level @PreAuthorize a repo kötelező authenticated kapuja; a szerep-RBAC a service-ben
 * fut, hogy a megtagadás ACCESS_DENIED auditot készítsen.
 */
@RestController
@RequestMapping("/api/v1/handling-fees")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class HandlingFeeDailySummaryController {

    private final HandlingFeeDailySummaryService service;
    private final ReportExportService reportExportService;

    @GetMapping("/daily-summary")
    public ResponseEntity<HandlingFeeDailySummaryDto> dailySummary(
            @RequestParam(required = false) UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(service.getDailySummary(branchId, startDate, endDate));
    }

    @GetMapping("/daily-summary/csv")
    public ResponseEntity<byte[]> dailySummaryCsv(
            @RequestParam(required = false) UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        HandlingFeeDailySummaryDto report = service.getDailySummary(branchId, startDate, endDate);
        byte[] bom = reportExportService.getBom();
        byte[] csv = reportExportService.exportHandlingFeeDailySummaryCsv(report)
                .getBytes(StandardCharsets.UTF_8);
        byte[] body = new byte[bom.length + csv.length];
        System.arraycopy(bom, 0, body, 0, bom.length);
        System.arraycopy(csv, 0, body, bom.length, csv.length);
        String filename = "kezelesi-dij-napi-" + startDate + "-" + endDate + ".csv";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(body);
    }
}
