package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.BookingExportService;
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
 * Könyvelési export controller — CSV letöltés.
 *
 * Endpointok:
 * - GET /daily?branchId=&date=       → napi CSV
 * - GET /monthly?branchId=&month=    → havi CSV
 * - GET /inventory?branchId=&date=   → készlet CSV
 */
@RestController
@RequestMapping("/api/v1/booking")
@RequiredArgsConstructor
public class BookingExportController {

    private final BookingExportService service;

    @GetMapping("/daily")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> exportDaily(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] csv = service.exportDailyBooking(branchId, date);
        return buildCsvResponse(csv, "konyveles-napi-" + date + ".csv");
    }

    @GetMapping("/monthly")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> exportMonthly(
            @RequestParam UUID branchId,
            @RequestParam String month) {
        byte[] csv = service.exportMonthlyBooking(branchId, month);
        return buildCsvResponse(csv, "konyveles-havi-" + month + ".csv");
    }

    @GetMapping("/inventory")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> exportInventory(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] csv = service.exportInventoryReport(branchId, date);
        return buildCsvResponse(csv, "keszlet-" + date + ".csv");
    }

    private ResponseEntity<byte[]> buildCsvResponse(byte[] data, String filename) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .contentLength(data.length)
                .body(data);
    }
}
